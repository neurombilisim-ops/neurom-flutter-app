import 'package:flutter/cupertino.dart';
import 'package:neurom_bilisim_store/l10n/app_localizations.dart';

class LangText {
  BuildContext context;
  late AppLocalizations local;

  LangText(this.context) {
    local = AppLocalizations.of(context)!;
  }
}
