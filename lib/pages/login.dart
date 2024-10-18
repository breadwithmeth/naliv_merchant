import 'package:flutter/material.dart';
import 'package:naliv_merchant/api.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoginButtonActive = true;
  TextEditingController _token = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
            child: TextField(
          decoration: InputDecoration(
              hintText: "Токен магазина", border: OutlineInputBorder()),
        )),
        Flexible(
            child: Container(
          padding: EdgeInsets.all(20),
          child: ElevatedButton(
              onPressed: _isLoginButtonActive
                  ? () {
                      setState(() {
                        _isLoginButtonActive = false;
                      });
                      login(_token.text);
                    }
                  : null,
              child: Text("Login")),
        ))
      ],
    ));
  }
}
