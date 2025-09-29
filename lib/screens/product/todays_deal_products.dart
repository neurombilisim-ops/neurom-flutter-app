import 'package:neurom_bilisim_store/data_model/product_mini_response.dart';
import 'package:neurom_bilisim_store/helpers/shared_value_helper.dart';
import 'package:neurom_bilisim_store/helpers/shimmer_helper.dart';
import 'package:neurom_bilisim_store/my_theme.dart';
import 'package:neurom_bilisim_store/repositories/product_repository.dart';
import 'package:neurom_bilisim_store/ui_elements/product_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:neurom_bilisim_store/l10n/app_localizations.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class TodaysDealProducts extends StatefulWidget {
  const TodaysDealProducts({super.key});

  @override
  _TodaysDealProductsState createState() => _TodaysDealProductsState();
}

class _TodaysDealProductsState extends State<TodaysDealProducts> {
  ScrollController? _scrollController;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
          app_language_rtl.$! ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xffF8F9FA),
        appBar: buildAppBar(context),
        body: buildProductList(context),
      ),
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent, // Şeffaf arka plan
      scrolledUnderElevation: 0.0,
      elevation: 8.0, // Gölge efekti
      shadowColor: const Color(0xff0091e5).withOpacity(0.4), // Mavi gölge
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xff0091e5), // Mavi
              Color(0xff00a8ff), // Açık mavi
              Color(0xff74b9ff), // Daha açık mavi
            ],
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(25),
            bottomRight: Radius.circular(25),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff0091e5).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
      ),
      leading: Container(),
      title: Row(
        children: [
          // Geri butonu - sol tarafta
          Container(
            height: 32,
            width: 32,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(
                CupertinoIcons.arrow_left,
                color: Colors.white,
                size: 18,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          // Başlık - ortada
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.todays_deal_ucf,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Sağ tarafta boşluk (geri butonu genişliği kadar)
          SizedBox(width: 32),
        ],
      ),
      centerTitle: true,
      titleSpacing: 0,
    );
  }

  buildProductList(context) {
    return FutureBuilder(
      future: ProductRepository().getTodaysDealProducts(),
      builder: (context, AsyncSnapshot<ProductMiniResponse> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return Container();
          } else if (snapshot.data!.products!.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.local_offer_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      AppLocalizations.of(context)!.no_data_is_available,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else if (snapshot.hasData) {
            var productResponse = snapshot.data;
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xffF8F9FA),
                    Color(0xffFFFFFF),
                  ],
                ),
              ),
              child: SingleChildScrollView(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 4, // Dikey boşluk 4px
                    crossAxisSpacing: 4, // Yatay boşluk 4px
                    childAspectRatio: 0.6, // Telefon için daha yüksek kartlar
                  ),
                  itemCount: productResponse!.products!.length,
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(
                    top: 20.0,
                    bottom: 20,
                    left: 20,
                    right: 20,
                  ),
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ProductCard(
                        id: productResponse.products![index].id,
                        slug: productResponse.products![index].slug!,
                        image: productResponse.products![index].thumbnail_image,
                        name: productResponse.products![index].name,
                        main_price: productResponse.products![index].main_price,
                        stroked_price:
                            productResponse.products![index].stroked_price,
                        has_discount:
                            productResponse.products![index].has_discount!,
                        discount: productResponse.products![index].discount,
                        is_wholesale: productResponse.products![index].isWholesale,
                      ),
                    );
                  },
                ),
              ),
            );
          }
        }

        return ShimmerHelper().buildProductGridShimmer(
          scontroller: _scrollController,
        );
      },
    );
  }
}
