import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/animations.dart';

class AboutPage extends StatelessWidget {
  final String appVersion = '1.0.0';
  final String buildNumber = '1';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tentang Aplikasi'),
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // App Logo & Name
            AnimatedCard(
              delay: Duration(milliseconds: 100),
              child: Container(
                padding: EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade700, Colors.indigo.shade700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 15,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.water_drop,
                      size: 80,
                      color: Colors.white,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'MyTank',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Aplikasi Perhitungan Volume Tangki',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            // Version Info
            AnimatedCard(
              delay: Duration(milliseconds: 200),
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informasi Versi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      _buildInfoRow('Versi', appVersion),
                      _buildInfoRow('Build Number', buildNumber),
                      _buildInfoRow('Platform', 'Android & iOS'),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: 16),

            // Features
            AnimatedCard(
              delay: Duration(milliseconds: 300),
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fitur Utama',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      _buildFeatureItem(
                        Icons.calculate,
                        'Perhitungan Volume Akurat',
                        'Menggunakan tabel kalibrasi dan VCF ASTM D1250',
                      ),
                      _buildFeatureItem(
                        Icons.history,
                        'History Perhitungan',
                        'Simpan dan lihat riwayat perhitungan',
                      ),
                      _buildFeatureItem(
                        Icons.compare_arrows,
                        'Kalkulator Selisih',
                        'Bandingkan 2 perhitungan untuk monitoring stock',
                      ),
                      _buildFeatureItem(
                        Icons.file_upload,
                        'Export/Import',
                        'Backup dan restore data tangki',
                      ),
                      _buildFeatureItem(
                        Icons.dark_mode,
                        'Dark Mode',
                        'Tampilan gelap untuk kenyamanan mata',
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: 16),

            // Developer Info
            AnimatedCard(
              delay: Duration(milliseconds: 400),
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Developer',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      _buildInfoRow('Nama', 'Danndi B.'),
                      _buildInfoRow('Email', 'dandimho5@gmail.com'),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: 16),

            // License Info
            AnimatedCard(
              delay: Duration(milliseconds: 500),
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lisensi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Copyright © 2025 MyTank App. All rights reserved.',
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Aplikasi ini menggunakan standar ASTM D1250 untuk perhitungan Volume Correction Factor (VCF).',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: 16),

            // Action Buttons
            AnimatedCard(
              delay: Duration(milliseconds: 600),
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      _showInfoDialog(
                        context,
                        'Kebijakan Privasi',
                        'Aplikasi ini tidak mengumpulkan atau membagikan data pribadi Anda. Semua data tersimpan secara lokal di perangkat Anda.',
                      );
                    },
                    icon: Icon(Icons.privacy_tip),
                    label: Text('Kebijakan Privasi'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 48),
                    ),
                  ),
                  SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      _showInfoDialog(
                        context,
                        'Syarat & Ketentuan',
                        'Dengan menggunakan aplikasi ini, Anda setuju untuk menggunakan hasil perhitungan sesuai dengan standar industri yang berlaku. Developer tidak bertanggung jawab atas kesalahan penggunaan data.',
                      );
                    },
                    icon: Icon(Icons.description),
                    label: Text('Syarat & Ketentuan'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size(double.infinity, 48),
                    ),
                  ),
                  SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      _showChangelogDialog(context);
                    },
                    icon: Icon(Icons.update),
                    label: Text('Changelog'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size(double.infinity, 48),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Credits
            Center(
              child: Text(
                '@ 2025 MyTank App. All rights reserved.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 24, color: Colors.blue.shade700),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(content),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showChangelogDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Changelog'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Version 1.0.0',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              _buildChangelogItem('✅ Perhitungan volume dengan VCF ASTM D1250'),
              _buildChangelogItem('✅ History perhitungan'),
              _buildChangelogItem('✅ Kalkulator selisih volume'),
              _buildChangelogItem('✅ Export/Import data'),
              _buildChangelogItem('✅ Dark mode'),
              _buildChangelogItem('✅ Data validation'),
              _buildChangelogItem('✅ Smooth animations'),
              _buildChangelogItem('✅ Dashboard statistik'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _buildChangelogItem(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: TextStyle(fontSize: 13),
      ),
    );
  }
}