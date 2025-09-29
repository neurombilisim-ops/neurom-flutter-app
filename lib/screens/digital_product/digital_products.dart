import 'package:neurom_bilisim_store/custom/lang_text.dart';
import 'package:neurom_bilisim_store/custom/useful_elements.dart';
import 'package:neurom_bilisim_store/helpers/shared_value_helper.dart';
import 'package:neurom_bilisim_store/helpers/shimmer_helper.dart';
import 'package:neurom_bilisim_store/helpers/string_helper.dart';
import 'package:neurom_bilisim_store/helpers/system_config.dart';
import 'package:neurom_bilisim_store/my_theme.dart';
import 'package:neurom_bilisim_store/repositories/product_repository.dart';
import 'package:neurom_bilisim_store/screens/auction/auction_products_details.dart';
import 'package:neurom_bilisim_store/screens/product/digital_product_details.dart';

import 'package:flutter/material.dart';
import 'package:neurom_bilisim_store/l10n/app_localizations.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DigitalProducts extends StatefulWidget {
  const DigitalProducts({super.key});

  @override
  _DigitalProductsState createState() => _DigitalProductsState();
}

class _DigitalProductsState extends State<DigitalProducts> {
  final ScrollController _mainScrollController = ScrollController();
  final ScrollController _xcrollController = ScrollController();

  //init
  bool _dataFetch = false;
  final List<dynamic> _digitalProducts = [];
  int _page = 1;
  int? _totalData = 0;

  bool _showLoadingContainer = false;

  @override
  void initState() {
    fetchData();
    _xcrollController.addListener(() {
      if (_xcrollController.position.pixels ==
          _xcrollController.position.maxScrollExtent) {
        setState(() {
          _page++;
          _showLoadingContainer = true;
        });
        fetchData();
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _mainScrollController.dispose();
    _xcrollController.dispose();
    super.dispose();
  }

  reset() {
    _dataFetch = false;
    _digitalProducts.clear();
    _totalData = 0;
    _page = 1;
    _showLoadingContainer = false;
    setState(() {});
  }

  fetchData() async {
    var digitalProductRes = await ProductRepository().getDigitalProducts(
      page: _page,
    );

    _digitalProducts.addAll(digitalProductRes.products!);
    _totalData = digitalProductRes.meta!.total;
    _dataFetch = true;
    _showLoadingContainer = false;
    setState(() {});
  }

  Future<void> _onPageRefresh() async {
    reset();
    fetchData();
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
          _totalData == _digitalProducts.length
              ? AppLocalizations.of(context)!.no_more_products_ucf
              : AppLocalizations.of(context)!.loading_more_products_ucf,
        ),
      ),
    );
  }

  bool? shouldProductBoxBeVisible(productName, searchKey) {
    if (searchKey == "") {
      return true; //do not check if the search key is empty
    }
    return StringHelper().stringContains(productName, searchKey);
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      scrolledUnderElevation: 0.0,
      backgroundColor: MyTheme.mainColor,
      centerTitle: false,
      leading: UsefulElements.backButton(context),
      title: Padding(
        padding: const EdgeInsets.only(right: 37),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context)!.digital_product_ucf,
              style: TextStyle(
                fontSize: 16,
                color: MyTheme.dark_font_grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            GestureDetector(
              onTap: () {},
              child: Image.asset('assets/search.png', height: 20),
            ),
          ],
        ),
      ),
      elevation: 0.0,
      titleSpacing: 0,
    );
  }

  Widget body() {
    if (!_dataFetch) {
      return ShimmerHelper().buildProductGridShimmer(
        scontroller: _mainScrollController,
      );
    }

    if (_digitalProducts.isEmpty) {
      return Center(child: Text(LangText(context).local.no_data_is_available));
    }
    return RefreshIndicator(
      onRefresh: _onPageRefresh,
      child: SingleChildScrollView(
        controller: _xcrollController,
        physics: AlwaysScrollableScrollPhysics(),
        child: MasonryGridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 14,
          itemCount: _digitalProducts.length,
          shrinkWrap: true,
          padding: EdgeInsets.only(top: 0.0, bottom: 10, left: 18, right: 18),
          physics: NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            // 3
            return DigitalProductCard(
              id: _digitalProducts[index].id,
              slug: _digitalProducts[index].slug,
              image: _digitalProducts[index].thumbnail_image,
              name: _digitalProducts[index].name,
              main_price: _digitalProducts[index].main_price,
              stroked_price: _digitalProducts[index].stroked_price,
              has_discount: _digitalProducts[index].has_discount,
              discount: _digitalProducts[index].discount,
              is_wholesale: null,
            );
          },
        ),
      ),
    );
  }
}

class DigitalProductCard extends StatefulWidget {
  final dynamic identifier;
  final int? id;
  final String slug;
  final String? image;
  final String? name;
  final String? main_price;
  final String? stroked_price;
  final bool has_discount;
  final bool? isWholesale;
  final String? discount;

  const DigitalProductCard({
    super.key,
    this.identifier,
    required this.slug,
    this.id,
    this.image,
    this.name,
    this.main_price,
    this.stroked_price,
    this.has_discount = false,
    bool? is_wholesale = false, // Corrected to use is_wholesale
    this.discount,
  }) : isWholesale = is_wholesale;

  @override
  _DigitalProductCardState createState() => _DigitalProductCardState();
}

class _DigitalProductCardState extends State<DigitalProductCard> {
  @override
  Widget build(BuildContext context) {
    debugPrint(
      'Wholesale status: ${widget.isWholesale}',
    ); // Debug print to check wholesale status
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return widget.identifier == 'auction'
                  ? AuctionProductsDetails(slug: widget.slug)
                  : DigitalProductDetails(slug: widget.slug);
            },
          ),
        );
      },
      child: Container(
        child: Stack(
          children: [
            Column(
              children: <Widget>[
                AspectRatio(
                  aspectRatio: 1,
                  child: Stack(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ClipRRect(
                          clipBehavior: Clip.hardEdge,
                          borderRadius: BorderRadius.circular(10),
                          child: CachedNetworkImage(
                            imageUrl: widget.image ?? '',
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Image.asset(
                              'assets/placeholder.png',
                              fit: BoxFit.cover,
                            ),
                            errorWidget: (context, url, error) => Image.asset(
                              'assets/placeholder.png',
                              fit: BoxFit.cover,
                            ),
                            memCacheWidth: 400,
                            memCacheHeight: 400,
                          ),
                        ),
                      ),
                      //    if (whole_sale_addon_installed.$ && widget.isWholesale !)
                      if ((whole_sale_addon_installed.$) &&
                          (widget.isWholesale ?? false))
                        Positioned(
                          bottom: 0,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blueGrey,
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(6),
                                bottomLeft: Radius.circular(6),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0x14000000),
                                  offset: Offset(-1, 1),
                                  blurRadius: 1,
                                ),
                              ],
                            ),
                            child: Text(
                              "Wholesale",
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                height: 1.8,
                              ),
                              textHeightBehavior: TextHeightBehavior(
                                applyHeightToFirstAscent: false,
                              ),
                              softWrap: false,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Text(
                          widget.name ?? 'No Name',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          style: TextStyle(
                            color: MyTheme.font_grey,
                            fontSize: 14,
                            height: 1.2,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      if (widget.has_discount)
                        Padding(
                          padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                          child: Text(
                            SystemConfig.systemCurrency != null
                                ? widget.stroked_price?.replaceAll(
                                      SystemConfig.systemCurrency!.code!,
                                      SystemConfig.systemCurrency!.symbol!,
                                    ) ??
                                    ''
                                : widget.stroked_price ?? '',
                            textAlign: TextAlign.left,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: MyTheme.medium_grey,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        )
                      else
                        SizedBox(height: 8.0),
                      Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(
                          SystemConfig.systemCurrency != null
                              ? widget.main_price?.replaceAll(
                                    SystemConfig.systemCurrency!.code!,
                                    SystemConfig.systemCurrency!.symbol!,
                                  ) ??
                                  ''
                              : widget.main_price ?? '',
                          textAlign: TextAlign.left,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(
                            color: MyTheme.accent_color, // Uygulama rengi ile uyumlu
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned.fill(
              child: Align(
                alignment: Alignment.topRight,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (widget.has_discount)
                      Container(
                        height: 20,
                        width: 48,
                        margin: EdgeInsets.only(top: 8, right: 8, bottom: 15),
                        decoration: BoxDecoration(
                          color: const Color(0xffe62e04),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0x14000000),
                              offset: Offset(-1, 1),
                              blurRadius: 1,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            widget.discount ?? '',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              height: 1.8,
                            ),
                            textHeightBehavior: TextHeightBehavior(
                              applyHeightToFirstAscent: false,
                            ),
                            softWrap: false,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
