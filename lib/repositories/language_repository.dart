import 'package:neurom_bilisim_store/app_config.dart';
import 'package:neurom_bilisim_store/repositories/api-request.dart';
import 'package:neurom_bilisim_store/data_model/language_list_response.dart';
import 'package:neurom_bilisim_store/helpers/shared_value_helper.dart';

class LanguageRepository {
  Future<LanguageListResponse> getLanguageList() async {
    String url = ("${AppConfig.BASE_URL}/languages");
    final response = await ApiRequest.get(url: url, headers: {
      "App-Language": app_language.$!,
    });

    return languageListResponseFromJson(response.body);
  }
}
