import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'sesion_actual.dart';

class ClienteScreen extends StatefulWidget {
  const ClienteScreen({super.key});

  @override
  State<ClienteScreen> createState() => _ClienteScreenState();
}

class _ClienteScreenState extends State<ClienteScreen>
    with SingleTickerProviderStateMixin {
  static const String baseUrl = 'http://localhost:5002/api';

  late TabController _tabController;

  List<dynamic> productos = [];
  bool cargandoProductos = true;
  String? errorProductos;
  final Map<int, Map<String, dynamic>> carrito = {};

  List<dynamic> misPedidos = [];
  bool cargandoPedidos = true;
  String? errorPedidos;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    obtenerProductos();
    obtenerMisPedidos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> obtenerProductos() async {
    setState(() {
      cargandoProductos = true;
      errorProductos = null;
    });

    try {
      final response = await http.get(Uri.parse('$baseUrl/productos'));

      if (response.statusCode == 200) {
        setState(() {
          productos = json.decode(response.body);
          cargandoProductos = false;
        });
      } else {
        setState(() {
          errorProductos = 'Error del servidor: ${response.statusCode}';
          cargandoProductos = false;
        });
      }
    } catch (e) {
      setState(() {
        errorProductos = 'No se pudo conectar con la API en localhost:5002';
        cargandoProductos = false;
      });
    }
  }

  Future<void> obtenerMisPedidos() async {
    setState(() {
      cargandoPedidos = true;
      errorPedidos = null;
    });

    try {
      final String queryParam = SesionActual.usuarioId != null
          ? '?clienteId=${SesionActual.usuarioId}'
          : '';
      final response = await http.get(Uri.parse('$baseUrl/pedidos$queryParam'));

      if (response.statusCode == 200) {
        setState(() {
          misPedidos = json.decode(response.body);
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
    final nombreController =
        TextEditingController(text: SesionActual.nombre ?? '');
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
                'clienteId': SesionActual.usuarioId,
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
                  await obtenerMisPedidos();
                  _tabController.animateTo(1);

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
                            final String tienda =
                                prod['nombreTienda'] ?? 'Tienda Local';

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              title: Text(
                                prod['nombre'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                '$tienda • \$${precio.toStringAsFixed(2)} c/u • Subtotal: \$${subtotal.toStringAsFixed(2)}',
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

  Widget _construirItemProducto(dynamic prod) {
    final int id = prod['id'];
    final double precio = (prod['precio'] as num).toDouble();
    final int stock = prod['stock'] ?? 0;
    final int cantidadEnCarrito =
        carrito.containsKey(id) ? carrito[id]!['cantidad'] : 0;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 6,
        ),
        leading: Icon(
          Icons.shopping_bag_outlined,
          color: Colors.green.shade700,
          size: 28,
        ),
        title: Text(
          prod['nombre'],
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((prod['descripcion'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(prod['descripcion']),
            ],
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
                    color: stock > 0 ? Colors.grey[700] : Colors.red,
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
  }

  Widget _construirTabCatalogo() {
    if (cargandoProductos) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorProductos != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(errorProductos!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: obtenerProductos,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (productos.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.storefront_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            const Text(
              'No hay productos disponibles por el momento',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Agrupar productos por tienda
    final Map<String, Map<String, dynamic>> tiendasMap = {};
    for (final prod in productos) {
      final String nombreTienda =
          (prod['nombreTienda'] ?? 'Tienda Local').toString().trim();
      final String tiendaVisible =
          nombreTienda.isEmpty ? 'Tienda Local' : nombreTienda;
      final String claveTienda =
          '${prod['comercianteId'] ?? 'general'}_$tiendaVisible';

      if (!tiendasMap.containsKey(claveTienda)) {
        tiendasMap[claveTienda] = {
          'nombreTienda': tiendaVisible,
          'productos': <dynamic>[],
        };
      }
      (tiendasMap[claveTienda]!['productos'] as List<dynamic>).add(prod);
    }

    final listaTiendas = tiendasMap.values.toList();

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: listaTiendas.length,
      itemBuilder: (context, index) {
        final tienda = listaTiendas[index];
        final String nombreTienda = tienda['nombreTienda'];
        final List<dynamic> productosTienda = tienda['productos'];

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            initiallyExpanded: true,
            backgroundColor: Colors.white,
            collapsedBackgroundColor: Colors.green.shade50,
            leading: CircleAvatar(
              backgroundColor: Colors.green.shade100,
              child: Icon(
                Icons.storefront,
                color: Colors.green.shade800,
              ),
            ),
            title: Text(
              nombreTienda,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            subtitle: Text(
              '${productosTienda.length} ${productosTienda.length == 1 ? 'producto disponible' : 'productos disponibles'}',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
            children: productosTienda.map((prod) {
              return _construirItemProducto(prod);
            }).toList(),
          ),
        );
      },
    );
  }

  int _pasoActualPedido(String estado) {
    if (estado == 'Entregado y Pagado') return 3;
    if (estado == 'Listo para envío') return 2;
    return 1;
  }

  Widget _construirIndicadorPaso(
      String etiqueta, int numeroPaso, int pasoActual) {
    final bool completado = pasoActual >= numeroPaso;
    return Expanded(
      child: Column(
        children: [
          Container(
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: completado ? Colors.green : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            etiqueta,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: completado ? FontWeight.bold : FontWeight.normal,
              color: completado ? Colors.green.shade800 : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirTabMisPedidos() {
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
              onPressed: obtenerMisPedidos,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (misPedidos.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'Aún no has realizado pedidos con esta cuenta',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: misPedidos.length,
      itemBuilder: (context, index) {
        final pedido = misPedidos[index];
        final int id = pedido['id'] ?? 0;
        final String cliente = pedido['clienteNombre'] ?? 'Cliente';
        final String direccion = pedido['direccionEntrega'] ?? '';
        final String estado = pedido['estado'] ?? 'Pendiente';
        final double total = (pedido['total'] as num?)?.toDouble() ?? 0.0;
        final List<dynamic> detalles = pedido['detalles'] ?? [];
        final int pasoActual = _pasoActualPedido(estado);

        Color colorEstado = Colors.orange.shade800;
        Color fondoEstado = Colors.orange.shade100;
        if (estado == 'Listo para envío') {
          colorEstado = Colors.blue.shade800;
          fondoEstado = Colors.blue.shade100;
        } else if (estado == 'Entregado y Pagado') {
          colorEstado = Colors.green.shade800;
          fondoEstado = Colors.green.shade100;
        }

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
                    Text(
                      'Pedido #$id',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: fondoEstado,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        estado,
                        style: TextStyle(
                          color: colorEstado,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _construirIndicadorPaso('1. Recibido', 1, pasoActual),
                    _construirIndicadorPaso('2. En camino', 2, pasoActual),
                    _construirIndicadorPaso('3. Entregado', 3, pasoActual),
                  ],
                ),
                const Divider(height: 20),
                Text(
                  'Entrega a: $cliente ($direccion)',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
                if (pedido['repartidorNombre'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Repartidor asignado: ${pedido['repartidorNombre']}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.teal.shade800,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                ...detalles.map((det) {
                  final tiendaItem = det['nombreTienda'] ?? 'Tienda Local';
                  return Text(
                    '• ${det['cantidad']} x ${det['nombreProducto']} ($tiendaItem)',
                    style: const TextStyle(fontSize: 14),
                  );
                }),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      estado == 'Entregado y Pagado'
                          ? 'Pagado en efectivo:'
                          : 'A pagar en efectivo:',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '\$${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
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

  @override
  Widget build(BuildContext context) {
    final String tituloAppBar = SesionActual.nombre != null
        ? 'Hola, ${SesionActual.nombre}'
        : 'Tienda Local Tepic';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          tituloAppBar,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: () {
              obtenerProductos();
              obtenerMisPedidos();
            },
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
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () {
              SesionActual.cerrar();
              Navigator.pushReplacementNamed(context, '/login');
            },
            icon: const Icon(Icons.logout),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            const Tab(
              icon: Icon(Icons.storefront),
              text: 'Tiendas',
            ),
            Tab(
              icon: const Icon(Icons.local_shipping_outlined),
              text: 'Mis Pedidos (${misPedidos.length})',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _construirTabCatalogo(),
          _construirTabMisPedidos(),
        ],
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