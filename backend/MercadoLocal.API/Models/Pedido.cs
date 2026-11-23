using System.Text.Json.Serialization;

namespace MercadoLocal.API.Models
{
    public class Pedido
    {
        public int Id { get; set; }
        public string ClienteNombre { get; set; } = string.Empty;
        public string DireccionEntrega { get; set; } = string.Empty;
        public string Telefono { get; set; } = string.Empty;
        public DateTime FechaPedido { get; set; } = DateTime.UtcNow;
        public decimal Total { get; set; }
        public string Estado { get; set; } = "Pendiente";

        public List<DetallePedido> Detalles { get; set; } = new();
    }

    public class DetallePedido
    {
        public int Id { get; set; }
        public int PedidoId { get; set; }
        [JsonIgnore]
        public Pedido? Pedido { get; set; }

        public int ProductoId { get; set; }
        public string NombreProducto { get; set; } = string.Empty;
        public int Cantidad { get; set; }
        public decimal PrecioUnitario { get; set; }
    }
}