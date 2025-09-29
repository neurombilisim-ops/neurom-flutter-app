import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:one_context/one_context.dart';
import 'package:shimmer/shimmer.dart';

import '../../custom/box_decorations.dart';
import '../../custom/useful_elements.dart';
import '../../helpers/main_helpers.dart';
import '../../helpers/shared_value_helper.dart';
import '../../my_theme.dart';
import '../../repositories/order_repository.dart';
import '../main.dart';
import 'order_details.dart';
import '../../l10n/app_localizations.dart';

class PaymentStatus {
  String option_key;
  String name;

  PaymentStatus(this.option_key, this.name);

  static List<PaymentStatus> getPaymentStatusList() {
    return <PaymentStatus>[
      PaymentStatus('', AppLocalizations.of(OneContext().context!)!.all_ucf),
      PaymentStatus(
        'paid',
        AppLocalizations.of(OneContext().context!)!.paid_ucf,
      ),
      PaymentStatus(
        'unpaid',
        AppLocalizations.of(OneContext().context!)!.unpaid_ucf,
      ),
    ];
  }
}

class DeliveryStatus {
  String option_key;
  String name;

  DeliveryStatus(this.option_key, this.name);

  static List<DeliveryStatus> getDeliveryStatusList() {
    return <DeliveryStatus>[
      DeliveryStatus('', AppLocalizations.of(OneContext().context!)!.all_ucf),
      DeliveryStatus(
        'confirmed',
        AppLocalizations.of(OneContext().context!)!.confirmed_ucf,
      ),
      DeliveryStatus(
        'on_the_way',
        AppLocalizations.of(OneContext().context!)!.on_the_way_ucf,
      ),
      DeliveryStatus(
        'delivered',
        AppLocalizations.of(OneContext().context!)!.delivered_ucf,
      ),
    ];
  }
}

class OrderList extends StatefulWidget {
  const OrderList({super.key, this.from_checkout = false});
  final bool from_checkout;

  @override
  _OrderListState createState() => _OrderListState();
}

class _OrderListState extends State<OrderList> {
  final ScrollController _scrollController = ScrollController();
  final ScrollController _xcrollController = ScrollController();

  final List<PaymentStatus> _paymentStatusList = PaymentStatus.getPaymentStatusList();
  final List<DeliveryStatus> _deliveryStatusList =
      DeliveryStatus.getDeliveryStatusList();

  PaymentStatus? _selectedPaymentStatus;
  DeliveryStatus? _selectedDeliveryStatus;

  List<DropdownMenuItem<PaymentStatus>>? _dropdownPaymentStatusItems;
  List<DropdownMenuItem<DeliveryStatus>>? _dropdownDeliveryStatusItems;

  final List<dynamic> _orderList = [];
  bool _isInitial = true;
  int _page = 1;
  int? _totalData = 0;
  bool _showLoadingContainer = false;
  String _defaultPaymentStatusKey = '';
  String _defaultDeliveryStatusKey = '';

  @override
  void initState() {
    init();
    super.initState();

    fetchData();

    _xcrollController.addListener(() {
      if (_xcrollController.position.pixels ==
          _xcrollController.position.maxScrollExtent) {
        setState(() {
          _page++;
        });
        _showLoadingContainer = true;
        fetchData();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _xcrollController.dispose();
    super.dispose();
  }

  init() {
    _dropdownPaymentStatusItems = buildDropdownPaymentStatusItems(
      _paymentStatusList,
    );

    _dropdownDeliveryStatusItems = buildDropdownDeliveryStatusItems(
      _deliveryStatusList,
    );

    for (int x = 0; x < _dropdownPaymentStatusItems!.length; x++) {
      if (_dropdownPaymentStatusItems![x].value!.option_key ==
          _defaultPaymentStatusKey) {
        _selectedPaymentStatus = _dropdownPaymentStatusItems![x].value;
      }
    }

    for (int x = 0; x < _dropdownDeliveryStatusItems!.length; x++) {
      if (_dropdownDeliveryStatusItems![x].value!.option_key ==
          _defaultDeliveryStatusKey) {
        _selectedDeliveryStatus = _dropdownDeliveryStatusItems![x].value;
      }
    }
  }

  reset() {
    _orderList.clear();
    _isInitial = true;
    _page = 1;
    _totalData = 0;
    _showLoadingContainer = false;
  }

  resetFilterKeys() {
    _defaultPaymentStatusKey = '';
    _defaultDeliveryStatusKey = '';

    setState(() {});
  }

  Future<void> _onRefresh() async {
    reset();
    resetFilterKeys();
    for (int x = 0; x < _dropdownPaymentStatusItems!.length; x++) {
      if (_dropdownPaymentStatusItems![x].value!.option_key ==
          _defaultPaymentStatusKey) {
        _selectedPaymentStatus = _dropdownPaymentStatusItems![x].value;
      }
    }

    for (int x = 0; x < _dropdownDeliveryStatusItems!.length; x++) {
      if (_dropdownDeliveryStatusItems![x].value!.option_key ==
          _defaultDeliveryStatusKey) {
        _selectedDeliveryStatus = _dropdownDeliveryStatusItems![x].value;
      }
    }
    setState(() {});
    fetchData();
  }

  fetchData() async {
    var orderResponse = await OrderRepository().getOrderList(
      page: _page,
      payment_status: _selectedPaymentStatus!.option_key,
      delivery_status: _selectedDeliveryStatus!.option_key,
    );
    _orderList.addAll(orderResponse.orders);
    _isInitial = false;
    _totalData = orderResponse.meta.total;
    _showLoadingContainer = false;
    setState(() {});
  }

  List<DropdownMenuItem<PaymentStatus>> buildDropdownPaymentStatusItems(
    List paymentStatusList,
  ) {
    List<DropdownMenuItem<PaymentStatus>> items = [];
    for (PaymentStatus item in paymentStatusList as Iterable<PaymentStatus>) {
      items.add(DropdownMenuItem(value: item, child: Text(item.name)));
    }
    return items;
  }

  List<DropdownMenuItem<DeliveryStatus>> buildDropdownDeliveryStatusItems(
    List deliveryStatusList,
  ) {
    List<DropdownMenuItem<DeliveryStatus>> items = [];
    for (DeliveryStatus item
        in deliveryStatusList as Iterable<DeliveryStatus>) {
      items.add(DropdownMenuItem(value: item, child: Text(item.name)));
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        if (widget.from_checkout) {
          context.go("/");
          return Future<bool>.value(false);
        } else {
          return Future<bool>.value(true);
        }
      },
      child: Directionality(
        textDirection:
            app_language_rtl.$! ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          backgroundColor: Color(0xffF8F9FA),
          appBar: buildAppBar(context),
          body: Stack(
            children: [
              buildOrderListList(),
              Align(
                alignment: Alignment.bottomCenter,
                child: buildLoadingContainer(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Container buildLoadingContainer() {
    return Container(
      height: _showLoadingContainer ? 60 : 0,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Center(
        child: _totalData == _orderList.length
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)!.no_more_orders_ucf,
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(MyTheme.accent_color),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context)!.loading_more_orders_ucf,
                    style: TextStyle(
                      color: MyTheme.font_grey,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  buildBottomAppBar(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: DropdownButton<PaymentStatus>(
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(6),
                icon: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Icon(Icons.keyboard_arrow_down, color: MyTheme.accent_color, size: 14),
                ),
                hint: Padding(
                  padding: const EdgeInsets.only(left: 12.0, right: 8.0),
                  child: Text(
                    "Ödeme",
                    style: TextStyle(color: MyTheme.font_grey, fontSize: 12, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                iconSize: 14,
                underline: SizedBox(),
                value: _selectedPaymentStatus,
                items: _dropdownPaymentStatusItems,
                onChanged: (PaymentStatus? selectedFilter) {
                  setState(() {
                    _selectedPaymentStatus = selectedFilter;
                  });
                  reset();
                  fetchData();
                },
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: DropdownButton<DeliveryStatus>(
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(6),
                icon: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Icon(Icons.keyboard_arrow_down, color: MyTheme.accent_color, size: 14),
                ),
                hint: Padding(
                  padding: const EdgeInsets.only(left: 12.0, right: 8.0),
                  child: Text(
                    "Teslimat",
                    style: TextStyle(color: MyTheme.font_grey, fontSize: 12, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                iconSize: 14,
                underline: SizedBox(),
                value: _selectedDeliveryStatus,
                items: _dropdownDeliveryStatusItems,
                onChanged: (DeliveryStatus? selectedFilter) {
                  setState(() {
                    _selectedDeliveryStatus = selectedFilter;
                  });
                  reset();
                  fetchData();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: Size.fromHeight(140.0),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              MyTheme.accent_color,
              MyTheme.accent_color.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (widget.from_checkout) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) {
                                return Main();
                              },
                            ),
                          );
                        } else {
                          return Navigator.of(context).pop();
                        }
                      },
                      icon: Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        "Siparişlerim",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        _onRefresh();
                      },
                      icon: Icon(
                        Icons.refresh,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
              buildBottomAppBar(context),
            ],
          ),
        ),
      ),
    );
  }


  buildOrderListList() {
    if (_isInitial && _orderList.isEmpty) {
      return SingleChildScrollView(
        child: ListView.builder(
          controller: _scrollController,
          itemCount: 5,
          scrollDirection: Axis.vertical,
          physics: NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 6.0,
              ),
              child: Shimmer.fromColors(
                baseColor: MyTheme.shimmer_base,
                highlightColor: MyTheme.shimmer_highlighted,
                child: Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            );
          },
        ),
      );
    } else if (_orderList.isNotEmpty) {
      return RefreshIndicator(
        color: MyTheme.accent_color,
        backgroundColor: Colors.white,
        displacement: 0,
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          controller: _xcrollController,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          child: ListView.separated(
            separatorBuilder: (context, index) => SizedBox(height: 14),
            padding: const EdgeInsets.only(
              left: 18,
              right: 18,
              top: 10,
              bottom: 0,
            ),
            itemCount: _orderList.length,
            scrollDirection: Axis.vertical,
            physics: NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return OrderDetails(id: _orderList[index].id);
                      },
                    ),
                  );
                },
                child: buildOrderListItemCard(index),
              );
            },
          ),
        ),
      );
    } else if (_totalData == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: MyTheme.accent_color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.shopping_bag_outlined,
                  size: 64,
                  color: MyTheme.accent_color,
                ),
              ),
              SizedBox(height: 24),
              Text(
                "Henüz siparişiniz yok",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: MyTheme.dark_font_grey,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "İlk siparişinizi vermek için ürünleri keşfedin",
                style: TextStyle(
                  fontSize: 14,
                  color: MyTheme.font_grey,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Main(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: MyTheme.accent_color,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  "Alışverişe Başla",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return Container(); // should never be happening
    }
  }

  buildOrderListItemCard(int index) {
    bool isPaid = _orderList[index].payment_status == "paid" ||
                  _orderList[index].payment_status_string.toLowerCase().contains("ödendi") ||
                  _orderList[index].payment_status_string.toLowerCase().contains("paid") ||
                  _orderList[index].payment_status_string.toLowerCase().contains("yapıldı");
    
    return Container(
      margin: EdgeInsets.only(left: 1.0, right: 1.0, top: 2.5, bottom: 2.5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) {
                  return OrderDetails(id: _orderList[index].id);
                },
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _orderList[index].code,
                        style: TextStyle(
                          color: MyTheme.accent_color,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isPaid ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isPaid ? "Ödendi" : "Ödenmedi",
                        style: TextStyle(
                          color: isPaid ? Colors.green : Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: MyTheme.font_grey,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _orderList[index].date,
                        style: TextStyle(
                          color: MyTheme.dark_font_grey,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.left,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      convertPrice(_orderList[index].grand_total),
                      style: TextStyle(
                        color: MyTheme.accent_color,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                // Durum bilgileri
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: MyTheme.mainColor.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.payment,
                            size: 16,
                            color: MyTheme.font_grey,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                text: "Ödeme Durumu: ",
                                style: TextStyle(
                                  color: MyTheme.dark_font_grey,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                children: [
                                  TextSpan(
                                    text: _orderList[index].payment_status_string,
                                    style: TextStyle(
                                      color: isPaid ? Colors.green : Colors.red,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.left,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.local_shipping,
                            size: 16,
                            color: MyTheme.font_grey,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                text: "Teslimat Durumu: ",
                                style: TextStyle(
                                  color: MyTheme.dark_font_grey,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                children: [
                                  TextSpan(
                                    text: _orderList[index].delivery_status_string,
                                    style: TextStyle(
                                      color: MyTheme.dark_font_grey,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.left,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Container buildPaymentStatusCheckContainer(String paymentStatus) {
    return Container(
      height: 16,
      width: 16,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.0),
        color: paymentStatus == "paid" ? Colors.green : Colors.red,
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Icon(
          paymentStatus == "paid" ? Icons.check : Icons.check,
          color: Colors.white,
          size: 10,
        ),
      ),
    );
  }
}
