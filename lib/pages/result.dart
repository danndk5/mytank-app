import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'dart:math' as math;
import '../models/tank.dart';
import '../models/calculation_history.dart';
import '../services/db.dart';
import '../utils/animations.dart';
import '../widgets/custom_widgets.dart';

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

class _ResultPageState extends State<ResultPage> with SingleTickerProviderStateMixin {
  bool isSaved = false;
  int? savedHistoryId;
  late AnimationController _animController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );
    
    // Animate percentage dari 0 ke nilai aktual
    final fillPercentage = _calculateFillPercentage();
    _progressAnimation = Tween<double>(begin: 0, end: fillPercentage).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
    
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  double _calculateFillPercentage() {
    // Hitung persentase isi tangki
    final vObs = widget.result['vObs'];
    final capacity = widget.tank.capacity;
    return (vObs / capacity * 100).clamp(0.0, 100.0);
  }

  Color _getColorByPercentage(double percentage) {
    if (percentage > 70) return Colors.green;
    if (percentage > 30) return Colors.orange;
    return Colors.red;
  }

  String _getStatusText(double percentage) {
    if (percentage > 90) return 'Hampir Penuh';
    if (percentage > 70) return 'Cukup Terisi';
    if (percentage > 30) return 'Setengah Terisi';
    if (percentage > 10) return 'Perlu Isi Ulang';
    return 'Hampir Kosong';
  }

  Widget _buildCircularGauge() {
    final fillPercentage = _calculateFillPercentage();
    final color = _getColorByPercentage(fillPercentage);
    
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return Container(
          width: 200,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background circle
              SizedBox(
                width: 180,
                height: 180,
                child: CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 16,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.grey.shade200,
                  ),
                ),
              ),
              // Progress circle
              SizedBox(
                width: 180,
                height: 180,
                child: CircularProgressIndicator(
                  value: _progressAnimation.value / 100,
                  strokeWidth: 16,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeCap: StrokeCap.round,
                ),
              ),
              // Center content
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_progressAnimation.value.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  SizedBox(height: 4),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(fillPercentage),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: AnimatedCard(
        delay: Duration(milliseconds: 200),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              color: color ?? Colors.grey.shade900,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareResults() async {
    final fillPercentage = _calculateFillPercentage();
    final text = '''
📊 HASIL PERHITUNGAN TANGKI
━━━━━━━━━━━━━━━━━━━━━━━━
🏢 Tangki: ${widget.tank.name}
🏭 Pemilik: ${widget.tank.owner}

📍 TINGGI CAIRAN
${widget.result['tinggiCairan']} mm (${widget.result['meter']}m ${widget.result['cm']}cm ${widget.result['mm']}mm)

💧 VOLUME
• V.OBS: ${widget.result['vObs'].toStringAsFixed(3)} L
• V.15: ${widget.result['v15'].toStringAsFixed(3)} L
• Fill: ${fillPercentage.toStringAsFixed(1)}%

🌡 TEMPERATUR
• Dalam: ${widget.tempDalam}°C
• Luar: ${widget.tempLuar}°C

📈 DATA TEKNIS
• VCF: ${widget.result['vcf'].toStringAsFixed(6)}
• D.15: ${widget.result['d15'].toStringAsFixed(4)}
• Density Obs: ${widget.densityObserved.toStringAsFixed(4)}

━━━━━━━━━━━━━━━━━━━━━━━━
Generated by MyTank App
    ''';

    // Show share options
    await showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Bagikan Hasil',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.copy, color: Colors.blue),
              title: Text('Salin ke Clipboard'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: text));
                Navigator.pop(context);
                CustomSnackBar.show(
                  context,
                  message: 'Berhasil disalin ke clipboard!',
                  type: SnackBarType.success,
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.share, color: Colors.green),
              title: Text('Bagikan via WhatsApp'),
              onTap: () {
                // Implement share to WhatsApp
                Navigator.pop(context);
                CustomSnackBar.show(
                  context,
                  message: 'Fitur berbagi ke WhatsApp segera hadir!',
                  type: SnackBarType.info,
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.email, color: Colors.orange),
              title: Text('Kirim via Email'),
              onTap: () {
                // Implement email sharing
                Navigator.pop(context);
                CustomSnackBar.show(
                  context,
                  message: 'Fitur email segera hadir!',
                  type: SnackBarType.info,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportToPDF() async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CustomLoading(message: 'Membuat PDF...'),
    );

    // Simulate PDF generation
    await Future.delayed(Duration(seconds: 2));
    
    Navigator.pop(context); // Close loading
    
    CustomSnackBar.show(
      context,
      message: 'Fitur export PDF segera hadir!',
      type: SnackBarType.info,
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

      // Haptic feedback
      HapticFeedback.mediumImpact();

      CustomSnackBar.show(
        context,
        message: 'Perhitungan berhasil disimpan ke history',
        type: SnackBarType.success,
      );
    } catch (e) {
      CustomSnackBar.show(
        context,
        message: 'Gagal menyimpan: ${e.toString()}',
        type: SnackBarType.error,
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
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          maxLines: 3,
          autofocus: true,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Simpan'),
          ),
        ],
      ),
    );

    if (notes != null && notes.isNotEmpty) {
      await DatabaseService.updateHistoryNotes(savedHistoryId!, notes);
      CustomSnackBar.show(
        context,
        message: 'Catatan berhasil ditambahkan',
        type: SnackBarType.success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fillPercentage = _calculateFillPercentage();
    final statusColor = _getColorByPercentage(fillPercentage);

    return Scaffold(
      appBar: AppBar(
        title: Text('Hasil Perhitungan'),
        backgroundColor: statusColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: _shareResults,
            tooltip: 'Bagikan',
          ),
          IconButton(
            icon: Icon(Icons.picture_as_pdf),
            onPressed: _exportToPDF,
            tooltip: 'Export PDF',
          ),
        ],
      ),
      body: GradientBackground(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // Success Animation
              AnimatedCard(
                delay: Duration(milliseconds: 100),
                child: Lottie.asset(
                  'assets/icon/animations/success.json',
                  width: 120,
                  height: 120,
                  repeat: false,
                ),
              ),
              
              SizedBox(height: 8),
              
              Text(
                'Perhitungan Berhasil!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
              
              SizedBox(height: 24),

              // Saved Banner
              if (isSaved)
                AnimatedCard(
                  delay: Duration(milliseconds: 150),
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Tersimpan di history',
                            style: TextStyle(
                              color: Colors.green.shade900,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: addNotes,
                          icon: Icon(Icons.note_add, size: 16),
                          label: Text('Catatan'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              if (isSaved) SizedBox(height: 16),

              // Circular Gauge
              AnimatedCard(
                delay: Duration(milliseconds: 200),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.white, statusColor.withOpacity(0.05)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Text(
                          widget.tank.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          widget.tank.owner,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: 20),
                        _buildCircularGauge(),
                        SizedBox(height: 16),
                        Text(
                          '${widget.result['vObs'].toStringAsFixed(0)} / ${widget.tank.capacity.toStringAsFixed(0)} Liter',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: 16),

              // Info Cards Row
              Row(
                children: [
                  _buildInfoCard(
                    icon: Icons.height,
                    label: 'Tinggi Cairan',
                    value: '${widget.result['tinggiCairan']} mm',
                    color: Colors.blue,
                  ),
                  SizedBox(width: 12),
                  _buildInfoCard(
                    icon: Icons.thermostat,
                    label: 'Temperatur',
                    value: '${widget.tempDalam}°C',
                    color: Colors.orange,
                  ),
                ],
              ),

              SizedBox(height: 12),

              Row(
                children: [
                  _buildInfoCard(
                    icon: Icons.opacity,
                    label: 'Density @15°C',
                    value: widget.result['d15'].toStringAsFixed(4),
                    color: Colors.purple,
                  ),
                  SizedBox(width: 12),
                  _buildInfoCard(
                    icon: Icons.science,
                    label: 'VCF',
                    value: widget.result['vcf'].toStringAsFixed(4),
                    color: Colors.teal,
                  ),
                ],
              ),

              SizedBox(height: 16),

              // Volume Details Card
              AnimatedCard(
                delay: Duration(milliseconds: 300),
                child: Card(
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
                              'Detail Volume',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        _buildDataRow(
                          'Volume ${widget.result['cm']}cm',
                          '${widget.result['volumeCm'].toStringAsFixed(3)} L',
                        ),
                        _buildDataRow(
                          'Volume ${widget.result['mm']}mm',
                          '${widget.result['volumeMm'].toStringAsFixed(3)} L',
                        ),
                        Divider(height: 24),
                        _buildDataRow(
                          'VT (Total Volume)',
                          '${widget.result['vt'].toStringAsFixed(3)} L',
                          bold: true,
                        ),
                        _buildDataRow(
                          'V.OBS (Observed Volume)',
                          '${widget.result['vObs'].toStringAsFixed(3)} L',
                          bold: true,
                          color: Colors.blue.shade700,
                        ),
                        _buildDataRow(
                          'V.15 (Volume @ 15°C)',
                          '${widget.result['v15'].toStringAsFixed(3)} L',
                          bold: true,
                          color: Colors.green.shade700,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: 16),

              // Measurement Data Card
              AnimatedCard(
                delay: Duration(milliseconds: 350),
                child: Card(
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
                            Icon(Icons.straighten, color: Colors.orange.shade700),
                            SizedBox(width: 8),
                            Text(
                              'Data Pengukuran',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        _buildDataRow('Sounding', '${widget.sounding} mm'),
                        _buildDataRow('Meja Ukur', '${widget.mejaUkur} mm'),
                        _buildDataRow('Temp. Dalam', '${widget.tempDalam}°C'),
                        _buildDataRow('Temp. Luar', '${widget.tempLuar}°C'),
                        _buildDataRow('Density Observed', widget.densityObserved.toStringAsFixed(4)),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: 24),

              // Action Buttons
              if (!isSaved)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: saveToHistory,
                    icon: Icon(Icons.save, size: 20),
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
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                  ),
                ),

              if (!isSaved) SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.arrow_back),
                  label: Text('Kembali'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.all(16),
                    side: BorderSide(color: statusColor, width: 2),
                    foregroundColor: statusColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}