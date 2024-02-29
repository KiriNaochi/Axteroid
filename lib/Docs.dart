import 'dart:convert';
import 'dart:io';
import 'package:Axteroid/Login.dart';
import 'package:Axteroid/Managers/TokenManager.dart';
import 'package:Axteroid/Managers/StateManager.dart';
import 'package:Axteroid/Widgets/DrawerG.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class DocumentDetails extends StatefulWidget {
  final Map<String, dynamic> document;

  DocumentDetails({required this.document});

  @override
  _DocumentDetailsState createState() => _DocumentDetailsState();
}

class _DocumentDetailsState extends State<DocumentDetails> {
  bool _isButtonEnabled = true;

  @override
  Widget build(BuildContext context) {
    String documentNumber = widget.document['number'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text('Detalles del Documento'),
      ),
      body: Container(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(10.0),
              ),
              padding: EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Nº $documentNumber',
                    style: TextStyle(color: Colors.white),
                  ),
                  Text(
                    'Fecha ${formatCreatedDate(widget.document['created'] ?? '')}',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.0),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10.0),
              ),
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resumen del documento',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Divider(),
                  SizedBox(height: 10.0),
                  Text('Razon Social: ${widget.document['customer_name']}'),
                  SizedBox(height: 10.0),
                  Text('${getTaxText()}: ${widget.document['tax_id'] ?? ''}'),
                  SizedBox(height: 10.0),
                  Text('Serie y Correlativo: $documentNumber'),
                  SizedBox(height: 10.0),
                  Text('Tipo de documento: ${mapDocumentType(widget.document['type'] ?? '')}'),
                  SizedBox(height: 10.0),
                  Text('Creado: ${formatCustomDate(widget.document['date'] ?? '')}'),
                  SizedBox(height: 10.0),
                  Row(
                    children: [
                      Text('Estado: '),
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
                        decoration: BoxDecoration(
                          color: _getStatusColor(widget.document['status']),
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                        child: Text(
                          '${_getStatusText(widget.document['status'])}',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 35.0),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isButtonEnabled
            ? () async {
          setState(() {
            _isButtonEnabled = false;
          });
          await _downloadPdf(context);
        }
            : null,
        backgroundColor: _isButtonEnabled ? Colors.blue : Colors.grey,
        tooltip: 'Descargar PDF',
        child: Icon(Icons.file_download),
      ),
    );
  }

  String getTaxText() {
    String country = widget.document['country'] ?? '';
    return country == 'PE' ? 'RUC' : (country == 'CL' ? 'RUT' : '');
  }

  String formatCreatedDate(String date) {
    DateTime parsedDate = DateTime.parse(date);
    return "${parsedDate.day} ${_getMonthName(parsedDate.month)} ${parsedDate.year}";
  }

  String formatCustomDate(String date) {
    DateTime parsedDate = DateTime.parse(date);
    return "${parsedDate.day} ${_getMonthName(parsedDate.month)} ${parsedDate.year}";
  }

  String _getMonthName(int month) {
    final monthNames = [
      'ene.', 'feb.', 'mar.', 'abr.', 'may.', 'jun.',
      'jul.', 'ago.', 'sep.', 'oct.', 'nov.', 'dic.'
    ];
    return monthNames[month - 1];
  }

  String mapDocumentType(String type) {
    switch (type) {
      case 'PE01':
        return 'Factura';
      case 'PE03':
        return 'Boleta';
      case 'PE07':
        return 'Nota de crédito';
      case 'PE08':
        return 'Nota de débito';
      case 'PE09':
        return 'Guía de remisión';
      case 'PE20':
        return 'Retención';
      case 'PE40':
        return 'Percepción';
      default:
        return 'Desconocido';
    }
  }

  static String _getStatusText(String? statusCode) {
    final Map<String, String> statusMap = {
      'REJ': 'Rechazado',
      'VOI': 'Anulado',
      'OBS': 'Aceptado con reparo',
      'APR': 'Aceptado',
      'CRE': 'Procesando',
      'SNT': 'Pendiente',
      'FAI': 'Pendiente',
      'DUP': 'Rechazado',
      'MRT': 'Reintento Manual',
      'ART': 'Reintento Automático',
    };

    if (statusCode != null && statusMap.containsKey(statusCode)) {
      return statusMap[statusCode] ?? 'Desconocido';
    } else {
      return 'Desconocido';
    }
  }

  Future<void> _downloadPdf(BuildContext context) async {
    try {
      bool permissionGranted = await _requestStoragePermission();
      if (!permissionGranted) {
        print('El usuario no concedió permisos de almacenamiento.');
        return;
      }

      String documentId = widget.document['id'] ?? '';
      String accessToken = TokenManager().accessToken ?? '';
      String authorizationHeader = 'JWT $accessToken';
      String acceptHeader = 'application/pdf';
      String workspaceHeader = StateManager().selectedOrganizationId ?? '';

      String pdfUrl = 'https://services.axteroid.com/documents/$documentId';

      final response = await http.get(
        Uri.parse(pdfUrl),
        headers: {
          'Authorization': authorizationHeader,
          'Accept': acceptHeader,
          'X-Ax-Workspace': workspaceHeader,
        },
      );

      if (response.statusCode == 200) {
        await _saveFile(response.bodyBytes, documentId);
      } else if (response.statusCode == 401) {
        await _refreshTokenAndRetryDownload(context, pdfUrl, documentId);
      } else {
        print('Error al descargar el PDF: ${response.statusCode}');
      }
    } catch (e) {
      print('Excepción durante la descarga: $e');
    }
  }

  Future<void> _refreshTokenAndRetryDownload(BuildContext context, String pdfUrl, String documentId) async {
    try {
      String refreshToken = TokenManager().refreshToken ?? '';
      if (refreshToken.isNotEmpty) {
        final refreshResponse = await http.post(
          Uri.parse('https://api.axteroid.com/token/refresh/'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'refresh': refreshToken}),
        );

        if (refreshResponse.statusCode == 200) {
          String newAccessToken = json.decode(refreshResponse.body)['access'];
          TokenManager().setTokens(refreshToken, newAccessToken);

          final retryResponse = await http.get(
            Uri.parse(pdfUrl),
            headers: {
              'Authorization': 'JWT $newAccessToken',
              'Accept': 'application/pdf',
              'X-Ax-Workspace': StateManager().selectedOrganizationId ?? '',
            },
          );

          if (retryResponse.statusCode == 200) {
            await _saveFile(retryResponse.bodyBytes, documentId);
          } else {
            print('Error al descargar el PDF después de la renovación del token: ${retryResponse.statusCode}');
          }
        } else {
          print('Error al renovar el token: ${refreshResponse.statusCode}');
        }
      } else {
        print('El refreshToken está vacío.');
      }
    } catch (e) {
      print('Excepción durante la renovación del token: $e');
    }
  }

  Future<bool> _requestStoragePermission() async {
    var status = await Permission.storage.request();
    return status == PermissionStatus.granted;
  }

  Future<void> _saveFile(List<int> bytes, String documentId) async {
    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/documento_$documentId.pdf');
      await file.writeAsBytes(bytes, flush: true);
      OpenFile.open(file.path);
    } catch (e) {
      print('Excepción al guardar el archivo: $e');
    }
  }

  Color _getStatusColor(String? statusCode) {
    switch (statusCode) {
      case 'VOI':
      case 'SNT':
      case 'FAI':
        return Colors.grey; // Anulado y Pendiente
      case 'CRE':
        return Colors.yellow; // Procesando
      case 'REJ':
      case 'DUP':
        return Colors.red; // Rechazado
      case 'APR':
      case 'OBS':
        return Colors.blue; // Aceptado y Aceptado con reparo
      default:
        return Colors.grey; // Otros estados
    }
  }
}

class Docs extends StatelessWidget {
  final Map<String, dynamic> responseData;

  Docs(this.responseData);

  Map<String, String> statusMap = {
    'REJ': 'Rechazado',
    'VOI': 'Anulado',
    'OBS': 'Aceptado con reparo',
    'APR': 'Aceptado',
    'CRE': 'Procesando',
    'SNT': 'Pendiente',
    'FAI': 'Pendiente',
    'DUP': 'Rechazado',
    'MRT': 'Reintento Manual',
    'ART': 'Reintento Automático',
  };

  Color _getStatusColor(String? statusCode) {
    switch (statusCode) {
      case 'VOI':
      case 'SNT':
      case 'FAI':
        return Colors.grey; // Gris para Anulado y Pendiente
      case 'CRE':
        return Colors.yellow; // Amarillo para Procesando
      case 'REJ':
      case 'DUP':
        return Colors.red; // Rojo para Rechazado
      case 'APR':
      case 'OBS':
        return Colors.blue; // Celeste para Aceptado y Aceptado con reparo
      default:
        return Colors.grey; // Gris por defecto
    }
  }

  String formatDate(String date) {
    List<String> dateParts = date.split('-');
    int year = int.parse(dateParts[0]);
    int month = int.parse(dateParts[1]);
    int day = int.parse(dateParts[2]);

    return "$day ${_MonthName(month)} $year";
  }

  String _MonthName(int month) {
    final monthNames = [
      'ene.', 'feb.', 'mar.', 'abr.', 'may.', 'jun.',
      'jul.', 'ago.', 'sep.', 'oct.', 'nov.', 'dic.'
    ];
    return monthNames[month - 1];
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
    List<Widget> documentList = [];

    if (responseData.containsKey('results')) {
      List<dynamic> results = responseData['results'];

      for (var document in results) {
        String customerName = document['customer_name'];
        String statusCode = document['status'];
        String status = statusMap[statusCode] ?? 'Desconocido';

        documentList.add(
          Column(
            children: [
              Divider(),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DocumentDetails(
                        document: document,
                      ),
                    ),
                  );
                },
                child: ListTile(
                  title: Text('$customerName'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Serie y Correlativo: ${document['number']}'),
                      Text('Creado: ${formatDate(document['date'] ?? '')}'),
                      Row(
                        children: [
                          Text('Estado: '),
                          Container(
                            padding: EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
                            decoration: BoxDecoration(
                              color: _getStatusColor(statusCode),
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                            child: Text(
                              '$status',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }
    }

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text(
            'Documentos',
            style: TextStyle(color: Colors.black),
          ),
          centerTitle: true,
        ),
        drawer: DrawerPageG(
          onLogout: () {
            _handleLogout(context);
          },
          currentPage: '',
        ),
        body: Container(
          color: Colors.white,
          child: ListView(
            children: documentList,
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

void main() {
  runApp(Docs({}));
}
