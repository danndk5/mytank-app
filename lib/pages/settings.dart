import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import 'about.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _temperatureUnit = '°C';
  String _volumeUnit = 'Liter';
  int _decimalPrecision = 3;
  bool _showNotifications = true;
  bool _autoSaveHistory = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _temperatureUnit = prefs.getString('temperatureUnit') ?? '°C';
      _volumeUnit = prefs.getString('volumeUnit') ?? 'Liter';
      _decimalPrecision = prefs.getInt('decimalPrecision') ?? 3;
      _showNotifications = prefs.getBool('showNotifications') ?? true;
      _autoSaveHistory = prefs.getBool('autoSaveHistory') ?? true;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('temperatureUnit', _temperatureUnit);
    await prefs.setString('volumeUnit', _volumeUnit);
    await prefs.setInt('decimalPrecision', _decimalPrecision);
    await prefs.setBool('showNotifications', _showNotifications);
    await prefs.setBool('autoSaveHistory', _autoSaveHistory);
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Pengaturan'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Appearance Section
          Text(
            'TAMPILAN',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8),
          Card(
            child: SwitchListTile(
              title: Text('Dark Mode'),
              subtitle: Text('Tema gelap untuk kenyamanan mata'),
              value: themeService.isDarkMode,
              onChanged: (value) {
                themeService.toggleTheme();
              },
              secondary: Icon(
                themeService.isDarkMode ? Icons.dark_mode : Icons.light_mode,
              ),
            ),
          ),

          SizedBox(height: 24),

          // Units Section
          Text(
            'SATUAN',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: Text('Satuan Temperatur'),
                  subtitle: Text(_temperatureUnit),
                  leading: Icon(Icons.thermostat),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () async {
                    final result = await showDialog<String>(
                      context: context,
                      builder: (context) => SimpleDialog(
                        title: Text('Pilih Satuan Temperatur'),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        children: [
                          SimpleDialogOption(
                            child: Text('Celsius (°C)'),
                            onPressed: () => Navigator.pop(context, '°C'),
                          ),
                          SimpleDialogOption(
                            child: Text('Fahrenheit (°F)'),
                            onPressed: () => Navigator.pop(context, '°F'),
                          ),
                        ],
                      ),
                    );
                    if (result != null) {
                      setState(() {
                        _temperatureUnit = result;
                      });
                      _saveSettings();
                    }
                  },
                ),
                Divider(height: 1),
                ListTile(
                  title: Text('Satuan Volume'),
                  subtitle: Text(_volumeUnit),
                  leading: Icon(Icons.water_drop),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () async {
                    final result = await showDialog<String>(
                      context: context,
                      builder: (context) => SimpleDialog(
                        title: Text('Pilih Satuan Volume'),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        children: [
                          SimpleDialogOption(
                            child: Text('Liter (L)'),
                            onPressed: () => Navigator.pop(context, 'Liter'),
                          ),
                          SimpleDialogOption(
                            child: Text('Gallon (gal)'),
                            onPressed: () => Navigator.pop(context, 'Gallon'),
                          ),
                          SimpleDialogOption(
                            child: Text('Meter Kubik (m³)'),
                            onPressed: () => Navigator.pop(context, 'm³'),
                          ),
                        ],
                      ),
                    );
                    if (result != null) {
                      setState(() {
                        _volumeUnit = result;
                      });
                      _saveSettings();
                    }
                  },
                ),
                Divider(height: 1),
                ListTile(
                  title: Text('Presisi Desimal'),
                  subtitle: Text('$_decimalPrecision digit'),
                  leading: Icon(Icons.format_list_numbered),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () async {
                    final result = await showDialog<int>(
                      context: context,
                      builder: (context) => SimpleDialog(
                        title: Text('Pilih Presisi Desimal'),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        children: [
                          SimpleDialogOption(
                            child: Text('2 digit (0.00)'),
                            onPressed: () => Navigator.pop(context, 2),
                          ),
                          SimpleDialogOption(
                            child: Text('3 digit (0.000)'),
                            onPressed: () => Navigator.pop(context, 3),
                          ),
                          SimpleDialogOption(
                            child: Text('4 digit (0.0000)'),
                            onPressed: () => Navigator.pop(context, 4),
                          ),
                        ],
                      ),
                    );
                    if (result != null) {
                      setState(() {
                        _decimalPrecision = result;
                      });
                      _saveSettings();
                    }
                  },
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // Data Section
          Text(
            'DATA',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: Text('Auto-Save History'),
                  subtitle: Text('Simpan otomatis setiap perhitungan'),
                  value: _autoSaveHistory,
                  onChanged: (value) {
                    setState(() {
                      _autoSaveHistory = value;
                    });
                    _saveSettings();
                  },
                  secondary: Icon(Icons.save),
                ),
                Divider(height: 1),
                SwitchListTile(
                  title: Text('Notifikasi'),
                  subtitle: Text('Aktifkan reminder & alert'),
                  value: _showNotifications,
                  onChanged: (value) {
                    setState(() {
                      _showNotifications = value;
                    });
                    _saveSettings();
                  },
                  secondary: Icon(Icons.notifications),
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // About Section
          Text(
            'TENTANG',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: Text('Tentang Aplikasi'),
                  leading: Icon(Icons.info),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AboutPage()),
                    );
                  },
                ),
                Divider(height: 1),
                ListTile(
                  title: Text('Versi'),
                  subtitle: Text('1.0.0'),
                  leading: Icon(Icons.apps),
                ),
              ],
            ),
          ),

          SizedBox(height: 30),
        ],
      ),
    );
  }
}