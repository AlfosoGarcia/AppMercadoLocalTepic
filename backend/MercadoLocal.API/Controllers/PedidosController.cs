using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MercadoLocal.API.Data;
using MercadoLocal.API.Models;

namespace MercadoLocal.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class PedidosController : ControllerBase
    {
        // <-- Verifica que aquí diga el nombre de tu Contexto (ej. ApplicationDbContext o AppDbContext)
        private readonly ApplicationDbContext _context;

        public PedidosController(ApplicationDbContext context)
        {
            _context = context;
        }

        // GET: api/pedidos
        [HttpGet]
        public async Task<ActionResult<IEnumerable<Pedido>>> GetPedidos()
        {
            return await _context.Pedidos
                .Include(p => p.Detalles)
                .OrderByDescending(p => p.FechaPedido)
                .ToListAsync();
        }

        // POST: api/pedidos
        [HttpPost]
        public async Task<ActionResult<Pedido>> CrearPedido([FromBody] CrearPedidoDto dto)
        {
            if (dto.Items == null || dto.Items.Count == 0)
            {
                return BadRequest("El carrito está vacío.");
            }

            var nuevoPedido = new Pedido
            {
                ClienteNombre = dto.ClienteNombre,
                DireccionEntrega = dto.DireccionEntrega,
                Telefono = dto.Telefono,
                FechaPedido = DateTime.UtcNow,
                Estado = "Pendiente"
            };

            decimal totalCalculado = 0;

            foreach (var item in dto.Items)
            {
                var producto = await _context.Productos.FindAsync(item.ProductoId);
                if (producto == null)
                {
                    return NotFound($"Producto con ID {item.ProductoId} no encontrado.");
                }

                if (producto.Stock < item.Cantidad)
                {
                    return BadRequest($"Stock insuficiente para {producto.Nombre}. Disponible: {producto.Stock}");
                }

                producto.Stock -= item.Cantidad;

                var detalle = new DetallePedido
                {
                    ProductoId = producto.Id,
                    NombreProducto = producto.Nombre,
                    Cantidad = item.Cantidad,
                    PrecioUnitario = producto.Precio
                };

                totalCalculado += producto.Precio * item.Cantidad;
                nuevoPedido.Detalles.Add(detalle);
            }

            nuevoPedido.Total = totalCalculado;

            _context.Pedidos.Add(nuevoPedido);
            await _context.SaveChangesAsync();

            return CreatedAtAction(nameof(GetPedidos), new { id = nuevoPedido.Id }, new
            {
                mensaje = "Pedido registrado con éxito",
                pedidoId = nuevoPedido.Id,
                total = nuevoPedido.Total
            });
        }

        // PUT: api/pedidos/5/estado
        [HttpPut("{id}/estado")]
        public async Task<IActionResult> ActualizarEstado(int id, [FromBody] ActualizarEstadoDto dto)
        {
            var pedido = await _context.Pedidos.FindAsync(id);
            if (pedido == null)
            {
                return NotFound($"Pedido con ID {id} no encontrado.");
            }

            if (string.IsNullOrWhiteSpace(dto.NuevoEstado))
            {
                return BadRequest("El nuevo estado es obligatorio.");
            }

            pedido.Estado = dto.NuevoEstado.Trim();
            await _context.SaveChangesAsync();

            return Ok(new
            {
                mensaje = $"Estado actualizado a {pedido.Estado}",
                pedidoId = pedido.Id,
                estado = pedido.Estado
            });
        }
    }

    public class CrearPedidoDto
    {
        public string ClienteNombre { get; set; } = string.Empty;
        public string DireccionEntrega { get; set; } = string.Empty;
        public string Telefono { get; set; } = string.Empty;
        public List<ItemPedidoDto> Items { get; set; } = new();
    }

    public class ItemPedidoDto
    {
        public int ProductoId { get; set; }
        public int Cantidad { get; set; }
    }

    public class ActualizarEstadoDto
    {
        public string NuevoEstado { get; set; } = string.Empty;
    }
}