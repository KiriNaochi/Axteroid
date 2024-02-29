import 'package:flutter/material.dart';

class InfoScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('Información', style: TextStyle(color: Colors.black))),
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0), // Margen de 20 en todos los lados del body
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Alinear el contenido a la izquierda
          children: [
            _buildInfoItem('Creador', 'Pedro Lopez Retamal'),
            _buildInfoItem('Fecha de inicio', '03/01/2024'),
            _buildInfoItem('Fecha de termino', '19/02/2024'),
            SizedBox(height: 8), // Añade un espacio entre los elementos
            _buildNotesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text('$label: ', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(width: 5), // Agrega un pequeño espacio entre los dos puntos y el valor
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.left, // Alinear el texto a la izquierda
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Notas: ', style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        Container(
          margin: EdgeInsets.symmetric(horizontal: 1), // Margen horizontal de 20 unidades
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              readOnly: true,
              controller: TextEditingController(text: 'Esta aplicación fue creada como proyecto de práctica, para la empresa Axteroid SPA'),
              maxLines: null, // Permite múltiples líneas
              decoration: InputDecoration.collapsed(
                hintText: 'Esta aplicación fue creada como proyecto de práctica, para la empresa Axteroid SPA',
              ),
            ),
          ),
        ),
      ],
    );
  }
}
