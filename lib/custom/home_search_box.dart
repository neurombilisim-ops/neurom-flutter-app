import 'package:neurom_bilisim_store/app_config.dart';
import 'package:flutter/material.dart';
import 'package:neurom_bilisim_store/l10n/app_localizations.dart';

class HomeSearchBox extends StatelessWidget {
  final BuildContext? context;
  const HomeSearchBox({super.key, this.context});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: Color(0xFF0091e5).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              color: Color(0xFF0091e5),
              size: 22,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.search_here_ucf,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
