import 'dart:async';
import 'dart:convert';
import 'package:Axteroid/Home.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:Axteroid/Managers/TokenManager.dart';
import 'package:flutter/services.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isObscured = true;
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  bool _showEmptyFieldsError = false;
  bool _showInvalidCredentialsError = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _toggleObscureText() {
    setState(() {
      _isObscured = !_isObscured;
    });
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse('https://api.axteroid.com/token/');
    final body = {"username": username, "password": password};

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      setState(() {
        _showInvalidCredentialsError = true;
      });
      throw Exception("Login Error" + response.statusCode.toString());
    }
  }

  void handleLogin() async {
    final username = _usernameController.text;
    final password = _passwordController.text;

    // Reiniciar errores antes de cada intento de inicio de sesión
    setState(() {
      _showEmptyFieldsError = false;
      _showInvalidCredentialsError = false;
    });

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _showEmptyFieldsError = true;
      });
      return;
    }

    try {
      final response = await login(username, password);

      final refreshToken = response['refresh'] as String?;
      final accessToken = response['access'] as String?;

      if (refreshToken != null && accessToken != null) {
        TokenManager().setTokens(refreshToken, accessToken);

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Home()),
        );
      } else {
        throw Exception('Tokens inválidos');
      }
    } catch (e) {
      print('Error de login: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: SizedBox(
          height: 50.0,
          child: Center(
            child: Text('Iniciar Sesión', style: TextStyle(color: Colors.black)),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 40.0),
              Container(
                padding: EdgeInsets.only(top: 1.0),
                width: 100,
                height: 100,
                child: Image.network('https://media.licdn.com/dms/image/C4D0BAQEZMEshF4F6Tg/company-logo_200_200/0/1651687998519/axteroid_logo?e=2147483647&v=beta&t=8HX6RBpoVOS_vumckUbEE7ntI5TABJG3j5Q04Xa1Jn0'),
              ),
              SizedBox(height: 40.0),
              Text('Email', style: TextStyle(color: Colors.blue)),
              SizedBox(height: 8.0),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20.0),
              Text('Contraseña', style: TextStyle(color: Colors.blue)),
              SizedBox(height: 8.0),
              Stack(
                alignment: Alignment.centerRight,
                children: [
                  TextField(
                    controller: _passwordController,
                    obscureText: _isObscured,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                  IconButton(
                    icon: Icon(_isObscured ? Icons.visibility : Icons.visibility_off),
                    onPressed: _toggleObscureText,
                  ),
                ],
              ),
              SizedBox(height: 10.0),
              if (_showEmptyFieldsError)
                Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Llena los campos para continuar',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              if (_showInvalidCredentialsError)
                Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Las credenciales ingresadas no son correctas',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              SizedBox(height: 30.0),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: handleLogin,
                  child: Text('Ingresar'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    primary: Colors.blue,
                    onPrimary: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
