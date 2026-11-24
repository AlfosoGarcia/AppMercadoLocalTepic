import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'sesion_actual.dart';

class ComercianteScreen extends StatefulWidget {
  const ComercianteScreen({super.key});

  @override
  State<ComercianteScreen> createState() => _ComercianteScreenState();
}

class _ComercianteScreenState extends State<ComercianteScreen>
    with SingleTickerProviderStateMixin {
  static const String baseUrl = 'http://localhost:5002/api';

  late TabController _tabController;

  List<dynamic> pedidos = [];
  bool cargandoPedidos = true;

  List<dynamic> misProductos = [];
  bool cargandoProductos = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    obtenerPedidos();
    obtenerMisProductos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> obtenerPedidos() async {
    setState(() => cargandoPedidos = true);
    try {
      final String queryParam = SesionActual.usuarioId != null
          ? '?comercianteId=${SesionActual.usuarioId}'
          : '';
      final response = await http.get(Uri.parse('$baseUrl/pedidos$queryParam'));
      if (response.statusCode == 200) {
        setState(() {
          pedidos = json.decode(response.body);
          cargandoPedidos = false;
        });
      }
    } catch (e) {
      setState(() => cargandoPedidos = false);
    }
  }

  Future<void> obtenerMisProductos() async {
    setState(() => cargandoProductos = true);
    try {
      final String queryParam = SesionActual.usuarioId != null
          ? '?comercianteId=${SesionActual.usuarioId}'
          : '';
      final response =
          await http.get(Uri.parse('$baseUrl/productos$queryParam'));
      if (response.statusCode == 200) {
        setState(() {
          misProductos = json.decode(response.body);
          cargandoProductos = false;
        });
      }
    } catch (e) {
      setState(() => cargandoProductos = false);
    }
  }

  Future<void> marcarListoParaEnvio(int pedidoId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/pedidos/$pedidoId/estado'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'estado': 'Listo para envío'}),
      );

      if (response.statusCode == 200) {
        await obtenerPedidos();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Pedido #$pedidoId marcado como Listo para envío'),
              backgroundColor: Colors.blue.shade700,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al actualizar pedido')),
        );
      }
    }
  }

  void mostrarDialogoNuevoProducto() {
    final formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController();
    final descController = TextEditingController();
    final precioController = TextEditingController();
    final stockController = TextEditingController(text: '10');
    bool guardando = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> guardar() async {
              if (!formKey.currentState!.validate()) return;
              setDialogState(() => guardando = true);

              try {
                final response = await http.post(
                  Uri.parse('$baseUrl/productos'),
                  headers: {'Content-Type': 'application/json'},
                  body: json.encode({
                    'nombre': nombreController.text.trim(),
                    'descripcion': descController.text.trim(),
                    'precio': double.parse(precioController.text.trim()),
                    'stock': int.parse(stockController.text.trim()),
                    'comercianteId': SesionActual.usuarioId,
                    'nombreTienda': SesionActual.nombre ?? 'Tienda Local',
                  }),
                );

                if (response.statusCode == 200 || response.statusCode == 201) {
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                  await obtenerMisProductos();
                  if (mounted) {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(
                        content: Text('Producto publicado en tu tienda'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } else {
                  setDialogState(() => guardando = false);
                }
              } catch (e) {
                setDialogState(() => guardando = false);
              }
            }

            return AlertDialog(
              title: const Text('Nuevo Producto'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nombreController,
                        decoration:
                            const InputDecoration(labelText: 'Nombre del producto'),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Obligatorio' : null,
                      ),
                      TextFormField(
                        controller: descController,
                        decoration:
                            const InputDecoration(labelText: 'Descripción breve'),
                      ),
                      TextFormField(
                        controller: precioController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Precio (\$)'),
                        validator: (v) =>
                            (v == null || double.tryParse(v) == null)
                                ? 'Ingresa un precio válido'
                                : null,
                      ),
                      TextFormField(
                        controller: stockController,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Stock inicial'),
                        validator: (v) =>
                            (v == null || int.tryParse(v) == null)
                                ? 'Ingresa cantidad entera'
                                : null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: guardando ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: guardando ? null : guardar,
                  child: Text(guardando ? 'Guardando...' : 'Publicar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _construirTabPedidos() {
    if (cargandoPedidos) {
      return const Center(child: CircularProgressIndicator());
    }

    if (pedidos.isEmpty) {
      return const Center(
        child: Text(
          'Aún no hay pedidos para tu tienda',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: pedidos.length,
      itemBuilder: (context, index) {
        final pedido = pedidos[index];
        final int id = pedido['id'];
        final String estado = pedido['estado'] ?? 'Pendiente';
        final double total = (pedido['total'] as num?)?.toDouble() ?? 0.0;
        final List<dynamic> detalles = pedido['detalles'] ?? [];

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
                      'Pedido #$id • ${pedido['clienteNombre']}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Chip(
                      label: Text(
                        estado,
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: estado == 'Pendiente'
                          ? Colors.orange.shade100
                          : Colors.green.shade100,
                    ),
                  ],
                ),
                Text(
                  'Dirección: ${pedido['direccionEntrega']} • Tel: ${pedido['telefono']}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
                const Divider(),
                ...detalles.map((d) => Text(
                      '• ${d['cantidad']} x ${d['nombreProducto']}',
                      style: const TextStyle(fontSize: 14),
                    )),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total tienda: \$${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green,
                      ),
                    ),
                    if (estado == 'Pendiente')
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => marcarListoParaEnvio(id),
                        icon: const Icon(Icons.check),
                        label: const Text('Listo para envío'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _construirTabProductos() {
    if (cargandoProductos) {
      return const Center(child: CircularProgressIndicator());
    }

    if (misProductos.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Tu tienda aún no tiene productos publicados',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: mostrarDialogoNuevoProducto,
              icon: const Icon(Icons.add),
              label: const Text('Agregar primer producto'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: misProductos.length,
      itemBuilder: (context, index) {
        final prod = misProductos[index];
        final double precio = (prod['precio'] as num).toDouble();
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.inventory_2, color: Colors.blue),
            title: Text(
              prod['nombre'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(prod['descripcion'] ?? ''),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${precio.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Text(
                  'Stock: ${prod['stock']}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String titulo = SesionActual.nombre != null
        ? 'Tienda: ${SesionActual.nombre}'
        : 'Panel Comerciante';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          titulo,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: () {
              obtenerPedidos();
              obtenerMisProductos();
            },
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(
              icon: const Icon(Icons.receipt_long),
              text: 'Pedidos (${pedidos.length})',
            ),
            Tab(
              icon: const Icon(Icons.store),
              text: 'Mis Productos (${misProductos.length})',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _construirTabPedidos(),
          _construirTabProductos(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        onPressed: mostrarDialogoNuevoProducto,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Producto'),
      ),
    );
  }
}