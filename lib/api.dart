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
    print(data);
    return false;
  }
}

Future<Map?> getActiveOrders() async {
  String? token = await getToken();
  print(token);
  if (token == null) {
    return null;
  }
  var url = Uri.https(URL_API, 'api/merchant/getActiveOrders');
  var response = await client.post(
    url,
    headers: {
      "Content-Type": "application/json",
      "AUTH": token,
    },
  );

  Map result = json.decode(utf8.decode(response.bodyBytes));
  return result;
}

Future<Map> getOrderDetails(String order_id) async {
  String? token = globals.currentToken;

  if (token == null) {
    return {};
  }
  var url = Uri.https(URL_API, 'api/merchant/getOrder');
  var response = await client.post(
    url,
    headers: {
      "Content-Type": "application/json",
      "AUTH": token,
    },
    body: json.encode({"order_id": order_id}),
  );

  Map<String, dynamic> result = json.decode(response.body) ?? {};
  print(json.encode(response.statusCode));
  print(response.body);
  return result;
}

Future<bool> logout() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('token', "000");
  final token = prefs.getString('token') ?? false;
  print(token);
  return token == false ? false : true;
}

Future<bool?> changeAmount(int relation_id, String amount) async {
  String? token = globals.currentToken;

  if (token == null) {
    return null;
  }
  var url = Uri.https(URL_API, 'api/merchant/changeAmount');
  var response = await client.post(
    url,
    body: json.encode({'relation_id': relation_id, 'amount': amount}),
    headers: {"Content-Type": "application/json", "AUTH": token},
  );
  bool? data = jsonDecode(response.body);

  return data;
}

Future<bool?> orderReady(String order_id) async {
  String? token = globals.currentToken;

  if (token == null) {
    return null;
  }
  var url = Uri.https(URL_API, 'api/merchant/orderReady');
  var response = await client.post(
    url,
    body: json.encode({'order_id': order_id}),
    headers: {"Content-Type": "application/json", "AUTH": token},
  );
  print(response.body);
  bool? data = jsonDecode(response.body);

  return data;
}

Future<bool?> acceptOrder(String order_id) async {
  String? token = globals.currentToken;

  if (token == null) {
    return null;
  }
  var url = Uri.https(URL_API, 'api/merchant/acceptOrder');
  var response = await client.post(
    url,
    body: json.encode({'order_id': order_id}),
    headers: {"Content-Type": "application/json", "AUTH": token},
  );
  print(response.body);
  bool? data = jsonDecode(response.body);

  return data;
}

Future<List?> getReplacementItems(String relation_id) async {
  String? token = globals.currentToken;

  if (token == null) {
    return null;
  }
  var url = Uri.https(URL_API, 'api/merchant/getReplacementItems');
  var response = await client.post(
    url,
    body: json.encode({'relation_id': relation_id}),
    headers: {
      "Content-Type": "application/json",
      "AUTH": token,
    },
  );
  print(response.body);

  List result = json.decode(response.body);
  print(json.encode(response.statusCode));
  print(response.body);
  return result;
}

Future<bool?> replaceItem(String relation_id, String item_id) async {
  String? token = globals.currentToken;

  if (token == null) {
    return null;
  }
  var url = Uri.https(URL_API, 'api/merchant/replaceItem');
  var response = await client.post(
    url,
    body: json.encode({'relation_id': relation_id, 'item_id': item_id}),
    headers: {"Content-Type": "application/json", "AUTH": token},
  );
  print(response.body);
  bool? data = jsonDecode(response.body);

  return data;
}
