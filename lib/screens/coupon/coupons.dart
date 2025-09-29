import 'package:neurom_bilisim_store/data_model/product_mini_response.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neurom_bilisim_store/l10n/app_localizations.dart';

import '../../custom/lang_text.dart';
import '../../custom/my_separator.dart';
import '../../custom/toast_component.dart';
import '../../custom/useful_elements.dart';
import '../../helpers/main_helpers.dart';
import '../../helpers/shared_value_helper.dart';
import '../../helpers/shimmer_helper.dart';
import '../../my_theme.dart';
import '../../repositories/coupon_repository.dart';

import 'coupon_products.dart';

class Coupons extends StatefulWidget {
  const Coupons({super.key});

  @override
  State<Coupons> createState() => _CouponsState();
}

class _CouponsState extends State<Coupons> {
  final ScrollController _scrollController = ScrollController();

  // Initialization variables
  bool _dataFetch = false;
  final List<dynamic> _couponsList = [];
  int _page = 1;
  int? _totalData = 0;
  bool _showLoadingContainer = false;

  _selectGradient(int index) {
    if (index == 0 || (index + 1 > 3 && ((index + 1) % 3) == 1)) {
      return MyTheme.buildLinearGradient1();
    } else if (index == 1 || (index + 1 > 3 && ((index + 1) % 3) == 2)) {
      return MyTheme.buildLinearGradient2();
    } else {
      return MyTheme.buildLinearGradient3();
    }
  }

  fetchData() async {
    var couponRes = await CouponRepository().getCouponResponseList(page: _page);
    setState(() {
      _couponsList.addAll(couponRes.data ?? []);
      _totalData = couponRes.meta?.total ?? 0;
      _dataFetch = true;
      _showLoadingContainer = false;
    });
  }

  reset() {
    setState(() {
      _dataFetch = false;
      _couponsList.clear();
      _totalData = 0;
      _page = 1;
      _showLoadingContainer = false;
    });
  }

  Future<void> _onPageRefresh() async {
    reset();
    fetchData();
  }

  @override
  void initState() {
    super.initState();
    fetchData();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        setState(() {
          _page++;
          _showLoadingContainer = true;
        });
        fetchData();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
          app_language_rtl.$! ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: MyTheme.mainColor,
        appBar: buildAppBar(context),
        body: Stack(
          children: [
            body(),
            Align(
              alignment: Alignment.bottomCenter,
              child: buildLoadingContainer(),
            ),
          ],
        ),
      ),
    );
  }

  Container buildLoadingContainer() {
    return Container(
      height: _showLoadingContainer ? 36 : 0,
      width: double.infinity,
      color: Colors.white,
      child: Center(
        child: Text(
          _totalData == _couponsList.length
              ? AppLocalizations.of(context)!.no_more_coupons_ucf
              : AppLocalizations.of(context)!.loading_coupons_ucf,
        ),
      ),
    );
  }

  Widget body() {
    if (!_dataFetch) {
      return ShimmerHelper().buildListShimmer();
    }

    if (_couponsList.isEmpty) {
      return Center(child: Text(LangText(context).local.no_data_is_available));
    }
    return RefreshIndicator(
      onRefresh: _onPageRefresh,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: AlwaysScrollableScrollPhysics(),
        child: ListView.separated(
          itemCount: _couponsList.length,
          shrinkWrap: true,
          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          physics: NeverScrollableScrollPhysics(),
          separatorBuilder: (BuildContext context, int index) => itemSpacer(),
          itemBuilder: (context, index) {
            return buildCouponCard(index);
          },
        ),
      ),
    );
  }

  Widget buildCouponCard(int index) {
    return Stack(
      alignment: AlignmentDirectional.centerStart,
      children: [
        Material(
          elevation: 0,
          borderRadius: BorderRadius.all(Radius.circular(30.0)),
          child: Container(
            decoration: BoxDecoration(
              gradient: _selectGradient(index),
              borderRadius: BorderRadius.all(Radius.circular(24.0)),
            ),
            padding: EdgeInsets.only(left: 37, right: 25, top: 22, bottom: 20),
            height: 250,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildCouponHeader(index),
                SizedBox(height: 12.5),
                MySeparator(color: Colors.white),
                SizedBox(height: 10.5),
                buildProductImageList(index),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      "${LangText(context).local.code}: ${_couponsList[index].code}",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // SizedBox(
                    //   width: 10,
                    // ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: _couponsList[index].code!),
                        ).then((_) {
                          ToastComponent.showDialog(
                            LangText(context).local.copied_ucf,
                          );
                        });
                      },
                      icon: Icon(color: Colors.white, Icons.copy, size: 15.0),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        buildCouponSideDecorations(),
      ],
    );
  }

  Widget buildCouponHeader(int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                _couponsList[index].shopName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: 5),
          ],
        ),
        SizedBox(height: 5),
        Text(
          _couponsList[index].discountType == "percent"
              ? "${_couponsList[index].discount}% ${LangText(context).local.off}"
              : "${convertPrice(_couponsList[index].discount.toString())} ${LangText(context).local.off}",
          style: TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget buildProductImageList(int index) {
    return FutureBuilder(
      future: CouponRepository().getCouponProductList(
        id: _couponsList[index].id!,
      ),
      builder: (context, AsyncSnapshot<ProductMiniResponse> snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("An error occurred"));
        } else if (snapshot.hasData) {
          var products = snapshot.data?.products ?? [];
          if (products.isEmpty) {
            return Text(
              "No products found",
              style: TextStyle(color: Colors.white),
            );
          }
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return CouponProducts(
                      code: _couponsList[index].code!,
                      id: _couponsList[index].id!,
                    );
                  },
                ),
              );
            },
            child: SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: products.length.clamp(0, 10),
                itemBuilder: (context, i) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child:
                    // Image.network(
                    //   products[i].thumbnail_image!,
                    //   height: 40,
                    //   width: 40,
                    //   fit: BoxFit.cover,
                    // ),
                    Container(
                      height: 55,
                      width: 55,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(products[i].thumbnail_image!),
                          fit: BoxFit.cover,
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(5)),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        } else {
          return SizedBox();
        }
      },
    );
  }

  Widget buildCouponSideDecorations() {
    return Row(
      //  mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          height: 40,
          width: 20,
          decoration: BoxDecoration(
            color: MyTheme.mainColor,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(30.0),
              bottomRight: Radius.circular(30.0),
            ),
          ),
        ),
        Expanded(child: SizedBox()),
        Container(
          height: 40,
          width: 20,
          decoration: BoxDecoration(
            color: MyTheme.mainColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30.0),
              bottomLeft: Radius.circular(30.0),
            ),
          ),
        ),
      ],
    );
  }

  itemSpacer({double height = 15.0}) => SizedBox(height: height);

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: MyTheme.mainColor,
      scrolledUnderElevation: 0.0,
      centerTitle: false,
      leading: UsefulElements.backButton(context),
      title: Text(
        LangText(context).local.coupons_ucf,
        style: TextStyle(
          fontSize: 16,
          color: MyTheme.dark_font_grey,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevation: 0.0,
      titleSpacing: 0,
    );
  }
}
