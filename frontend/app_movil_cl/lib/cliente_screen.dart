import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ClienteScreen extends StatefulWidget {
  const ClienteScreen({super.key});

  @override
  State<ClienteScreen> createState() => _ClienteScreenState();
}

class _ClienteScreenState extends State<ClienteScreen> {
  static const String baseUrl = 'http://localhost:5002/api';

  List<dynamic> productos = [];
  bool cargando = true;
  String? errorMensaje;

  final Map<int, Map<String, dynamic>> carrito = {};

  @override
  void initState() {
    super.initState();
    obtenerProductos();
  }

  Future<void> obtenerProductos() async {
    setState(() {
      cargando = true;
      errorMensaje = null;
    });

    try {
      final response = await http.get(Uri.parse('$baseUrl/productos'));

      if (response.statusCode == 200) {
        setState(() {
          productos = json.decode(response.body);
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

  void agregarAlCarrito(Map<String, dynamic> producto) {
    final int id = producto['id'];
    final int stockDisponible = producto['stock'] ?? 0;
    final int cantidadActual =
        carrito.containsKey(id) ? carrito[id]!['cantidad'] : 0;

    if (cantidadActual >= stockDisponible) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Stock máximo alcanzado (${producto['nombre']})'),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      if (carrito.containsKey(id)) {
        carrito[id]!['cantidad'] += 1;
      } else {
        carrito[id] = {
          'producto': producto,
          'cantidad': 1,
        };
      }
    });
  }

  void quitarDelCarrito(int id) {
    if (!carrito.containsKey(id)) return;
    setState(() {
      if (carrito[id]!['cantidad'] > 1) {
        carrito[id]!['cantidad'] -= 1;
      } else {
        carrito.remove(id);
      }
    });
  }

  int get totalArticulos {
    int suma = 0;
    for (var item in carrito.values) {
      suma += item['cantidad'] as int;
    }
    return suma;
  }

  double get totalPagar {
    double total = 0.0;
    for (var item in carrito.values) {
      final double precio = (item['producto']['precio'] as num).toDouble();
      final int cantidad = item['cantidad'] as int;
      total += precio * cantidad;
    }
    return total;
  }

  void mostrarResumenCarrito() {
    final formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController();
    final direccionController = TextEditingController();
    final telefonoController = TextEditingController();

    bool enviandoPedido = false;
    String? errorEnvio;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final items = carrito.values.toList();

            Future<void> confirmarYEnviarPedido() async {
              if (!formKey.currentState!.validate()) return;

              setModalState(() {
                enviandoPedido = true;
                errorEnvio = null;
              });

              final double montoFinal = totalPagar;

              final payload = {
                'clienteNombre': nombreController.text.trim(),
                'direccionEntrega': direccionController.text.trim(),
                'telefono': telefonoController.text.trim(),
                'items': items
                    .map((item) => {
                          'productoId': item['producto']['id'],
                          'cantidad': item['cantidad'],
                        })
                    .toList(),
              };

              try {
                final response = await http.post(
                  Uri.parse('$baseUrl/pedidos'),
                  headers: {'Content-Type': 'application/json'},
                  body: json.encode(payload),
                );

                if (response.statusCode == 201 || response.statusCode == 200) {
                  final data = json.decode(response.body);
                  final pedidoId = data['pedidoId'];

                  if (modalContext.mounted) {
                    Navigator.pop(modalContext);
                  }

                  setState(() {
                    carrito.clear();
                  });

                  await obtenerProductos();

                  if (mounted) {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Pedido #$pedidoId enviado • Pagarás \$${montoFinal.toStringAsFixed(2)} en efectivo al recibir',
                        ),
                        backgroundColor: Colors.green.shade700,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }
                } else {
                  setModalState(() {
                    enviandoPedido = false;
                    errorEnvio =
                        'No se pudo registrar (${response.statusCode}): ${response.body}';
                  });
                }
              } catch (e) {
                setModalState(() {
                  enviandoPedido = false;
                  errorEnvio = 'Error de conexión con el servidor.';
                });
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tu Carrito y Entrega',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: enviandoPedido
                              ? null
                              : () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(),
                    if (items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Text(
                          'Tu carrito está vacío',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      )
                    else ...[
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final prod = items[index]['producto'];
                            final int cant = items[index]['cantidad'];
                            final double precio =
                                (prod['precio'] as num).toDouble();
                            final double subtotal = precio * cant;

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              title: Text(
                                prod['nombre'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                '\$${precio.toStringAsFixed(2)} c/u  •  Subtotal: \$${subtotal.toStringAsFixed(2)}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                      color: Colors.red,
                                    ),
                                    onPressed: enviandoPedido
                                        ? null
                                        : () {
                                            quitarDelCarrito(prod['id']);
                                            setModalState(() {});
                                          },
                                  ),
                                  Text(
                                    '$cant',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.add_circle_outline,
                                      color: Colors.green,
                                    ),
                                    onPressed: enviandoPedido
                                        ? null
                                        : () {
                                            agregarAlCarrito(prod);
                                            setModalState(() {});
                                          },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const Divider(),
                      const Text(
                        'Datos de Entrega (Pago en efectivo al recibir)',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Form(
                        key: formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: nombreController,
                              enabled: !enviandoPedido,
                              decoration: const InputDecoration(
                                labelText: 'Nombre completo',
                                prefixIcon: Icon(Icons.person_outline),
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              validator: (val) =>
                                  (val == null || val.trim().isEmpty)
                                      ? 'Ingresa tu nombre'
                                      : null,
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: direccionController,
                              enabled: !enviandoPedido,
                              decoration: const InputDecoration(
                                labelText: 'Dirección en Tepic (Calle, # y Col.)',
                                prefixIcon: Icon(Icons.location_on_outlined),
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              validator: (val) =>
                                  (val == null || val.trim().isEmpty)
                                      ? 'Ingresa la dirección de entrega'
                                      : null,
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: telefonoController,
                              enabled: !enviandoPedido,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Teléfono / WhatsApp',
                                prefixIcon: Icon(Icons.phone_outlined),
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              validator: (val) =>
                                  (val == null || val.trim().length < 7)
                                      ? 'Ingresa un teléfono válido'
                                      : null,
                            ),
                          ],
                        ),
                      ),
                      if (errorEnvio != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade300),
                          ),
                          child: Text(
                            errorEnvio!,
                            style: TextStyle(
                              color: Colors.red.shade900,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total a pagar:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '\$${totalPagar.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed:
                            enviandoPedido ? null : confirmarYEnviarPedido,
                        icon: enviandoPedido
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_circle),
                        label: Text(
                          enviandoPedido
                              ? 'Registrando pedido...'
                              : 'Confirmar Pedido',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tienda Local Tepic',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Actualizar catálogo',
            onPressed: obtenerProductos,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Ver carrito',
            onPressed: mostrarResumenCarrito,
            icon: Badge(
              label: Text('$totalArticulos'),
              isLabelVisible: totalArticulos > 0,
              child: const Icon(Icons.shopping_cart),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : errorMensaje != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(errorMensaje!,
                          style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: obtenerProductos,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: productos.length,
                  itemBuilder: (context, index) {
                    final prod = productos[index];
                    final int id = prod['id'];
                    final double precio = (prod['precio'] as num).toDouble();
                    final int stock = prod['stock'] ?? 0;
                    final int cantidadEnCarrito =
                        carrito.containsKey(id) ? carrito[id]!['cantidad'] : 0;

                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const Icon(
                          Icons.shopping_bag,
                          color: Colors.green,
                          size: 32,
                        ),
                        title: Text(
                          prod['nombre'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(prod['descripcion'] ?? ''),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  '\$${precio.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  stock > 0 ? 'Stock: $stock' : 'Agotado',
                                  style: TextStyle(
                                    color:
                                        stock > 0 ? Colors.grey[700] : Colors.red,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: stock == 0
                            ? const Chip(label: Text('Sin stock'))
                            : cantidadEnCarrito == 0
                                ? ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () => agregarAlCarrito(prod),
                                    child: const Text('+ Agregar'),
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.remove_circle_outline,
                                          color: Colors.red,
                                        ),
                                        onPressed: () => quitarDelCarrito(id),
                                      ),
                                      Text(
                                        '$cantidadEnCarrito',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.add_circle_outline,
                                          color: Colors.green,
                                        ),
                                        onPressed: () => agregarAlCarrito(prod),
                                      ),
                                    ],
                                  ),
                      ),
                    );
                  },
                ),
      bottomNavigationBar: carrito.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.green.shade700,
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 6),
                ],
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$totalArticulos art.  •  Total: \$${totalPagar.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.green.shade800,
                      ),
                      onPressed: mostrarResumenCarrito,
                      child: const Text(
                        'Ver Carrito',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}