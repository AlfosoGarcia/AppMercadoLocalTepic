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
        private readonly ApplicationDbContext _context;

        public PedidosController(ApplicationDbContext context)
        {
            _context = context;
        }

        // GET: api/pedidos?clienteId=1&comercianteId=2&repartidorId=3
        [HttpGet]
        public async Task<IActionResult> GetPedidos(
            [FromQuery] int? clienteId,
            [FromQuery] int? comercianteId,
            [FromQuery] int? repartidorId)
        {
            var query = _context.Pedidos
                .Include(p => p.Detalles)
                .AsQueryable();

            if (clienteId.HasValue)
            {
                query = query.Where(p => p.ClienteId == clienteId.Value);
            }

            if (comercianteId.HasValue)
            {
                query = query.Where(p => p.Detalles.Any(d => d.ComercianteId == comercianteId.Value));
            }

            if (repartidorId.HasValue)
            {
                query = query.Where(p =>
                    (p.Estado == "Listo para envío" && (p.RepartidorId == null || p.RepartidorId == repartidorId.Value)) ||
                    (p.Estado == "Entregado y Pagado" && p.RepartidorId == repartidorId.Value));
            }

            var lista = await query.OrderByDescending(p => p.Id).ToListAsync();

            var resultado = lista.Select(p =>
            {
                var detallesFiltrados = comercianteId.HasValue
                    ? p.Detalles.Where(d => d.ComercianteId == comercianteId.Value).ToList()
                    : p.Detalles.ToList();

                var totalMostrar = comercianteId.HasValue
                    ? detallesFiltrados.Sum(d => d.PrecioUnitario * d.Cantidad)
                    : p.Total;

                return new
                {
                    id = p.Id,
                    clienteId = p.ClienteId,
                    clienteNombre = p.ClienteNombre,
                    direccionEntrega = p.DireccionEntrega,
                    telefono = p.Telefono,
                    estado = p.Estado,
                    total = totalMostrar,
                    repartidorId = p.RepartidorId,
                    repartidorNombre = p.RepartidorNombre,
                    detalles = detallesFiltrados.Select(d => new
                    {
                        id = d.Id,
                        productoId = d.ProductoId,
                        nombreProducto = d.NombreProducto,
                        cantidad = d.Cantidad,
                        precioUnitario = d.PrecioUnitario,
                        nombreTienda = d.NombreTienda
                    })
                };
            });

            return Ok(resultado);
        }

        // POST: api/pedidos
        [HttpPost]
        public async Task<IActionResult> CrearPedido([FromBody] CrearPedidoDto dto)
        {
            if (dto.Items == null || !dto.Items.Any())
            {
                return BadRequest("El pedido debe incluir al menos un producto.");
            }

            var pedido = new Pedido
            {
                ClienteId = dto.ClienteId,
                ClienteNombre = dto.ClienteNombre.Trim(),
                DireccionEntrega = dto.DireccionEntrega.Trim(),
                Telefono = dto.Telefono.Trim(),
                Estado = "Pendiente",
                FechaCreacion = DateTime.UtcNow
            };

            decimal totalCalculado = 0;

            foreach (var item in dto.Items)
            {
                var producto = await _context.Productos.FindAsync(item.ProductoId);
                if (producto == null)
                {
                    return BadRequest($"El producto con ID {item.ProductoId} no existe.");
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
                    PrecioUnitario = producto.Precio,
                    ComercianteId = producto.ComercianteId,
                    NombreTienda = producto.NombreTienda
                };

                totalCalculado += producto.Precio * item.Cantidad;
                pedido.Detalles.Add(detalle);
            }

            pedido.Total = totalCalculado;

            _context.Pedidos.Add(pedido);
            await _context.SaveChangesAsync();

            return Ok(new
            {
                mensaje = "Pedido registrado correctamente",
                pedidoId = pedido.Id
            });
        }

        // PUT: api/pedidos/5/estado
        [HttpPut("{id}/estado")]
        public async Task<IActionResult> ActualizarEstado(int id, [FromBody] ActualizarEstadoPedidoDto dto)
        {
            var pedido = await _context.Pedidos.FindAsync(id);
            if (pedido == null)
            {
                return NotFound("Pedido no encontrado.");
            }

            if (dto.RepartidorId.HasValue)
            {
                if (pedido.RepartidorId.HasValue && pedido.RepartidorId != dto.RepartidorId)
                {
                    return BadRequest("Este pedido ya fue tomado por otro repartidor.");
                }
                pedido.RepartidorId = dto.RepartidorId;
                pedido.RepartidorNombre = dto.RepartidorNombre;
            }

            if (!string.IsNullOrWhiteSpace(dto.Estado))
            {
                pedido.Estado = dto.Estado.Trim();
            }

            await _context.SaveChangesAsync();

            return Ok(new
            {
                mensaje = "Estado actualizado",
                id = pedido.Id,
                estado = pedido.Estado,
                repartidorId = pedido.RepartidorId
            });
        }
    }

    public class CrearPedidoDto
    {
        public int? ClienteId { get; set; }
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

    public class ActualizarEstadoPedidoDto
    {
        public string Estado { get; set; } = string.Empty;
        public int? RepartidorId { get; set; }
        public string? RepartidorNombre { get; set; }
    }
}