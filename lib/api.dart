import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import './globals.dart' as globals;

var client = http.Client();

String URL_API = 'chorenn.naliv.kz';


Future<String?> getToken() async {
  final prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('token');
  if (token == "000" || token == null) {
    return null;
  }
  globals.setToken(token);
  print(token);
  return token;
}


Future<bool> setToken(Map data) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('token', data['token']);
  final token = prefs.getString('token') ?? false;
  print(token);
  return token == false ? false : true;
}


Future<bool> login(String token) async {
  var url = Uri.https(URL_API, 'api/merchant/login');
  var response = await client.post(
    url,
    body: json.encode({'token': token}),
    headers: {"Content-Type": "application/json"},
  );
  var data = jsonDecode(response.body);
  if (response.statusCode == 202) {
    await SharedPreferences.getInstance();
    setToken(data);
    print(data['token']);

    return true;
  } else {
    return false;
  }
}