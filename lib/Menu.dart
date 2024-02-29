import 'package:Axteroid/Login.dart';
import 'package:flutter/material.dart';
import 'package:Axteroid/Managers/TokenManager.dart';
import 'package:Axteroid/Widgets/DrawerG.dart';
import 'package:flutter/services.dart';

class MenuPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    return Scaffold(
      appBar: AppBar(
        title: Text('Bienvenido'),
        centerTitle: true,
      ),
      drawer: DrawerPageG(
        onLogout: () {
          _handleLogout(context);
        },
        currentPage: '',
      ),
      body: Center(
        child: Text('¡Bienvenido!', style: TextStyle(fontSize: 24)),
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    TokenManager().clearTokens();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
          (Route<dynamic> route) => false,
    );
  }
}