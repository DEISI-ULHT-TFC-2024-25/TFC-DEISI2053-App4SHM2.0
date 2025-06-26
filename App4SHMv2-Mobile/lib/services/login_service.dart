import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LoginService {
  Future<bool> sendLoginRequest(String username, String password) async {
    final response = await http.post(
      Uri.parse(dotenv.env['BASE_URL']! + dotenv.env['LOGIN_URL']!),
      body: {
        'username': username,
        'password': password,
      },
    );
    dynamic body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['token'] != null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('userid', username);
      prefs.setString('token', body['token']);
      return true;
    } else {
      return false;
    }
  }
}