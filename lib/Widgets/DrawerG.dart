import 'package:Axteroid/Login.dart';
import 'package:flutter/material.dart';
import 'package:Axteroid/BDoc.dart';
import 'package:Axteroid/Graficos.dart';
import 'package:Axteroid/Home.dart';
import 'package:Axteroid/Managers/UserManager.dart' as UserMgr;
import 'package:Axteroid/Managers/TokenManager.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class DrawerPageG extends StatelessWidget {
  final VoidCallback onLogout;
  final String currentPage; // Nueva propiedad

  DrawerPageG({required this.onLogout, required this.currentPage});

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
                    child: Icon(Icons.business),
                  ),
                  title: Text('Organizaciones'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Home()),
                    );
                  },
                ),
                ListTile(
                  leading: SizedBox(
                    width: 40,
                    child: Icon(Icons.search, color: currentPage == 'BDoc' ? Colors.blue : null),
                  ),
                  title: Text('Buscar Documento'),
                  onTap: () {
                    if (currentPage != 'BDoc') { // Evitar redirección si ya estás en la página 'BDoc'
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => BDoc()),
                      );
                    }
                  },
                ),
                ListTile(
                  leading: SizedBox(
                    width: 40,
                    child: Icon(Icons.bar_chart, color: currentPage == 'Graficos' ? Colors.blue : null),
                  ),
                  title: Text('Graficos'),
                  onTap: () {
                    if (currentPage != 'Graficos') { // Evitar redirección si ya estás en la página 'Graficos'
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => GraficosPage()),
                      );
                    }
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