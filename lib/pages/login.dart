import 'package:flutter/cupertino.dart';
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
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.white,
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: CupertinoTextField(
                  controller: _token,
                  placeholder: "Токен магазина",
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: CupertinoColors.systemGrey,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.all(12),
                ),
              ),
            ),
            Flexible(
              child: Container(
                padding: EdgeInsets.all(20),
                child: CupertinoButton.filled(
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
                              Navigator.pushReplacement(
                                context,
                                CupertinoPageRoute(
                                  builder: (context) => Main(),
                                ),
                              );
                            }
                          });
                        }
                      : null,
                  child: Text("Войти"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
