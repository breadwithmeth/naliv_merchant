import 'package:flutter/material.dart';
import 'package:naliv_merchant/api.dart';
import 'package:naliv_merchant/main.dart';

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
          controller: _token,
          decoration: InputDecoration(
              hintText: "Токен магазина", border: OutlineInputBorder()),
        )),
        Flexible(
            child: Container(
          padding: EdgeInsets.all(20),
          child: ElevatedButton(
              onPressed: _isLoginButtonActive
                  ? () async {
                      print(_token.text);
                      setState(() {
                        _isLoginButtonActive = false;
                      });
                      await login(_token.text).then((v) {
                        setState(() {
                          _isLoginButtonActive = true;
                        });
                        if (v) {
                          Navigator.pushReplacement(context, MaterialPageRoute(
                            builder: (context) {
                              return Main();
                            },
                          ));
                        }
                      });
                    }
                  : null,
              child: Text("Login")),
        ))
      ],
    ));
  }
}
