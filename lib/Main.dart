import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:Axteroid/Login.dart';
import 'package:Axteroid/Info.dart'; // Importa la pantalla Info

void main() {
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]); // Establece la orientación vertical

  runApp(LoginApp());
}

class LoginApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  int _tapCount = 0; // Contador de toques

  @override
  void initState() {
    super.initState();
    Timer(
      Duration(seconds: 3),
          () {
        if (_tapCount < 5) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginPage()),
          );
        }
      },
    );
  }

  void _handleTap() {
    setState(() {
      _tapCount++;
      if (_tapCount >= 5) { // Si se toca 5 veces o más
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => InfoScreen()), // Redirige a la pantalla de información
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: GestureDetector(
          onTap: _handleTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 140,
                height: 140,
                child: Image.network('https://media.licdn.com/dms/image/C4D0BAQEZMEshF4F6Tg/company-logo_200_200/0/1651687998519/axteroid_logo?e=2147483647&v=beta&t=8HX6RBpoVOS_vumckUbEE7ntI5TABJG3j5Q04Xa1Jn0'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
