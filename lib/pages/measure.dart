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

  // Validation constants
  static const double MAX_MEJA_UKUR = 5000.0;
  static const double MIN_TEMP = -50.0;
  static const double MAX_TEMP = 100.0;
  static const double TEMP_WARNING = 80.0;
  static const double TEMP_DIFF_WARNING = 30.0;
  static const double MIN_DENSITY = 0.5;
  static const double MAX_DENSITY = 1.5;
  static const double DENSITY_WARNING_LOW = 0.7;
  static const double DENSITY_WARNING_HIGH = 1.0;

  // Validator methods
  String? validateSounding(String? value) {
    if (value == null || value.isEmpty) {
      return 'Sounding harus diisi';
    }
    
    final sounding = double.tryParse(value);
    if (sounding == null) {
      return 'Format angka tidak valid';
    }
    
    if (sounding <= 0) {
      return 'Sounding harus lebih dari 0';
    }
    
    // Check against tank capacity (assuming capacity is in Liters, convert to mm height)
    // This is a simplified check - adjust based on your tank calculation logic
    final maxHeight = widget.tank.capacity * 1000 / (3.14159 * (widget.tank.diameter / 2) * (widget.tank.diameter / 2));
    if (sounding > maxHeight) {
      return 'Sounding melebihi kapasitas tangki (max: ${maxHeight.toStringAsFixed(0)} mm)';
    }
    
    return null;
  }

  String? validateMejaUkur(String? value) {
    if (value == null || value.isEmpty) {
      return 'Meja ukur harus diisi';
    }
    
    final mejaUkur = double.tryParse(value);
    if (mejaUkur == null) {
      return 'Format angka tidak valid';
    }
    
    if (mejaUkur < 0) {
      return 'Meja ukur tidak boleh negatif';
    }
    
    if (mejaUkur > MAX_MEJA_UKUR) {
      return 'Meja ukur terlalu tinggi (max: $MAX_MEJA_UKUR mm)';
    }
    
    return null;
  }

  String? validateTemperature(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName harus diisi';
    }
    
    final temp = double.tryParse(value);
    if (temp == null) {
      return 'Format angka tidak valid';
    }
    
    if (temp < MIN_TEMP || temp > MAX_TEMP) {
      return 'Temperatur di luar range ($MIN_TEMP°C - $MAX_TEMP°C)';
    }
    
    return null;
  }

  String? validateDensity(String? value) {
    if (value == null || value.isEmpty) {
      return 'Density harus diisi';
    }
    
    final density = double.tryParse(value);
    if (density == null) {
      return 'Format angka tidak valid';
    }
    
    if (density < MIN_DENSITY || density > MAX_DENSITY) {
      return 'Density di luar range ($MIN_DENSITY - $MAX_DENSITY)';
    }
    
    return null;
  }

  // Warning checks
  Future<bool> checkWarnings() async {
    List<String> warnings = [];
    
    // Check temperature warnings
    final tempDalam = double.tryParse(tempDalamController.text);
    final tempLuar = double.tryParse(tempLuarController.text);
    
    if (tempDalam != null && tempDalam > TEMP_WARNING) {
      warnings.add('⚠ Temperatur dalam sangat tinggi (${tempDalam.toStringAsFixed(1)}°C)');
    }
    
    if (tempDalam != null && tempLuar != null) {
      final tempDiff = (tempDalam - tempLuar).abs();
      if (tempDiff > TEMP_DIFF_WARNING) {
        warnings.add('⚠ Selisih temperatur dalam-luar terlalu besar (${tempDiff.toStringAsFixed(1)}°C)');
      }
    }
    
    // Check density warnings
    final density = double.tryParse(densityController.text);
    if (density != null) {
      if (density < DENSITY_WARNING_LOW) {
        warnings.add('⚠ Density sangat rendah (${density.toStringAsFixed(3)})');
      } else if (density > DENSITY_WARNING_HIGH) {
        warnings.add('⚠ Density sangat tinggi (${density.toStringAsFixed(3)})');
      }
    }
    
    // If there are warnings, show dialog
    if (warnings.isNotEmpty) {
      return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text('Peringatan Data'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Data yang Anda masukkan memiliki nilai yang tidak biasa:'),
              SizedBox(height: 12),
              ...warnings.map((w) => Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text(w, style: TextStyle(color: Colors.orange.shade700)),
              )),
              SizedBox(height: 12),
              Text('Apakah Anda yakin ingin melanjutkan?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Periksa Lagi'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: Text('Lanjutkan'),
            ),
          ],
        ),
      ) ?? false;
    }
    
    return true;
  }

  Future<void> calculate() async {
    // First validate form
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mohon perbaiki data yang tidak valid'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check warnings
    final proceed = await checkWarnings();
    if (!proceed) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    try {
      final calibration = await DatabaseService.getCalibration(widget.tank.id!);
      final fraction = await DatabaseService.getFraction(widget.tank.id!);

      // Close loading
      Navigator.pop(context);

      if (calibration.isEmpty || fraction.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tabel kalibrasi atau fraksi belum diisi!'),
            backgroundColor: Colors.orange,
          ),
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
            tank: widget.tank,
            sounding: double.parse(soundingController.text),
            mejaUkur: double.parse(mejaUkurController.text),
            tempDalam: double.parse(tempDalamController.text),
            tempLuar: double.parse(tempLuarController.text),
            densityObserved: double.parse(densityController.text),
          ),
        ),
      );
    } catch (e) {
      // Close loading if still open
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tank.name),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
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
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
                        prefixIcon: Icon(Icons.height),
                        helperText: 'Tinggi cairan dari dasar tangki',
                      ),
                      validator: validateSounding,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: mejaUkurController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Meja Ukur (mm)',
                        border: OutlineInputBorder(),
                        hintText: '40',
                        prefixIcon: Icon(Icons.straighten),
                        helperText: 'Tinggi meja ukur referensi',
                      ),
                      validator: validateMejaUkur,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: tempDalamController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Temperatur Dalam (°C)',
                        border: OutlineInputBorder(),
                        hintText: '31.0',
                        prefixIcon: Icon(Icons.thermostat),
                        helperText: 'Suhu cairan di dalam tangki',
                      ),
                      validator: (v) => validateTemperature(v, 'Temperatur dalam'),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: tempLuarController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Temperatur Luar (°C)',
                        border: OutlineInputBorder(),
                        hintText: '30.0',
                        prefixIcon: Icon(Icons.wb_sunny),
                        helperText: 'Suhu lingkungan luar',
                      ),
                      validator: (v) => validateTemperature(v, 'Temperatur luar'),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: densityController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Density Observed',
                        border: OutlineInputBorder(),
                        hintText: '0.850',
                        prefixIcon: Icon(Icons.opacity),
                        helperText: 'Massa jenis cairan pada suhu observasi',
                      ),
                      validator: validateDensity,
                    ),
                    SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: calculate,
                      icon: Icon(Icons.calculate),
                      label: Text('Hitung Volume'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.all(16),
                        textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
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

  @override
  void dispose() {
    soundingController.dispose();
    mejaUkurController.dispose();
    tempDalamController.dispose();
    tempLuarController.dispose();
    densityController.dispose();
    super.dispose();
  }
}