import 'package:neurom_bilisim_store/helpers/system_config.dart';
import 'package:neurom_bilisim_store/repositories/auth_repository.dart';

import '../data_model/login_response.dart';
import 'shared_value_helper.dart';

class AuthHelper {
  setUserData(LoginResponse loginResponse) {
    if (loginResponse.result == true) {
      SystemConfig.systemUser = loginResponse.user;
      
      // E-posta doğrulama kontrolü - sadece doğrulanmış kullanıcılar giriş yapabilir
      if (loginResponse.user?.emailVerified == true) {
        is_logged_in.$ = true;
        is_logged_in.save();
        access_token.$ = loginResponse.access_token;
        access_token.save();
        user_id.$ = loginResponse.user?.id;
        user_id.save();
        user_name.$ = loginResponse.user?.name;
        user_name.save();
        user_email.$ = loginResponse.user?.email ?? "";
        user_email.save();
        user_phone.$ = loginResponse.user?.phone ?? "";
        user_phone.save();
        avatar_original.$ = loginResponse.user?.avatar_original;
        avatar_original.save();
      } else {
        // E-posta doğrulanmamışsa sadece geçici verileri kaydet
        print("E-posta doğrulanmamış, kullanıcı giriş yapamaz");
        // Geçici token'ı kaydet (OTP için gerekli)
        access_token.$ = loginResponse.access_token;
        access_token.save();
        user_id.$ = loginResponse.user?.id;
        user_id.save();
        user_name.$ = loginResponse.user?.name;
        user_name.save();
        user_email.$ = loginResponse.user?.email ?? "";
        user_email.save();
        user_phone.$ = loginResponse.user?.phone ?? "";
        user_phone.save();
        avatar_original.$ = loginResponse.user?.avatar_original;
        avatar_original.save();
      }
    }
  }

  clearUserData() {
    SystemConfig.systemUser = null;
    is_logged_in.$ = false;
    is_logged_in.save();
    access_token.$ = "";
    access_token.save();
    user_id.$ = 0;
    user_id.save();
    user_name.$ = "";
    user_name.save();
    user_email.$ = "";
    user_email.save();
    user_phone.$ = "";
    user_phone.save();
    avatar_original.$ = "";
    avatar_original.save();

    temp_user_id.$ = "";
    temp_user_id.save();
  }

  fetch_and_set() async {
    var userByTokenResponse = await AuthRepository().getUserByTokenResponse();
    if (userByTokenResponse.result == true) {
      // E-posta doğrulama kontrolü yap
      if (userByTokenResponse.user?.emailVerified == true) {
        setUserData(userByTokenResponse);
      } else {
        // E-posta doğrulanmamışsa kullanıcıyı çıkış yaptır
        print("E-posta doğrulanmamış kullanıcı tespit edildi, çıkış yapılıyor");
        clearUserData();
      }
    } else {
      clearUserData();
    }
  }
}
