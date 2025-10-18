import '../models/tank.dart';
import 'vcf_services.dart';

class CalculatorService {
  static Map<String, dynamic> calculateVolume(
    double sounding,
    double mejaUkur,
    List<CalibrationEntry> calibration,
    List<FractionEntry> fraction,
  ) {
    final tinggiCairan = (sounding - mejaUkur).toInt();
    final meter = tinggiCairan ~/ 1000;
    final cm = (tinggiCairan % 1000) ~/ 10;
    final mm = tinggiCairan % 10;

    final calEntry = calibration.firstWhere(
      (c) => c.meter == meter && c.cm == cm,
      orElse: () => CalibrationEntry(meter: 0, cm: 0, volume: 0),
    );
    final volumeCm = calEntry.volume;

    final tinggiCairanMeter = tinggiCairan / 1000.0;
    
    final fracEntry = fraction.firstWhere(
      (f) => f.mm == mm && 
             tinggiCairanMeter >= f.heightFrom && 
             tinggiCairanMeter <= f.heightTo,
      orElse: () => FractionEntry(
        cincin: '',
        heightFrom: 0,
        heightTo: 0,
        mm: 0,
        volume: 0,
      ),
    );
    final volumeMm = fracEntry.volume;

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

  static double applyTempCorrection(double vt, double tempDalam, double tempRef, double koef) {
    final deltaT = tempDalam - tempRef;
    final correctionFactor = 1 + (deltaT * koef);
    return vt * correctionFactor;
  }

  static double calculateVCF(double temp, double density) {
    // Pakai VCF Service yang lebih akurat
    return VCFService.getVCF(temp, density);
  }
}
