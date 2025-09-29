import 'package:neurom_bilisim_store/app_config.dart';
import 'package:neurom_bilisim_store/data_model/search_suggestion_response.dart';
import 'package:neurom_bilisim_store/helpers/shared_value_helper.dart';
import 'package:neurom_bilisim_store/repositories/api-request.dart';

class SearchRepository {
  Future<List<SearchSuggestionResponse>> getSearchSuggestionListResponse(
      {query_key = "", type = "product"}) async {
    String url =
        ("${AppConfig.BASE_URL}/get-search-suggestions?query_key=$query_key&type=$type");
    final response = await ApiRequest.get(
      url: url,
      headers: {
        "App-Language": app_language.$!,
      },
    );
    return searchSuggestionResponseFromJson(response.body);
  }
}
