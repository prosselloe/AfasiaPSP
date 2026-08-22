import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';

class AssetLoaderService {
  // Singleton pattern
  AssetLoaderService._privateConstructor();
  static final AssetLoaderService _instance = AssetLoaderService._privateConstructor();
  static AssetLoaderService get instance => _instance;

  final String _baseUrl = 'https://raw.githubusercontent.com/prosselloe/AfasiaPSP/main/';

  Future<String> loadString(String assetPath) async {
    final connectivityResult = await (Connectivity().checkConnectivity());
    // CORREGIT: Comprovam si a la llista hi ha ALMENYS UNA connexió que no sigui 'none'
    if (connectivityResult.any((result) => result != ConnectivityResult.none)) {
      try {
        final response = await http.get(Uri.parse(_baseUrl + assetPath));
        if (response.statusCode == 200) {
          return response.body;
        }
      } catch (e) {
        // Fallback to local asset if network request fails
      }
    }
    return await rootBundle.loadString(assetPath);
  }

  Future<Uint8List> loadBytes(String assetPath) async {
    final connectivityResult = await (Connectivity().checkConnectivity());
    // CORREGIT: Comprovam si a la llista hi ha ALMENYS UNA connexió que no sigui 'none'
    if (connectivityResult.any((result) => result != ConnectivityResult.none)) {
      try {
        final response = await http.get(Uri.parse(_baseUrl + assetPath));
        if (response.statusCode == 200) {
          return response.bodyBytes;
        }
      } catch (e) {
        // Fallback to local asset if network request fails
      }
    }
    return (await rootBundle.load(assetPath)).buffer.asUint8List();
  }
}
