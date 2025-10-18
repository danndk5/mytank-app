import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get Device ID
  static Future<String> getDeviceId() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        return androidInfo.id; // Unique Android ID
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'unknown';
      }
    } catch (e) {
      return 'unknown';
    }
    return 'unknown';
  }

  // Cek apakah sudah aktivasi
  static Future<bool> isActivated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_activated') ?? false;
  }

  // Simpan status aktivasi
  static Future<void> saveActivation(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_activated', true);
    await prefs.setString('activation_key', key);
    await prefs.setString('activation_date', DateTime.now().toString());
  }

  // Validasi key ke Firebase
  static Future<Map<String, dynamic>> validateKey(String key) async {
    try {
      // Format key harus: MYTANK-XXXX-XXXX-XXXX
      if (!key.startsWith('MYTANK-') || key.length != 23) {
        return {'success': false, 'message': 'Format key tidak valid'};
      }

      // Get Device ID
      String deviceId = await getDeviceId();

      // Cek key di Firebase
      DocumentSnapshot keyDoc = await _firestore
          .collection('activation_keys')
          .doc(key)
          .get();

      if (!keyDoc.exists) {
        return {'success': false, 'message': 'Key tidak ditemukan'};
      }

      Map<String, dynamic> keyData = keyDoc.data() as Map<String, dynamic>;

      // Cek apakah key sudah digunakan
      if (keyData['is_used'] == true) {
        String usedDeviceId = keyData['device_id'] ?? '';
        
        // Cek apakah digunakan di device yang sama
        if (usedDeviceId == deviceId) {
          // Device yang sama, boleh (re-activation)
          await saveActivation(key);
          return {'success': true, 'message': 'Aktivasi berhasil!'};
        } else {
          // Device berbeda, tolak
          return {
            'success': false,
            'message': 'Key sudah digunakan di perangkat lain'
          };
        }
      }

      // Key belum digunakan, aktivasi sekarang
      await _firestore.collection('activation_keys').doc(key).update({
        'is_used': true,
        'device_id': deviceId,
        'activated_at': FieldValue.serverTimestamp(),
      });

      // Simpan di lokal
      await saveActivation(key);

      return {'success': true, 'message': 'Aktivasi berhasil!'};
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}'
      };
    }
  }

  // Get activation info (untuk About screen)
  static Future<Map<String, String>> getActivationInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'key': prefs.getString('activation_key') ?? 'N/A',
      'date': prefs.getString('activation_date') ?? 'N/A',
      'device_id': await getDeviceId(),
    };
  }
}