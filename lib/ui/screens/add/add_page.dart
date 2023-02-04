import 'package:flutter/material.dart';
import 'package:sheets_backend/providers/sheets/google_sheets_provider.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'dart:async';
import 'dart:convert';

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:iconsax/iconsax.dart';

import 'package:googleapis/drive/v3.dart' as ga;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:http/io_client.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddPage extends StatefulWidget {
  final GoogleSheetsProvider provider;
  const AddPage({required this.provider, Key? key}) : super(key: key);

  @override
  _AddPageState createState() => _AddPageState();
}

class GoogleHttpClient extends IOClient {
  Map<String, String> _headers;

  GoogleHttpClient(this._headers) : super();

  @override
  Future<IOStreamedResponse> send(http.BaseRequest request) =>
      super.send(request..headers.addAll(_headers));

  @override
  Future<http.Response> head(Uri url, {Map<String, String>? headers}) =>
      super.head(url, headers: headers?..addAll(_headers));
}

class _AddPageState extends State<AddPage> with SingleTickerProviderStateMixin {
  // Form Element Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _complaintController = TextEditingController();
  final TextEditingController _levelOtherController = TextEditingController();
  final TextEditingController _originOtherController = TextEditingController();
  final TextEditingController _teamNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _certificateController = TextEditingController();

  String origin = "Rutin Kontrol"; // Origin Radio Button default value
  String crimeLevel =
      "Kabahatler Kanunu"; // Crime Level radio button default value
  bool isOriginOtherDisabled = false;
  bool isLevelOtherDisabled = false;

  /// file upload
  ///
  late AnimationController loadingController;

  File? _imageFile, _customFile;
  PlatformFile? _platformImageFile, _platformCustomFile;

  selectImageFile() async {
    final imageFile = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['png', 'jpg', 'jpeg']);

    if (imageFile != null) {
      setState(() {
        _imageFile = File(imageFile.files.single.path!);
        _platformImageFile = imageFile.files.first;
      });
    }
    loadingController.forward();
  }

  selectCustomFile() async {
    final customFile = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['pdf', 'txt', 'doc']);

    if (customFile != null) {
      setState(() {
        _customFile = File(customFile.files.single.path!);
        _platformCustomFile = customFile.files.first;
      });
    }
    loadingController.forward();
  }

  @override
  void initState() {
    loadingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addListener(() {
        setState(() {});
      });

    super.initState();
  }

  final storage = new FlutterSecureStorage();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn =
      GoogleSignIn(scopes: ['https://www.googleapis.com/auth/drive.file']);
  late GoogleSignInAccount? googleSignInAccount;
  late ga.FileList list;
  var signedIn = false;

  Future<void> _loginWithGoogle() async {
    signedIn = await storage.read(key: "signedIn") == "true" ? true : false;
    googleSignIn.onCurrentUserChanged
        .listen((GoogleSignInAccount? googleSignInAccount) async {
      if (googleSignInAccount != null) {
        _afterGoogleLogin(googleSignInAccount);
      }
    });
    if (signedIn) {
      try {
        googleSignIn.signInSilently().whenComplete(() => () {
              _afterGoogleLogin(googleSignInAccount);
            });
      } catch (e) {
        storage.write(key: "signedIn", value: "false").then((value) {
          setState(() {
            signedIn = false;
          });
        });
      }
    } else {
      final GoogleSignInAccount? googleSignInAccount =
          await googleSignIn.signIn();
      print(googleSignInAccount);
      _afterGoogleLogin(googleSignInAccount);
    }
  }

  Future<void> _afterGoogleLogin(GoogleSignInAccount? gSA) async {
    print('aaaaaaaaaaaaaaaaaaaaaaaaaaa');
    googleSignInAccount = gSA;
    final GoogleSignInAuthentication googleSignInAuthentication =
        await googleSignInAccount!.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleSignInAuthentication.accessToken,
      idToken: googleSignInAuthentication.idToken,
    );

    final UserCredential authResult =
        await _auth.signInWithCredential(credential);
    final User? user = authResult.user;

    assert(!user!.isAnonymous);
    assert(await user!.getIdToken() != null);

    final User currentUser = await _auth.currentUser!;
    assert(user!.uid == currentUser.uid);

    print('signInWithGoogle succeeded: $user');

    storage.write(key: "signedIn", value: "true").then((value) {
      setState(() {
        signedIn = true;
      });
    });
    _uploadFileToGoogleDrive();
  }

  _uploadFileToGoogleDrive() async {
    var client = GoogleHttpClient(await googleSignInAccount!.authHeaders);
    var drive = ga.DriveApi(client);
    ga.File fileToUpload = ga.File();
    final now = new DateTime.now();
    String prefix = DateFormat('yMd').format(now);
    if (_imageFile != null) {
      var file = _imageFile;
      fileToUpload.parents = ["1mcvdWg3-XYGZj_scV8Vgb3a9EK_RAC6O"];
      fileToUpload.name = prefix + path.basename(file!.absolute.path);
      var response = await drive.files.create(
        fileToUpload,
        uploadMedia: ga.Media(file.openRead(), file.lengthSync()),
      );
      print(response);
    }
    if (_customFile != null) {
      var file = _customFile;
      fileToUpload.parents = ["1mcvdWg3-XYGZj_scV8Vgb3a9EK_RAC6O"];
      fileToUpload.name = prefix + path.basename(file!.absolute.path);
      var response = await drive.files.create(
        fileToUpload,
        uploadMedia: ga.Media(file.openRead(), file.lengthSync()),
      );
      print(response);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size.width;
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
            decoration: BoxDecoration(
                // image: DecorationImage(
                //   image: AssetImage("images/home_bg.png"),
                //   fit: BoxFit.cover,
                // ),
                ),
            child: SafeArea(
              minimum: const EdgeInsets.fromLTRB(24, 40, 24, 24),
              child: SingleChildScrollView(
                  child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          width: size > 300 ? 300 : size,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              /// User name
                              Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Kişi/İş Yeri Adı*",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 18.0,
                                  ),
                                  TextFormField(
                                    controller: _nameController,
                                    onChanged: (_) => setState(() {}),
                                    style: TextStyle(),
                                    decoration: const InputDecoration(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                vertical: 10.0,
                                                horizontal: 10.0),
                                        enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                          width: 2,
                                          color: Colors.blueAccent,
                                        )),
                                        hintText: "Cevabınız"),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 30.0,
                              ),

                              /// Complaint
                              Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Şikayet Konusu/Durum Tespiti*",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 18.0,
                                  ),
                                  TextFormField(
                                    controller: _complaintController,
                                    onChanged: (_) => setState(() {}),
                                    style: TextStyle(),
                                    decoration: const InputDecoration(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                vertical: 10.0,
                                                horizontal: 10.0),
                                        enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                          width: 2,
                                          color: Colors.blueAccent,
                                        )),
                                        hintText: "Cevabınız "),
                                  ),
                                ],
                              ),

                              const SizedBox(
                                height: 30.0,
                              ),

                              /// origin radio button
                              Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Nereden Geldiği*",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 13.0,
                                  ),
                                  RadioListTile(
                                    contentPadding:
                                        EdgeInsets.fromLTRB(-50, 0, 0, 0),
                                    title: Text(
                                      "Rutin Kontrol",
                                      style: TextStyle(
                                        fontSize: 15,
                                      ),
                                    ),
                                    dense: true,
                                    value: "Rutin Kontrol",
                                    groupValue: origin,
                                    onChanged: (value) {
                                      setState(() {
                                        origin = value.toString();
                                      });
                                    },
                                  ),
                                  RadioListTile(
                                    contentPadding:
                                        EdgeInsets.fromLTRB(-50, 0, 0, 0),
                                    title: Text(
                                      "Beyaz Masa",
                                      style: TextStyle(
                                        fontSize: 15,
                                      ),
                                    ),
                                    dense: true,
                                    value: "Beyaz Masa",
                                    groupValue: origin,
                                    onChanged: (value) {
                                      setState(() {
                                        origin = value.toString();
                                      });
                                    },
                                  ),
                                  RadioListTile(
                                    contentPadding:
                                        EdgeInsets.fromLTRB(-50, 0, 0, 0),
                                    title: Text(
                                      "Çağrı Merkezi",
                                      style: TextStyle(
                                        fontSize: 15,
                                      ),
                                    ),
                                    dense: true,
                                    value: "Çağrı Merkezi",
                                    groupValue: origin,
                                    onChanged: (value) {
                                      setState(() {
                                        origin = value.toString();
                                      });
                                    },
                                  ),
                                  RadioListTile(
                                    contentPadding:
                                        EdgeInsets.fromLTRB(-50, 0, 0, 0),
                                    title: Text(
                                      "Flexy",
                                      style: TextStyle(
                                        fontSize: 15,
                                      ),
                                    ),
                                    dense: true,
                                    value: "Flexy",
                                    groupValue: origin,
                                    onChanged: (value) {
                                      setState(() {
                                        origin = value.toString();
                                      });
                                    },
                                  ),
                                  RadioListTile(
                                    contentPadding:
                                        EdgeInsets.fromLTRB(-50, 0, 0, 0),
                                    title: Text(
                                      "Cimer",
                                      style: TextStyle(
                                        fontSize: 15,
                                      ),
                                    ),
                                    dense: true,
                                    value: "Cimer",
                                    groupValue: origin,
                                    onChanged: (value) {
                                      setState(() {
                                        origin = value.toString();
                                      });
                                    },
                                  ),
                                  RadioListTile(
                                    contentPadding:
                                        EdgeInsets.fromLTRB(-50, 0, 0, 0),
                                    title: Text(
                                      "Alo153",
                                      style: TextStyle(
                                        fontSize: 15,
                                      ),
                                    ),
                                    dense: true,
                                    value: "Alo153",
                                    groupValue: origin,
                                    onChanged: (value) {
                                      setState(() {
                                        origin = value.toString();
                                      });
                                    },
                                  ),
                                  RadioListTile(
                                    contentPadding:
                                        EdgeInsets.fromLTRB(-50, 0, 0, 0),
                                    title: Text(
                                      "Komiser/Amir",
                                      style: TextStyle(
                                        fontSize: 15,
                                      ),
                                    ),
                                    dense: true,
                                    value: "Komiser/Amir",
                                    groupValue: origin,
                                    onChanged: (value) {
                                      setState(() {
                                        origin = value.toString();
                                      });
                                    },
                                  ),

                                  /// Other Part
                                  Row(
                                    children: [
                                      Expanded(
                                        child: RadioListTile(
                                          contentPadding:
                                              EdgeInsets.fromLTRB(-50, 0, 0, 0),
                                          title: Text(
                                            "Diğer",
                                            style: TextStyle(
                                              fontSize: 15,
                                            ),
                                          ),
                                          dense: true,
                                          value: "Diğer",
                                          groupValue: origin,
                                          onChanged: (value) {
                                            setState(() {
                                              origin = value.toString();
                                              isOriginOtherDisabled = true;
                                            });
                                          },
                                        ),
                                      ),
                                      if (origin == 'Diğer')
                                        Visibility(
                                          visible: isOriginOtherDisabled,
                                          child: Expanded(
                                              child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              TextFormField(
                                                //focusNode: otherFocus,
                                                controller:
                                                    _originOtherController,
                                                onChanged: (_) =>
                                                    setState(() {}),
                                                enabled: isOriginOtherDisabled,
                                                style: TextStyle(),
                                                decoration:
                                                    const InputDecoration(
                                                  contentPadding:
                                                      const EdgeInsets
                                                              .symmetric(
                                                          vertical: 10.0,
                                                          horizontal: 10.0),
                                                ),
                                              ),
                                              const SizedBox(
                                                height: 8.0,
                                              ),
                                              Text(
                                                '\u{26A0} bu zorunlu alan',
                                                textAlign: TextAlign.end,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Color.fromARGB(
                                                      255, 255, 0, 1),
                                                  decorationColor:
                                                      Color.fromARGB(
                                                          255, 255, 0, 1),
                                                  fontWeight: FontWeight.normal,
                                                ),
                                              ),
                                            ],
                                          )),
                                        ),
                                    ],
                                  ),
                                ],
                              ),

                              const SizedBox(
                                height: 30.0,
                              ),

                              /// crime level radio button
                              Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Yapılan İşlem*",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 13.0,
                                  ),
                                  RadioListTile(
                                    contentPadding:
                                        EdgeInsets.fromLTRB(-50, 0, 0, 0),
                                    title: Text(
                                      "İhbarname",
                                      style: TextStyle(
                                        fontSize: 15,
                                      ),
                                    ),
                                    dense: true,
                                    value: "ihbarname",
                                    groupValue: crimeLevel,
                                    onChanged: (value) {
                                      setState(() {
                                        crimeLevel = value.toString();
                                      });
                                    },
                                  ),
                                  RadioListTile(
                                    contentPadding:
                                        EdgeInsets.fromLTRB(-50, 0, 0, 0),
                                    title: Text(
                                      "Kabahatler Kanunu",
                                      style: TextStyle(
                                        fontSize: 15,
                                      ),
                                    ),
                                    dense: true,
                                    value: "Kabahatler Kanunu",
                                    groupValue: crimeLevel,
                                    onChanged: (value) {
                                      setState(() {
                                        crimeLevel = value.toString();
                                      });
                                    },
                                  ),
                                  RadioListTile(
                                    contentPadding:
                                        EdgeInsets.fromLTRB(-50, 0, 0, 0),
                                    title: Text(
                                      "Zabıt Varakası",
                                      style: TextStyle(
                                        fontSize: 15,
                                      ),
                                    ),
                                    dense: true,
                                    value: "Zabıt Varakası",
                                    groupValue: crimeLevel,
                                    onChanged: (value) {
                                      setState(() {
                                        crimeLevel = value.toString();
                                      });
                                    },
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: RadioListTile(
                                          contentPadding:
                                              EdgeInsets.fromLTRB(-50, 0, 0, 0),
                                          title: Text(
                                            "Diğer",
                                            style: TextStyle(
                                              fontSize: 15,
                                            ),
                                          ),
                                          dense: true,
                                          value: "Diğer",
                                          groupValue: crimeLevel,
                                          onChanged: (value) {
                                            setState(() {
                                              crimeLevel = value.toString();
                                              isLevelOtherDisabled = true;
                                            });
                                          },
                                        ),
                                      ),
                                      if (crimeLevel == 'Diğer')
                                        Visibility(
                                          visible: isLevelOtherDisabled,
                                          child: Expanded(
                                              child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              TextFormField(
                                                //focusNode: otherFocus,
                                                controller:
                                                    _levelOtherController,
                                                onChanged: (_) =>
                                                    setState(() {}),
                                                enabled: isLevelOtherDisabled,
                                                style: TextStyle(),
                                                decoration:
                                                    const InputDecoration(
                                                  contentPadding:
                                                      const EdgeInsets
                                                              .symmetric(
                                                          vertical: 10.0,
                                                          horizontal: 10.0),
                                                ),
                                              ),
                                              const SizedBox(
                                                height: 8.0,
                                              ),
                                              Text(
                                                '\u{26A0} bu zorunlu alan',
                                                textAlign: TextAlign.end,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Color.fromARGB(
                                                      255, 255, 0, 1),
                                                  decorationColor:
                                                      Color.fromARGB(
                                                          255, 255, 0, 1),
                                                  fontWeight: FontWeight.normal,
                                                ),
                                              ),
                                            ],
                                          )),
                                        ),
                                    ],
                                  ),
                                ],
                              ),

                              const SizedBox(
                                height: 30.0,
                              ),

                              /// Team name
                              Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Ekip Adı*",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 18.0,
                                  ),
                                  TextFormField(
                                    controller: _teamNameController,
                                    onChanged: (_) => setState(() {}),
                                    style: TextStyle(),
                                    decoration: const InputDecoration(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                vertical: 10.0,
                                                horizontal: 10.0),
                                        enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                          width: 2,
                                          color: Colors.blueAccent,
                                        )),
                                        hintText: "Cevabınız"),
                                  ),
                                ],
                              ),

                              const SizedBox(
                                height: 30.0,
                              ),

                              /// Address
                              Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Adres*",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 18.0,
                                  ),
                                  TextFormField(
                                    controller: _addressController,
                                    onChanged: (_) => setState(() {}),
                                    style: TextStyle(),
                                    decoration: const InputDecoration(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                vertical: 10.0,
                                                horizontal: 10.0),
                                        enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                          width: 2,
                                          color: Colors.blueAccent,
                                        )),
                                        hintText: "Cevabınız"),
                                  ),
                                ],
                              ),

                              const SizedBox(
                                height: 33.0,
                              ),

                              /// Date
                              Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Tarih*",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 9.0,
                                  ),
                                  TextField(
                                    controller: _dateController,
                                    //editing controller of this TextField
                                    decoration: InputDecoration(
                                        icon: Icon(Icons
                                            .calendar_today), //icon of text field
                                        labelText:
                                            "Enter Date" //label text of field
                                        ),
                                    readOnly: true,
                                    //set it true, so that user will not able to edit text
                                    onTap: () async {
                                      DateTime? pickedDate = await showDatePicker(
                                          context: context,
                                          initialDate: DateTime.now(),
                                          firstDate: DateTime(1950),
                                          //DateTime.now() - not to allow to choose before today.
                                          lastDate: DateTime(2100));

                                      if (pickedDate != null) {
                                        String formattedDate =
                                            DateFormat('yyyy-MM-dd')
                                                .format(pickedDate);
                                        print(
                                            formattedDate); //formatted date output using intl package =>  2021-03-16
                                        setState(() {
                                          _dateController.text =
                                              formattedDate; //set output date to TextField value.
                                        });
                                      } else {}
                                    },
                                  )
                                ],
                              ),

                              const SizedBox(
                                height: 33.0,
                              ),

                              /// Upload Image
                              Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Görsel",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 18.0,
                                  ),
                                  GestureDetector(
                                    onTap: selectImageFile,
                                    child: Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 40.0, vertical: 20.0),
                                        child: DottedBorder(
                                          borderType: BorderType.RRect,
                                          radius: Radius.circular(10),
                                          dashPattern: [10, 4],
                                          strokeCap: StrokeCap.round,
                                          color: Colors.blue.shade400,
                                          child: Container(
                                            width: double.infinity,
                                            height: 150,
                                            decoration: BoxDecoration(
                                                color: Colors.blue.shade50
                                                    .withOpacity(.3),
                                                borderRadius:
                                                    BorderRadius.circular(10)),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Iconsax.folder_open,
                                                  color: Colors.blue,
                                                  size: 40,
                                                ),
                                                SizedBox(
                                                  height: 15,
                                                ),
                                                Text(
                                                  'dosyanızı seçin',
                                                  style: TextStyle(
                                                      fontSize: 15,
                                                      color:
                                                          Colors.grey.shade400),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )),
                                  ),
                                  _platformImageFile != null
                                      ? Container(
                                          padding: EdgeInsets.all(20),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Seçili dosya',
                                                style: TextStyle(
                                                  color: Colors.grey.shade400,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              SizedBox(
                                                height: 10,
                                              ),
                                              Container(
                                                  padding: EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                      color: Colors.white,
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors
                                                              .grey.shade200,
                                                          offset: Offset(0, 1),
                                                          blurRadius: 3,
                                                          spreadRadius: 2,
                                                        )
                                                      ]),
                                                  child: Row(
                                                    children: [
                                                      ClipRRect(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                          child: Image.file(
                                                            _imageFile!,
                                                            width: 70,
                                                          )),
                                                      SizedBox(
                                                        width: 10,
                                                      ),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              _platformImageFile!
                                                                  .name,
                                                              style: TextStyle(
                                                                  fontSize: 13,
                                                                  color: Colors
                                                                      .black),
                                                            ),
                                                            SizedBox(
                                                              height: 5,
                                                            ),
                                                            Text(
                                                              '${(_platformImageFile!.size / 1024).ceil()} KB',
                                                              style: TextStyle(
                                                                  fontSize: 13,
                                                                  color: Colors
                                                                      .grey
                                                                      .shade500),
                                                            ),
                                                            SizedBox(
                                                              height: 5,
                                                            ),
                                                            Container(
                                                                height: 5,
                                                                clipBehavior: Clip
                                                                    .hardEdge,
                                                                decoration:
                                                                    BoxDecoration(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              5),
                                                                  color: Colors
                                                                      .blue
                                                                      .shade50,
                                                                ),
                                                                child:
                                                                    LinearProgressIndicator(
                                                                  value:
                                                                      loadingController
                                                                          .value,
                                                                )),
                                                          ],
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        width: 10,
                                                      ),
                                                    ],
                                                  )),
                                              SizedBox(
                                                height: 20,
                                              ),
                                            ],
                                          ))
                                      : Container(),
                                ],
                              ),

                              const SizedBox(
                                height: 30.0,
                              ),

                              /// Upload PDF
                              Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Dosya",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 18.0,
                                  ),
                                  GestureDetector(
                                    onTap: selectCustomFile,
                                    child: Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 40.0, vertical: 20.0),
                                        child: DottedBorder(
                                          borderType: BorderType.RRect,
                                          radius: Radius.circular(10),
                                          dashPattern: [10, 4],
                                          strokeCap: StrokeCap.round,
                                          color: Colors.blue.shade400,
                                          child: Container(
                                            width: double.infinity,
                                            height: 150,
                                            decoration: BoxDecoration(
                                                color: Colors.blue.shade50
                                                    .withOpacity(.3),
                                                borderRadius:
                                                    BorderRadius.circular(10)),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Iconsax.folder_open,
                                                  color: Colors.blue,
                                                  size: 40,
                                                ),
                                                SizedBox(
                                                  height: 15,
                                                ),
                                                Text(
                                                  'dosyanızı seçin',
                                                  style: TextStyle(
                                                      fontSize: 15,
                                                      color:
                                                          Colors.grey.shade400),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )),
                                  ),
                                  _platformCustomFile != null
                                      ? Container(
                                          padding: EdgeInsets.all(20),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Seçili dosya',
                                                style: TextStyle(
                                                  color: Colors.grey.shade400,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              SizedBox(
                                                height: 10,
                                              ),
                                              Container(
                                                  padding: EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                      color: Colors.white,
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors
                                                              .grey.shade200,
                                                          offset: Offset(0, 1),
                                                          blurRadius: 3,
                                                          spreadRadius: 2,
                                                        )
                                                      ]),
                                                  child: Row(
                                                    children: [
                                                      ClipRRect(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                          child: Image.file(
                                                            _imageFile!,
                                                            width: 70,
                                                          )),
                                                      SizedBox(
                                                        width: 10,
                                                      ),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              _platformCustomFile!
                                                                  .name,
                                                              style: TextStyle(
                                                                  fontSize: 13,
                                                                  color: Colors
                                                                      .black),
                                                            ),
                                                            SizedBox(
                                                              height: 5,
                                                            ),
                                                            Text(
                                                              '${(_platformCustomFile!.size / 1024).ceil()} KB',
                                                              style: TextStyle(
                                                                  fontSize: 13,
                                                                  color: Colors
                                                                      .grey
                                                                      .shade500),
                                                            ),
                                                            SizedBox(
                                                              height: 5,
                                                            ),
                                                            Container(
                                                                height: 5,
                                                                clipBehavior: Clip
                                                                    .hardEdge,
                                                                decoration:
                                                                    BoxDecoration(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              5),
                                                                  color: Colors
                                                                      .blue
                                                                      .shade50,
                                                                ),
                                                                child:
                                                                    LinearProgressIndicator(
                                                                  value:
                                                                      loadingController
                                                                          .value,
                                                                )),
                                                          ],
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        width: 10,
                                                      ),
                                                    ],
                                                  )),
                                              SizedBox(
                                                height: 20,
                                              ),
                                            ],
                                          ))
                                      : Container(),
                                ],
                              ),

                              /// Certificate
                              Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "İmza*",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 18.0,
                                  ),
                                  TextFormField(
                                    controller: _certificateController,
                                    onChanged: (_) => setState(() {}),
                                    style: TextStyle(),
                                    decoration: const InputDecoration(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                vertical: 10.0,
                                                horizontal: 10.0),
                                        enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                          width: 2,
                                          color: Colors.blueAccent,
                                        )),
                                        hintText: "Cevabınız"),
                                  ),
                                ],
                              ),

                              const SizedBox(
                                height: 30.0,
                              ),

                              MaterialButton(
                                  child: const Text(
                                    'Göndermek',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  color: Theme.of(context).primaryColor,
                                  onPressed: () async {
                                    String path =
                                        "https://drive.google.com/drive/folders/1mcvdWg3-XYGZj_scV8Vgb3a9EK_RAC6O";
                                    _loginWithGoogle();
                                    if (origin == 'diğer') {
                                      origin = _originOtherController.text;
                                    }
                                    if (crimeLevel == 'diğer') {
                                      crimeLevel = _levelOtherController.text;
                                    }
                                    await widget.provider.addHouse(
                                        _nameController.text,
                                        _complaintController.text,
                                        origin,
                                        crimeLevel,
                                        _teamNameController.text,
                                        _addressController.text,
                                        _dateController.text,
                                        _certificateController.text,
                                        path);
                                    Navigator.of(context).pop();
                                  }),
                            ],
                          ),
                        ),
                      )
                    ],
                  )
                ],
              )),
            )),
        bottomNavigationBar: Container(
            height: 75,
            decoration: BoxDecoration(
              image: DecorationImage(
                  image: AssetImage('assets/images/bottom_bg.png'),
                  fit: BoxFit.fill),
            ),
            child: BottomNavigationBar(
              backgroundColor: Colors.transparent,
              type: BottomNavigationBarType.fixed, // new line
              elevation: 0,
              iconSize: 0,
              items: [
                BottomNavigationBarItem(
                  icon: Icon(Icons.add),
                  label: "",
                ),
                BottomNavigationBarItem(icon: Icon(Icons.remove), label: ""),
              ],
            )));
  }
}
