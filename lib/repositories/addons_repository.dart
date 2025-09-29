import 'package:neurom_bilisim_store/app_config.dart';
import 'package:neurom_bilisim_store/data_model/addons_response.dart';
import 'package:neurom_bilisim_store/repositories/api-request.dart';

class AddonsRepository {
  Future<List<AddonsListResponse>> getAddonsListResponse() async {
    // $();
    String url = ('${AppConfig.BASE_URL}/addon-list');
    final response = await ApiRequest.get(url: url);

    return addonsListResponseFromJson(response.body);
  }
}
//has_state =0
