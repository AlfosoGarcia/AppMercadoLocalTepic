class Producto {
  final int id;
  final String nombre;
  final String descripcion;
  final double precio;
  final int stock;
  final bool disponible;

  Producto({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.stock,
    required this.disponible,
  });

  // Convertir el JSON recibido del Backend C# a un objeto Dart
  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['id'],
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'] ?? '',
      precio: (json['precio'] as num).toDouble(),
      stock: json['stock'] ?? 0,
      disponible: json['disponible'] ?? true,
    );
  }
}