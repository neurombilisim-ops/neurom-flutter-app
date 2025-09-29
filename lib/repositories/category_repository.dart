import 'package:neurom_bilisim_store/app_config.dart';
import 'package:neurom_bilisim_store/data_model/category_response.dart';
import 'package:neurom_bilisim_store/helpers/shared_value_helper.dart';
import 'package:neurom_bilisim_store/repositories/api-request.dart';

class CategoryRepository {
  Future<CategoryResponse> getCategories({parent_id = 0}) async {
    String url = ("${AppConfig.BASE_URL}/categories?parent_id=$parent_id");
    final response = await ApiRequest.get(url: url, headers: {
      "App-Language": app_language.$!,
    });
    return categoryResponseFromJson(response.body);
  }

  Future<CategoryResponse> getFeturedCategories({int limit = 100}) async {
    String url = ("${AppConfig.BASE_URL}/categories/featured?limit=$limit");
    final response = await ApiRequest.get(url: url, headers: {
      "App-Language": app_language.$!,
    });

    return categoryResponseFromJson(response.body);
  }

  Future<CategoryResponse> getCategoryInfo(slug) async {
    String url = ("${AppConfig.BASE_URL}/category/info/$slug");
    final response = await ApiRequest.get(url: url, headers: {
      "App-Language": app_language.$!,
    });
    return categoryResponseFromJson(response.body);
  }

  Future<CategoryResponse> getTopCategories({int limit = 50}) async {
    String url = ("${AppConfig.BASE_URL}/categories/top?limit=$limit");
    final response = await ApiRequest.get(url: url, headers: {
      "App-Language": app_language.$!,
    });
    return categoryResponseFromJson(response.body);
  }

  Future<CategoryResponse> getFilterPageCategories() async {
    String url = ("${AppConfig.BASE_URL}/filter/categories");
    final response = await ApiRequest.get(url: url, headers: {
      "App-Language": app_language.$!,
    });
    return categoryResponseFromJson(response.body);
  }
}
