import 'package:neurom_bilisim_store/helpers/main_helpers.dart';
import 'package:neurom_bilisim_store/middlewares/route_middleware.dart';
import 'package:neurom_bilisim_store/screens/auth/login.dart';
import 'package:flutter/cupertino.dart';

class AuthMiddleware extends RouteMiddleware {
  final Widget _goto;

  AuthMiddleware(this._goto);

  @override
  Widget next() {
    if (!userIsLogedIn) {
      return Login();
    }
    return _goto;
  }
}
