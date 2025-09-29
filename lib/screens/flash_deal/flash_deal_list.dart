import 'package:neurom_bilisim_store/custom/box_decorations.dart';
import 'package:neurom_bilisim_store/custom/device_info.dart';
import 'package:neurom_bilisim_store/custom/lang_text.dart';
import 'package:neurom_bilisim_store/custom/toast_component.dart';
import 'package:neurom_bilisim_store/custom/useful_elements.dart';
import 'package:neurom_bilisim_store/data_model/flash_deal_response.dart';
import 'package:neurom_bilisim_store/helpers/main_helpers.dart';
import 'package:neurom_bilisim_store/helpers/shared_value_helper.dart';
import 'package:neurom_bilisim_store/helpers/shimmer_helper.dart';
import 'package:neurom_bilisim_store/l10n/app_localizations.dart';
import 'package:neurom_bilisim_store/my_theme.dart';
import 'package:neurom_bilisim_store/repositories/flash_deal_repository.dart';
import 'package:neurom_bilisim_store/screens/flash_deal/flash_deal_products.dart';
import 'package:flutter/material.dart';
import 'package:flutter_countdown_timer/index.dart';
import 'package:neurom_bilisim_store/l10n/app_localizations.dart';

class FlashDealList extends StatefulWidget {
  const FlashDealList({super.key});

  @override
  _FlashDealListState createState() => _FlashDealListState();
}

class _FlashDealListState extends State<FlashDealList> {
  final List<CountdownTimerController> _timerControllerList = [];

  DateTime convertTimeStampToDateTime(int timeStamp) {
    var dateToTimeStamp = DateTime.fromMillisecondsSinceEpoch(timeStamp * 1000);
    return dateToTimeStamp;
  }

  @override
  Widget build(BuildContext context) {
    // print("object");
    return Directionality(
      textDirection:
          app_language_rtl.$! ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: buildAppBar(context),
        backgroundColor: MyTheme.mainColor,
        body: buildFlashDealList(context),
      ),
    );
  }

  Widget buildFlashDealList(context) {
    return FutureBuilder<FlashDealResponse>(
      future: FlashDealRepository().getFlashDeals(),
      builder: (context, AsyncSnapshot<FlashDealResponse> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return Center(
              child: Text(AppLocalizations.of(context)!.network_error),
            );
          } else if (snapshot.data == null) {
            return Container(
              child: Center(
                child: Text(AppLocalizations.of(context)!.no_data_is_available),
              ),
            );
          } else if (snapshot.hasData) {
            FlashDealResponse flashDealResponse = snapshot.data!;
            return SingleChildScrollView(
              child: ListView.separated(
                separatorBuilder: (context, index) {
                  return SizedBox(height: 20);
                },
                itemCount: flashDealResponse.flashDeals!.length,
                scrollDirection: Axis.vertical,
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  return buildFlashDealListItem(flashDealResponse, index);
                },
              ),
            );
          }
        }
        return buildShimmer();
      },
    );
  }

  CustomScrollView buildShimmer() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: ListView.separated(
            separatorBuilder: (context, index) {
              return SizedBox(height: 20);
            },
            itemCount: 20,
            scrollDirection: Axis.vertical,
            physics: NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemBuilder: (context, index) {
              return buildFlashDealListItemShimmer();
            },
          ),
        ),
      ],
    );
  }

  String timeText(String txt, {default_length = 3}) {
    var blankZeros = default_length == 3 ? "000" : "00";
    var leadingZeros = "";
    if (default_length == 3 && txt.length == 1) {
      leadingZeros = "00";
    } else if (default_length == 3 && txt.length == 2) {
      leadingZeros = "0";
    } else if (default_length == 2 && txt.length == 1) {
      leadingZeros = "0";
    }

    var newtxt = (txt == "" || txt == null.toString()) ? blankZeros : txt;

    if (default_length > txt.length) {
      newtxt = leadingZeros + newtxt;
    }

    return newtxt;
  }

  buildFlashDealListItem(FlashDealResponse flashDealResponse, index) {
    DateTime end = convertTimeStampToDateTime(
      flashDealResponse.flashDeals![index].date!,
    ); // YYYY-mm-dd
    DateTime now = DateTime.now();
    int diff = end.difference(now).inMilliseconds;
    int endTime = diff + now.millisecondsSinceEpoch;

    void onEnd() {}

    CountdownTimerController timeController = CountdownTimerController(
      endTime: endTime,
      onEnd: onEnd,
    );
    _timerControllerList.add(timeController);

    return SizedBox(
      // color: MyTheme.amber,
      height: 340,
      child: CountdownTimer(
        controller: _timerControllerList[index],
        widgetBuilder: (_, CurrentRemainingTime? time) {
          return GestureDetector(
            onTap: () {
              if (time == null) {
                ToastComponent.showDialog(
                  AppLocalizations.of(context)!.flash_deal_has_ended,
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return FlashDealProducts(
                        slug: flashDealResponse.flashDeals![index].slug,
                      );
                    },
                  ),
                );
              }
            },
            //flash deals time,product card
            child: Stack(
              children: [
                buildFlashDealBanner(flashDealResponse, index),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    width: DeviceInfo(context).width,
                    height: 198,
                    margin: EdgeInsets.symmetric(horizontal: 20),
                    //decoration: BoxDecorations.buildBoxDecoration_1(),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.16),
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          child: Center(
                            child:
                                time == null
                                    ? Text(
                                      AppLocalizations.of(context)!.ended_ucf,
                                      style: TextStyle(
                                        color: MyTheme.accent_color,
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    )
                                    : buildTimerRow(time),
                          ),
                        ),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: BouncingScrollPhysics(),
                          child: Container(
                            padding: EdgeInsets.only(
                              top: 0,
                              left: 2,
                              bottom: 17,
                            ),
                            width: 460,
                            child: Wrap(
                              //spacing: 10,
                              runSpacing: 10,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              runAlignment: WrapAlignment.spaceBetween,
                              alignment: WrapAlignment.start,

                              children: List.generate(
                                flashDealResponse
                                    .flashDeals![index]
                                    .products!
                                    .products!
                                    .length,
                                (productIndex) {
                                  return buildFlashDealsProductItem(
                                    flashDealResponse,
                                    index,
                                    productIndex,
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  buildFlashDealListItemShimmer() {
    return SizedBox(
      height: 340,
      child: Stack(
        children: [
          buildFlashDealBannerShimmer(),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              width: DeviceInfo(context).width,
              height: 196,
              margin: EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecorations.buildBoxDecoration_1(),
              child: Column(
                children: [
                  Container(child: buildTimerRowRowShimmer()),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: BouncingScrollPhysics(),
                    child: Container(
                      padding: EdgeInsets.only(top: 0, left: 2, bottom: 16),
                      width: 460,
                      child: Wrap(
                        //spacing: 10,
                        runSpacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        runAlignment: WrapAlignment.spaceBetween,
                        alignment: WrapAlignment.start,

                        children: List.generate(6, (productIndex) {
                          return buildFlashDealsProductItemShimmer();
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildFlashDealsProductItem(
    flashDealResponse,
    flashDealIndex,
    productIndex,
  ) {
    return Container(
      margin: EdgeInsets.only(left: 10),
      height: 50,
      width: 136,
      decoration: BoxDecoration(
        color: Color(0xffF6F7F8),
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(width: 2),
          ClipRRect(
            borderRadius: BorderRadius.circular(
              4,
            ), // Rounding the image corners
            child: SizedBox(
              height: 46,
              width: 44,
              child: FadeInImage(
                placeholder: AssetImage("assets/placeholder.png"),
                image: NetworkImage(
                  flashDealResponse
                      .flashDeals[flashDealIndex]
                      .products
                      .products[productIndex]
                      .image,
                ),
                fit:
                    BoxFit
                        .cover, // Ensures the image fits within the rounded corners
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: Text(
              convertPrice(
                flashDealResponse
                    .flashDeals[flashDealIndex]
                    .products
                    .products[productIndex]
                    .price,
              ),
              style: TextStyle(
                fontSize: 13,
                color: MyTheme.accent_color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildFlashDealsProductItemShimmer() {
    return Container(
      margin: EdgeInsets.only(left: 10),
      height: 50,
      width: 136,
      decoration: BoxDecoration(
        color: Color(0xffF6F7F8),
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(6),
                bottomLeft: Radius.circular(6),
              ),
            ),
            child: ShimmerHelper().buildBasicShimmerCustomRadius(
              height: 46,
              width: 44,
              radius: BorderRadius.only(
                topLeft: Radius.circular(6),
                bottomLeft: Radius.circular(6),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: ShimmerHelper().buildBasicShimmer(height: 15, width: 60),
          ),
        ],
      ),
    );
  }

  Container buildFlashDealBanner(flashDealResponse, index) {
    return Container(
      child: FadeInImage.assetNetwork(
        placeholder: 'assets/placeholder_rectangle.png',
        image: flashDealResponse.flashDeals[index].banner,
        fit: BoxFit.cover,
        width: DeviceInfo(context).width,
        height: 180,
      ),
    );
  }

  Widget buildFlashDealBannerShimmer() {
    return ShimmerHelper().buildBasicShimmerCustomRadius(
      width: DeviceInfo(context).width,
      height: 180,
      color: MyTheme.medium_grey_50,
    );
  }

  Widget buildTimerRow(CurrentRemainingTime time) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          //  SizedBox(width: 10), // Circular timer for Days (handling null)
          Column(
            children: [
              timerCircularContainer(
                time.days ?? 0,
                365,
                timeText((time.days ?? 0).toString(), default_length: 3),
              ),
              SizedBox(height: 5),
              Text('Days', style: TextStyle(color: Colors.grey, fontSize: 10)),
            ],
          ),
          SizedBox(width: 12),

          Column(
            children: [
              timerCircularContainer(
                time.hours ?? 0,
                24,
                timeText((time.hours ?? 0).toString(), default_length: 2),
              ),
              SizedBox(height: 5),
              Text('Hours', style: TextStyle(color: Colors.grey, fontSize: 10)),
            ],
          ),
          SizedBox(width: 10),

          Column(
            children: [
              timerCircularContainer(
                time.min ?? 0,
                60,
                timeText((time.min ?? 0).toString(), default_length: 2),
              ),
              SizedBox(height: 5),
              Text(
                'Minutes',
                style: TextStyle(color: Colors.grey, fontSize: 10),
              ),
            ],
          ),
          SizedBox(width: 5),

          Column(
            children: [
              timerCircularContainer(
                time.sec ?? 0,
                60,
                timeText((time.sec ?? 0).toString(), default_length: 2),
              ),
              SizedBox(height: 5),
              Text(
                'Seconds',
                style: TextStyle(color: Colors.grey, fontSize: 10),
              ),
            ],
          ),

          SizedBox(width: 10),
          Column(
            children: [
              Image.asset(
                "assets/flash_deal.png",
                height: 20,
                color: MyTheme.golden,
              ),
              SizedBox(height: 12),
            ],
          ),
          Spacer(),
          InkWell(
            onTap: () {},
            child: Row(
              children: [
                Text(
                  LangText(context).local.shop_more_ucf,
                  style: TextStyle(fontSize: 10, color: Color(0xffA8AFB3)),
                ),
                SizedBox(width: 3),
                Icon(
                  Icons.arrow_forward_outlined,
                  size: 10,
                  color: MyTheme.grey_153,
                ),
                SizedBox(width: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTimerRowRowShimmer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 20, 0, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Icon(
          //   Icons.watch_later_outlined,
          //   color: MyTheme.grey_153,
          // ),
          SizedBox(width: 10),
          // ShimmerHelper().buildBasicShimmerCustomRadius(
          //     height: 30,
          //     width: 30,
          //     radius: BorderRadius.circular(6),
          //     color: MyTheme.shimmer_base),
          ShimmerHelper().buildCircleShimmer(height: 30, width: 30),
          SizedBox(width: 12),
          ShimmerHelper().buildCircleShimmer(height: 30, width: 30),
          SizedBox(width: 10),
          ShimmerHelper().buildCircleShimmer(height: 30, width: 30),
          SizedBox(width: 10),
          ShimmerHelper().buildCircleShimmer(height: 30, width: 30),
          SizedBox(width: 10),
          Image.asset(
            "assets/flash_deal.png",
            height: 20,
            color: MyTheme.golden,
          ),
          Spacer(),
          InkWell(
            onTap: () {},
            child: Row(
              children: [
                Text(
                  LangText(context).local.shop_more_ucf,
                  style: TextStyle(fontSize: 10, color: Color(0xffA8AFB3)),
                ),
                SizedBox(width: 3),
                Icon(
                  Icons.arrow_forward_outlined,
                  size: 10,
                  color: MyTheme.grey_153,
                ),
                SizedBox(width: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget timerCircularContainer(
    int currentValue,
    int totalValue,
    String timeText,
  ) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 30,
          height: 30,
          child: CircularProgressIndicator(
            value: currentValue / totalValue,
            backgroundColor: const Color.fromARGB(255, 240, 220, 220),
            valueColor: AlwaysStoppedAnimation<Color>(
              const Color.fromARGB(255, 255, 80, 80),
            ),
            strokeWidth: 4.0,
            strokeCap: StrokeCap.round,
          ),
        ),
        Text(
          timeText,
          style: TextStyle(
            color: const Color.fromARGB(228, 218, 29, 29),
            fontSize: 10.0,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget timerContainer(Widget child) {
    return Container(
      constraints: BoxConstraints(minWidth: 30, minHeight: 24),
      alignment: Alignment.center,
      padding: EdgeInsets.all(6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: Color(0xffE62E04),
      ),
      child: child,
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: MyTheme.mainColor,
      scrolledUnderElevation: 0.0,
      centerTitle: false,
      leading: Builder(
        builder:
            (context) => IconButton(
              icon: UsefulElements.backButton(context),
              onPressed: () => Navigator.of(context).pop(),
            ),
      ),
      title: Text(
        AppLocalizations.of(context)!.flash_deals_ucf,
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
