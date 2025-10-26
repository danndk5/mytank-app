import 'dart:convert';
import 'package:flutter/services.dart';

class ASTMTableService {
  static Map<String, dynamic>? _cachedData;

  // Load JSON from assets
  static Future<Map<String, dynamic>> loadTables() async {
    if (_cachedData != null) return _cachedData!;

    try {
      final jsonString = await rootBundle.loadString('assets/icon/astm_table.json');
      _cachedData = json.decode(jsonString);
      return _cachedData!;
    } catch (e) {
      throw Exception('Failed to load ASTM tables: $e');
    }
  }

  // Get Density @ 15°C from Table 53
  // Input: Density Observed, Temperature Observed
  // Output: Density @ 15°C
  static Future<double> getDensity15(double densityObs, double tempObs) async {
    final tables = await loadTables();
    final table53 = tables['table53']['data'] as Map<String, dynamic>;

    // Find nearest temperature
    String tempKey = _findNearestTemp(table53, tempObs);
    
    if (!table53.containsKey(tempKey)) {
      throw Exception('Temperature $tempObs not found in Table 53');
    }

    final densityMap = table53[tempKey] as Map<String, dynamic>;
    
    // Round density to nearest 0.001 for lookup
    String densityKey = densityObs.toStringAsFixed(3);
    
    // If exact match exists
    if (densityMap.containsKey(densityKey)) {
      return (densityMap[densityKey] as num).toDouble();
    }

    // Interpolate between two nearest density values
    return _interpolateDensity(densityMap, densityObs);
  }

  // Get VCF from Table 54
  // Input: Density @ 15°C, Temperature Observed
  // Output: VCF (Volume Correction Factor)
  static Future<double> getVCF(double density15, double tempObs) async {
    final tables = await loadTables();
    final table54 = tables['table54']['data'] as Map<String, dynamic>;

    // Find nearest temperature
    String tempKey = _findNearestTemp(table54, tempObs);
    
    if (!table54.containsKey(tempKey)) {
      throw Exception('Temperature $tempObs not found in Table 54');
    }

    final vcfMap = table54[tempKey] as Map<String, dynamic>;
    
    // Round density to nearest 0.001 for lookup
    String densityKey = density15.toStringAsFixed(3);
    
    // If exact match exists
    if (vcfMap.containsKey(densityKey)) {
      return (vcfMap[densityKey] as num).toDouble();
    }

    // Interpolate between two nearest density values (ABB Method)
    return _interpolateVCF(vcfMap, density15);
  }

  // Find nearest temperature key in table
  static String _findNearestTemp(Map<String, dynamic> table, double temp) {
    final temps = table.keys.map((k) => double.parse(k)).toList()..sort();
    
    // Find exact match or nearest
    for (var t in temps) {
      if ((t - temp).abs() < 0.1) {
        return t.toStringAsFixed(1);
      }
    }
    
    // If not found, find closest
    double nearest = temps.reduce((a, b) => 
      (a - temp).abs() < (b - temp).abs() ? a : b
    );
    
    return nearest.toStringAsFixed(1);
  }

  // Interpolate density using ABB method
  static double _interpolateDensity(Map<String, dynamic> densityMap, double densityObs) {
    // Get all density keys and sort
    final densities = densityMap.keys
        .map((k) => double.parse(k))
        .toList()..sort();

    // Find two nearest densities
    double lower = densities.first;
    double upper = densities.last;

    for (int i = 0; i < densities.length - 1; i++) {
      if (densityObs >= densities[i] && densityObs <= densities[i + 1]) {
        lower = densities[i];
        upper = densities[i + 1];
        break;
      }
    }

    // Get values
    double valueLower = (densityMap[lower.toStringAsFixed(3)] as num).toDouble();
    double valueUpper = (densityMap[upper.toStringAsFixed(3)] as num).toDouble();

    // ABB Interpolation Method
    // Step = 0.005 (constant from ASTM table)
    const double step = 0.005;
    
    double selisih = densityObs - lower;
    double rasio = selisih / step;
    double deltaValue = valueUpper - valueLower;
    double result = valueLower + (rasio * deltaValue);

    return result;
  }

  // Interpolate VCF using ABB method
  static double _interpolateVCF(Map<String, dynamic> vcfMap, double density15) {
    // Get all density keys and sort
    final densities = vcfMap.keys
        .map((k) => double.parse(k))
        .toList()..sort();

    // Find two nearest densities
    double lower = densities.first;
    double upper = densities.last;

    for (int i = 0; i < densities.length - 1; i++) {
      if (density15 >= densities[i] && density15 <= densities[i + 1]) {
        lower = densities[i];
        upper = densities[i + 1];
        break;
      }
    }

    // Get VCF values
    double vcfLower = (vcfMap[lower.toStringAsFixed(3)] as num).toDouble();
    double vcfUpper = (vcfMap[upper.toStringAsFixed(3)] as num).toDouble();

    // ABB Interpolation Method
    // Selisih = Density15 - DensityTableLower
    double selisih = density15 - lower;
    
    // Rasio = Selisih ÷ 0.005
    const double step = 0.005;
    double rasio = selisih / step;
    
    // Step_VCF = VCF_upper - VCF_lower
    double stepVCF = vcfUpper - vcfLower;
    
    // Delta_VCF = Rasio × Step_VCF
    double deltaVCF = rasio * stepVCF;
    
    // VCF_hasil = VCF_lower + Delta_VCF
    double vcf = vcfLower + deltaVCF;
    
    return vcf;
  }

  // Main calculation - 2 Step Process
  static Future<Map<String, double>> calculateASTM({
    required double densityObserved,
    required double tempLuar,
    required double tempDalam,
  }) async {
    // STEP 1: Get Density @ 15°C using Table 53
    double density15 = await getDensity15(densityObserved, tempLuar);
    
    // STEP 2: Get VCF using Table 54
    double vcf = await getVCF(density15, tempDalam);
    
    return {
      'density15': density15,
      'vcf': vcf,
    };
  }

  // Test function
  static Future<void> testCalculation() async {
    print('=== TEST ASTM TABLE SERVICE ===');
    
    try {
      // Test 1: Density 0.850 @ 30°C
      final result1 = await calculateASTM(
        densityObserved: 0.850,
        tempLuar: 30.0,
        tempDalam: 31.0,
      );
      
      print('Test 1: D_obs=0.850, TempLuar=30°C, TempDalam=31°C');
      print('  D15 = ${result1['density15']} (expected: 0.8598)');
      print('  VCF = ${result1['vcf']} (expected: 0.9872)');
      
      // Test 2: Interpolation test
      final result2 = await calculateASTM(
        densityObserved: 0.845,
        tempLuar: 30.0,
        tempDalam: 31.0,
      );
      
      print('\nTest 2: D_obs=0.845, TempLuar=30°C, TempDalam=31°C');
      print('  D15 = ${result2['density15']} (expected: ~0.8548)');
      
      final d15 = 0.8549;
      final vcf2 = await getVCF(d15, 31.0);
      print('  VCF at D15=0.8549 = $vcf2 (expected: 0.987298)');
      
      print('\n✅ All tests completed!');
    } catch (e) {
      print('❌ Error: $e');
    }
  }
}