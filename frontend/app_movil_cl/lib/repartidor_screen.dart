import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'sesion_actual.dart';

class RepartidorScreen extends StatefulWidget {
  const RepartidorScreen({super.key});

  @override
  State<RepartidorScreen> createState() => _RepartidorScreenState();
}

class _RepartidorScreenState extends State<RepartidorScreen> {
  static const String baseUrl = 'http://localhost:5002/api';

  List<dynamic> pedidos = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    obtenerPedidos();
  }

  Future<void> obtenerPedidos() async {
    setState(() => cargando = true);
    try {
      final String queryParam = SesionActual.usuarioId != null
          ? '?repartidorId=${SesionActual.usuarioId}'
          : '';
      final response = await http.get(Uri.parse('$baseUrl/pedidos$queryParam'));
      if (response.statusCode == 200) {
        final List<dynamic> todos = json.decode(response.body);
        setState(() {
          pedidos = todos
              .where((p) =>
                  p['estado'] == 'Listo para envío' ||
                  p['estado'] == 'Entregado y Pagado')
              .toList();
          cargando = false;
        });
      }
    } catch (e) {
      setState(() => cargando = false);
    }
  }

  Future<void> aceptarEnvio(int pedidoId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/pedidos/$pedidoId/estado'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'estado': 'Listo para envío',
          'repartidorId': SesionActual.usuarioId,
          'repartidorNombre': SesionActual.nombre ?? 'Repartidor',
        }),
      );

      if (response.statusCode == 200) {
        await obtenerPedidos();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Asignaste el pedido #$pedidoId a tu ruta'),
              backgroundColor: Colors.teal.shade700,
            ),
          );
        }
      } else {
        await obtenerPedidos();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.body.replaceAll('"', ''))),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al tomar el pedido')),
        );
      }
    }
  }

  Future<void> marcarEntregadoYPagado(int pedidoId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/pedidos/$pedidoId/estado'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'estado': 'Entregado y Pagado',
          'repartidorId': SesionActual.usuarioId,
          'repartidorNombre': SesionActual.nombre ?? 'Repartidor',
        }),
      );

      if (response.statusCode == 200) {
        await obtenerPedidos();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Pedido #$pedidoId entregado y cobrado'),
              backgroundColor: Colors.green.shade700,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al confirmar entrega')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String titulo = SesionActual.nombre != null
        ? 'Repartidor: ${SesionActual.nombre}'
        : 'Panel Repartidor';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          titulo,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Actualizar envíos',
            onPressed: obtenerPedidos,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () {
              SesionActual.cerrar();
              Navigator.pushReplacementNamed(context, '/login');
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : pedidos.isEmpty
              ? const Center(
                  child: Text(
                    'No hay pedidos listos para envío en este momento',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: pedidos.length,
                  itemBuilder: (context, index) {
                    final pedido = pedidos[index];
                    final int id = pedido['id'];
                    final String estado = pedido['estado'] ?? '';
                    final int? repartidorAsignado = pedido['repartidorId'];
                    final double total =
                        (pedido['total'] as num?)?.toDouble() ?? 0.0;
                    final List<dynamic> detalles = pedido['detalles'] ?? [];

                    final bool esMio = SesionActual.usuarioId == null ||
                        repartidorAsignado == SesionActual.usuarioId;
                    final bool sinAsignar = repartidorAsignado == null;

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Pedido #$id',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Chip(
                                  label: Text(
                                    estado == 'Entregado y Pagado'
                                        ? 'Entregado'
                                        : sinAsignar
                                            ? 'Disponible'
                                            : 'En tu ruta',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  backgroundColor:
                                      estado == 'Entregado y Pagado'
                                          ? Colors.green.shade100
                                          : sinAsignar
                                              ? Colors.amber.shade100
                                              : Colors.teal.shade100,
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text('Cliente: ${pedido['clienteNombre']}'),
                            Text(
                              'Dirección: ${pedido['direccionEntrega']}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text('Teléfono: ${pedido['telefono']}'),
                            const Divider(),
                            ...detalles.map((d) => Text(
                                  '• ${d['cantidad']} x ${d['nombreProducto']} (${d['nombreTienda'] ?? 'Tienda Local'})',
                                )),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Cobrar: \$${total.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                if (estado == 'Listo para envío' &&
                                    sinAsignar &&
                                    SesionActual.usuarioId != null)
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.amber.shade800,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () => aceptarEnvio(id),
                                    icon: const Icon(Icons.delivery_dining),
                                    label: const Text('Tomar envío'),
                                  )
                                else if (estado == 'Listo para envío' && esMio)
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal.shade700,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () => marcarEntregadoYPagado(id),
                                    icon: const Icon(Icons.payments_outlined),
                                    label: const Text('Entregado y Pagado'),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}