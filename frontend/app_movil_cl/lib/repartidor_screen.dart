import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RepartidorScreen extends StatefulWidget {
  const RepartidorScreen({super.key});

  @override
  State<RepartidorScreen> createState() => _RepartidorScreenState();
}

class _RepartidorScreenState extends State<RepartidorScreen> {
  static const String baseUrl = 'http://localhost:5002/api';

  List<dynamic> todosLosPedidos = [];
  bool cargando = true;
  String? errorMensaje;
  final Set<int> _procesandoIds = {};

  @override
  void initState() {
    super.initState();
    obtenerPedidos();
  }

  Future<void> obtenerPedidos() async {
    setState(() {
      cargando = true;
      errorMensaje = null;
    });

    try {
      final response = await http.get(Uri.parse('$baseUrl/pedidos'));

      if (response.statusCode == 200) {
        setState(() {
          todosLosPedidos = json.decode(response.body);
          cargando = false;
        });
      } else {
        setState(() {
          errorMensaje = 'Error del servidor: ${response.statusCode}';
          cargando = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMensaje = 'No se pudo conectar con la API en localhost:5002';
        cargando = false;
      });
    }
  }

  Future<void> confirmarCobroYEntrega(int pedidoId, double total) async {
    setState(() {
      _procesandoIds.add(pedidoId);
    });

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/pedidos/$pedidoId/estado'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'nuevoEstado': 'Entregado y Pagado'}),
      );

      if (response.statusCode == 200) {
        setState(() {
          final index = todosLosPedidos.indexWhere((p) => p['id'] == pedidoId);
          if (index != -1) {
            todosLosPedidos[index]['estado'] = 'Entregado y Pagado';
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Pedido #$pedidoId completado • Efectivo cobrado: \$${total.toStringAsFixed(2)}',
              ),
              backgroundColor: Colors.green.shade700,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al actualizar (${response.statusCode})'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error de conexión con el servidor'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _procesandoIds.remove(pedidoId);
        });
      }
    }
  }

  Widget _construirListaPedidos(List<dynamic> lista,
      {required bool esRutaActiva}) {
    if (cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMensaje != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(errorMensaje!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: obtenerPedidos,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (lista.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              esRutaActiva ? Icons.delivery_dining : Icons.check_circle_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              esRutaActiva
                  ? 'No hay pedidos listos para recoger'
                  : 'Aún no has completado entregas',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: lista.length,
      itemBuilder: (context, index) {
        final pedido = lista[index];
        final int id = pedido['id'] ?? 0;
        final String cliente = pedido['clienteNombre'] ?? 'Sin nombre';
        final String direccion = pedido['direccionEntrega'] ?? 'Sin dirección';
        final String telefono = pedido['telefono'] ?? 'Sin teléfono';
        final double total = (pedido['total'] as num?)?.toDouble() ?? 0.0;
        final List<dynamic> detalles = pedido['detalles'] ?? [];
        final bool procesando = _procesandoIds.contains(id);

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pedido #$id',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: esRutaActiva
                            ? Colors.amber.shade100
                            : Colors.green.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: esRutaActiva
                              ? Colors.amber.shade700
                              : Colors.green.shade700,
                        ),
                      ),
                      child: Text(
                        esRutaActiva
                            ? 'Cobrar: \$${total.toStringAsFixed(2)}'
                            : 'Cobrado: \$${total.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: esRutaActiva
                              ? Colors.amber.shade900
                              : Colors.green.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(),
                Row(
                  children: [
                    const Icon(Icons.person, size: 18, color: Colors.blueGrey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        cliente,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on, size: 18, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        direccion,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.phone, size: 18, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      telefono,
                      style: const TextStyle(fontSize: 15),
                    ),
                  ],
                ),
                const Divider(),
                Text(
                  'Paquete (${detalles.length} producto${detalles.length == 1 ? '' : 's'}):',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                ...detalles.map((det) {
                  return Text(
                    '• ${det['cantidad']} x ${det['nombreProducto']}',
                    style: const TextStyle(fontSize: 14),
                  );
                }),
                if (esRutaActiva) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      onPressed: procesando
                          ? null
                          : () => confirmarCobroYEntrega(id, total),
                      icon: procesando
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.payments_outlined),
                      label: Text(
                        procesando
                            ? 'Registrando pago...'
                            : 'Confirmar Cobro en Efectivo y Entrega',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final porEntregar = todosLosPedidos
        .where((p) => p['estado'] == 'Listo para envío')
        .toList();
    final entregados = todosLosPedidos
        .where((p) => p['estado'] == 'Entregado y Pagado')
        .toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Panel de Repartidor',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.teal.shade800,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              tooltip: 'Actualizar envíos',
              onPressed: obtenerPedidos,
              icon: const Icon(Icons.refresh),
            ),
          ],
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(
                icon: const Icon(Icons.delivery_dining),
                text: 'Por Entregar (${porEntregar.length})',
              ),
              Tab(
                icon: const Icon(Icons.task_alt),
                text: 'Completados (${entregados.length})',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _construirListaPedidos(porEntregar, esRutaActiva: true),
            _construirListaPedidos(entregados, esRutaActiva: false),
          ],
        ),
      ),
    );
  }
}