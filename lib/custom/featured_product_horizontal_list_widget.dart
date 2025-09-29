import 'package:flutter/material.dart';
import 'package:neurom_bilisim_store/l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../helpers/shimmer_helper.dart';
import '../my_theme.dart';
import '../presenter/home_presenter.dart';
import '../ui_elements/mini_product_card.dart';

class FeaturedProductHorizontalListWidget extends StatelessWidget {
  final HomePresenter homeData;
  const FeaturedProductHorizontalListWidget({super.key, required this.homeData});

  @override
  Widget build(BuildContext context) {
    if (homeData.isFeaturedProductInitial == true &&
        homeData.featuredProductList.isEmpty) {
      return Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ShimmerHelper().buildBasicShimmer(
                height: 120.0,
                width: (MediaQuery.of(context).size.width - 64) / 3,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ShimmerHelper().buildBasicShimmer(
                height: 120.0,
                width: (MediaQuery.of(context).size.width - 64) / 3,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ShimmerHelper().buildBasicShimmer(
                height: 120.0,
                width: (MediaQuery.of(context).size.width - 160) / 3,
              ),
            ),
          ),
        ],
      );
    } else if (homeData.featuredProductList.isNotEmpty) {
      return Container(
        color: Colors.white, // Beyaz arka plan ekle
        child: SingleChildScrollView(
          child: SizedBox(
            height: 230,
            child: NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification scrollInfo) {
                if (scrollInfo.metrics.pixels ==
                    scrollInfo.metrics.maxScrollExtent) {
                  homeData.fetchFeaturedProducts();
                }
                return true;
              },
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 18.0),
                separatorBuilder: (context, index) => SizedBox(width: 12),
                itemCount:
                    homeData.totalFeaturedProductData! >
                            homeData.featuredProductList.length
                        ? homeData.featuredProductList.length + 1
                        : homeData.featuredProductList.length,
                scrollDirection: Axis.horizontal,

                //itemExtent: 135,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                itemBuilder: (context, index) {
                  return (index == homeData.featuredProductList.length)
                      ? SpinKitFadingFour(
                          itemBuilder: (BuildContext context, int index) {
                            return DecoratedBox(
                              decoration: BoxDecoration(color: Colors.white),
                            );
                          },
                        )
                      : MiniProductCard(
                          id: homeData.featuredProductList[index].id,
                          slug: homeData.featuredProductList[index].slug,
                          image:
                              homeData.featuredProductList[index].thumbnail_image,
                          name: homeData.featuredProductList[index].name,
                          main_price:
                              homeData.featuredProductList[index].main_price,
                          stroked_price:
                              homeData.featuredProductList[index].stroked_price,
                          has_discount:
                              homeData.featuredProductList[index].has_discount,
                          is_wholesale:
                              homeData.featuredProductList[index].isWholesale,
                          discount: homeData.featuredProductList[index].discount,
                        );
                },
              ),
            ),
          ),
        ),
      );
    } else {
      return SizedBox(
        height: 100,
        child: Center(
          child: Text(
            AppLocalizations.of(context)!.no_related_product,
            style: TextStyle(color: MyTheme.font_grey),
          ),
        ),
      );
    }
  }
}