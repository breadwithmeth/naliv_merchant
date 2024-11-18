import 'package:flutter/material.dart';
import 'package:naliv_merchant/NotificationController.dart';
import 'package:naliv_merchant/api.dart';
import 'package:naliv_merchant/pages/bottomMenu.dart';
import 'package:naliv_merchant/pages/login.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Always initialize Awesome Notifications
  await NotificationController.initializeLocalNotifications();
  await NotificationController.initializeIsolateReceivePort();
    FlutterForegroundTask.initCommunicationPort();

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
          _redirect = BottomMenu();
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
        NotificationController.startListeningNotificationEvents();

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
          seedColor: Colors.white,
          surface: Colors.black,
          dynamicSchemeVariant: DynamicSchemeVariant.content,
          contrastLevel: 0,
          brightness: Brightness.dark,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.transparent,
        ),
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: _redirect,
    );
  }
}
