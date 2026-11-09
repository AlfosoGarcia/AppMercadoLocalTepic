using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MercadoLocal.API.Data;
using MercadoLocal.API.Models;

namespace MercadoLocal.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ProductosController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public ProductosController(ApplicationDbContext context)
        {
            _context = context;
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<Producto>>> GetProductos()
        {
            return await _context.Productos.Where(p => p.Disponible).ToListAsync();
        }

        [HttpPost]
        public async Task<IActionResult> CrearProducto(Producto producto)
        {
            _context.Productos.Add(producto);
            await _context.SaveChangesAsync();
            return Ok(new { mensaje = "Producto creado exitosamente.", productoId = producto.Id });
        }
    }
}