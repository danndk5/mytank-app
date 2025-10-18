import 'package:flutter/material.dart';
import '../models/tank.dart';
import '../models/calculation_history.dart';
import '../services/db.dart';

class ResultPage extends StatefulWidget {
  final Map<String, dynamic> result;
  final Tank tank;
  final double sounding;
  final double mejaUkur;
  final double tempDalam;
  final double tempLuar;
  final double densityObserved;

  ResultPage({
    required this.result,
    required this.tank,
    required this.sounding,
    required this.mejaUkur,
    required this.tempDalam,
    required this.tempLuar,
    required this.densityObserved,
  });

  @override
  _ResultPageState createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  bool isSaved = false;
  int? savedHistoryId;

  Widget _buildRow(String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> saveToHistory() async {
    try {
      final history = CalculationHistory(
        tankId: widget.tank.id!,
        tankName: widget.tank.name,
        sounding: widget.sounding,
        mejaUkur: widget.mejaUkur,
        tempDalam: widget.tempDalam,
        tempLuar: widget.tempLuar,
        densityObserved: widget.densityObserved,
        vt: widget.result['vt'],
        vObs: widget.result['vObs'],
        vcf: widget.result['vcf'],
        v15: widget.result['v15'],
        d15: widget.result['d15'],
        timestamp: DateTime.now(),
      );

      final id = await DatabaseService.saveHistory(history);

      setState(() {
        isSaved = true;
        savedHistoryId = id;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Perhitungan berhasil disimpan ke history'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> addNotes() async {
    if (savedHistoryId == null) return;

    final controller = TextEditingController();
    final notes = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tambah Catatan'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Masukkan catatan...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text('Simpan'),
          ),
        ],
      ),
    );

    if (notes != null && notes.isNotEmpty) {
      await DatabaseService.updateHistoryNotes(savedHistoryId!, notes);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Catatan berhasil ditambahkan')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hasil Perhitungan'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
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
              // Success Banner
              if (isSaved)
                Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade700),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Perhitungan telah disimpan ke history',
                            style: TextStyle(color: Colors.green.shade900),
                          ),
                        ),
                        TextButton(
                          onPressed: addNotes,
                          child: Text('+ Catatan'),
                        ),
                      ],
                    ),
                  ),
                ),
              
              if (isSaved) SizedBox(height: 8),

              // Tinggi Cairan Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.height, color: Colors.blue.shade700),
                          SizedBox(width: 8),
                          Text(
                            'Tinggi Cairan',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        '${widget.result['tinggiCairan']} mm',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '(${widget.result['meter']}m ${widget.result['cm']}cm ${widget.result['mm']}mm)',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 12),

              // Volume Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.water_drop, color: Colors.blue.shade700),
                          SizedBox(width: 8),
                          Text(
                            'Volume',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      _buildRow(
                        'Volume ${widget.result['cm']}cm:',
                        '${widget.result['volumeCm'].toStringAsFixed(3)} L',
                      ),
                      _buildRow(
                        'Volume ${widget.result['mm']}mm:',
                        '${widget.result['volumeMm'].toStringAsFixed(3)} L',
                      ),
                      Divider(height: 24),
                      _buildRow(
                        'VT:',
                        '${widget.result['vt'].toStringAsFixed(3)} L',
                        bold: true,
                      ),
                      _buildRow(
                        'V.OBS:',
                        '${widget.result['vObs'].toStringAsFixed(3)} L',
                        bold: true,
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 12),

              // Koreksi Standar Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.thermostat, color: Colors.green.shade700),
                          SizedBox(width: 8),
                          Text(
                            'Koreksi Standar (15°C)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      _buildRow(
                        'VCF:',
                        '${widget.result['vcf'].toStringAsFixed(6)}',
                      ),
                      _buildRow(
                        'V.15:',
                        '${widget.result['v15'].toStringAsFixed(3)} L',
                        bold: true,
                        color: Colors.green.shade700,
                      ),
                      _buildRow(
                        'D.15:',
                        '${widget.result['d15'].toStringAsFixed(4)}',
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20),

              // Save Button (hanya muncul kalau belum disimpan)
              if (!isSaved)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: saveToHistory,
                    icon: Icon(Icons.save),
                    label: Text('Simpan ke History'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.all(16),
                      textStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),

              SizedBox(height: 12),

              // Back Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.arrow_back),
                  label: Text('Kembali'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.all(16),
                    side: BorderSide(color: Colors.green.shade700),
                    foregroundColor: Colors.green.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
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