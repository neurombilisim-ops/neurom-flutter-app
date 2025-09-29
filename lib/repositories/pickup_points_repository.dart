import 'package:neurom_bilisim_store/app_config.dart';
import 'package:neurom_bilisim_store/data_model/pickup_points_response.dart';
import 'package:neurom_bilisim_store/repositories/api-request.dart';

class PickupPointRepository {
  Future<PickupPointListResponse> getPickupPointListResponse() async {
    String url = ('${AppConfig.BASE_URL}/pickup-list');

    final response = await ApiRequest.get(url: url);

    return pickupPointListResponseFromJson(response.body);
  }
}
