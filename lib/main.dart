import 'package:flutter/cupertino.dart';
import 'package:naliv_merchant/api.dart';
import 'package:naliv_merchant/pages/activeOrders.dart';
import 'package:naliv_merchant/pages/login.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
  Widget _redirect = CupertinoPageScaffold(
    child: Center(
      child: CupertinoActivityIndicator(),
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
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      print(MediaQuery.of(context).size.aspectRatio);
    });
    _checkAuth();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      theme: const CupertinoThemeData(
        primaryColor: CupertinoColors.activeOrange,
        brightness: Brightness.light,
        scaffoldBackgroundColor: CupertinoColors.white,
        barBackgroundColor: CupertinoColors.activeOrange,
      ),
      home: _redirect,
    );
  }
}
