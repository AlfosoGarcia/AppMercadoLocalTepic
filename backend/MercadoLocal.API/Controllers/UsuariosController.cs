using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MercadoLocal.API.Data;
using MercadoLocal.API.Models;

namespace MercadoLocal.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class UsuariosController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public UsuariosController(ApplicationDbContext context)
        {
            _context = context;
        }

        // POST: api/usuarios/registro
        [HttpPost("registro")]
        public async Task<IActionResult> Registrar([FromBody] RegistroUsuarioDto dto)
        {
            if (string.IsNullOrWhiteSpace(dto.Nombre) ||
                string.IsNullOrWhiteSpace(dto.Email) ||
                string.IsNullOrWhiteSpace(dto.Password))
            {
                return BadRequest("Todos los campos son obligatorios.");
            }

            var emailNormalizado = dto.Email.Trim().ToLower();
            var existe = await _context.Usuarios.AnyAsync(u => u.Email == emailNormalizado);
            if (existe)
            {
                return BadRequest("Este correo ya está registrado.");
            }

            var rolesValidos = new[] { "Cliente", "Comerciante", "Repartidor" };
            var rolAsignado = rolesValidos.Contains(dto.Rol) ? dto.Rol : "Cliente";

            var nuevoUsuario = new Usuario
            {
                Nombre = dto.Nombre.Trim(),
                Email = emailNormalizado,
                PasswordHash = dto.Password.Trim(),
                Rol = rolAsignado
            };

            _context.Usuarios.Add(nuevoUsuario);
            await _context.SaveChangesAsync();

            return Ok(new
            {
                mensaje = "Usuario registrado con éxito",
                id = nuevoUsuario.Id,
                nombre = nuevoUsuario.Nombre,
                email = nuevoUsuario.Email,
                rol = nuevoUsuario.Rol
            });
        }

        // POST: api/usuarios/login
        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginUsuarioDto dto)
        {
            var emailNormalizado = dto.Email.Trim().ToLower();
            var usuario = await _context.Usuarios
                .FirstOrDefaultAsync(u => u.Email == emailNormalizado && u.PasswordHash == dto.Password.Trim());

            if (usuario == null)
            {
                return Unauthorized("Correo o contraseña incorrectos.");
            }

            return Ok(new
            {
                mensaje = "Inicio de sesión exitoso",
                id = usuario.Id,
                nombre = usuario.Nombre,
                email = usuario.Email,
                rol = usuario.Rol
            });
        }
    }

    public class RegistroUsuarioDto
    {
        public string Nombre { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
        public string Rol { get; set; } = "Cliente";
    }

    public class LoginUsuarioDto
    {
        public string Email { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
    }
}