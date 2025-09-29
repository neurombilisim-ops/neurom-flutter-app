import 'package:neurom_bilisim_store/custom/btn.dart';
import 'package:neurom_bilisim_store/custom/lang_text.dart';
import 'package:neurom_bilisim_store/custom/useful_elements.dart';
import 'package:neurom_bilisim_store/helpers/shared_value_helper.dart';
import 'package:neurom_bilisim_store/helpers/shimmer_helper.dart';
import 'package:neurom_bilisim_store/my_theme.dart';
import 'package:neurom_bilisim_store/presenter/select_address_provider.dart';
import 'package:neurom_bilisim_store/screens/address.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SelectAddress extends StatefulWidget {
  int? owner_id;
  SelectAddress({Key? key, this.owner_id}) : super(key: key);

  @override
  State<SelectAddress> createState() => _SelectAddressState();
}

class _SelectAddressState extends State<SelectAddress> {
  double mWidth = 0;
  double mHeight = 0;

  @override
  Widget build(BuildContext context) {
    mHeight = MediaQuery.of(context).size.height;
    mWidth = MediaQuery.of(context).size.width;
    return ChangeNotifierProvider(
      create: (_) => SelectAddressProvider()..init(context),
      child: Consumer<SelectAddressProvider>(
          builder: (context, selectAddressProvider, _) {
        return Directionality(
          textDirection:
              app_language_rtl.$! ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            appBar: AppBar(
              elevation: 0,
              backgroundColor: Colors.white,
              automaticallyImplyLeading: false,
              centerTitle: true,
              title: buildAppbarTitle(context),
              leading: UsefulElements.backButton(context),
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(1),
                child: Container(
                  height: 1,
                  color: Color(0xffE9ECEF),
                ),
              ),
            ),
            backgroundColor: Colors.white,
            bottomNavigationBar:
                buildBottomAppBar(context, selectAddressProvider),
            body: RefreshIndicator(
              color: MyTheme.accent_color,
              backgroundColor: Colors.white,
              onRefresh: () => selectAddressProvider.onRefresh(context),
              displacement: 0,
              child: Container(
                child: CustomScrollView(
                  controller: selectAddressProvider.mainScrollController,
                  physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics()),
                  slivers: [
                    SliverList(
                        delegate: SliverChildListDelegate([
                      Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: buildShippingInfoList(
                              selectAddressProvider, context)),
                      buildAddOrEditAddress(context, selectAddressProvider),
                      SizedBox(
                        height: 100,
                      )
                    ]))
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget buildAddOrEditAddress(BuildContext context, provider) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) {
            return Address(
              from_shipping_info: true,
            );
          })).then((value) {
            provider.onPopped(value, context);
          });
        },
        icon: Icon(
          Icons.add,
          size: 20,
          color: MyTheme.accent_color,
        ),
        label: Text(
          "Yeni Adres Ekle",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: MyTheme.accent_color,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: MyTheme.accent_color,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: MyTheme.accent_color,
              width: 1,
            ),
          ),
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      ),
    );
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
        "${LangText(context).local.shipping_info}",
        style: TextStyle(
          fontSize: 20,
          color: Color(0xff2C3E50),
          fontWeight: FontWeight.w700,
        ),
      ),
      elevation: 0.0,
      titleSpacing: 0,
    );
  }

  buildShippingInfoList(selectAddressProvider, BuildContext context) {
    if (is_logged_in.$ == false) {
      return Container(
          height: 100,
          child: Center(
              child: Text(
            LangText(context).local.you_need_to_log_in,
            style: TextStyle(color: MyTheme.font_grey),
          )));
    } else if (!selectAddressProvider.faceData &&
        selectAddressProvider.shippingAddressList.length == 0) {
      return SingleChildScrollView(
          child: ShimmerHelper()
              .buildListShimmer(item_count: 5, item_height: 100.0));
    } else if (selectAddressProvider.shippingAddressList.length > 0) {
      return SingleChildScrollView(
        child: ListView.builder(
          itemCount: selectAddressProvider.shippingAddressList.length,
          scrollDirection: Axis.vertical,
          physics: NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: buildShippingInfoItemCard(
                  index, selectAddressProvider, context),
            );
          },
        ),
      );
    } else if (selectAddressProvider.faceData &&
        selectAddressProvider.shippingAddressList.length == 0) {
      return Container(
          height: 100,
          child: Center(
              child: Text(
            LangText(context).local.no_address_is_added,
            style: TextStyle(color: MyTheme.font_grey),
          )));
    }
  }

  GestureDetector buildShippingInfoItemCard(
      index, selectAddressProvider, BuildContext context) {
    bool isSelected = selectAddressProvider.selectedShippingAddress ==
        selectAddressProvider.shippingAddressList[index].id;
    
    return GestureDetector(
      onTap: () => selectAddressProvider.shippingInfoCardFnc(index, context),
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? MyTheme.accent_color : Color(0xffE5E7EB),
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
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "Adres ${index + 1}",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? MyTheme.accent_color : Color(0xff1A1A1A),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: MyTheme.accent_color,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: MyTheme.accent_color.withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                ],
              ),
              SizedBox(height: 16),
              buildShippingInfoItemAddress(index, selectAddressProvider),
            ],
          ),
        ),
      ),
    );
  }

  Padding buildShippingInfoItemPhone(index, selectAddressProvider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.phone_outlined,
            color: Color(0xff6C757D),
            size: 16,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              selectAddressProvider.shippingAddressList[index].phone,
              maxLines: 2,
              style: TextStyle(
                color: Color(0xff6B7280),
                fontWeight: FontWeight.w600,
                fontSize: 15,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Padding buildShippingInfoItemPostalCode(index, selectAddressProvider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.local_post_office_outlined,
            color: Color(0xff6C757D),
            size: 16,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              selectAddressProvider.shippingAddressList[index].postal_code,
              maxLines: 2,
              style: TextStyle(
                color: Color(0xff6B7280),
                fontWeight: FontWeight.w600,
                fontSize: 15,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Padding buildShippingInfoItemCountry(index, selectAddressProvider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.public_outlined,
            color: Color(0xff6C757D),
            size: 16,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              selectAddressProvider.shippingAddressList[index].country_name,
              maxLines: 2,
              style: TextStyle(
                color: Color(0xff6B7280),
                fontWeight: FontWeight.w600,
                fontSize: 15,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Padding buildShippingInfoItemState(index, selectAddressProvider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.location_city_outlined,
            color: Color(0xff6C757D),
            size: 16,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              selectAddressProvider.shippingAddressList[index].state_name,
              maxLines: 2,
              style: TextStyle(
                color: Color(0xff6B7280),
                fontWeight: FontWeight.w600,
                fontSize: 15,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Padding buildShippingInfoItemCity(index, selectAddressProvider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.location_city_outlined,
            color: Color(0xff6C757D),
            size: 16,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              selectAddressProvider.shippingAddressList[index].city_name,
              maxLines: 2,
              style: TextStyle(
                color: Color(0xff6B7280),
                fontWeight: FontWeight.w600,
                fontSize: 15,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Padding buildShippingInfoItemAddress(index, selectAddressProvider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.home_outlined,
            color: Color(0xff6C757D),
            size: 16,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              selectAddressProvider.shippingAddressList[index].address,
              maxLines: 2,
              style: TextStyle(
                color: Color(0xff6B7280),
                fontWeight: FontWeight.w600,
                fontSize: 15,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Container buildShippingOptionsCheckContainer(bool check) {
    return check
        ? Container(
            height: 16,
            width: 16,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.0), color: Colors.green),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Icon(Icons.check, color: Colors.white, size: 10),
            ),
          )
        : Container();
  }

  Widget buildBottomAppBar(BuildContext context, provider) {
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
                provider.onPressProceed(context);
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
                    LangText(context).local.continue_to_delivery_info_ucf,
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

  Text buildAppbarTitle(BuildContext context) {
    return Text(
      "${LangText(context).local.shipping_info}",
      style: TextStyle(
        fontSize: 20,
        color: Color(0xff2C3E50),
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
