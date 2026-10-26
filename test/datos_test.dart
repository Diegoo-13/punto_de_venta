import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart'; // Importante para la variable Database
import 'package:punto_venta_dolores/datos/base_datos.dart';
import 'package:punto_venta_dolores/datos/repositorio_productos.dart';
import 'package:punto_venta_dolores/datos/repositorio_ventas.dart';
import 'package:punto_venta_dolores/dominio/carrito.dart';
import 'package:punto_venta_dolores/dominio/excepciones.dart';
import 'package:punto_venta_dolores/dominio/producto.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi; // Configura SQLite para pruebas en PC

  late Database db; // Declaramos la base de datos aquí para poder cerrarla después
  late RepositorioProductos productos;
  late RepositorioVentas ventas;

  setUp(() async {
    // Se ejecuta ANTES de cada prueba: crea una DB limpia
    db = await BaseDatos.abrir(ruta: inMemoryDatabasePath);
    productos = RepositorioProductos(db);
    ventas = RepositorioVentas(db);
    await productos.agregar(const Producto(
        codigo: 'NV-001', nombre: 'Nieve de limón',
        precioCentavos: 2500, existencias: 5));
  });

  tearDown(() async {
    // Se ejecuta DESPUÉS de cada prueba: cierra y destruye la DB
    await db.close();
  });

  group('RepositorioProductos y Transacciones de Ventas', () {
    // ! Ronda 4: Base de datos y Productos
    test('guarda y busca producto', () async {
      final p = await productos.buscarPorCodigo('NV-001');
      expect(p!.nombre, 'Nieve de limón');
      expect(p.id, isNotNull);
    });

    test('código duplicado lanza excepción de dominio', () {
      expect(
          () => productos.agregar(const Producto(
              codigo: 'NV-001', nombre: 'Otra',
              precioCentavos: 100, existencias: 1)),
          throwsA(isA<CodigoDuplicadoException>()));
    });

    // ! Ronda 5: Cobros y Transacciones
    test('cobrar descuenta inventario y registra venta', () async {
      final p = (await productos.buscarPorCodigo('NV-001'))!;
      final carrito = Carrito()..agregar(p, cantidad: 2);
      
      final venta = await ventas.cobrar(carrito, 10000);
      
      expect(venta.cambioCentavos, 5000);
      expect((await productos.buscarPorCodigo('NV-001'))!.existencias, 3);
    });

    test('si falla el cobro NO se descuenta inventario', () async {
      final p = (await productos.buscarPorCodigo('NV-001'))!;
      final carrito = Carrito()..agregar(p, cantidad: 2);
      
      await expectLater(ventas.cobrar(carrito, 100),
          throwsA(isA<PagoInsuficienteException>()));
          
      expect((await productos.buscarPorCodigo('NV-001'))!.existencias, 5);
    });

    test('corte del día suma ventas de hoy', () async {
      final p = (await productos.buscarPorCodigo('NV-001'))!;
      await ventas.cobrar(Carrito()..agregar(p), 2500);
      await ventas.cobrar(Carrito()..agregar(p, cantidad: 2), 5000);
      
      final r = await ventas.corteDelDia(DateTime.now());
      
      expect(r.numeroVentas, 2);
      expect(r.totalCentavos, 7500);
    });
  });
}