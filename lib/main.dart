import 'package:flutter/material.dart';
import 'package:naliv_merchant/api.dart';
import 'package:naliv_merchant/pages/activeOrders.dart';
import 'package:naliv_merchant/pages/login.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Always initialize Awesome Notifications

  runApp(Main());
}

class Main extends StatefulWidget {
  const Main({super.key});
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
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
    await getToken().then((token) {
      if (token != null) {
        setState(() {
          _redirect = ActiveOrders();
        });
      } else {
        setState(() {
          _redirect = LoginPage();
        });
      }
    });

    // _requestPermission().then((value) async {
    //   if (value) {
    //   } else {
    //     _redirect = PermissionPage();
    //   }
    // });
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      print(MediaQuery.of(context).size.aspectRatio);
    });
    // TODO: implement initState
    _checkAuth();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
          contrastLevel: 0,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      home: _redirect,
    );
  }
}
