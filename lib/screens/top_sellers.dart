import 'package:neurom_bilisim_store/custom/lang_text.dart';
import 'package:neurom_bilisim_store/custom/useful_elements.dart';
import 'package:neurom_bilisim_store/helpers/shimmer_helper.dart';
import 'package:neurom_bilisim_store/my_theme.dart';
import 'package:neurom_bilisim_store/repositories/shop_repository.dart';
import 'package:neurom_bilisim_store/ui_elements/shop_square_card.dart';
import 'package:flutter/material.dart';

import '../data_model/shop_response.dart';

class TopSellers extends StatefulWidget {
  const TopSellers({super.key});

  @override
  State<TopSellers> createState() => _TopSellersState();
}

class _TopSellersState extends State<TopSellers> {
  ScrollController? _scrollController;
  List<Shop> topSellers = [];
  bool isInit = false;

  getTopSellers() async {
    ShopResponse response = await ShopRepository().topSellers();
    isInit = true;
    if (response.shops != null) {
      topSellers.addAll(response.shops!);
    }

    setState(() {});
  }

  clearAll() {
    isInit = false;
    topSellers.clear();
    setState(() {});
  }

  Future<void> onRefresh() async {
    clearAll();

    return await getTopSellers();
  }

  @override
  void initState() {
    // TODO: implement initState
    getTopSellers();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyTheme.mainColor,
      appBar: buildAppBar(context),
      body: RefreshIndicator(
        onRefresh: onRefresh,
        child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: buildTopSellerList(context)),
      ),
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: MyTheme.mainColor,
      // centerTitle: true,
      leading: UsefulElements.backButton(context),
      title: Text(
        LangText(context).local.top_sellers_ucf,
        style: TextStyle(
            fontSize: 16,
            color: MyTheme.dark_font_grey,
            fontWeight: FontWeight.bold),
      ),
      elevation: 0.0,
      scrolledUnderElevation: 0.0,
      titleSpacing: 0,
    );
  }

  Widget buildTopSellerList(context) {
    if (isInit) {
      //print(productResponse.toString());
      return GridView.builder(
        // 2
        //addAutomaticKeepAlives: true,
        itemCount: topSellers.length,
        controller: _scrollController,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.68),
        padding: EdgeInsets.only(top: 20, bottom: 10, left: 18, right: 18),
        physics: NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemBuilder: (context, index) {
          // 3
          return ShopSquareCard(
            id: topSellers[index].id,
            shopSlug: topSellers[index].slug ?? "",
            image: topSellers[index].logo,
            name: topSellers[index].name,
            stars: double.parse(topSellers[index].rating.toString()),
          );
        },
      );
    } else {
      return ShimmerHelper()
          .buildSquareGridShimmer(scontroller: _scrollController);
    }
  }
}
