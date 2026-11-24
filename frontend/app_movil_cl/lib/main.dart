import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'registro_screen.dart';
import 'cliente_screen.dart';
import 'comerciante_screen.dart';
import 'repartidor_screen.dart';

void main() {
  runApp(const MercadoLocalApp());
}

class MercadoLocalApp extends StatelessWidget {
  const MercadoLocalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mercado Local Tepic',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/registro': (context) => const RegistroScreen(),
        '/roles': (context) => const RolSelectorScreen(),
        '/cliente': (context) => const ClienteScreen(),
        '/comerciante': (context) => const ComercianteScreen(),
        '/repartidor': (context) => const RepartidorScreen(),
      },
    );
  }
}

class RolSelectorScreen extends StatelessWidget {
  const RolSelectorScreen({super.key});

  Widget _construirTarjetaRol({
    required BuildContext context,
    required String titulo,
    required String subtitulo,
    required IconData icono,
    required Color colorIcono,
    required Color colorFondoIcono,
    required String ruta,
  }) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.pushNamed(context, ruta),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: colorFondoIcono,
                child: Icon(icono, size: 30, color: colorIcono),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitulo,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 18, color: colorIcono),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Selector Rápido (Demo)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _construirTarjetaRol(
                  context: context,
                  titulo: 'Soy Cliente',
                  subtitulo: 'Explora productos locales y sigue tus pedidos',
                  icono: Icons.shopping_bag_outlined,
                  colorIcono: Colors.green.shade700,
                  colorFondoIcono: Colors.green.shade50,
                  ruta: '/cliente',
                ),
                _construirTarjetaRol(
                  context: context,
                  titulo: 'Soy Comerciante',
                  subtitulo: 'Prepara pedidos recibidos y publica tu catálogo',
                  icono: Icons.storefront_outlined,
                  colorIcono: Colors.blue.shade700,
                  colorFondoIcono: Colors.blue.shade50,
                  ruta: '/comerciante',
                ),
                _construirTarjetaRol(
                  context: context,
                  titulo: 'Soy Repartidor',
                  subtitulo: 'Recoge pedidos listos y cobra en efectivo',
                  icono: Icons.delivery_dining,
                  colorIcono: Colors.teal.shade700,
                  colorFondoIcono: Colors.teal.shade50,
                  ruta: '/repartidor',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}