import 'dart:async';
import 'dart:convert';
import 'package:Axteroid/Widgets/DrawerH.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:Axteroid/Managers/TokenManager.dart';
import 'package:Axteroid/Managers/StateManager.dart';
import 'package:Axteroid/Menu.dart';
import 'package:Axteroid/Login.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final TokenManager _tokenManager = TokenManager();
  TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> organizations = [];
  String? selectedOrganizationId;

  @override
  void initState() {
    super.initState();
    _fetchData('');
  }

  Future<void> _fetchData(String searchText) async {
    organizations.clear();
    String apiUrl = searchText.isEmpty
        ? 'https://api.axteroid.com/accounts/'
        : 'https://api.axteroid.com/accounts/?name__icontains=$searchText';

    String? accessToken = _tokenManager.accessToken;

    if (accessToken != null) {
      String jwtToken = 'JWT $accessToken';

      try {
        var response = await http.get(
          Uri.parse(apiUrl),
          headers: {'Authorization': jwtToken},
        );

        if (response.statusCode == 200) {
          var jsonData = json.decode(response.body);
          var results = jsonData['results'];

          for (var result in results) {
            String name = result['name'];
            String country = result['country'];
            String taxId = result['tax_id'];
            String orgId = result['id'];

            organizations.add({
              'name': name,
              'country': country,
              'taxId': taxId,
              'id': orgId,
            });

            if (StateManager().selectedOrganizationId == null) {
              StateManager().selectedOrganizationId = orgId;
            }
          }
        } else if (response.statusCode == 401) {
          await _refreshTokenAndRetry(apiUrl);
        } else {
          print('Error al obtener los datos. Código de estado: ${response.statusCode}');
        }
      } catch (e) {
        print('Error: $e');
      }
    }

    setState(() {});
  }

  Future<void> _refreshTokenAndRetry(String apiUrl) async {
    String? refreshToken = _tokenManager.refreshToken;

    if (refreshToken != null) {
      String refreshTokenUrl = 'https://api.axteroid.com/token/refresh/';
      try {
        var refreshResponse = await http.post(
          Uri.parse(refreshTokenUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'refresh': refreshToken}),
        );

        if (refreshResponse.statusCode == 200) {
          var refreshData = json.decode(refreshResponse.body);
          String newAccessToken = refreshData['access'];
          _tokenManager.setTokens(refreshToken, newAccessToken);

          await _retryOriginalRequest(apiUrl, newAccessToken);
        } else {
          print('Error al refrescar el token. Código de estado: ${refreshResponse.statusCode}');
        }
      } catch (e) {
        print('Error al refrescar el token: $e');
      }
    } else {
      print('No hay un token de actualización disponible.');
    }
  }

  Future<void> _retryOriginalRequest(String apiUrl, String newAccessToken) async {
    try {
      var retryResponse = await http.get(
        Uri.parse(apiUrl),
        headers: {'Authorization': 'JWT $newAccessToken'},
      );

      if (retryResponse.statusCode == 200) {
        var jsonData = json.decode(retryResponse.body);
        var results = jsonData['results'];

        for (var result in results) {
          String name = result['name'];
          String country = result['country'];
          String taxId = result['tax_id'];
          String orgId = result['id'];

          organizations.add({
            'name': name,
            'country': country,
            'taxId': taxId,
            'id': orgId,
          });

          if (StateManager().selectedOrganizationId == null) {
            StateManager().selectedOrganizationId = orgId;
          }
        }
      } else {
        print('Error al obtener los datos después de actualizar el token. Código de estado: ${retryResponse.statusCode}');
      }
    } catch (e) {
      print('Error al volver a intentar la solicitud: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    return Scaffold(
      appBar: AppBar(
        title: Text('Organizaciones'),
        centerTitle: true,
      ),
      drawer: DrawerPageH(
        onLogout: () {
          _handleLogout(context);
        },
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar',
                    ),
                  ),
                ),
                SizedBox(width: 8.0),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    primary: Colors.blue,
                    onPrimary: Colors.white,
                  ),
                  onPressed: () {
                    String searchText = _searchController.text.trim();
                    _fetchData(searchText);
                  },
                  child: Text('Buscar'),
                ),
              ],
            ),
          ),
          Expanded(
            child: organizations.isEmpty
                ? Center(child: Text('No hay datos disponibles'))
                : ListView.builder(
              itemCount: organizations.length * 2 - 1, // *2-1 to account for dividers
              itemBuilder: (context, index) {
                if (index.isOdd) {
                  return Divider();
                }
                final int dataIndex = index ~/ 2;
                String country = organizations[dataIndex]['country'];
                String taxId = organizations[dataIndex]['taxId'];
                return GestureDetector(
                  onTap: () {
                    _handleOrganizationSelection(organizations[dataIndex]['id']);
                  },
                  child: ListTile(
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(organizations[dataIndex]['name']),
                        SizedBox(height: 5),
                        Row(
                          children: [
                            Text(country == 'PE' ? 'RUC: ' : 'RUT: '),
                            Text(taxId),
                          ],
                        ),
                      ],
                    ),
                    selected: selectedOrganizationId == organizations[dataIndex]['id'],
                    selectedTileColor: Colors.blue.withOpacity(0.2),
                  ),
                );
              },
            ),
          ),
        ],
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

  void _handleOrganizationSelection(String orgId) {
    setState(() {
      StateManager().selectedOrganizationId = orgId;
      print('Selected Organization ID: $orgId');
    });
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MenuPage()),
    );
  }
}
