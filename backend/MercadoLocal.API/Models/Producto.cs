namespace MercadoLocal.API.Models
{
    public class Producto
    {
        public int Id { get; set; }
        public string Nombre { get; set; } = string.Empty;
        public string Descripcion { get; set; } = string.Empty;
        public decimal Precio { get; set; }
        public int Stock { get; set; }

        public int? ComercianteId { get; set; }
        public string NombreTienda { get; set; } = "Tienda Local";
    }
}