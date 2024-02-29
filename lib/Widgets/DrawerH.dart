import 'package:Axteroid/Login.dart';
import 'package:flutter/material.dart';
import 'package:Axteroid/Managers/UserManager.dart' as UserMgr;
import 'package:Axteroid/Managers/TokenManager.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class DrawerPageH extends StatelessWidget {
  final VoidCallback onLogout;

  DrawerPageH({required this.onLogout});

  Future<void> _fetchUserData() async {
    String? accessToken = TokenManager().accessToken;

    if (accessToken != null) {
      String apiUrl = 'https://api.axteroid.com/auth/user/';
      String jwtToken = 'JWT $accessToken';

      try {
        var response = await http.get(
          Uri.parse(apiUrl),
          headers: {'Authorization': jwtToken},
        );

        if (response.statusCode == 200) {
          var jsonData = json.decode(response.body);
          String firstName = jsonData['first_name'];
          String lastName = jsonData['last_name'];

          UserMgr.UserManager().setUserDetails(firstName, lastName);
        } else {
          print('Error al obtener los detalles del usuario. Código de estado: ${response.statusCode}');
        }
      } catch (e) {
        print('Error: $e');
      }
    }
  }

  void _handleLogout(BuildContext context) {
    TokenManager().clearTokens();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
          (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: FutureBuilder(
        future: _fetchUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                DrawerHeader(
                  padding: EdgeInsets.only(top: 30.0, bottom: 10.0),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        leading: SizedBox(
                          width: 40,
                          child: Icon(Icons.account_circle),
                        ),
                        title: Text(UserMgr.UserManager().fullName ?? ''),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: SizedBox(
                    width: 40,
                    child: Icon(Icons.business, color: Colors.blue),
                  ),
                  title: Text('Organizaciones'),
                  onTap: () {
                  },
                ),
                ListTile(
                  leading: SizedBox(
                    width: 40,
                    child: Icon(Icons.exit_to_app, color: Colors.red),
                  ),
                  title: Text('Cerrar Sesión'),
                  onTap: () {
                    Navigator.pop(context);
                    _handleLogout(context);
                  },
                ),
                Divider(),
              ],
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}