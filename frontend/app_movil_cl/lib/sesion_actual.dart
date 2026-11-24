class SesionActual {
  static int? usuarioId;
  static String? nombre;
  static String? rol;

  static void iniciar({
    required int id,
    required String nombreUsuario,
    required String rolUsuario,
  }) {
    usuarioId = id;
    nombre = nombreUsuario;
    rol = rolUsuario;
  }

  static void cerrar() {
    usuarioId = null;
    nombre = null;
    rol = null;
  }
}