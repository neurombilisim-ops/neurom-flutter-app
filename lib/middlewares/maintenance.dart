import 'dart:convert';

import 'package:neurom_bilisim_store/custom/device_info.dart';
import 'package:neurom_bilisim_store/middlewares/middleware.dart';
import 'package:neurom_bilisim_store/my_theme.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:one_context/one_context.dart';

class MaintenanceMiddleware extends Middleware {
  @override
  bool next(http.Response response) {
    try {
      var jsonData = jsonDecode(response.body);
      if (jsonData.runtimeType != List &&
          jsonData['result'] != null &&
          !jsonData['result']) {
        if (jsonData.containsKey("status") &&
            jsonData['status'] == "maintenance") {
          OneContext().addOverlay(
              overlayId: "maintenance",
              builder: (context) => Scaffold(
                    body: Container(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      height: DeviceInfo(context).height!,
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              "assets/maintenance.png",
                            ),
                            SizedBox(
                              height: 14,
                            ),
                            Text(
                              jsonData['message'],
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: MyTheme.font_grey),
                            )
                          ]),
                    ),
                  ));
          return false;
        }
      }
    } on Exception {
      // TODO
    }
    return true;
  }
}
