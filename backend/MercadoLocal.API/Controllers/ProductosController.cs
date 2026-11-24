using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MercadoLocal.API.Data;
using MercadoLocal.API.Models;

namespace MercadoLocal.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ProductosController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public ProductosController(ApplicationDbContext context)
        {
            _context = context;
        }

        // GET: api/productos?comercianteId=2
        [HttpGet]
        public async Task<ActionResult<IEnumerable<Producto>>> GetProductos([FromQuery] int? comercianteId)
        {
            var query = _context.Productos.AsQueryable();

            if (comercianteId.HasValue)
            {
                query = query.Where(p => p.ComercianteId == comercianteId.Value);
            }

            return await query.OrderByDescending(p => p.Id).ToListAsync();
        }

        // POST: api/productos
        [HttpPost]
        public async Task<ActionResult<Producto>> PostProducto([FromBody] Producto producto)
        {
            if (string.IsNullOrWhiteSpace(producto.Nombre) || producto.Precio <= 0)
            {
                return BadRequest("El nombre y un precio mayor a 0 son obligatorios.");
            }

            producto.Nombre = producto.Nombre.Trim();
            producto.Descripcion = producto.Descripcion?.Trim() ?? string.Empty;
            producto.NombreTienda = string.IsNullOrWhiteSpace(producto.NombreTienda)
                ? "Tienda Local"
                : producto.NombreTienda.Trim();

            _context.Productos.Add(producto);
            await _context.SaveChangesAsync();

            return Ok(producto);
        }

        // PUT: api/productos/5
        [HttpPut("{id}")]
        public async Task<IActionResult> PutProducto(int id, [FromBody] Producto productoActualizado)
        {
            var producto = await _context.Productos.FindAsync(id);
            if (producto == null)
            {
                return NotFound("Producto no encontrado.");
            }

            producto.Nombre = productoActualizado.Nombre.Trim();
            producto.Descripcion = productoActualizado.Descripcion?.Trim() ?? string.Empty;
            producto.Precio = productoActualizado.Precio;
            producto.Stock = productoActualizado.Stock;

            await _context.SaveChangesAsync();
            return Ok(producto);
        }
    }
}