import 'package:flutter/material.dart';
import 'datos/base_datos.dart';
import 'datos/repositorio_productos.dart';
import 'datos/repositorio_ventas.dart';
import 'presentacion/caja_viewmodel.dart';
import 'presentacion/pantalla_caja.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await BaseDatos.abrir(ruta: 'punto_venta.db'); // Composition root
  final productos = RepositorioProductos(db);
  await productos.sembrarEjemplos();
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Punto de Venta Dolores',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal), 
      useMaterial3: true,
    ),
    home: PantallaCaja(vm: CajaViewModel(productos, RepositorioVentas(db))),
  ));
}