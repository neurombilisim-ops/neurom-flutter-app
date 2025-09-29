import 'package:neurom_bilisim_store/helpers/main_helpers.dart';
import 'package:neurom_bilisim_store/middlewares/group_middleware.dart';
import 'package:neurom_bilisim_store/middlewares/middleware.dart';
import 'package:neurom_bilisim_store/repositories/aiz_api_response.dart';
import 'package:http/http.dart' as http;

class ApiRequest {
  static Future<http.Response> get(
      {required String url,
      Map<String, String>? headers,
      Middleware? middleware,
      GroupMiddleware? groupMiddleWare}) async {
    Uri uri = Uri.parse(url);
    Map<String, String>? headerMap = commonHeader;
    headerMap.addAll(currencyHeader);
    if (headers != null) {
      headerMap.addAll(headers);
    }
    var response = await http.get(uri, headers: headerMap);
    return AIZApiResponse.check(response,
        middleware: middleware, groupMiddleWare: groupMiddleWare);
  }

  static Future<http.Response> post(
      {required String url,
      Map<String, String>? headers,
      required String body,
      Middleware? middleware,
      GroupMiddleware? groupMiddleWare}) async {
    Uri uri = Uri.parse(url);
    Map<String, String>? headerMap = commonHeader;
    headerMap.addAll(currencyHeader);
    if (headers != null) {
      headerMap.addAll(headers);
    }
    var response = await http.post(uri, headers: headerMap, body: body);
    return AIZApiResponse.check(response,
        middleware: middleware, groupMiddleWare: groupMiddleWare);
  }

  static Future<http.Response> put(
      {required String url,
      Map<String, String>? headers,
      required String body,
      Middleware? middleware,
      GroupMiddleware? groupMiddleWare}) async {
    Uri uri = Uri.parse(url);
    Map<String, String>? headerMap = commonHeader;
    headerMap.addAll(currencyHeader);
    if (headers != null) {
      headerMap.addAll(headers);
    }
    var response = await http.put(uri, headers: headerMap, body: body);
    return AIZApiResponse.check(response,
        middleware: middleware, groupMiddleWare: groupMiddleWare);
  }

  static Future<http.Response> delete(
      {required String url,
      Map<String, String>? headers,
      Middleware? middleware,
      GroupMiddleware? groupMiddleWare}) async {
    Uri uri = Uri.parse(url);
    Map<String, String>? headerMap = commonHeader;
    headerMap.addAll(currencyHeader);
    if (headers != null) {
      headerMap.addAll(headers);
    }
    var response = await http.delete(uri, headers: headerMap);
    return AIZApiResponse.check(response,
        middleware: middleware, groupMiddleWare: groupMiddleWare);
  }
}
