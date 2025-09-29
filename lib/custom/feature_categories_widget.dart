import 'package:neurom_bilisim_store/helpers/shimmer_helper.dart';
import 'package:neurom_bilisim_store/presenter/home_presenter.dart';
import 'package:neurom_bilisim_store/screens/main.dart';
import 'package:flutter/material.dart';
import '../my_theme.dart';

class FeaturedCategoriesWidget extends StatelessWidget {
  final HomePresenter homeData;
  const FeaturedCategoriesWidget({super.key, required this.homeData});

  @override
  Widget build(BuildContext context) {
    print('FeaturedCategoriesWidget build: isCategoryInitial=${homeData.isCategoryInitial}, featuredCategoryList.length=${homeData.featuredCategoryList.length}');
    
    if (homeData.isCategoryInitial) {
      // Loading state - show shimmer
      return ShimmerHelper().buildHorizontalGridShimmerWithAxisCount(
          crossAxisSpacing: 12.0,
          mainAxisSpacing: 12.0,
          item_count: 10,
          mainAxisExtent: 170.0,
          controller: homeData.featuredCategoryScrollController);
    } else if (homeData.featuredCategoryList.isNotEmpty) {
      // Has categories - show them
      print('FeaturedCategoriesWidget: ${homeData.featuredCategoryList.length} kategori gösteriliyor');
      for (var category in homeData.featuredCategoryList) {
        print('Kategori: ${category.name}');
      }
      return GridView.builder(
        padding:
            const EdgeInsets.only(left: 20, right: 20, top: 11, bottom: 24),
        scrollDirection: Axis.horizontal,
        controller: homeData.featuredCategoryScrollController,
        itemCount: homeData.featuredCategoryList.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1, // Ensures square boxes
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 170.0),
        itemBuilder: (context, index) {
          return InkWell(
              onTap: () {
                print('Ana sayfa kategorisi tıklandı: ${homeData.featuredCategoryList[index].name}');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      print('Main sayfasına yönlendiriliyor...');
                      return Main(goToCategories: true);
                    },
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                child: Row(
                  children: [
                    AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xff000000).withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 15,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: FadeInImage.assetNetwork(
                              placeholder: 'assets/placeholder.png',
                              image: homeData
                                  .featuredCategoryList[index].coverImage!,
                              fit: BoxFit.cover,
                            ),
                          ),
                        )),
                    SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        homeData.featuredCategoryList[index].name,
                        textAlign: TextAlign.left,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 3,
                        softWrap: true,
                        style: TextStyle(
                          fontSize: 12,
                          color: MyTheme.font_grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ));
        },
      );
    } else {
      // No categories - show empty state
      print('FeaturedCategoriesWidget: Kategori bulunamadı');
      return SizedBox(
        height: 100,
        child: Center(
          child: Text(
            "Kategori bulunamadı",
            style: TextStyle(color: MyTheme.font_grey),
          ),
        ),
      );
    }
  }
}
