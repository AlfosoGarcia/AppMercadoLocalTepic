using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MercadoLocal.API.Migrations
{
    /// <inheritdoc />
    public partial class SepararPorUsuariosYTiendas : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Disponible",
                table: "Productos");

            migrationBuilder.DropColumn(
                name: "FechaCreacion",
                table: "Productos");

            migrationBuilder.RenameColumn(
                name: "FechaPedido",
                table: "Pedidos",
                newName: "FechaCreacion");

            migrationBuilder.AddColumn<int>(
                name: "ComercianteId",
                table: "Productos",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "NombreTienda",
                table: "Productos",
                type: "text",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<int>(
                name: "ClienteId",
                table: "Pedidos",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "RepartidorId",
                table: "Pedidos",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "RepartidorNombre",
                table: "Pedidos",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "ComercianteId",
                table: "DetallePedidos",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "NombreTienda",
                table: "DetallePedidos",
                type: "text",
                nullable: false,
                defaultValue: "");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "ComercianteId",
                table: "Productos");

            migrationBuilder.DropColumn(
                name: "NombreTienda",
                table: "Productos");

            migrationBuilder.DropColumn(
                name: "ClienteId",
                table: "Pedidos");

            migrationBuilder.DropColumn(
                name: "RepartidorId",
                table: "Pedidos");

            migrationBuilder.DropColumn(
                name: "RepartidorNombre",
                table: "Pedidos");

            migrationBuilder.DropColumn(
                name: "ComercianteId",
                table: "DetallePedidos");

            migrationBuilder.DropColumn(
                name: "NombreTienda",
                table: "DetallePedidos");

            migrationBuilder.RenameColumn(
                name: "FechaCreacion",
                table: "Pedidos",
                newName: "FechaPedido");

            migrationBuilder.AddColumn<bool>(
                name: "Disponible",
                table: "Productos",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<DateTime>(
                name: "FechaCreacion",
                table: "Productos",
                type: "timestamp with time zone",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));
        }
    }
}
