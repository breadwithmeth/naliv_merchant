import 'package:flutter/material.dart';
import 'package:naliv_merchant/api.dart';
import 'package:naliv_merchant/pages/login.dart';

void main() {
  runApp(Main());
}

class Main extends StatefulWidget {
  const Main({super.key});

  @override
  State<Main> createState() => _MainState();
}

class _MainState extends State<Main> {
  Widget _redirect = Scaffold(
    body: Center(
      child: CircularProgressIndicator(),
    ),
  );

  Future<void> _checkAuth() async {
    String? token = await getToken();
    if (token != null) {
    } else {
      setState(() {
        _redirect = LoginPage();
      });
    }
    // _requestPermission().then((value) async {
    //   if (value) {
    //   } else {
    //     _redirect = PermissionPage();
    //   }
    // });
  }

  @override
  void initState() {
    // TODO: implement initState
    _checkAuth();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: _redirect,
    );
  }
}
