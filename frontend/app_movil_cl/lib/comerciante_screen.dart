import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ComercianteScreen extends StatefulWidget {
  const ComercianteScreen({super.key});

  @override
  State<ComercianteScreen> createState() => _ComercianteScreenState();
}

class _ComercianteScreenState extends State<ComercianteScreen> {
  static const String baseUrl = 'http://localhost:5002/api';

  List<dynamic> pedidos = [];
  bool cargandoPedidos = true;
  String? errorPedidos;
  final Set<int> _actualizandoIds = {};

  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _precioController = TextEditingController();
  final _stockController = TextEditingController();
  bool guardandoProducto = false;

  @override
  void initState() {
    super.initState();
    obtenerPedidos();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _precioController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> obtenerPedidos() async {
    setState(() {
      cargandoPedidos = true;
      errorPedidos = null;
    });

    try {
      final response = await http.get(Uri.parse('$baseUrl/pedidos'));

      if (response.statusCode == 200) {
        setState(() {
          pedidos = json.decode(response.body);
          cargandoPedidos = false;
        });
      } else {
        setState(() {
          errorPedidos = 'Error del servidor: ${response.statusCode}';
          cargandoPedidos = false;
        });
      }
    } catch (e) {
      setState(() {
        errorPedidos = 'No se pudo conectar con la API en localhost:5002';
        cargandoPedidos = false;
      });
    }
  }

  Future<void> marcarListoParaEnvio(int pedidoId) async {
    setState(() {
      _actualizandoIds.add(pedidoId);
    });

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/pedidos/$pedidoId/estado'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'nuevoEstado': 'Listo para envío'}),
      );

      if (response.statusCode == 200) {
        setState(() {
          final index = pedidos.indexWhere((p) => p['id'] == pedidoId);
          if (index != -1) {
            pedidos[index]['estado'] = 'Listo para envío';
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Pedido #$pedidoId listo para el repartidor'),
              backgroundColor: Colors.blue.shade700,
              duration: const Duration(seconds: 2),
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
          _actualizandoIds.remove(pedidoId);
        });
      }
    }
  }

  Future<void> crearProducto() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      guardandoProducto = true;
    });

    final nuevoProducto = {
      'nombre': _nombreController.text.trim(),
      'descripcion': _descripcionController.text.trim(),
      'precio': double.parse(_precioController.text.trim()),
      'stock': int.parse(_stockController.text.trim()),
      'disponible': true,
    };

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/productos'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(nuevoProducto),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        _nombreController.clear();
        _descripcionController.clear();
        _precioController.clear();
        _stockController.clear();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Producto "${nuevoProducto['nombre']}" agregado al catálogo',
              ),
              backgroundColor: Colors.green.shade700,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error al guardar (${response.statusCode}): ${response.body}',
              ),
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
          guardandoProducto = false;
        });
      }
    }
  }

  Color _colorFondoEstado(String estado) {
    switch (estado) {
      case 'Listo para envío':
        return Colors.blue.shade100;
      case 'Entregado y Pagado':
        return Colors.green.shade100;
      default:
        return Colors.orange.shade100;
    }
  }

  Color _colorTextoEstado(String estado) {
    switch (estado) {
      case 'Listo para envío':
        return Colors.blue.shade900;
      case 'Entregado y Pagado':
        return Colors.green.shade900;
      default:
        return Colors.orange.shade900;
    }
  }

  Widget _construirTabPedidos() {
    if (cargandoPedidos) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorPedidos != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(errorPedidos!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: obtenerPedidos,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (pedidos.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'Aún no hay pedidos registrados',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: pedidos.length,
      itemBuilder: (context, index) {
        final pedido = pedidos[index];
        final int id = pedido['id'] ?? 0;
        final String cliente = pedido['clienteNombre'] ?? 'Sin nombre';
        final String direccion = pedido['direccionEntrega'] ?? 'Sin dirección';
        final String telefono = pedido['telefono'] ?? 'Sin teléfono';
        final String estado = pedido['estado'] ?? 'Pendiente';
        final bool esPendiente = estado == 'Pendiente';
        final bool actualizando = _actualizandoIds.contains(id);
        final double total = (pedido['total'] as num?)?.toDouble() ?? 0.0;
        final List<dynamic> detalles = pedido['detalles'] ?? [];

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Pedido #$id',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _colorFondoEstado(estado),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            estado,
                            style: TextStyle(
                              color: _colorTextoEstado(estado),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '\$${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const Divider(),
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        cliente,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(child: Text(direccion)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.phone, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(telefono),
                  ],
                ),
                const Divider(),
                const Text(
                  'Artículos a preparar:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                ...detalles.map((det) {
                  final int cant = det['cantidad'] ?? 0;
                  final String nombreProd = det['nombreProducto'] ?? '';
                  final double precioUnit =
                      (det['precioUnitario'] as num?)?.toDouble() ?? 0.0;
                  final double subtotal = cant * precioUnit;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text('$cant x $nombreProd')),
                        Text(
                          '\$${subtotal.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  );
                }),
                if (esPendiente) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: actualizando
                          ? null
                          : () => marcarListoParaEnvio(id),
                      icon: actualizando
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.inventory_outlined),
                      label: Text(
                        actualizando
                            ? 'Actualizando...'
                            : 'Marcar Listo para Envío',
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

  Widget _construirTabNuevoProducto() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Publicar Producto Local',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'El producto aparecerá de inmediato en el catálogo para los compradores de Tepic.',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nombreController,
                  enabled: !guardandoProducto,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del producto',
                    hintText: 'Ej. Aguacate Hass (kg)',
                    prefixIcon: Icon(Icons.inventory_2_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => (val == null || val.trim().isEmpty)
                      ? 'Ingresa el nombre del producto'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descripcionController,
                  enabled: !guardandoProducto,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    hintText: 'Ej. Cosecha fresca de productores de Nayarit',
                    prefixIcon: Icon(Icons.description_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => (val == null || val.trim().isEmpty)
                      ? 'Ingresa una descripción'
                      : null,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _precioController,
                        enabled: !guardandoProducto,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Precio (\$ MXN)',
                          hintText: '0.00',
                          prefixIcon: Icon(Icons.attach_money),
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Ingresa el precio';
                          }
                          final numero = double.tryParse(val.trim());
                          if (numero == null || numero <= 0) {
                            return 'Precio inválido';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _stockController,
                        enabled: !guardandoProducto,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Stock inicial',
                          hintText: 'Ej. 20',
                          prefixIcon: Icon(Icons.numbers),
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Ingresa el stock';
                          }
                          final entero = int.tryParse(val.trim());
                          if (entero == null || entero <= 0) {
                            return 'Stock inválido';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  onPressed: guardandoProducto ? null : crearProducto,
                  icon: guardandoProducto
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.add_business),
                  label: Text(
                    guardandoProducto
                        ? 'Guardando producto...'
                        : 'Publicar en Catálogo',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Panel de Comerciante',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.blue.shade800,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              tooltip: 'Actualizar pedidos',
              onPressed: obtenerPedidos,
              icon: const Icon(Icons.refresh),
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(
                icon: Icon(Icons.list_alt),
                text: 'Pedidos Recibidos',
              ),
              Tab(
                icon: Icon(Icons.add_circle_outline),
                text: 'Agregar Producto',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _construirTabPedidos(),
            _construirTabNuevoProducto(),
          ],
        ),
      ),
    );
  }
}