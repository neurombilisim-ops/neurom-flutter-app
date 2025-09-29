import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:neurom_bilisim_store/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import '../app_config.dart';
import '../helpers/shimmer_helper.dart';
import '../my_theme.dart';
import '../presenter/home_presenter.dart';
import 'aiz_image.dart';

class HomeCarouselSlider extends StatelessWidget {
  final HomePresenter? homeData;
  final BuildContext? context;
  const HomeCarouselSlider({super.key, this.homeData, this.context});

  @override
  Widget build(BuildContext context) {
    if (homeData!.isCarouselInitial && homeData!.carouselImageList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: ShimmerHelper().buildBasicShimmer(height: 200),
      );
    } else if (homeData!.carouselImageList.where((i) => i.photo != null && i.photo!.isNotEmpty).isNotEmpty) {
      return Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 0.5,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: CarouselSlider(
            options: CarouselOptions(
              height: 200, // Vatan Computer benzeri yükseklik
              viewportFraction: 1,
              initialPage: 0,
              enableInfiniteScroll: true,
              autoPlay: true,
              autoPlayInterval: Duration(seconds: 4),
              autoPlayAnimationDuration: Duration(milliseconds: 800),
              autoPlayCurve: Curves.easeInOut,
              enlargeCenterPage: false,
              scrollDirection: Axis.horizontal,
              onPageChanged: (index, reason) {
                homeData!.incrementCurrentSlider(index);
              },
            ),
          items: homeData!.carouselImageList
              .where((i) => i.photo != null && i.photo!.isNotEmpty) // Boş olanları filtrele
              .map((i) {
                return Builder(
                  builder: (BuildContext context) {
                    return SizedBox(
                      width: double.infinity,
                      child: InkWell(
                        onTap: () {
                          var url =
                              i.url?.split(AppConfig.DOMAIN_PATH).last ?? "";
                          print(url);
                          GoRouter.of(context).go(url);
                        },
                        child: AIZImage.radiusImage(i.photo, 0),
                      ),
                    );
                  },
                );
              }).toList(),
          ),
        ),
      );
    } else if (!homeData!.isCarouselInitial &&
        homeData!.carouselImageList.isEmpty) {
      return SizedBox(
        height: 100,
        child: Center(
          child: Text(
            AppLocalizations.of(context)!.no_carousel_image_found,
            style: TextStyle(color: MyTheme.font_grey),
          ),
        ),
      );
    } else {
      return Container(height: 100);
    }
  }
}
