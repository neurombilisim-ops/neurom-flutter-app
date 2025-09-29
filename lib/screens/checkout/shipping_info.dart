import 'dart:convert';

import 'package:neurom_bilisim_store/custom/box_decorations.dart';
import 'package:neurom_bilisim_store/custom/btn.dart';
import 'package:neurom_bilisim_store/custom/device_info.dart';
import 'package:neurom_bilisim_store/custom/enum_classes.dart';
import 'package:neurom_bilisim_store/custom/fade_network_image.dart';
import 'package:neurom_bilisim_store/custom/lang_text.dart';
import 'package:neurom_bilisim_store/custom/toast_component.dart';
import 'package:neurom_bilisim_store/custom/useful_elements.dart';
import 'package:neurom_bilisim_store/data_model/delivery_info_response.dart';
import 'package:neurom_bilisim_store/helpers/shared_value_helper.dart';
import 'package:neurom_bilisim_store/helpers/shimmer_helper.dart';
import 'package:neurom_bilisim_store/helpers/system_config.dart';
import 'package:neurom_bilisim_store/l10n/app_localizations.dart';
import 'package:neurom_bilisim_store/my_theme.dart';
import 'package:neurom_bilisim_store/repositories/address_repository.dart';
import 'package:neurom_bilisim_store/repositories/shipping_repository.dart';
import 'package:neurom_bilisim_store/screens/checkout/checkout.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ShippingInfo extends StatefulWidget {
  final String? guestCheckOutShippingAddress;

  ShippingInfo({
    Key? key,
    this.guestCheckOutShippingAddress,
  }) : super(key: key);

  @override
  _ShippingInfoState createState() => _ShippingInfoState();
}

class _ShippingInfoState extends State<ShippingInfo> {
  ScrollController _mainScrollController = ScrollController();
  List<SellerWithShipping> _sellerWiseShippingOption = [];
  List<DeliveryInfoResponse> _deliveryInfoList = [];
  String? _shipping_cost_string = ". . .";
  bool _isFetchDeliveryInfo = false;
  double mWidth = 0;
  double mHeight = 0;

  fetchAll() {
    getDeliveryInfo();
  }

  getDeliveryInfo() async {
    try {
      _deliveryInfoList = await (ShippingRepository()
          .getDeliveryInfo(guestAddress: widget.guestCheckOutShippingAddress));
      _isFetchDeliveryInfo = true;

      if (_deliveryInfoList.isEmpty) {
        getSetShippingCost();
        setState(() {});
        return;
      }

      _deliveryInfoList.forEach((element) {
      
      var shippingOption = carrier_base_shipping.$
          ? ShippingOption.Carrier
          : ShippingOption.HomeDelivery;
      int? shippingId;
      
      if (carrier_base_shipping.$ &&
          element.carriers!.data!.isNotEmpty &&
          !(element.cartItems
                  ?.every((element2) => element2.isDigital ?? false) ??
              false)) {
        shippingId = element.carriers!.data!.first.id;
      } else if (!carrier_base_shipping.$) {
        shippingId = 0;
      }

      _sellerWiseShippingOption.add(
          new SellerWithShipping(element.ownerId, shippingOption, shippingId));
    });
    getSetShippingCost();
    setState(() {});
    } catch (e) {
      _isFetchDeliveryInfo = true;
      getSetShippingCost();
      setState(() {});
    }
  }

  getSetShippingCost() async {
    if (shipping_type.$ == "area_wise_shipping" || 
        shipping_type.$ == "product_wise_shipping" || 
        shipping_type.$ == "seller_wise_shipping") {
      _shipping_cost_string = "Ücretsiz Kargo";
      if (mounted) {
        setState(() {});
      }
      return;
    }

    var shippingCostResponse;
    shippingCostResponse = await AddressRepository()
        .getShippingCostResponse(shipping_type: _sellerWiseShippingOption);

    if (shippingCostResponse.result == true &&
        shippingCostResponse.value_string != null) {
      _shipping_cost_string = shippingCostResponse.value_string.replaceAll('TRY', '₺');
    } else {
      _shipping_cost_string = "0.0₺";
    }
    
    if (mounted) {
      setState(() {});
    }
  }

  resetData() {
    clearData();
    fetchAll();
  }

  clearData() {
    _deliveryInfoList.clear();
    _sellerWiseShippingOption.clear();
    _shipping_cost_string = ". . .";
    _shipping_cost_string = ". . .";
    _isFetchDeliveryInfo = false;
    setState(() {});
  }

  Future<void> _onRefresh() async {
    clearData();
    if (is_logged_in.$ == true) {
      fetchAll();
    }
  }

  onPopped(value) async {
    resetData();
  }

  afterAddingAnAddress() {
    resetData();
  }

  onPickUpPointSwitch() async {
    _shipping_cost_string = ". . .";
    setState(() {});
  }

  changeShippingOption(ShippingOption option, index) {
    if (option.index == 0) { // HomeDelivery
      if (_deliveryInfoList.isNotEmpty && 
          _deliveryInfoList.length > index &&
          _deliveryInfoList[index].carriers != null &&
          _deliveryInfoList[index].carriers!.data != null &&
          _deliveryInfoList[index].carriers!.data!.isNotEmpty) {
        _sellerWiseShippingOption[index].shippingId =
            _deliveryInfoList[index].carriers!.data!.first.id;
      } else {
        _sellerWiseShippingOption[index].shippingId = 0;
      }
    } else if (option.index == 1) { // PickUpPoint
      if (_deliveryInfoList.isNotEmpty && 
          _deliveryInfoList.length > index &&
          _deliveryInfoList[index].pickupPoints != null &&
          _deliveryInfoList[index].pickupPoints!.isNotEmpty) {
        _sellerWiseShippingOption[index].shippingId =
            _deliveryInfoList[index].pickupPoints!.first.id;
      } else {
        _sellerWiseShippingOption[index].shippingId = 0;
      }
    }
    _sellerWiseShippingOption[index].shippingOption = option;
    getSetShippingCost();

    setState(() {});
  }

  onPressProceed(context) async {
    var shippingCostResponse;

    shippingCostResponse = await AddressRepository()
        .getShippingCostResponse(shipping_type: _sellerWiseShippingOption);

    if (shippingCostResponse.result == false) {
      ToastComponent.showDialog(
        LangText(context).local.network_error,
      );
      return;
    }

    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return Checkout(
        title: AppLocalizations.of(context)!.checkout_ucf,
        paymentFor: PaymentFor.Order,
        guestCheckOutShippingAddress: widget.guestCheckOutShippingAddress,
      );
    })).then((value) {
      onPopped(value);
    });
  }

  @override
  void initState() {
    super.initState();

    fetchAll();
  }

  @override
  void dispose() {
    super.dispose();
    _mainScrollController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    mHeight = MediaQuery.of(context).size.height;
    mWidth = MediaQuery.of(context).size.width;
    return Directionality(
      textDirection:
          app_language_rtl.$! ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
          backgroundColor: Color(0xffF8F9FA),
          appBar: customAppBar(context) as PreferredSizeWidget?,
          bottomNavigationBar: buildBottomAppBar(context),
          body: buildBody(context)),
    );
  }

  RefreshIndicator buildBody(BuildContext context) {
    return RefreshIndicator(
      color: MyTheme.accent_color,
      backgroundColor: Colors.white,
      onRefresh: _onRefresh,
      displacement: 0,
      child: Container(
        child: buildBodyChildren(context),
      ),
    );
  }

  Widget buildBodyChildren(BuildContext context) {
    return buildCartSellerList();
  }

  Widget buildShippingListBody(sellerIndex) {
    return _sellerWiseShippingOption[sellerIndex].shippingOption ==
            ShippingOption.PickUpPoint
        ? buildPickupPoint(sellerIndex)
        : buildHomeDeliveryORCarrier(sellerIndex);
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      centerTitle: true,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(CupertinoIcons.arrow_left, color: MyTheme.dark_grey),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      title: Text(
        "${AppLocalizations.of(context)!.shipping_cost_ucf} $_shipping_cost_string",
        style: TextStyle(fontSize: 16, color: MyTheme.accent_color),
      ),
      elevation: 0.0,
      titleSpacing: 0,
    );
  }

  buildHomeDeliveryORCarrier(sellerArrayIndex) {
    if (carrier_base_shipping.$) {
      return buildCarrierSection(sellerArrayIndex);
    } else {
      // carrier_base_shipping false olsa bile kargo seçeneklerini göster
      return buildCarrierSection(sellerArrayIndex);
    }
  }

  Container buildLoginWarning() {
    return Container(
        height: 100,
        child: Center(
            child: Text(
          LangText(context).local.you_need_to_log_in,
          style: TextStyle(color: MyTheme.font_grey),
        )));
  }

  Widget buildPickupPoint(sellerArrayIndex) {
    if (_isFetchDeliveryInfo && _deliveryInfoList.length == 0) {
      return buildCarrierShimmer();
    } else if (_deliveryInfoList[sellerArrayIndex].pickupPoints!.length > 0) {
      return ListView.separated(
        separatorBuilder: (context, index) => SizedBox(
          height: 14,
        ),
        itemCount: _deliveryInfoList[sellerArrayIndex].pickupPoints!.length,
        scrollDirection: Axis.vertical,
        physics: NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemBuilder: (context, index) {
          return buildPickupPointItemCard(index, sellerArrayIndex);
        },
      );
    } else if (_isFetchDeliveryInfo &&
        _deliveryInfoList[sellerArrayIndex].pickupPoints!.length == 0) {
      return Container(
        height: 100,
        child: Center(
          child: Text(
            AppLocalizations.of(context)!.pickup_point_is_unavailable_ucf,
            style: TextStyle(color: MyTheme.font_grey),
          ),
        ),
      );
    }
    return SizedBox.shrink();
  }

  GestureDetector buildPickupPointItemCard(pickupPointIndex, sellerArrayIndex) {
    bool isSelected = _sellerWiseShippingOption[sellerArrayIndex].shippingId ==
        _deliveryInfoList[sellerArrayIndex]
            .pickupPoints![pickupPointIndex]
            .id;
    
    return GestureDetector(
      onTap: () {
        if (_sellerWiseShippingOption[sellerArrayIndex].shippingId !=
            _deliveryInfoList[sellerArrayIndex]
                .pickupPoints![pickupPointIndex]
                .id) {
          _sellerWiseShippingOption[sellerArrayIndex].shippingId =
              _deliveryInfoList[sellerArrayIndex]
                  .pickupPoints![pickupPointIndex]
                  .id;
        }
        setState(() {});
        getSetShippingCost();
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? MyTheme.accent_color : Color(0xffE9ECEF),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: buildPickUpPointInfoItemChildren(
              pickupPointIndex, sellerArrayIndex),
        ),
      ),
    );
  }

  Column buildPickUpPointInfoItemChildren(pickupPointIndex, sellerArrayIndex) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 75,
                child: Text(
                  AppLocalizations.of(context)!.address_ucf,
                  style: TextStyle(
                    fontSize: 13,
                    color: MyTheme.dark_font_grey,
                  ),
                ),
              ),
              Container(
                width: 175,
                child: Text(
                  _deliveryInfoList[sellerArrayIndex]
                      .pickupPoints![pickupPointIndex]
                      .name!,
                  maxLines: 2,
                  style: TextStyle(
                      fontSize: 13,
                      color: MyTheme.dark_grey,
                      fontWeight: FontWeight.w600),
                ),
              ),
              Spacer(),
              buildShippingSelectMarkContainer(
                  _sellerWiseShippingOption[sellerArrayIndex].shippingId ==
                      _deliveryInfoList[sellerArrayIndex]
                          .pickupPoints![pickupPointIndex]
                          .id)
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 75,
                child: Text(
                  AppLocalizations.of(context)!.phone_ucf,
                  style: TextStyle(
                    fontSize: 13,
                    color: MyTheme.dark_font_grey,
                  ),
                ),
              ),
              Container(
                width: 200,
                child: Text(
                  _deliveryInfoList[sellerArrayIndex]
                      .pickupPoints![pickupPointIndex]
                      .phone!,
                  maxLines: 2,
                  style: TextStyle(
                      fontSize: 13,
                      color: MyTheme.dark_grey,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildCarrierSection(sellerArrayIndex) {
    if (!_isFetchDeliveryInfo) {
      return buildCarrierShimmer();
    } else if (_deliveryInfoList.length > sellerArrayIndex && 
               _deliveryInfoList[sellerArrayIndex].carriers != null &&
               _deliveryInfoList[sellerArrayIndex].carriers!.data != null &&
               _deliveryInfoList[sellerArrayIndex].carriers!.data!.length > 0) {
      return Container(child: buildCarrierListView(sellerArrayIndex));
    } else {
      return buildCarrierNoData();
    }
  }

  Container buildCarrierNoData() {
    return Container(
      height: 100,
      child: Center(
        child: Text(
          AppLocalizations.of(context)!.carrier_points_is_unavailable_ucf,
          style: TextStyle(color: MyTheme.font_grey),
        ),
      ),
    );
  }

  Widget buildCarrierListView(sellerArrayIndex) {
    return ListView.separated(
      itemCount: _deliveryInfoList[sellerArrayIndex].carriers!.data!.length,
      scrollDirection: Axis.vertical,
      separatorBuilder: (context, index) {
        return SizedBox(
          height: 14,
        );
      },
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemBuilder: (context, index) {
        return buildCarrierItemCard(index, sellerArrayIndex);
      },
    );
  }

  Widget buildCarrierShimmer() {
    return ShimmerHelper().buildListShimmer(item_count: 2, item_height: 50.0);
  }

  GestureDetector buildCarrierItemCard(carrierIndex, sellerArrayIndex) {
    bool isSelected = _sellerWiseShippingOption[sellerArrayIndex].shippingId ==
        _deliveryInfoList[sellerArrayIndex]
            .carriers!
            .data![carrierIndex]
            .id;
    
    return GestureDetector(
      onTap: () {
        if (_sellerWiseShippingOption[sellerArrayIndex].shippingId !=
            _deliveryInfoList[sellerArrayIndex]
                .carriers!
                .data![carrierIndex]
                .id) {
          _sellerWiseShippingOption[sellerArrayIndex].shippingId =
              _deliveryInfoList[sellerArrayIndex]
                  .carriers!
                  .data![carrierIndex]
                  .id;
          _sellerWiseShippingOption[sellerArrayIndex].shippingOption = ShippingOption.HomeDelivery;
          setState(() {});
          getSetShippingCost();
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? MyTheme.accent_color : Color(0xffE9ECEF),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: buildCarrierInfoItemChildren(carrierIndex, sellerArrayIndex),
      ),
    );
  }

  Widget buildCarrierInfoItemChildren(carrierIndex, sellerArrayIndex) {
    return Container(
      width: double.infinity,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Logo kutusu - sol tarafta
          Container(
            height: 75.0,
            width: 75.0,
            margin: EdgeInsets.only(left: 1, top: 1, bottom: 1),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Color(0xffE9ECEF),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: FadeInImage.assetNetwork(
                placeholder: 'assets/placeholder.png',
                image: _deliveryInfoList[sellerArrayIndex]
                    .carriers!
                    .data![carrierIndex]
                    .logo!,
                fit: BoxFit.contain,
                width: 60,
                height: 60,
              ),
            ),
          ),
          // Kargo bilgileri - ortada
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 12.0, right: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _deliveryInfoList[sellerArrayIndex]
                        .carriers!
                        .data![carrierIndex]
                        .name!,
                    maxLines: 2,
                    style: TextStyle(
                        fontSize: 14,
                        color: MyTheme.dark_font_grey,
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _deliveryInfoList[sellerArrayIndex]
                            .carriers!
                            .data![carrierIndex]
                            .transitTime
                            .toString() +
                        " " +
                        LangText(context).local.day_ucf,
                    maxLines: 1,
                    style: TextStyle(
                        fontSize: 12,
                        color: MyTheme.grey_153,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
          // Fiyat - sağ tarafta
          Container(
            margin: EdgeInsets.only(right: 1),
            child: Text(
              _deliveryInfoList[sellerArrayIndex]
                  .carriers!
                  .data![carrierIndex]
                  .transitPrice
                  .toString()
                  .replaceAll('TRY', '₺'),
              maxLines: 1,
              style: TextStyle(
                  fontSize: 14,
                  color: MyTheme.dark_font_grey,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Container buildShippingSelectMarkContainer(bool check) {
    return check
        ? Container(
            height: 24,
            width: 24,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.0),
              color: MyTheme.accent_color,
              boxShadow: [
                BoxShadow(
                  color: MyTheme.accent_color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.check,
              color: Colors.white,
              size: 16,
            ),
          )
        : Container(
            height: 24,
            width: 24,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: Color(0xffE9ECEF),
                width: 1,
              ),
            ),
          );
  }

  Widget buildBottomAppBar(BuildContext context) {
    // Sistem navigation bar'ı var mı kontrol et
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final hasSystemNavBar = bottomPadding > 0;
    
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: hasSystemNavBar ? 10 : 10,
        bottom: hasSystemNavBar ? bottomPadding + 10 : 10,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Container(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                onPressProceed(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: MyTheme.accent_color,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)!.proceed_to_checkout,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget customAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      automaticallyImplyLeading: false,
      title: buildAppbarTitle(context),
      leading: UsefulElements.backButton(context),
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Container(
          height: 1,
          color: Color(0xffE9ECEF),
        ),
      ),
    );
  }

  Container buildAppbarTitle(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width - 40,
      child: Center(
        child: Text(
          "${AppLocalizations.of(context)!.shipping_cost_ucf} $_shipping_cost_string",
          style: TextStyle(
            fontSize: 18,
            color: Color(0xff2C3E50),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Container buildAppbarBackArrow() {
    return Container(
      width: 40,
      child: UsefulElements.backButton(context),
    );
  }

  Widget buildChooseShippingOptions(BuildContext context, sellerIndex) {
    // Panelden kargo bilgileri kapatılmışsa hiçbir seçenek gösterme
    if (!carrier_base_shipping.$ && !pick_up_status.$) {
      return Container();
    }
    
    return Container(
      color: MyTheme.white,
      child: Column(
        children: [
          // Adrese Teslim seçeneği - her zaman göster
          buildAddressOption(context, sellerIndex),
          if (pick_up_status.$) ...[
            SizedBox(height: 12),
            buildPickUpPointOption(context, sellerIndex),
          ],
        ],
      ),
    );
  }

  Widget buildPickUpPointOption(BuildContext context, sellerIndex) {
    bool isSelected = _sellerWiseShippingOption[sellerIndex].shippingOption ==
        ShippingOption.PickUpPoint;
    
    return Container(
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            changeShippingOption(ShippingOption.PickUpPoint, sellerIndex);
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? MyTheme.accent_color : Colors.white,
          foregroundColor: isSelected ? Colors.white : MyTheme.accent_color,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? MyTheme.accent_color : Color(0xffE9ECEF),
              width: 1,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.store_outlined,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)!.pickup_point_ucf,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isSelected) ...[
              SizedBox(width: 8),
              Icon(
                Icons.check_circle,
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget buildAddressOption(BuildContext context, sellerIndex) {
    bool isSelected = _sellerWiseShippingOption[sellerIndex].shippingOption ==
        ShippingOption.HomeDelivery;
    
    return Container(
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        onPressed: () {
          changeShippingOption(ShippingOption.HomeDelivery, sellerIndex);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? MyTheme.accent_color : Colors.white,
          foregroundColor: isSelected ? Colors.white : MyTheme.accent_color,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? MyTheme.accent_color : Color(0xffE9ECEF),
              width: 1,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.home_outlined,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)!.home_delivery_ucf,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isSelected) ...[
              SizedBox(width: 8),
              Icon(
                Icons.check_circle,
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget buildCarrierOption(BuildContext context, sellerIndex) {
    bool isSelected = _sellerWiseShippingOption[sellerIndex].shippingOption ==
        ShippingOption.Carrier;
    
    return Container(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          changeShippingOption(ShippingOption.Carrier, sellerIndex);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? MyTheme.accent_color : Colors.white,
          foregroundColor: isSelected ? Colors.white : MyTheme.accent_color,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? MyTheme.accent_color : Color(0xffE9ECEF),
              width: 1,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_shipping_outlined,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)!.carrier_ucf,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isSelected) ...[
              SizedBox(width: 8),
              Icon(
                Icons.check_circle,
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget buildCartSellerList() {
    // if (is_logged_in.$ == false) {
    //   return Container(
    //       height: 100,
    //       child: Center(
    //           child: Text(
    //             AppLocalizations
    //                 .of(context)!
    //                 .please_log_in_to_see_the_cart_items,
    //             style: TextStyle(color: MyTheme.font_grey),
    //           )));
    // }
    // else
    if (_isFetchDeliveryInfo && _deliveryInfoList.length == 0) {
      return SingleChildScrollView(
          child: ShimmerHelper()
              .buildListShimmer(item_count: 5, item_height: 100.0));
    } else if (_deliveryInfoList.length > 0) {
      return buildCartSellerListBody();
    } else if (_isFetchDeliveryInfo && _deliveryInfoList.length == 0) {
      return Container(
          height: 100,
          child: Center(
              child: Text(
            AppLocalizations.of(context)!.cart_is_empty,
            style: TextStyle(color: MyTheme.font_grey),
          )));
    }
    return Container();
  }

  SingleChildScrollView buildCartSellerListBody() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0),
        child: ListView.separated(
          padding: EdgeInsets.only(bottom: 20),
          separatorBuilder: (context, index) => SizedBox(
            height: 26,
          ),
          itemCount: _deliveryInfoList.length,
          scrollDirection: Axis.vertical,
          physics: NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemBuilder: (context, index) {
            return buildCartSellerListItem(index, context);
          },
        ),
      ),
    );
  }

  Column buildCartSellerListItem(int index, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sadece teslimat seçme ve kargo alanı - mağaza bilgileri ve ürün listesi kaldırıldı
        if (!(_deliveryInfoList[index]
            .cartItems!
            .every((element) => (element.isDigital ?? false))))
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 18.0),
                child: Text(
                  LangText(context).local.choose_delivery_ucf,
                  style: TextStyle(
                      color: MyTheme.dark_font_grey,
                      fontWeight: FontWeight.w700,
                      fontSize: 12),
                ),
              ),
              SizedBox(
                height: 5,
              ),
              buildChooseShippingOptions(context, index),
              SizedBox(
                height: 10,
              ),
              buildShippingListBody(index),
            ],
          ),
      ],
    );
  }

  SingleChildScrollView buildCartSellerItemList(seller_index) {
    return SingleChildScrollView(
      child: ListView.separated(
        separatorBuilder: (context, index) => SizedBox(
          height: 14,
        ),
        itemCount: _deliveryInfoList[seller_index].cartItems!.length,
        scrollDirection: Axis.vertical,
        physics: NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemBuilder: (context, index) {
          return buildCartSellerItemCard(index, seller_index);
        },
      ),
    );
  }

  buildCartSellerItemCard(itemIndex, sellerIndex) {
    return Container(
      height: 80,
      decoration: BoxDecorations.buildBoxDecoration_1(),
      child: Row(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
        Container(
          width: DeviceInfo(context).width! / 4,
          height: 120,
          child: ClipRRect(
            borderRadius: BorderRadius.horizontal(
                left: Radius.circular(6), right: Radius.zero),
            child: FadeInImage.assetNetwork(
              placeholder: 'assets/placeholder.png',
              image: _deliveryInfoList[sellerIndex]
                  .cartItems![itemIndex]
                  .productThumbnailImage!,
              fit: BoxFit.cover,
            ),
          ),
        ),
        SizedBox(
          width: 10,
        ),
        Container(
          //color: Colors.red,
          width: DeviceInfo(context).width! / 2,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _deliveryInfoList[sellerIndex]
                      .cartItems![itemIndex]
                      .productName!,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  style: TextStyle(
                      color: MyTheme.font_grey,
                      fontSize: 12,
                      fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

enum ShippingOption { HomeDelivery, PickUpPoint, Carrier }

class SellerWithShipping {
  int? sellerId;
  ShippingOption shippingOption;
  int? shippingId;
  bool isAllDigital;

  SellerWithShipping(this.sellerId, this.shippingOption, this.shippingId,
      {this.isAllDigital = false});

  Map toJson() => {
        'seller_id': sellerId,
        'shipping_type': shippingOption == ShippingOption.HomeDelivery
            ? "home_delivery"
            : shippingOption == ShippingOption.Carrier
                ? "carrier"
                : "pickup_point",
        'shipping_id': shippingId,
      };
}
