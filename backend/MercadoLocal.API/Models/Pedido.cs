namespace MercadoLocal.API.Models
{
    public class Pedido
    {
        public int Id { get; set; }
        public string ClienteNombre { get; set; } = string.Empty;
        public string DireccionEntrega { get; set; } = string.Empty;
        public string Telefono { get; set; } = string.Empty;
        public decimal Total { get; set; }
        public string Estado { get; set; } = "Pendiente";
        public DateTime FechaCreacion { get; set; } = DateTime.UtcNow;

        public int? ClienteId { get; set; }
        public int? RepartidorId { get; set; }
        public string? RepartidorNombre { get; set; }

        public List<DetallePedido> Detalles { get; set; } = new();
    }

    public class DetallePedido
    {
        public int Id { get; set; }
        public int PedidoId { get; set; }
        public int ProductoId { get; set; }
        public string NombreProducto { get; set; } = string.Empty;
        public int Cantidad { get; set; }
        public decimal PrecioUnitario { get; set; }

        public int? ComercianteId { get; set; }
        public string NombreTienda { get; set; } = "Tienda Local";
    }
}