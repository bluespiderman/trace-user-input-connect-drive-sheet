import 'package:flutter/material.dart';
import 'package:sheets_backend/config/secrets.dart';
import 'package:sheets_backend/providers/sheets/google_sheets_provider.dart';
import 'package:sheets_backend/ui/app.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  final provider = GoogleSheetsProvider(credentials);

  /// Initialize provider
  await provider.initializeForWorksheet(sheetId, worksheetTitle);

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(SheetsApp(
    provider: provider,
  ));
}

///
// Villa Mascarada	Rua de Luís de Camões, nº 22, Alcabideche
// Mansão Verde	Avenida de Tóquio, nº 7, Porto
// Casa de Repouso	Rua do Descanso, nº 99, Santiago do Cacém
