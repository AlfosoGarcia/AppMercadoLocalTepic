using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MercadoLocal.API.Data;
using MercadoLocal.API.Models;
using MercadoLocal.API.DTOs;

namespace MercadoLocal.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class UsuariosController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public UsuariosController(ApplicationDbContext context)
        {
            _context = context;
        }

        [HttpPost("registro")]
        public async Task<IActionResult> Registrar(RegistroDto dto)
        {
            // Validar si el correo ya existe
            if (await _context.Usuarios.AnyAsync(u => u.Email == dto.Email))
            {
                return BadRequest(new { mensaje = "El correo electrónico ya está registrado." });
            }

            // Crear el nuevo usuario (Por ahora guardamos el texto plano, luego agregaremos hash seguro)
            var usuario = new Usuario
            {
                Nombre = dto.Nombre,
                Email = dto.Email,
                PasswordHash = dto.Password, 
                Rol = dto.Rol
            };

            _context.Usuarios.Add(usuario);
            await _context.SaveChangesAsync();

            return Ok(new { mensaje = "Usuario registrado exitosamente.", usuarioId = usuario.Id });
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<Usuario>>> ObtenerUsuarios()
        {
            return await _context.Usuarios.ToListAsync();
        }
    }
}