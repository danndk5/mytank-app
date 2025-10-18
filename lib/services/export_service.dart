import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'db.dart';
import '../models/tank.dart';

class ExportService {
  
  // Export semua data ke JSON
  static Future<String?> exportData() async {
    try {
      // Get semua data
      final tanks = await DatabaseService.getTanks();
      
      List<Map<String, dynamic>> exportData = [];
      
      for (var tank in tanks) {
        final calibration = await DatabaseService.getCalibration(tank.id!);
        final fraction = await DatabaseService.getFraction(tank.id!);
        
        exportData.add({
          'tank': tank.toJson(),
          'calibration': calibration.map((c) => c.toJson()).toList(),
          'fraction': fraction.map((f) => f.toJson()).toList(),
        });
      }
      
      // Convert ke JSON string
      String jsonString = JsonEncoder.withIndent('  ').convert(exportData);
      
      // Save ke file
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/mytank_backup.json');
      await file.writeAsString(jsonString);
      
      return file.path;
    } catch (e) {
      print('Error export: $e');
      return null;
    }
  }
  
  // Import data dari JSON
  static Future<bool> importData() async {
    try {
      // Pick file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      
      if (result == null) return false;
      
      // Read file
      File file = File(result.files.single.path!);
      String jsonString = await file.readAsString();
      
      // Parse JSON
      List<dynamic> importData = json.decode(jsonString);
      
      // Import data
      for (var item in importData) {
        // Import tank
        Tank tank = Tank.fromJson(item['tank']);
        await DatabaseService.saveTank(tank);
        
        // Import calibration
        List<CalibrationEntry> calibration = (item['calibration'] as List)
            .map((c) => CalibrationEntry.fromJson(c))
            .toList();
        await DatabaseService.saveCalibration(tank.id!, calibration);
        
        // Import fraction
        List<FractionEntry> fraction = (item['fraction'] as List)
            .map((f) => FractionEntry.fromJson(f))
            .toList();
        await DatabaseService.saveFraction(tank.id!, fraction);
      }
      
      return true;
    } catch (e) {
      print('Error import: $e');
      return false;
    }
  }
}