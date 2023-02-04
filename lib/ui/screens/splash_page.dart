import 'package:flutter/material.dart';
import 'package:sheets_backend/ui/screens/home/home_page.dart';
import 'package:sheets_backend/providers/sheets/google_sheets_provider.dart';

class SplashPage extends StatefulWidget {
  final GoogleSheetsProvider provider;
  const SplashPage({required this.provider, Key? key}) : super(key: key);
  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    Future.delayed(Duration(seconds: 5), () {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => HomePage(provider: widget.provider)));
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Image.asset(
          'assets/images/landing.png',
          // set the fit property to cover
          fit: BoxFit.cover, // new line
        ),
      ),
    );
  }
}
