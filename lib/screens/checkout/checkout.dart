import 'package:neurom_bilisim_store/custom/btn.dart';
import 'package:neurom_bilisim_store/custom/enum_classes.dart';
import 'package:neurom_bilisim_store/custom/lang_text.dart';
import 'package:neurom_bilisim_store/custom/toast_component.dart';
import 'package:neurom_bilisim_store/helpers/shared_value_helper.dart';
import 'package:neurom_bilisim_store/helpers/shimmer_helper.dart';
import 'package:neurom_bilisim_store/helpers/system_config.dart';
import 'package:neurom_bilisim_store/l10n/app_localizations.dart';
import 'package:neurom_bilisim_store/my_theme.dart';
import 'package:neurom_bilisim_store/repositories/cart_repository.dart';
import 'package:neurom_bilisim_store/repositories/coupon_repository.dart';
import 'package:neurom_bilisim_store/repositories/payment_repository.dart';
import 'package:neurom_bilisim_store/screens/orders/order_list.dart';
import 'package:neurom_bilisim_store/screens/payment_method_screen/amarpay_screen.dart';
import 'package:neurom_bilisim_store/screens/payment_method_screen/bkash_screen.dart';
import 'package:neurom_bilisim_store/screens/payment_method_screen/flutterwave_screen.dart';
import 'package:neurom_bilisim_store/screens/payment_method_screen/iyzico_screen.dart';
import 'package:neurom_bilisim_store/screens/payment_method_screen/khalti_screen.dart';
import 'package:neurom_bilisim_store/screens/payment_method_screen/my_fatoora_screen.dart';
import 'package:neurom_bilisim_store/screens/payment_method_screen/nagad_screen.dart';
import 'package:neurom_bilisim_store/screens/payment_method_screen/offline_screen.dart';
import 'package:neurom_bilisim_store/screens/payment_method_screen/online_pay.dart';
import 'package:neurom_bilisim_store/screens/payment_method_screen/payfast_screen.dart';
import 'package:neurom_bilisim_store/screens/payment_method_screen/paypal_screen.dart';
import 'package:neurom_bilisim_store/screens/payment_method_screen/paystack_screen.dart';
import 'package:neurom_bilisim_store/screens/payment_method_screen/paytm_screen.dart';
import 'package:neurom_bilisim_store/screens/payment_method_screen/razorpay_screen.dart';
import 'package:neurom_bilisim_store/screens/payment_method_screen/sslcommerz_screen.dart';
import 'package:neurom_bilisim_store/screens/payment_method_screen/stripe_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:one_context/one_context.dart';

import '../../custom/loading.dart';
import '../../helpers/auth_helper.dart';
import '../../repositories/guest_checkout_repository.dart';
import '../guest_checkout_pages/guest_checkout_address.dart';

import '../payment_method_screen/cybersource_screen.dart';
import '../payment_method_screen/phonePe/phonePe_screen.dart';
import '../payment_method_screen/paytr_screen.dart';

class Checkout extends StatefulWidget {
  int? order_id; // only need when making manual payment from order details
  String list;
  final PaymentFor? paymentFor;
  final double rechargeAmount;
  final String? title;
  var packageId;
  final String? guestCheckOutShippingAddress;

  Checkout({
    super.key,
    this.guestCheckOutShippingAddress,
    this.order_id = 0,
    this.paymentFor,
    this.list = "both",
    this.rechargeAmount = 0.0,
    this.title,
    this.packageId = 0,
  });

  @override
  _CheckoutState createState() => _CheckoutState();
}

class _CheckoutState extends State<Checkout> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  var _selected_payment_method_index = 0;
  String? _selected_payment_method = "";
  String? _selected_payment_method_key = "";

  final ScrollController _mainScrollController = ScrollController();
  final TextEditingController _couponController = TextEditingController();
  final _paymentTypeList = [];
  bool _isInitial = true;
  String? _totalString = ". . .";
  double? _grandTotalValue = 0.00;
  String? _subTotalString = ". . .";
  String? _taxString = ". . .";
  String _shippingCostString = ". . .";
  String? _discountString = ". . .";
  String _used_coupon_code = "";
  bool? _coupon_applied = false;
  late BuildContext loadingcontext;
  String payment_type = "cart_payment";
  String? _title;

  @override
  void initState() {
    super.initState();
    fetchAll();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_title == null) {
      if (widget.paymentFor == PaymentFor.WalletRecharge) {
        _title = AppLocalizations.of(context)!.recharge_wallet_ucf;
      } else if (widget.paymentFor == PaymentFor.PackagePay) {
        _title = AppLocalizations.of(context)!.buy_package_ucf;
      } else if (widget.paymentFor == PaymentFor.OrderRePayment) {
        _title = AppLocalizations.of(context)!.re_order_ucf;
      } else if (widget.paymentFor == PaymentFor.ManualPayment) {
        _title = AppLocalizations.of(context)!.make_offline_payment_ucf;
      } else {
        _title = AppLocalizations.of(context)!.checkout_ucf;
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
    _mainScrollController.dispose();
  }

  String balance() {
    String? displayValue;

    if (widget.paymentFor == PaymentFor.ManualPayment ||
        widget.paymentFor == PaymentFor.WalletRecharge ||
        widget.paymentFor == PaymentFor.PackagePay ||
        widget.paymentFor == PaymentFor.OrderRePayment) {
      displayValue = SystemConfig.systemCurrency != null
          ? "${SystemConfig.systemCurrency!.symbol!} ${widget.rechargeAmount.toStringAsFixed(2)}"
          : widget.rechargeAmount.toStringAsFixed(2);
    } else {
      displayValue = SystemConfig.systemCurrency != null
          ? _totalString?.replaceAll(SystemConfig.systemCurrency!.code!,
              SystemConfig.systemCurrency!.symbol!)
          : _totalString;
    }

    return displayValue ?? '';
  }

  fetchAll() async {
    String mode = '';
    setState(() {
      mode = widget.paymentFor != PaymentFor.Order &&
              widget.paymentFor != PaymentFor.ManualPayment
          ? "wallet"
          : "order";
    });

    var paymentTypeResponseList = await PaymentRepository()
        .getPaymentResponseList(list: widget.list, mode: mode);

    _paymentTypeList.clear(); // Clear existing list before adding
    _paymentTypeList.addAll(paymentTypeResponseList);
    if (_paymentTypeList.isNotEmpty) {
      _selected_payment_method = _paymentTypeList[0].payment_type;
      _selected_payment_method_key = _paymentTypeList[0].payment_type_key;
    }
    _isInitial = false;
    setState(() {});

    await fetchSummary();

    if (widget.paymentFor == PaymentFor.WalletRecharge ||
        widget.paymentFor == PaymentFor.PackagePay ||
        widget.paymentFor == PaymentFor.OrderRePayment ||
        widget.paymentFor == PaymentFor.ManualPayment) {
      setState(() {
        _grandTotalValue = widget.rechargeAmount;
      });
      if (widget.paymentFor == PaymentFor.OrderRePayment) {
        payment_type = 'order_re_payment';
      } else if (widget.paymentFor == PaymentFor.WalletRecharge) {
        payment_type = "wallet_payment";
      } else if (widget.paymentFor == PaymentFor.PackagePay) {
        payment_type = "customer_package_payment";
      } else if (widget.paymentFor == PaymentFor.ManualPayment) {
      }
    } else {
      payment_type = 'cart_payment';
    }
    setState(() {}); // Update the UI after all data is fetched and processed
  }

  fetchSummary() async {
    var cartSummaryResponse = await CartRepository().getCartSummaryResponse();

    if (cartSummaryResponse != null) {
      setState(() {
        _subTotalString = cartSummaryResponse.sub_total;
        _taxString = cartSummaryResponse.tax;
        _shippingCostString = cartSummaryResponse.shipping_cost;
        _discountString = cartSummaryResponse.discount;
        _totalString = cartSummaryResponse.grand_total;
        _grandTotalValue =
            cartSummaryResponse.grand_total_value; // Crucial update
        _used_coupon_code =
            cartSummaryResponse.coupon_code ?? _used_coupon_code;
        _couponController.text = _used_coupon_code;
        _coupon_applied = cartSummaryResponse.coupon_applied;
      });
    }
  }

  reset() {
    _paymentTypeList.clear();
    _isInitial = true;
    _selected_payment_method_index = 0;
    _selected_payment_method = "";
    _selected_payment_method_key = "";
    setState(() {});

    reset_summary();
  }

  reset_summary() {
    _totalString = ". . .";
    _grandTotalValue = 0.00;
    _subTotalString = ". . .";
    _taxString = ". . .";
    _shippingCostString = ". . .";
    _discountString = ". . .";
    _used_coupon_code = "";
    _couponController.text = _used_coupon_code;
    _coupon_applied = false;

    setState(() {});
  }

  Future<void> _onRefresh() async {
    reset();
    await fetchAll(); // Use await to ensure data is fetched before refresh completes
  }

  onPopped(value) {
    fetchAll();
  }

  onCouponApply() async {
    var couponCode = _couponController.text.toString();
    if (couponCode == "") {
      ToastComponent.showDialog(
        AppLocalizations.of(context)!.enter_coupon_code,
      );
      return;
    }

    var couponApplyResponse =
        await CouponRepository().getCouponApplyResponse(couponCode);
    if (couponApplyResponse.result == false) {
      ToastComponent.showDialog(
        couponApplyResponse.message,
      );
      return;
    }

    reset_summary();
    await fetchSummary(); // Await to ensure summary is updated before continuing
  }

  onCouponRemove() async {
    var couponRemoveResponse =
        await CouponRepository().getCouponRemoveResponse();

    if (couponRemoveResponse.result == false) {
      ToastComponent.showDialog(
        couponRemoveResponse.message,
      );
      return;
    }

    reset_summary();
    await fetchSummary(); // Await to ensure summary is updated before continuing
  }

  // onPressPlaceOrderOrProceed() async {
  //   if (guest_checkout_status.$ && !is_logged_in.$) {
  //     Loading.show(context);
  //     // guest checkout user create response
  //     var guestUserAccountCreateResponse = await GuestCheckoutRepository()
  //         .guestUserAccountCreate(widget.guestCheckOutShippingAddress);
  //     Loading.close();

  //     // after creating guest user save to auth helper
  //     AuthHelper().setUserData(guestUserAccountCreateResponse);

  //     if (!guestUserAccountCreateResponse.result!) {
  //       ToastComponent.showDialog(
  //         LangText(context).local.already_have_account,
  //       );

  //       // if user not created
  //       // or any issue occurred
  //       // then it goes to guest check address page
  //       Navigator.pushAndRemoveUntil(OneContext().context!,
  //           MaterialPageRoute(builder: (context) {
  //         return GuestCheckoutAddress();
  //       }), (Route<dynamic> route) => true);
  //     }
  //     return;
  //   }

  //   if (_selected_payment_method == "") {
  //     ToastComponent.showDialog(
  //       AppLocalizations.of(context)!.please_choose_one_option_to_pay,
  //     );
  //     return;
  //   }

  onPressPlaceOrderOrProceed() async {
    if (guest_checkout_status.$ && !is_logged_in.$) {
      Loading.show(context);
      // guest checkout user create response
      var guestUserAccountCreateResponse = await GuestCheckoutRepository()
          .guestUserAccountCreate(widget.guestCheckOutShippingAddress);
      Loading.close();

      // after creating guest user save to auth helper
      AuthHelper().setUserData(guestUserAccountCreateResponse);

      if (!guestUserAccountCreateResponse.result!) {
        ToastComponent.showDialog(
          LangText(context).local.already_have_account,
        );

        // if user not created
        // or any issue occurred
        // then it goes to guest check address page
        Navigator.pushAndRemoveUntil(OneContext().context!,
            MaterialPageRoute(builder: (context) {
          return GuestCheckoutAddress();
        }), (Route<dynamic> route) => true);
        // Return ONLY if the guest account creation fails.
        return;
      }
      // Do not return here, allow the function to proceed to payment.
    }

    if (_selected_payment_method == "") {
      ToastComponent.showDialog(
        AppLocalizations.of(context)!.please_choose_one_option_to_pay,
      );
      return;
    }
    // This is the crucial check. Ensure _grandTotalValue is accurate.
    // The previous changes ensure _grandTotalValue is updated correctly.
    if (_grandTotalValue == null || _grandTotalValue! <= 0.00) {
      ToastComponent.showDialog(
        AppLocalizations.of(context)!.nothing_to_pay,
      );
      return;
    }

    if (_selected_payment_method == "bkash") {
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return BkashScreen(
          amount: _grandTotalValue,
          payment_type: payment_type,
          payment_method_key: _selected_payment_method_key,
          package_id: widget.packageId.toString(),
          orderId: widget.order_id,
        );
      })).then((value) {
        onPopped(value);
      });
    }
    if (_selected_payment_method == "stripe") {
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return StripeScreen(
          amount: _grandTotalValue,
          payment_type: payment_type,
          payment_method_key: _selected_payment_method_key,
          package_id: widget.packageId.toString(),
          orderId: widget.order_id,
        );
      })).then((value) {
        onPopped(value);
      });
    }
    if (_selected_payment_method == "aamarpay") {
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return AmarpayScreen(
          amount: _grandTotalValue,
          payment_type: payment_type,
          payment_method_key: _selected_payment_method_key,
          package_id: widget.packageId.toString(),
          orderId: widget.order_id,
        );
      })).then((value) {
        onPopped(value);
      });
    } else if (_selected_payment_method == "paypal") {
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return PaypalScreen(
          amount: _grandTotalValue,
          payment_type: payment_type,
          payment_method_key: _selected_payment_method_key,
          package_id: widget.packageId.toString(),
          orderId: widget.order_id,
        );
      })).then((value) {
        onPopped(value);
      });
    } else if (_selected_payment_method == "razorpay") {
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return RazorpayScreen(
          amount: _grandTotalValue,
          payment_type: payment_type,
          payment_method_key: _selected_payment_method_key,
          package_id: widget.packageId.toString(),
          orderId: widget.order_id,
        );
      })).then((value) {
        onPopped(value);
      });
    } else if (_selected_payment_method == "paystack") {
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return PaystackScreen(
          amount: _grandTotalValue,
          payment_type: payment_type,
          payment_method_key: _selected_payment_method_key,
          package_id: widget.packageId.toString(),
          orderId: widget.order_id,
        );
      })).then((value) {
        onPopped(value);
      });
    } else if (_selected_payment_method == "iyzico") {
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return IyzicoScreen(
          amount: _grandTotalValue,
          payment_type: payment_type,
          payment_method_key: _selected_payment_method_key,
          package_id: widget.packageId.toString(),
          orderId: widget.order_id,
        );
      })).then((value) {
        onPopped(value);
      });
    } else if (_selected_payment_method == "iyzico") {
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return MyFatooraScreen(
          amount: _grandTotalValue,
          payment_type: payment_type,
          payment_method_key: _selected_payment_method_key,
          package_id: widget.packageId.toString(),
          orderId: widget.order_id,
        );
      })).then((value) {
        onPopped(value);
      });
    }
    if (_selected_payment_method == "cybersource") {
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return CybersourceScreen(
          amount: _grandTotalValue,
          payment_type: payment_type,
          payment_method_key: _selected_payment_method_key,
          package_id: widget.packageId.toString(),
          orderId: widget.order_id,
        );
      })).then((value) {
        onPopped(value);
      });
    } else if (_selected_payment_method == "bkash") {
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return BkashScreen(
          amount: _grandTotalValue,
          payment_type: payment_type,
          payment_method_key: _selected_payment_method_key,
          package_id: widget.packageId.toString(),
          orderId: widget.order_id,
        );
      })).then((value) {
        onPopped(value);
      });
    } else if (_selected_payment_method == "nagad") {
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return NagadScreen(
          amount: _grandTotalValue,
          payment_type: payment_type,
          payment_method_key: _selected_payment_method_key,
          package_id: widget.packageId.toString(),
          orderId: widget.order_id,
        );
      })).then((value) {
        onPopped(value);
      });
    } else if (_selected_payment_method == "sslcommerz") {
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return SslCommerzScreen(
          amount: _grandTotalValue,
          payment_type: payment_type,
          payment_method_key: _selected_payment_method_key,
          package_id: widget.packageId.toString(),
          orderId: widget.order_id,
        );
      })).then((value) {
        onPopped(value);
      });
    } else if (_selected_payment_method == "flutterwave") {
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return FlutterwaveScreen(
          amount: _grandTotalValue,
          payment_type: payment_type,
          payment_method_key: _selected_payment_method_key,
          package_id: widget.packageId.toString(),
          orderId: widget.order_id,
        );
      })).then((value) {
        onPopped(value);
      });
    }

    else if (_selected_payment_method == "paytm") {
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return PaytmScreen(
          amount: _grandTotalValue,
          payment_type: payment_type,
          payment_method_key: _selected_payment_method_key,
          package_id: widget.packageId.toString(),
          orderId: widget.order_id,
        );
      })).then((value) {
        onPopped(value);
      });
    } else if (_selected_payment_method == "khalti") {
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return KhaltiScreen(
          amount: _grandTotalValue,
          payment_type: payment_type,
          payment_method_key: _selected_payment_method_key,
          package_id: widget.packageId.toString(),
          orderId: widget.order_id,
        );
      })).then((value) {
        onPopped(value);
      });
    } else if (_selected_payment_method == "instamojo") {
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return OnlinePay(
          title: LangText(context).local.pay_with_instamojo,
          amount: _grandTotalValue,
          payment_type: payment_type,
          payment_method_key: _selected_payment_method_key,
          package_id: widget.packageId.toString(),
          orderId: widget.order_id,
        );
      })).then((value) {
        onPopped(value);
      });
    } else if (_selected_payment_method == "payfast") {
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return PayfastScreen(
          amount: _grandTotalValue,
          payment_type: payment_type,
          payment_method_key: _selected_payment_method_key,
          package_id: widget.packageId.toString(),
          orderId: widget.order_id,
        );
      })).then((value) {
        onPopped(value);
      });
    } else if (_selected_payment_method == "paytr") {
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return PaytrScreen(
          amount: _grandTotalValue,
          payment_type: payment_type,
          payment_method_key: _selected_payment_method_key,
          package_id: widget.packageId.toString(),
          orderId: widget.order_id,
        );
      })).then((value) {
        onPopped(value);
      });
    }
    // else if (_selected_payment_method == "phonepe") {
    //   Navigator.push(context, MaterialPageRoute(builder: (context) {
    //     return PhonePeScreen(
    //       amount: _grandTotalValue,
    //       payment_type: payment_type,
    //       payment_method_key: _selected_payment_method_key,
    //       package_id: widget.packageId.toString(),
    //      // orderId: widget.order_id,
    //     );
    //   })).then((value) {
    //     onPopped(value);
    //   });
    // }
    else if (_selected_payment_method == "wallet_system") {
      pay_by_wallet();
    } else if (_selected_payment_method == "cash_payment") {
      pay_by_cod();
    } else if (_selected_payment_method == "manual_payment" &&
        widget.paymentFor == PaymentFor.Order) {
      pay_by_manual_payment();
    } else if (_selected_payment_method == "manual_payment" &&
        (widget.paymentFor == PaymentFor.ManualPayment ||
            widget.paymentFor == PaymentFor.WalletRecharge ||
            widget.paymentFor == PaymentFor.PackagePay)) {
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return OfflineScreen(
          order_id: widget.order_id,
          paymentInstruction:
              _paymentTypeList[_selected_payment_method_index].details,
          offline_payment_id: _paymentTypeList[_selected_payment_method_index]
              .offline_payment_id,
          rechargeAmount: widget.rechargeAmount,
          offLinePaymentFor: widget.paymentFor,
          paymentMethod: _paymentTypeList[_selected_payment_method_index].name,
          packageId: widget.packageId,
        );
      })).then((value) {
        onPopped(value);
      });
    }
  }

  pay_by_wallet() async {
    loading();
    var orderCreateResponse = await PaymentRepository()
        .getOrderCreateResponseFromWallet(
            _selected_payment_method_key, _grandTotalValue);
    Navigator.of(loadingcontext).pop();

    if (orderCreateResponse.result == false) {
      ToastComponent.showDialog(
        orderCreateResponse.message,
      );
      return;
    }

    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return OrderList(from_checkout: true);
    }));
  }

  pay_by_cod() async {
    loading();
    var orderCreateResponse = await PaymentRepository()
        .getOrderCreateResponseFromCod(_selected_payment_method_key);
    Navigator.of(loadingcontext).pop();
    if (orderCreateResponse.result == false) {
      ToastComponent.showDialog(
        orderCreateResponse.message,
      );
      Navigator.of(context).pop();
      return;
    }

    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return OrderList(from_checkout: true);
    }));
  }

  pay_by_manual_payment() async {
    loading();
    var orderCreateResponse = await PaymentRepository()
        .getOrderCreateResponseFromManualPayment(_selected_payment_method_key);
    Navigator.pop(loadingcontext);
    if (orderCreateResponse.result == false) {
      ToastComponent.showDialog(
        orderCreateResponse.message,
      );
      Navigator.of(context).pop();
      return;
    }

    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return OrderList(from_checkout: true);
    }));
  }

  onPaymentMethodItemTap(index) {
    if (_selected_payment_method_key !=
        _paymentTypeList[index].payment_type_key) {
      setState(() {
        _selected_payment_method_index = index;
        _selected_payment_method = _paymentTypeList[index].payment_type;
        _selected_payment_method_key = _paymentTypeList[index].payment_type_key;
      });
    }
  }

  onPressDetails() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.receipt_long,
              color: MyTheme.accent_color,
              size: 24,
            ),
            SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)!.order_details_ucf,
              style: TextStyle(
                color: MyTheme.dark_font_grey,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        contentPadding: EdgeInsets.fromLTRB(24, 16, 24, 0),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow(
                AppLocalizations.of(context)!.subtotal_all_capital,
                SystemConfig.systemCurrency != null
                    ? (_subTotalString ?? ". . .").replaceAll(
                        SystemConfig.systemCurrency!.code!,
                        SystemConfig.systemCurrency!.symbol!)
                    : (_subTotalString ?? ". . ."),
                Icons.shopping_cart_outlined,
                false,
              ),
              SizedBox(height: 12),
              _buildDetailRow(
                AppLocalizations.of(context)!.tax_all_capital,
                SystemConfig.systemCurrency != null
                    ? (_taxString ?? "0.00TRY").replaceAll(
                        SystemConfig.systemCurrency!.code!,
                        SystemConfig.systemCurrency!.symbol!)
                    : (_taxString ?? "0.00"),
                Icons.account_balance_outlined,
                false,
              ),
              SizedBox(height: 12),
              _buildDetailRow(
                AppLocalizations.of(context)!.shipping_cost_all_capital,
                SystemConfig.systemCurrency != null
                    ? (_shippingCostString).replaceAll(
                        SystemConfig.systemCurrency!.code!,
                        SystemConfig.systemCurrency!.symbol!)
                    : _shippingCostString,
                Icons.local_shipping_outlined,
                false,
              ),
              SizedBox(height: 12),
              _buildDetailRow(
                AppLocalizations.of(context)!.discount_all_capital,
                SystemConfig.systemCurrency != null
                    ? (_discountString ?? ". . .").replaceAll(
                        SystemConfig.systemCurrency!.code!,
                        SystemConfig.systemCurrency!.symbol!)
                    : (_discountString ?? ". . ."),
                Icons.discount_outlined,
                false,
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: MyTheme.accent_color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: MyTheme.accent_color.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: _buildDetailRow(
                  AppLocalizations.of(context)!.grand_total_all_capital,
                  SystemConfig.systemCurrency != null
                      ? (_totalString ?? ". . .").replaceAll(
                          SystemConfig.systemCurrency!.code!,
                          SystemConfig.systemCurrency!.symbol!)
                      : (_totalString ?? ". . ."),
                  Icons.account_balance_wallet_outlined,
                  true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(24, 8, 24, 5),
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: MyTheme.accent_color,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                AppLocalizations.of(context)!.close_all_lower,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, bool isTotal) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isTotal 
                ? MyTheme.accent_color.withOpacity(0.2)
                : MyTheme.font_grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 16,
            color: isTotal ? MyTheme.accent_color : MyTheme.font_grey,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: isTotal ? MyTheme.accent_color : MyTheme.font_grey,
              fontSize: 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isTotal ? MyTheme.accent_color : MyTheme.font_grey,
            fontSize: 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
          app_language_rtl.$! ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: MyTheme.mainColor,
        appBar: buildAppBar(context),
        bottomNavigationBar: buildBottomAppBar(context),
        body: Stack(
          children: [
            RefreshIndicator(
              color: MyTheme.accent_color,
              backgroundColor: Colors.white,
              onRefresh: _onRefresh,
              displacement: 0,
              child: CustomScrollView(
                controller: _mainScrollController,
                physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics()),
                slivers: [
                  SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: buildPaymentMethodList(),
                        ),
                        Container(
                          height: 140,
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),

            //Apply Coupon and order details container
            Align(
              alignment: Alignment.bottomCenter,
              child: widget.paymentFor == PaymentFor.WalletRecharge ||
                      widget.paymentFor == PaymentFor.PackagePay
                  ? SizedBox.shrink()
                  : Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                      ),
                      height: (widget.paymentFor == PaymentFor.ManualPayment) ||
                              (widget.paymentFor == PaymentFor.OrderRePayment)
                          ? 80
                          : 140,
                      //color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            widget.paymentFor == PaymentFor.Order
                                ? Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 16.0),
                                    child: buildApplyCouponRow(context),
                                  )
                                : SizedBox.shrink(),
                            grandTotalSection(),
                          ],
                        ),
                      ),
                    ),
            )
          ],
        ),
      ),
    );
  }

  Row buildApplyCouponRow(BuildContext context) {
    return Row(
      children: [
        Form(
          key: _formKey,
          child: SizedBox(
            height: 42,
            width: (MediaQuery.of(context).size.width - 32) * (2 / 3),
            child: TextFormField(
              controller: _couponController,
              readOnly: _coupon_applied!,
              autofocus: false,
              decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.enter_coupon_code,
                  hintStyle:
                      TextStyle(fontSize: 14.0, color: MyTheme.textfield_grey),
                  enabledBorder: app_language_rtl.$!
                      ? OutlineInputBorder(
                          borderSide: BorderSide(
                              color: MyTheme.textfield_grey, width: 0.5),
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(8.0),
                            bottomRight: Radius.circular(8.0),
                          ),
                        )
                      : OutlineInputBorder(
                          borderSide: BorderSide(
                              color: MyTheme.textfield_grey, width: 0.5),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8.0),
                            bottomLeft: Radius.circular(8.0),
                          ),
                        ),
                  focusedBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: MyTheme.medium_grey, width: 0.5),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8.0),
                      bottomLeft: Radius.circular(8.0),
                    ),
                  ),
                  contentPadding: EdgeInsets.only(left: 16.0)),
            ),
          ),
        ),
        !_coupon_applied!
            ? SizedBox(
                width: (MediaQuery.of(context).size.width - 32) * (1 / 3),
                height: 42,
                child: Btn.basic(
                  minWidth: MediaQuery.of(context).size.width,
                  color: MyTheme.accent_color,
                  shape: app_language_rtl.$!
                      ? RoundedRectangleBorder(
                          borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8.0),
                          bottomLeft: Radius.circular(8.0),
                        ))
                      : RoundedRectangleBorder(
                          borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(8.0),
                          bottomRight: Radius.circular(8.0),
                        )),
                  child: Text(
                    AppLocalizations.of(context)!.apply_coupon_all_capital,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                  onPressed: () {
                    onCouponApply();
                  },
                ),
              )
            : SizedBox(
                width: (MediaQuery.of(context).size.width - 32) * (1 / 3),
                height: 42,
                child: Btn.basic(
                  minWidth: MediaQuery.of(context).size.width,
                  color: MyTheme.accent_color,
                  shape: RoundedRectangleBorder(
                      borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(8.0),
                    bottomRight: Radius.circular(8.0),
                  )),
                  child: Text(
                    AppLocalizations.of(context)!.remove_ucf,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                  onPressed: () {
                    onCouponRemove();
                  },
                ),
              )
      ],
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: MyTheme.mainColor,
      scrolledUnderElevation: 0.0,
      centerTitle: true,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(CupertinoIcons.arrow_left, color: MyTheme.dark_grey),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      title: Text(
        widget.title!, // Use widget.title as it's passed in the constructor
        style: TextStyle(fontSize: 16, color: MyTheme.accent_color),
      ),
      elevation: 0.0,
      titleSpacing: 0,
    );
  }

  buildPaymentMethodList() {
    if (_isInitial && _paymentTypeList.isEmpty) {
      return SingleChildScrollView(
          child: ShimmerHelper()
              .buildListShimmer(item_count: 5, item_height: 100.0));
    } else if (_paymentTypeList.isNotEmpty) {
      return SingleChildScrollView(
        child: ListView.separated(
          separatorBuilder: (context, index) {
            return SizedBox(
              height: 16,
            );
          },
          itemCount: _paymentTypeList.length,
          scrollDirection: Axis.vertical,
          physics: NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 0.0),
              child: buildPaymentMethodItemCard(index),
            );
          },
        ),
      );
    } else if (!_isInitial && _paymentTypeList.isEmpty) {
      return SizedBox(
          height: 100,
          child: Center(
              child: Text(
            AppLocalizations.of(context)!.no_payment_method_is_added,
            style: TextStyle(color: MyTheme.font_grey),
          )));
    }
  }

/////Method card paypal,Strip,Bkash,etc//////////
  GestureDetector buildPaymentMethodItemCard(index) {
    return GestureDetector(
      onTap: () {
        onPaymentMethodItemTap(index);
      },
      child: Stack(
        children: [
          AnimatedContainer(
            duration: Duration(milliseconds: 400),
            decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(6))
                .copyWith(
                    border: Border.all(
                        color: _selected_payment_method_key ==
                                _paymentTypeList[index].payment_type_key
                            ? MyTheme.accent_color
                            : MyTheme.light_grey,
                        width: _selected_payment_method_key ==
                                _paymentTypeList[index].payment_type_key
                            ? 2.0
                            : 0.0)),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  SizedBox(
                      width: 100,
                      height: 70,
                      child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child:
                              /*Image.asset(
                          _paymentTypeList[index].image,
                          fit: BoxFit.fitWidth,
                        ),*/
                              FadeInImage.assetNetwork(
                            placeholder: 'assets/placeholder.png',
                            image: _paymentTypeList[index].payment_type ==
                                    "manual_payment"
                                ? _paymentTypeList[index].image
                                : _paymentTypeList[index].image,
                            fit: BoxFit.fitWidth,
                          ))),
                  SizedBox(
                    width: 150,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: Text(
                            _paymentTypeList[index].title,
                            textAlign: TextAlign.left,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                            style: TextStyle(
                                color: MyTheme.font_grey,
                                fontSize: 14,
                                height: 1.6,
                                fontWeight: FontWeight.w400),
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
          ),
          Positioned(
            right: 16,
            top: 16,
            child: buildPaymentMethodCheckContainer(
                _selected_payment_method_key ==
                    _paymentTypeList[index].payment_type_key),
          )
        ],
      ),
    );
  }

  Widget buildPaymentMethodCheckContainer(bool check) {
    return AnimatedOpacity(
      duration: Duration(milliseconds: 400),
      opacity: check ? 1 : 0,
      child: Container(
        height: 16,
        width: 16,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.0), color: Colors.green),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Icon(Icons.check, color: Colors.white, size: 10),
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
        top: 10,
        bottom: hasSystemNavBar ? bottomPadding + 10 : 10,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: MyTheme.accent_color,
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              onPressPlaceOrderOrProceed();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MyTheme.accent_color,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
            child: Text(
              widget.paymentFor == PaymentFor.WalletRecharge
                  ? AppLocalizations.of(context)!.recharge_wallet_ucf
                  : widget.paymentFor == PaymentFor.ManualPayment
                      ? AppLocalizations.of(context)!.proceed_all_caps
                      : widget.paymentFor == PaymentFor.PackagePay
                          ? AppLocalizations.of(context)!.buy_package_ucf
                          : AppLocalizations.of(context)!
                              .place_my_order_all_capital,
              style: TextStyle(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }

  Widget grandTotalSection() {
    return Container(
      height: 40,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        color: MyTheme.soft_accent_color,
      ),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Text(
                AppLocalizations.of(context)!.total_amount_ucf,
                style: TextStyle(color: MyTheme.font_grey, fontSize: 14),
              ),
            ),
            Visibility(
              visible: widget.paymentFor != PaymentFor.ManualPayment,
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: InkWell(
                  onTap: () {
                    onPressDetails();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: MyTheme.accent_color.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.see_details_all_lower,
                      style: TextStyle(
                        color: MyTheme.accent_color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Spacer(),
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(balance(),
                  style: TextStyle(
                      color: MyTheme.accent_color,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  loading() {
    showDialog(
      context: context,
      builder: (context) {
        loadingcontext = context;
        return AlertDialog(
            content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(
              width: 10,
            ),
            Text(AppLocalizations.of(context)!.please_wait_ucf),
          ],
        ));
      },
    );
  }
}
