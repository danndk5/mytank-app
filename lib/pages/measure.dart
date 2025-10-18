import 'package:flutter/material.dart';
import '../models/tank.dart';
import '../services/db.dart';
import '../services/calc.dart';
import 'result.dart';

class MeasurementPage extends StatefulWidget {
  final Tank tank;
  MeasurementPage({required this.tank});

  @override
  _MeasurementPageState createState() => _MeasurementPageState();
}

class _MeasurementPageState extends State<MeasurementPage> {
  final _formKey = GlobalKey<FormState>();
  final soundingController = TextEditingController();
  final mejaUkurController = TextEditingController();
  final tempDalamController = TextEditingController();
  final tempLuarController = TextEditingController();
  final densityController = TextEditingController();

  Future<void> calculate() async {
    if (!_formKey.currentState!.validate()) return;

    final calibration = await DatabaseService.getCalibration(widget.tank.id!);
    final fraction = await DatabaseService.getFraction(widget.tank.id!);

    if (calibration.isEmpty || fraction.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tabel kalibrasi atau fraksi belum diisi!')),
      );
      return;
    }

    final volResult = CalculatorService.calculateVolume(
      double.parse(soundingController.text),
      double.parse(mejaUkurController.text),
      calibration,
      fraction,
    );

    final vObs = CalculatorService.applyTempCorrection(
      volResult['vt'],
      double.parse(tempDalamController.text),
      widget.tank.tempRef,
      widget.tank.koefEkspansi,
    );

    final vcf = CalculatorService.calculateVCF(
      double.parse(tempDalamController.text),
      double.parse(densityController.text),
    );

    final v15 = vObs * vcf;
    final d15 = double.parse(densityController.text) / vcf;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultPage(
          result: {
            ...volResult,
            'vObs': vObs,
            'vcf': vcf,
            'v15': v15,
            'd15': d15,
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tank.name),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.blue.shade100],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: soundingController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Sounding (mm)',
                        border: OutlineInputBorder(),
                        hintText: '1823',
                      ),
                      validator: (v) => v!.isEmpty ? 'Harus diisi' : null,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: mejaUkurController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Meja Ukur (mm)',
                        border: OutlineInputBorder(),
                        hintText: '40',
                      ),
                      validator: (v) => v!.isEmpty ? 'Harus diisi' : null,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: tempDalamController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Temperatur Dalam (°C)',
                        border: OutlineInputBorder(),
                        hintText: '31',
                      ),
                      validator: (v) => v!.isEmpty ? 'Harus diisi' : null,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: tempLuarController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Temperatur Luar (°C)',
                        border: OutlineInputBorder(),
                        hintText: '30',
                      ),
                      validator: (v) => v!.isEmpty ? 'Harus diisi' : null,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: densityController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Density Observed',
                        border: OutlineInputBorder(),
                        hintText: '0.850',
                      ),
                      validator: (v) => v!.isEmpty ? 'Harus diisi' : null,
                    ),
                    SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: calculate,
                      icon: Icon(Icons.calculate),
                      label: Text('Hitung Volume'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.all(16),
                        textStyle: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}