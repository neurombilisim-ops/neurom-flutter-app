import 'package:neurom_bilisim_store/helpers/shared_value_helper.dart';
import 'package:neurom_bilisim_store/helpers/shimmer_helper.dart';
import 'package:neurom_bilisim_store/helpers/system_config.dart';
import 'package:neurom_bilisim_store/my_theme.dart';
import 'package:neurom_bilisim_store/repositories/product_repository.dart';

import 'package:neurom_bilisim_store/data_model/wholesale_model.dart';
import 'package:neurom_bilisim_store/screens/auction/auction_products_details.dart';
import 'package:neurom_bilisim_store/screens/product/product_details.dart';
import 'package:neurom_bilisim_store/ui_elements/product_card_black.dart';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:neurom_bilisim_store/l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';

class WholesalesScreen extends StatefulWidget {
  const WholesalesScreen({super.key});

  @override
  State<WholesalesScreen> createState() => _WholesalesScreenState();
}

class _WholesalesScreenState extends State<WholesalesScreen> {
  ScrollController? _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: buildAppBar(context),
      body: buildProductList(context),
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      scrolledUnderElevation: 0.0,
      centerTitle: true,
      elevation: 0,
      toolbarHeight: 60,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Sol tarafta geri butonu
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Image.asset(
              'assets/sol.png',
              width: 20,
              height: 20,
            ),
          ),
          // Ortada başlık
          Expanded(
            child: Center(
              child: Text(
                AppLocalizations.of(context)!.wholesale_products_ucf,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          // Sağ tarafta boş alan (simetri için)
          Container(
            width: 40,
            height: 40,
          ),
        ],
      ),
    );
  }

  Widget buildProductList(context) {
    return FutureBuilder<WholesaleProductModel>(
      // future: ApiService().fetchWholesaleProducts(),
      future: ProductRepository().getWholesaleProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ShimmerHelper().buildProductGridShimmer(
            scontroller: _scrollController,
          );
        }

        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return Center(child: Text('Error loading products'));
          }

          // Safely check if data and products exist
          final productResponse = snapshot.data;
          if (productResponse == null || productResponse.products.isEmpty) {
            return Center(
              child: Text(AppLocalizations.of(context)!.no_data_is_available),
            );
          }

          final products = productResponse.products.data; // Access product list
          return SingleChildScrollView(
            controller: _scrollController,
            child: Container(
              color: Colors.white,
              child: StaggeredGrid.count(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: products.map((product) {
                  return ProductCardBlack(
                    id: product.id,
                    slug: product.slug ?? '',
                    image: product.thumbnailImage,
                    name: product.name,
                    main_price: product.baseDiscountedPrice.toString(),
                    stroked_price: product.basePrice.toString(),
                    has_discount: product.discount != 0.0,
                    discount: product.discount_percentage,
                    is_wholesale: true,
                    rating: 0, // Wholesale modelinde rating yok
                    sales: 0, // Wholesale modelinde sales yok
                  );
                }).toList(),
              ),
            ),
          );
        }

        // Default: still loading
        return ShimmerHelper().buildProductGridShimmer(
          scontroller: _scrollController,
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController
        ?.dispose(); // Dispose the scroll controller when not needed
    super.dispose();
  }
}

