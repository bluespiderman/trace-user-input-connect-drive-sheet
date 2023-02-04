import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sheets_backend/providers/sheets/google_sheets_provider.dart';
import 'package:sheets_backend/ui/app.dart';

class HomePage extends StatefulWidget {
  final GoogleSheetsProvider provider;
  const HomePage({
    required this.provider,
    Key? key,
  }) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 39, 39, 127),
        titleSpacing: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 30,
              height: 50,
            ),
            const SizedBox(
              width: 10.0,
              height: 10.0,
            ),
            Text(
              'BZTS',
              style: TextStyle(color: Colors.white), //<-- SEE HERE
            ),
          ],
        ),
      ),
      body: Container(
          padding: EdgeInsets.all(30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // const SizedBox(
                  //   height: 20.0,
                  // ),
                  Image.asset(
                    'assets/images/mark.png',
                    height: 250,
                  ),
                  const SizedBox(
                    height: 30.0,
                  ),
                  // Text(
                  //   "BZTS*",
                  //   style: TextStyle(
                  //       fontSize: 30,
                  //       fontWeight: FontWeight.normal,
                  //       color: Color.fromRGBO(39, 39, 127, 1)),
                  // ),
                  // const SizedBox(
                  //   height: 10.0,
                  // ),
                  // Text(
                  //   "Balıkesir Zabıta Başkanlığı Takip Sistemi*",
                  //   style: TextStyle(
                  //       fontSize: 20,
                  //       fontWeight: FontWeight.normal,
                  //       color: Color.fromRGBO(39, 39, 127, 1)),
                  // ),
                ],
              )),
            ],
          )),
      drawer: Drawer(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(10, 70, 10, 30),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  width: 80,
                  height: 80,
                ),
                const SizedBox(
                  width: 10.0,
                  height: 10.0,
                ),
                Text(
                  'BZTS',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color.fromRGBO(29, 29, 127, 1)), //<-- SEE HERE
                ),
              ],
            ),
            const SizedBox(
              width: 10.0,
              height: 30.0,
            ),
            Divider(
              height: 10,
              color: Colors.grey,
              thickness: 1,
              indent: 10,
              endIndent: 10,
            ),
            const SizedBox(
              width: 10.0,
              height: 10.0,
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('About'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.shortcut),
              title: const Text('Add shortcut'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete my account'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color.fromRGBO(29, 29, 127, 1),
        onPressed: () async {
          await Navigator.of(context).pushNamed(routeAdd);
          setState(() {});
        },
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }
}
