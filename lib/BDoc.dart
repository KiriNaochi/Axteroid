import 'package:Axteroid/Login.dart';
import 'package:Axteroid/Docs.dart';
import 'package:flutter/material.dart';
import 'package:Axteroid/Widgets/DrawerG.dart';
import 'package:Axteroid/Managers/TokenManager.dart';
import 'package:Axteroid/Managers/StateManager.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';

void main() {
  runApp(MyApp());
}

class BDoc extends StatelessWidget {
  final TextEditingController serieController = TextEditingController();
  final TextEditingController correlativoController = TextEditingController();

  Future<void> _refreshToken() async {
    String? refreshToken = TokenManager().refreshToken;

    if (refreshToken != null) {
      String refreshTokenUrl = "https://api.axteroid.com/token/refresh/";

      try {
        http.Response refreshResponse = await http.post(
          Uri.parse(refreshTokenUrl),
          headers: {
            "Content-Type": "application/json",
          },
          body: json.encode({"refresh": refreshToken}),
        );

        if (refreshResponse.statusCode == 200) {
          Map<String, dynamic> refreshData = json.decode(refreshResponse.body);
          String newAccessToken = refreshData["access"];

          TokenManager().setTokens(refreshToken, newAccessToken);
        } else {
          print("Error al refrescar el token: ${refreshResponse.statusCode}");
        }
      } catch (e) {
        print("Excepción al refrescar el token: $e");
      }
    }
  }

  Future<void> _buscarDocumentos(BuildContext context) async {
    String serie = serieController.text.trim();
    String correlativo = correlativoController.text.trim();

    String organizationId = StateManager().selectedOrganizationId ?? "";
    String accessToken = TokenManager().accessToken ?? "";

    String baseUrl = "https://services.axteroid.com/documents";
    String endpoint;

    if (serie.isNotEmpty && correlativo.isNotEmpty) {
      endpoint =
      "$baseUrl?series=$serie&serial=$correlativo&test=true&ordering=-date&ordering=-created";
    } else {
      endpoint = "$baseUrl?ordering=-date&ordering=-created";
    }

    try {
      http.Response response = await http.get(
        Uri.parse(endpoint),
        headers: {
          "Authorization": "JWT $accessToken",
          "X-Ax-Workspace": organizationId,
        },
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = json.decode(response.body);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Docs(responseData),
          ),
        );
      } else if (response.statusCode == 401) {
        await _refreshToken();

        response = await http.get(
          Uri.parse(endpoint),
          headers: {
            "Authorization": "JWT ${TokenManager().accessToken}",
            "X-Ax-Workspace": organizationId,
          },
        );

        if (response.statusCode == 200) {
          Map<String, dynamic> responseData = json.decode(response.body);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Docs(responseData),
            ),
          );
        } else {
          print("Error en la segunda solicitud: ${response.statusCode}");
        }
      } else {
        print("Error en la solicitud: ${response.statusCode}");
      }
    } catch (e) {
      print("Excepción durante la solicitud: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text(
            'Buscar Documento',
            style: TextStyle(color: Colors.black),
          ),
          centerTitle: true,
        ),
        drawer: DrawerPageG(
          onLogout: () {
            _handleLogout(context);
          },
          currentPage: 'BDoc',
        ),
        body: Container(
          padding: EdgeInsets.all(20.0),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 20),
              Text(
                'Serie',
                style: TextStyle(color: Colors.blue),
              ),
              SizedBox(height: 6),
              TextFormField(
                controller: serieController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '',
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Correlativo',
                style: TextStyle(color: Colors.blue),
              ),
              SizedBox(height: 6),
              TextFormField(
                controller: correlativoController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '',
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _buscarDocumentos(context),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Text('Buscar', style: TextStyle(color: Colors.white)),
                ),
                style: ElevatedButton.styleFrom(
                  primary: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
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

  void _handleLogout(BuildContext context) {
    TokenManager().clearTokens();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
          (Route<dynamic> route) => false,
    );
  }

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BDoc',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: BDoc(),
    );
  }
}