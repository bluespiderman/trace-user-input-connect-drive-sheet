import 'package:flutter/material.dart';
import 'package:sheets_backend/providers/sheets/google_sheets_provider.dart';
import 'package:sheets_backend/ui/screens/add/add_page.dart';
import 'package:sheets_backend/ui/screens/home/home_page.dart';
import 'package:sheets_backend/ui/screens/splash_page.dart';

const String routeAdd = '/add';
const String routeHome = '/';
const String routeSplash = '/loading';

class SheetsApp extends StatelessWidget {
  final GoogleSheetsProvider provider;

  const SheetsApp({
    required this.provider,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Büyükşehir Belediyesi Zabıta Daire Başkanlığı - Takip Sistemi',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: routeSplash,
      routes: {
        routeAdd: (_) => AddPage(provider: provider),
        routeHome: (_) => HomePage(provider: provider),
        routeSplash: (_) => SplashPage(provider: provider)
      },
    );
  }
}
