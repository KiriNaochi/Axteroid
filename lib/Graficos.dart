import 'dart:convert';
import 'dart:async';
import 'package:Axteroid/Managers/StateManager.dart';
import 'package:Axteroid/Managers/TokenManager.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class GraficosPage extends StatefulWidget {
  @override
  _GraficosPageState createState() => _GraficosPageState();
}

enum ChartType {
  original,
  copy,
}

class _GraficosPageState extends State<GraficosPage> {
  late List<ChartData> chartDataList;
  late Timer timer;
  String selectedTimeRange = '1 Hora';
  late String apiUrl;
  ChartType chartType = ChartType.original;

  @override
  void initState() {
    super.initState();
    chartDataList = [];
    apiUrl = 'https://services.axteroid.com/metrics/last-hour';
    _loadData();

    timer = Timer.periodic(Duration(minutes: 3), (Timer t) {
      _loadData();
    });

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight
    ]);
  }

  @override
  void dispose() {
    timer.cancel();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  Future<void> _loadData() async {
    String? accessToken = TokenManager().accessToken;
    String? selectedOrganizationId = StateManager().selectedOrganizationId;

    if (accessToken != null && selectedOrganizationId != null) {
      String jwtToken = 'JWT $accessToken';

      // Limpiamos la lista antes de agregar nuevos datos
      chartDataList.clear();

      try {
        var response = await http.get(
          Uri.parse(apiUrl), // Utilizar el enlace dinámico
          headers: {
            'Authorization': jwtToken,
            'X-Ax-Workspace': selectedOrganizationId,
          },
        );

        if (response.statusCode == 200) {
          var jsonData = json.decode(response.body);
          var refreshValue = jsonData['refresh'];

          // Convertir el valor del temporizador de segundos a milisegundos
          int timerDuration = refreshValue * 1000;

          // Cancelar el temporizador anterior si existe
          timer.cancel();

          // Configurar el temporizador con la nueva duración
          timer = Timer.periodic(Duration(milliseconds: timerDuration), (Timer t) {
            _loadData();
          });

          var data = jsonData['data'];

          // Obtener la hora actual
          var now = DateTime.now();
          var formatter = DateFormat('HH:mm');
          var currentHour = formatter.format(now);

          // Procesar datos para el rango de tiempo seleccionado
          data.forEach((key, value) {
            if (apiUrl.contains('last-hour')) {
              String hour = key.split('T')[1].substring(0, 5);
              chartDataList.add(ChartData(hour, value.toDouble()));
            } else if (apiUrl.contains('last-24hour')) {
              String hour = key.split('T')[1].substring(0, 5);
              chartDataList.add(ChartData(hour, value.toDouble()));
            } else if (apiUrl.contains('last-7days')) {
              String date = key.split('T')[0];
              String formattedDate = '${date.split('-')[2]}-${date.split('-')[1]}-${date.split('-')[0]}';
              chartDataList.add(ChartData(formattedDate, value.toDouble()));
            }
          });

          // Ordenar la lista por hora en caso de que sea el gráfico de 24 horas
          if (apiUrl.contains('last-24hour')) {
            // Obtener la hora actual
            var now = DateTime.now();
            var formatter = DateFormat('HH:mm');
            var currentHour = formatter.format(now);

            // Función de comparación personalizada
            int customCompare(String a, String b) {
              var timeA = formatter.parse(a);
              var timeB = formatter.parse(b);

              // Calcular el número de minutos desde la hora actual
              var minutesA = (timeA.hour * 60 + timeA.minute) - (now.hour * 60 + now.minute);
              var minutesB = (timeB.hour * 60 + timeB.minute) - (now.hour * 60 + now.minute);

              // Ajustar para manejar el orden circular
              minutesA = (minutesA + 1440) % 1440; // 1440 minutos en un día
              minutesB = (minutesB + 1440) % 1440;

              return minutesA.compareTo(minutesB);
            }

            // Ordenar la lista de acuerdo a la hora actual usando la función de comparación personalizada
            chartDataList.sort((a, b) => customCompare(a.label, b.label));

            // Encontrar el índice de la hora más cercana a la hora actual
            var nearestHourIndex = chartDataList.indexWhere((element) {
              return element.label == currentHour;
            });

            // Eliminar el primer bloque de respuesta que tenga la misma hora que el último bloque de respuesta
            if (nearestHourIndex != -1 && nearestHourIndex < chartDataList.length - 1) {
              chartDataList.removeAt(nearestHourIndex);
            }
          }
          // Actualizar la interfaz gráfica con los nuevos datos
          setState(() {});
        } else if (response.statusCode == 401) {
          await _refreshTokenAndRetry(apiUrl);
        } else {
          print('Error al obtener los datos. Código de estado: ${response.statusCode}');
        }
      } catch (e) {
        print('Error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WillPopScope(
        onWillPop: () async {
          return true;
        },
        child: SafeArea(
          child: SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              _changeTimeRange('1 Hora', 'https://services.axteroid.com/metrics/last-hour');
                            },
                            style: ElevatedButton.styleFrom(
                              primary: Colors.blue,
                              onPrimary: Colors.white,
                            ),
                            child: Text('1 Hora'),
                          ),
                          SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              _changeTimeRange('24 Horas', 'https://services.axteroid.com/metrics/last-24hour');
                            },
                            style: ElevatedButton.styleFrom(
                              primary: Colors.blue,
                              onPrimary: Colors.white,
                            ),
                            child: Text('24 Horas'),
                          ),
                          SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              _changeTimeRange('7 Días', 'https://services.axteroid.com/metrics/last-7days');
                            },
                            style: ElevatedButton.styleFrom(
                              primary: Colors.blue,
                              onPrimary: Colors.white,
                            ),
                            child: Text('7 Días'),
                          ),
                          SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _reloadData,
                            style: ElevatedButton.styleFrom(
                              primary: Colors.blue,
                              onPrimary: Colors.white,
                            ),
                            child: Text('Recargar'),
                          ),
                        ],
                      ),
                      SizedBox(width: 48),
                    ],
                  ),
                  SizedBox(height: 10),
                  Center(
                    child: Column(
                      children: [
                        if (chartType == ChartType.original && chartDataList.isNotEmpty)
                          BarChartOriginal(dataList: chartDataList),
                        if (chartType == ChartType.copy && chartDataList.isNotEmpty)
                          BarChartCopy(dataList: chartDataList),
                        if (chartDataList.isEmpty)
                          Text('Cargando datos...'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _changeTimeRange(String timeRange, String url) {
    selectedTimeRange = timeRange;
    apiUrl = url;
    if (timeRange == '1 Hora' || timeRange == '24 Horas') {
      setState(() {
        chartType = ChartType.original;
      });
    } else if (timeRange == '7 Días') {
      setState(() {
        chartType = ChartType.copy;
      });
    }
    _loadData();
  }

  void _reloadData() {
    _loadData();
  }

  Future<void> _refreshTokenAndRetry(String apiUrl) async {
    String? refreshToken = TokenManager().refreshToken;

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
          TokenManager().setTokens(refreshToken, newAccessToken);

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

        // Procesar los datos como sea necesario
      } else {
        print('Error al obtener los datos después de actualizar el token. Código de estado: ${retryResponse.statusCode}');
      }
    } catch (e) {
      print('Error al volver a intentar la solicitud: $e');
    }
  }
}

class ChartData {
  final String label;
  final double value;

  ChartData(this.label, this.value);
}

class BarChartOriginal extends StatelessWidget {
  final List<ChartData> dataList;

  BarChartOriginal({required this.dataList});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.9,
      height: MediaQuery.of(context).size.height * 0.65,
      child: SfCartesianChart(
        isTransposed: true,
        primaryXAxis: CategoryAxis(),
        primaryYAxis: NumericAxis(),
        series: <CartesianSeries<dynamic, dynamic>>[
          BarSeries<ChartData, String>(
            width: 0.6,
            dataSource: dataList,
            xValueMapper: (ChartData data, _) => data.label,
            yValueMapper: (ChartData data, _) => data.value,
            dataLabelSettings: DataLabelSettings(
              isVisible: true,
              labelAlignment: ChartDataLabelAlignment.top,
            ),
          ),
        ],
      ),
    );
  }
}

class BarChartCopy extends StatelessWidget {
  final List<ChartData> dataList;

  BarChartCopy({required this.dataList});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.9,
      height: MediaQuery.of(context).size.height * 0.65,
      child: SfCartesianChart(
        isTransposed: true,
        primaryXAxis: CategoryAxis(),
        primaryYAxis: NumericAxis(),
        series: <CartesianSeries<dynamic, dynamic>>[
          BarSeries<ChartData, String>(
            width: 0.6,
            dataSource: dataList,
            xValueMapper: (ChartData data, _) => data.label,
            yValueMapper: (ChartData data, _) => data.value,
            dataLabelSettings: DataLabelSettings(
              isVisible: true,
              labelAlignment: ChartDataLabelAlignment.top,
            ),
          ),
        ],
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: GraficosPage(),
  ));
}