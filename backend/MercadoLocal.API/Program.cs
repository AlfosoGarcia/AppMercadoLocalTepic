using Microsoft.EntityFrameworkCore;
using MercadoLocal.API.Data;

var builder = WebApplication.CreateBuilder(args);

// 1. Configurar política de CORS para permitir la conexión desde Flutter
builder.Services.AddCors(options =>
{
    options.AddPolicy("PermitirFlutter", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

builder.Services.AddControllers();

// 2. Configuración de la base de datos PostgreSQL
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));

var app = builder.Build();

// 3. Activar el middleware de CORS (debe ir antes de MapControllers)
app.UseCors("PermitirFlutter");

app.UseAuthorization();
app.MapControllers();

app.Run();