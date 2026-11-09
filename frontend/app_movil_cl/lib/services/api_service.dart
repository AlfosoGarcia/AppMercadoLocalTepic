import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/producto.dart';

class ApiService {
  // Cambia el puerto por el que te muestra "dotnet run"
  static const String baseUrl = 'http://localhost:5002/api';

  static Future<List<Producto>> obtenerProductos() async {
    final response = await http.get(Uri.parse('$baseUrl/productos'));

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => Producto.fromJson(item)).toList();
    } else {
      throw Exception('Error al cargar la lista de productos');
    }
  }
}