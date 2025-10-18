class VCFService {
  // Database VCF sederhana (nanti bisa diperluas dengan tabel lengkap)
  // Format: temperature (°C) -> density -> VCF
  
  static double getVCF(double temperature, double density) {
    // Simplified ASTM D1250 calculation
    // Dalam implementasi lengkap, ini akan menggunakan tabel lookup
    
    // Formula approksimasi (lebih akurat dari yang sekarang)
    double tempDiff = temperature - 15.0;
    double densityFactor = (density - 0.8500);
    
    // CTL (Correction for Temperature on Liquid)
    double alpha = 0.0007; // Koefisien ekspansi termal rata-rata
    double ctl = 1.0 - (alpha * tempDiff * (1.0 + 0.8 * alpha * tempDiff));
    
    // CPL (Correction for Pressure on Liquid) - biasanya diabaikan untuk tekanan atmosfer
    double cpl = 1.0;
    
    // CTL * CPL = VCF
    double vcf = ctl * cpl;
    
    // Adjustmen berdasarkan density
    vcf = vcf + (densityFactor * 0.00025);
    
    return vcf;
  }
  
  static double getDensity15(double densityObs, double vcf) {
    return densityObs / vcf;
  }
  
  // Untuk implementasi lengkap dengan tabel ASTM
  static Future<double> getVCFFromTable(double temperature, double density) async {
    // TODO: Load dari file JSON/database tabel ASTM lengkap
    // Untuk sekarang pakai formula di atas
    return getVCF(temperature, density);
  }
}