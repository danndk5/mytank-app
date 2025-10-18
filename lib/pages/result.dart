import 'package:flutter/material.dart';

class ResultPage extends StatelessWidget {
  final Map<String, dynamic> result;
  ResultPage({required this.result});

  Widget _buildRow(String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: color)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hasil Perhitungan'),
        backgroundColor: Colors.green,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green.shade50, Colors.green.shade100],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tinggi Cairan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      SizedBox(height: 8),
                      Text('${result['tinggiCairan']} mm', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
                      Text('(${result['meter']}m ${result['cm']}cm ${result['mm']}mm)', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Volume', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      SizedBox(height: 8),
                      _buildRow('Volume ${result['cm']}cm:', '${result['volumeCm'].toStringAsFixed(3)} L'),
                      _buildRow('Volume ${result['mm']}mm:', '${result['volumeMm'].toStringAsFixed(3)} L'),
                      Divider(),
                      _buildRow('VT:', '${result['vt'].toStringAsFixed(3)} L', bold: true),
                      _buildRow('V.OBS:', '${result['vObs'].toStringAsFixed(3)} L', bold: true),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Koreksi Standar (15°C)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      SizedBox(height: 8),
                      _buildRow('VCF:', '${result['vcf'].toStringAsFixed(6)}'),
                      _buildRow('V.15:', '${result['v15'].toStringAsFixed(3)} L', bold: true, color: Colors.green),
                      _buildRow('D.15:', '${result['d15'].toStringAsFixed(4)}'),
                    ],
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