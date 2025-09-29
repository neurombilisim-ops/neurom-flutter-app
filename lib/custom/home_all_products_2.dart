import 'package:flutter/material.dart';
import 'package:neurom_bilisim_store/l10n/app_localizations.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../helpers/shimmer_helper.dart';
import '../presenter/home_presenter.dart';
import '../ui_elements/product_card_black.dart';
//
// class HomeAllProducts2 extends StatelessWidget {
//   final BuildContext? context;
//   final HomePresenter? homeData;
//   const HomeAllProducts2({super.key, this.context, this.homeData});
//
//   @override
//   Widget build(BuildContext context) {
//     if (homeData!.isAllProductInitial) {
//       return SingleChildScrollView(
//         child: ShimmerHelper().buildProductGridShimmer(
//           scontroller: homeData!.allProductScrollController,
//         ),
//       );
//     } else if (homeData!.allProductList.isNotEmpty) {
//       return MasonryGridView.count(
//         crossAxisCount: 2,
//         mainAxisSpacing: 14,
//         crossAxisSpacing: 14,
//         itemCount: homeData!.allProductList.length,
//         shrinkWrap: true,
//         padding: EdgeInsets.only(top: 20.0, bottom: 10, left: 18, right: 18),
//         physics: NeverScrollableScrollPhysics(),
//         itemBuilder: (context, index) {
//           return ProductCardBlack(
//             id: homeData!.allProductList[index].id,
//             slug: homeData!.allProductList[index].slug,
//             image: homeData!.allProductList[index].thumbnail_image,
//             name: homeData!.allProductList[index].name,
//             main_price: homeData!.allProductList[index].main_price,
//             stroked_price: homeData!.allProductList[index].stroked_price,
//             has_discount: homeData!.allProductList[index].has_discount,
//             discount: homeData!.allProductList[index].discount,
//             is_wholesale: homeData!.allProductList[index].isWholesale,
//           );
//         },
//       );
//     } else if (homeData!.totalAllProductData == 0) {
//       return Center(
//         child: Text(AppLocalizations.of(context)!.no_product_is_available),
//       );
//     } else {
//       return Container(); // should never be happening
//     }
//   }
// }


class HomeAllProducts2 extends StatelessWidget {
  final HomePresenter homeData;

  const HomeAllProducts2({super.key, required this.homeData});

  @override
  Widget build(BuildContext context) {
    if (homeData.isAllProductInitial) {
      return SingleChildScrollView(
        child: ShimmerHelper().buildProductGridShimmer(
          scontroller: homeData.allProductScrollController,
        ),
      );
    } else if (homeData.allProductList.isNotEmpty) {
      return Container(
        color: Colors.white,
        child: StaggeredGrid.count(
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: homeData.allProductList.map((product) {
            return ProductCardBlack(
              id: product.id,
              slug: product.slug,
              image: product.thumbnail_image,
              name: product.name,
              main_price: product.main_price,
              stroked_price: product.stroked_price,
              has_discount: product.has_discount,
              discount: product.discount,
              is_wholesale: product.isWholesale,
              rating: product.rating,
              sales: product.sales,
            );
          }).toList(),
        ),
      );
    } else if (homeData.totalAllProductData == 0) {
      return Center(
        child: Text(AppLocalizations.of(context)!.no_product_is_available),
      );
    } else {
      return const SizedBox.shrink(); // Clean fallback
    }
  }
}
