import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'sesion_actual.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  static const String baseUrl = 'http://localhost:5002/api';

  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String rolSeleccionado = 'Cliente';
  bool guardando = false;
  String? errorMensaje;

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> registrarUsuario() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      guardando = true;
      errorMensaje = null;
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/usuarios/registro'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'nombre': _nombreController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
          'rol': rolSeleccionado,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        final int id = data['id'] ?? 0;
        final String rol = data['rol'] ?? rolSeleccionado;
        final String nombre = data['nombre'] ?? _nombreController.text.trim();

        SesionActual.iniciar(id: id, nombreUsuario: nombre, rolUsuario: rol);

        String rutaDestino = '/cliente';
        if (rol == 'Comerciante') {
          rutaDestino = '/comerciante';
        } else if (rol == 'Repartidor') {
          rutaDestino = '/repartidor';
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cuenta creada como $rol'),
              backgroundColor: Colors.green.shade700,
              duration: const Duration(seconds: 2),
            ),
          );

          Navigator.pushNamedAndRemoveUntil(
            context,
            rutaDestino,
            (route) => false,
          );
        }
      } else {
        setState(() {
          errorMensaje = response.body.replaceAll('"', '');
          guardando = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMensaje = 'No se pudo conectar con el servidor en localhost:5002';
        guardando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Crear Cuenta'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
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
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Registro en Mercado Local',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _nombreController,
                        enabled: !guardando,
                        decoration: InputDecoration(
                          labelText: rolSeleccionado == 'Comerciante'
                              ? 'Nombre de tu tienda o negocio'
                              : 'Nombre completo',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (val) => (val == null || val.trim().isEmpty)
                            ? 'Este campo es obligatorio'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _emailController,
                        enabled: !guardando,
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
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _passwordController,
                        enabled: !guardando,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: Icon(Icons.lock_outline),
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) =>
                            (val == null || val.trim().length < 4)
                                ? 'Mínimo 4 caracteres'
                                : null,
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: rolSeleccionado,
                        decoration: const InputDecoration(
                          labelText: '¿Cómo usarás la app?',
                          prefixIcon: Icon(Icons.badge_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Cliente',
                            child: Text('Cliente (Comprar a domicilio)'),
                          ),
                          DropdownMenuItem(
                            value: 'Comerciante',
                            child: Text('Comerciante (Vender productos)'),
                          ),
                          DropdownMenuItem(
                            value: 'Repartidor',
                            child: Text('Repartidor (Entregar y cobrar)'),
                          ),
                        ],
                        onChanged: guardando
                            ? null
                            : (valor) {
                                if (valor != null) {
                                  setState(() {
                                    rolSeleccionado = valor;
                                  });
                                }
                              },
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
                        onPressed: guardando ? null : registrarUsuario,
                        child: guardando
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Registrarme y Entrar',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
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