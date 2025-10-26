import 'dart:math';
import '../models/tank.dart';
import 'astm_table_service.dart';

class CalculatorService {
  // Hitung volume dari tabel kalibrasi
  static Map<String, dynamic> calculateVolume(
    double sounding,
    double mejaUkur,
    List<CalibrationEntry> calibration,
    List<FractionEntry> fraction,
  ) {
    // PERBAIKAN: Tinggi cairan = Sounding - Meja Ukur
    final tinggiCairan = sounding - mejaUkur;
    
    // Breakdown tinggi
    final meter = (tinggiCairan / 1000).floor();
    final sisaMm = tinggiCairan % 1000;
    final cm = (sisaMm / 10).floor();
    final mm = (sisaMm % 10).floor();

    // Volume dari tabel kalibrasi (per cm)
    double volumeCm = 0;
    final calEntry = calibration.where((e) => e.meter == meter && e.cm == cm).firstOrNull;
    if (calEntry != null) {
      volumeCm = calEntry.volume;
    }

    // Volume dari fraksi (per mm)
    double volumeMm = 0;
    final fracEntry = fraction.where((e) {
      final heightMm = (meter * 1000) + (cm * 10);
      return heightMm >= e.heightFrom * 1000 && heightMm < e.heightTo * 1000 && e.mm == mm;
    }).firstOrNull;
    
    if (fracEntry != null) {
      volumeMm = fracEntry.volume;
    }

    final vt = volumeCm + volumeMm;

    return {
      'tinggiCairan': tinggiCairan,
      'meter': meter,
      'cm': cm,
      'mm': mm,
      'volumeCm': volumeCm,
      'volumeMm': volumeMm,
      'vt': vt,
    };
  }

  // Koreksi temperatur untuk tangki (ekspansi shell)
  static double applyTempCorrection(
    double volume,
    double tempObserved,
    double tempRef,
    double koefEkspansi,
  ) {
    final deltaT = tempObserved - tempRef;
    final correctionFactor = 1 + (koefEkspansi * deltaT);
    return volume * correctionFactor;
  }

  // Main calculation - ASTM D1250 (menggunakan JSON Table)
  static Future<Map<String, double>> calculateASTM({
    required double densityObserved,
    required double tempLuar,
    required double tempDalam,
  }) async {
    try {
      // Load dari ASTM Table JSON dan calculate
      return await ASTMTableService.calculateASTM(
        densityObserved: densityObserved,
        tempLuar: tempLuar,
        tempDalam: tempDalam,
      );
    } catch (e) {
      // Fallback to formula if JSON fails
      print('Warning: ASTM table load failed, using formula: $e');
      return _calculateASTMFormula(
        densityObserved: densityObserved,
        tempLuar: tempLuar,
        tempDalam: tempDalam,
      );
    }
  }

  // Fallback formula-based calculation (jika JSON gagal)
  static Map<String, double> _calculateASTMFormula({
    required double densityObserved,
    required double tempLuar,
    required double tempDalam,
  }) {
    // STEP 1: Get Density @ 15°C using simplified formula
    double alpha53;
    if (densityObserved < 0.788) {
      alpha53 = 0.000700;
    } else if (densityObserved < 0.839) {
      alpha53 = 0.000650;
    } else if (densityObserved < 0.900) {
      alpha53 = 0.000620;
    } else {
      alpha53 = 0.000600;
    }

    double deltaT = tempLuar - 15.0;
    double density15 = densityObserved + (densityObserved * alpha53 * deltaT);

    // STEP 2: Get VCF using simplified formula
    double alpha54;
    if (density15 < 0.650) {
      alpha54 = 0.001211;
    } else if (density15 < 0.700) {
      alpha54 = 0.001164;
    } else if (density15 < 0.750) {
      alpha54 = 0.001118;
    } else if (density15 < 0.788) {
      alpha54 = 0.001073;
    } else if (density15 < 0.820) {
      alpha54 = 0.001028;
    } else if (density15 < 0.850) {
      alpha54 = 0.000983;
    } else if (density15 < 0.880) {
      alpha54 = 0.000783;
    } else if (density15 < 0.900) {
      alpha54 = 0.000738;
    } else if (density15 < 0.950) {
      alpha54 = 0.000693;
    } else {
      alpha54 = 0.000648;
    }

    double deltaT54 = tempDalam - 15.0;
    double vcf = exp(-alpha54 * deltaT54 * (1 + 0.8 * alpha54 * deltaT54));

    return {
      'density15': density15,
      'vcf': vcf,
    };
  }

  // Helper: Detect product type
  static String detectProductType(double density15) {
    if (density15 >= 0.700 && density15 < 0.750) {
      return 'Pertalite';
    } else if (density15 >= 0.800 && density15 < 0.850) {
      return 'Solar';
    } else if (density15 >= 0.900 && density15 <= 1.000) {
      return 'MFO';
    }
    return 'Unknown Product';
  }
}