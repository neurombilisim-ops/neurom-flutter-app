// import 'dart:convert';
// import 'package:neurom_bilisim_store/app_config.dart';
// import 'package:neurom_bilisim_store/helpers/shared_value_helper.dart';
// import 'package:neurom_bilisim_store/riaj/single_banner/model.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;

// class PhotoProvider with ChangeNotifier {
//   List<SingleBanner> _singleBanner = [];

//   List<SingleBanner> get singleBanner => _singleBanner;

//   Future<void> fetchPhotos() async {
//     const url =
//         "${AppConfig.BASE_URL}/banners-two"; // Replace with your actual API
//     final response = await http.get(Uri.parse(url), headers: {
//       "App-Language": app_language.$!,
//       "Authorization": "Bearer ${access_token.$}",
//       "Content-Type": "application/json",
//       "System-key": "${AppConfig.system_key}"
//     });

//     if (response.statusCode == 200) {
//       final responseData = json.decode(response.body);
//       if (responseData['success']) {
//         _singleBanner = (responseData['data'] as List)
//             .map((data) => SingleBanner.fromJson(data))
//             .toList();
//         notifyListeners();
//       }
//     }
//   }
// }

import 'dart:async';
import 'dart:convert';
import 'package:neurom_bilisim_store/app_config.dart';
import 'package:neurom_bilisim_store/helpers/shared_value_helper.dart';

import 'package:neurom_bilisim_store/single_banner/model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PhotoProvider with ChangeNotifier {
  List<SingleBanner> _singleBanner = [];

  List<SingleBanner> get singleBanner => _singleBanner;

  // Future<void> fetchPhotos() async {
  //   const url =
  //       "${AppConfig.BASE_URL}/banners-two"; // Replace with your actual API

  //   try {
  //     final response = await http.get(Uri.parse(url), headers: {
  //       "App-Language": app_language.$ ?? 'en', // Use a default if null
  //       "Authorization":
  //           access_token.$ != null ? "Bearer ${access_token.$}" : '',
  //       "Content-Type": "application/json",
  //       "System-key": AppConfig.system_key
  //     }).timeout(Duration(seconds: 10));

  //     if (response.statusCode == 200) {
  //       final responseData = json.decode(response.body);

  //       if (responseData['success']) {
  //         _singleBanner = (responseData['data'] as List)
  //             .map((data) => SingleBanner.fromJson(data))
  //             .toList();
  //       } else {
  //         _singleBanner = [];
  //       }

  //       notifyListeners();
  //     } else {
  //       throw Exception(
  //           "Failed to load photos. Status code: ${response.statusCode}");
  //     }
  //   } catch (error) {
  //     print("Error fetching photos: $error");
  //     _singleBanner = [];
  //     notifyListeners();
  //   }
  // }

  Future<void> fetchPhotos() async {
    const url = "${AppConfig.BASE_URL}/banners-two";

    try {
      final response = await http.get(Uri.parse(url), headers: {
        "App-Language": app_language.$ ?? 'en',
        "Authorization":
            access_token.$ != null ? "Bearer ${access_token.$}" : '',
        "Content-Type": "application/json",
        "System-key": AppConfig.system_key
      }).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success']) {
          _singleBanner = (responseData['data'] as List)
              .map((data) => SingleBanner.fromJson(data))
              .toList();
        } else {
          _singleBanner = [];
        }

        notifyListeners();
      } else {
        throw Exception(
            "Failed to load photos. Status code: ${response.statusCode}");
      }
    } on TimeoutException catch (_) {
      print("Request timed out");
      _singleBanner = [];
      notifyListeners();
    } catch (error) {
      print("Error fetching photos: $error");
      _singleBanner = [];
      notifyListeners();
    }
  }
}
