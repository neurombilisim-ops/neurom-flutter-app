// import 'package:neurom_bilisim_store/app_config.dart';
// import 'package:neurom_bilisim_store/data_model/business_setting_response.dart';
// import 'package:neurom_bilisim_store/repositories/api-request.dart';

// class BusinessSettingRepository {
//   Future<BusinessSettingListResponse> getBusinessSettingList() async {
//     String url = ("${AppConfig.BASE_URL}/business-settings");

//     var businessSettings = [
//       "facebook_login",
//       "google_login",
//       "twitter_login",
//       "pickup_point",
//       "wallet_system",
//       "email_verification",
//       "conversation_system",
//       "shipping_type",
//       "classified_product",
//       "google_recaptcha",
//       "vendor_system_activation",
//       "guest_checkout_activation",
//       "last_viewed_product_activation",
//       "notification_show_type"
//     ];
//     String params = businessSettings.join(',');
//     var body = {"keys": params};
//     var response = await ApiRequest.get(
//       url: url,
//     );
//     print('has_state?________________${response.body}');
//     return businessSettingListResponseFromJson(response.body);
//   }
// }

import 'package:neurom_bilisim_store/app_config.dart';
import 'package:neurom_bilisim_store/data_model/business_setting_response.dart';
import 'package:neurom_bilisim_store/repositories/api-request.dart';

class BusinessSettingRepository {
  Future<BusinessSettingListResponse> getBusinessSettingList() async {
    String url = ("${AppConfig.BASE_URL}/business-settings");

    // Add "has_state" to this list
    var businessSettings = [
      "facebook_login",
      "google_login",
      "twitter_login",
      "pickup_point",
      "wallet_system",
      "email_verification",
      "conversation_system",
      "shipping_type",
      "classified_product",
      "google_recaptcha",
      "vendor_system_activation",
      "guest_checkout_activation",
      "last_viewed_product_activation",
      "notification_show_type",
      "has_state",
      "terms_conditions_url",
      "privacy_policy_url",
      "membership_disclosure_url"
    ];
    String params = businessSettings.join(',');
    var body = {"keys": params};
    // Assuming your API helper handles the body correctly for GET or POST
    var response = await ApiRequest.get(
      url: url,
    );
    
    print('Business Settings API Response: ${response.body}');
    
    return businessSettingListResponseFromJson(response.body);
  }
}
