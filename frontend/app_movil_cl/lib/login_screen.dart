import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'sesion_actual.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const String baseUrl = 'http://localhost:5002/api';

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool cargando = false;
  bool ocultarPassword = true;
  String? errorMensaje;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _redirigirPorRol(String rol, String nombre) {
    String rutaDestino = '/cliente';
    if (rol == 'Comerciante') {
      rutaDestino = '/comerciante';
    } else if (rol == 'Repartidor') {
      rutaDestino = '/repartidor';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Bienvenido, $nombre ($rol)'),
        backgroundColor: Colors.green.shade700,
        duration: const Duration(seconds: 2),
      ),
    );

    Navigator.pushReplacementNamed(context, rutaDestino);
  }

  Future<void> iniciarSesion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      cargando = true;
      errorMensaje = null;
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/usuarios/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final int id = data['id'] ?? 0;
        final String rol = data['rol'] ?? 'Cliente';
        final String nombre = data['nombre'] ?? '';

        SesionActual.iniciar(id: id, nombreUsuario: nombre, rolUsuario: rol);

        if (mounted) {
          _redirigirPorRol(rol, nombre);
        }
      } else if (response.statusCode == 401) {
        setState(() {
          errorMensaje = 'Correo o contraseña incorrectos.';
          cargando = false;
        });
      } else {
        setState(() {
          errorMensaje = 'Error del servidor (${response.statusCode})';
          cargando = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMensaje = 'No se pudo conectar con el servidor en localhost:5002';
        cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.store_mall_directory,
                        size: 64,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Mercado Local Tepic',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Inicia sesión para continuar',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _emailController,
                        enabled: !cargando,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Correo electrónico',
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Ingresa tu correo';
                          }
                          if (!val.contains('@')) {
                            return 'Ingresa un correo válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        enabled: !cargando,
                        obscureText: ocultarPassword,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              ocultarPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                ocultarPassword = !ocultarPassword;
                              });
                            },
                          ),
                        ),
                        validator: (val) => (val == null || val.trim().isEmpty)
                            ? 'Ingresa tu contraseña'
                            : null,
                      ),
                      if (errorMensaje != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade300),
                          ),
                          child: Text(
                            errorMensaje!,
                            style: TextStyle(
                              color: Colors.red.shade900,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 22),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: cargando ? null : iniciarSesion,
                        child: cargando
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Entrar',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('¿No tienes cuenta?'),
                          TextButton(
                            onPressed: cargando
                                ? null
                                : () => Navigator.pushNamed(context, '/registro'),
                            child: const Text(
                              'Regístrate aquí',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      TextButton.icon(
                        onPressed: cargando
                            ? null
                            : () {
                                SesionActual.cerrar();
                                Navigator.pushNamed(context, '/roles');
                              },
                        icon: const Icon(Icons.bolt, size: 18),
                        label: const Text(
                          'Acceso rápido general (Modo Demo)',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}