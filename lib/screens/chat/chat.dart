import 'dart:async';

import 'package:neurom_bilisim_store/custom/device_info.dart';
import 'package:neurom_bilisim_store/custom/useful_elements.dart';
import 'package:neurom_bilisim_store/helpers/shared_value_helper.dart';
import 'package:neurom_bilisim_store/helpers/shimmer_helper.dart';
import 'package:neurom_bilisim_store/my_theme.dart';
import 'package:neurom_bilisim_store/repositories/chat_repository.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart';
import 'package:neurom_bilisim_store/l10n/app_localizations.dart';
import 'package:intl/intl.dart' as intl;
import 'package:shimmer/shimmer.dart';

class Chat extends StatefulWidget {
  const Chat({
    super.key,
    this.conversation_id,
    this.messenger_name,
    this.messenger_title,
    this.messenger_image,
  });

  final int? conversation_id;
  final String? messenger_name;
  final String? messenger_title;
  final String? messenger_image;

  @override
  _ChatState createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  final TextEditingController _chatTextController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  final ScrollController _xcrollController = ScrollController();
  final lastKey = GlobalKey();

  var uid = user_id;

  List<dynamic> _list = [];
  bool _isInitial = true;
  int _page = 1;
  int _totalData = 0;
  bool _showLoadingContainer = false;
  int? _last_id = 0;
  Timer? timer;
  final String _message = "";
  bool _isSendingMessage = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    fetchData();
    
    // Text field değişikliklerini dinle
    _chatTextController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _chatTextController.dispose();
    super.dispose();
  }

  fetchData() async {
    var messageResponse = await ChatRepository().getMessageResponse(
      conversation_id: widget.conversation_id,
      page: _page,
    );
    _list.addAll(messageResponse.data);
    _isInitial = false;
    _showLoadingContainer = false;
    _last_id = _list[0].id;
    setState(() {});

    fetch_new_message();
  }

  reset() {
    _list.clear();
    _isInitial = true;
    _totalData = 0;
    _page = 1;
    _showLoadingContainer = false;
    _last_id = 0;
    setState(() {});
  }

  Future<void> _onRefresh() async {
    reset();
    fetchData();
  }

  onPressLoadMore() {
    setState(() {
      _page++;
    });
    _showLoadingContainer = true;
    fetchData();
  }

  onTapSendMessage() async {
    if (_isSendingMessage) return; // Zaten gönderiliyorsa tekrar gönderme
    
    var chatText = _chatTextController.text.trim();
    if (chatText.isEmpty) return; // Boş mesaj gönderme
    
    setState(() {
      _isSendingMessage = true;
    });
    
    _chatTextController.clear(); // Text'i hemen temizle
    
    try {
      final DateTime now = DateTime.now();
      final intl.DateFormat dateFormatter = intl.DateFormat('yyyy-MM-dd');
      final intl.DateFormat timeFormatter = intl.DateFormat('hh:ss');
      final String formattedDate = dateFormatter.format(now);
      final String formattedTime = timeFormatter.format(now);

      var messageResponse = await ChatRepository().getInserMessageResponse(
        conversation_id: widget.conversation_id,
        message: chatText,
      );
      
      if (messageResponse.result == true) {
        _list = [messageResponse.data, _list].expand((x) => x).toList(); //prepend
        _last_id = _list[0].id;
        
        // Mesaj gönderildikten sonra hemen yeni mesajları çek
        Future.delayed(Duration(milliseconds: 500), () {
          get_new_message();
        });
      }
    } catch (e) {
      print("Mesaj gönderme hatası: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isSendingMessage = false;
        });
      }
    }
  }

  fetch_new_message() async {
    await Future.delayed(const Duration(seconds: 3), () { // 3 saniyeye düşürdük
      get_new_message();
    }).then((value) {
      fetch_new_message();
    });
  }

  get_new_message() async {
    try {
      var messageResponse = await ChatRepository().getNewMessageResponse(
        conversation_id: widget.conversation_id,
        last_message_id: _last_id,
      );

      if (messageResponse.data != null && messageResponse.data.isNotEmpty) {
        _list = [messageResponse.data, _list].expand((x) => x).toList(); //prepend
        _last_id = _list[0].id;

        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      print("Yeni mesaj çekme hatası: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
          app_language_rtl.$! ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: buildAppBar2(context),
        body: Stack(
          children: [
            !_isInitial ? conversations() : chatShimmer(),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: typeSmsSection(),
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
          _totalData == _list.length
              ? AppLocalizations.of(context)!.no_more_items_ucf
              : AppLocalizations.of(context)!.loading_more_items_ucf,
        ),
      ),
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: MyTheme.mainColor,
      toolbarHeight: 75,
      leading: Builder(
        builder:
            (context) => IconButton(
              icon: Icon(CupertinoIcons.arrow_left, color: MyTheme.dark_grey),
              onPressed: () => Navigator.of(context).pop(),
            ),
      ),
      title: Container(
        child: SizedBox(
          width: 350,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(35),
                  border: Border.all(
                    color: Color.fromRGBO(112, 112, 112, .3),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(35),
                  child: FadeInImage.assetNetwork(
                    placeholder: 'assets/placeholder.png',
                    image: widget.messenger_image!,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              SizedBox(
                width: 220,
                child: Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.messenger_name!,
                        textAlign: TextAlign.left,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        style: TextStyle(
                          color: MyTheme.font_grey,
                          fontSize: 14,
                          height: 1.6,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        widget.messenger_title!,
                        textAlign: TextAlign.left,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                          color: MyTheme.medium_grey,
                          fontSize: 12,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Spacer(),
              InkWell(
                onTap: () {
                  _onRefresh();
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(Icons.rotate_left, color: MyTheme.font_grey),
                ),
              ),
            ],
          ),
        ),
      ),
      elevation: 0.0,
      titleSpacing: 0,
    );
  }

  AppBar buildAppBar2(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      centerTitle: false,
      scrolledUnderElevation: 0.0,
      elevation: 0,
      leading: Container(
        margin: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      title: Row(
        children: [
          Container(
            width: 150,
            height: 60,
            child: widget.messenger_image != null && widget.messenger_image!.isNotEmpty
                ? FadeInImage.assetNetwork(
                    placeholder: 'assets/placeholder.png',
                    image: widget.messenger_image!,
                    fit: BoxFit.contain,
                    imageErrorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: MyTheme.accent_color.withOpacity(0.1),
                        child: Icon(
                          Icons.store,
                          color: MyTheme.accent_color,
                          size: 32,
                        ),
                      );
                    },
                  )
                : Container(
                    color: MyTheme.accent_color.withOpacity(0.1),
                    child: Icon(
                      Icons.store,
                      color: MyTheme.accent_color,
                      size: 32,
                    ),
                  ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.messenger_name ?? 'Satıcı',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  widget.messenger_title ?? 'Mesaj',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              _onRefresh();
            },
            icon: Icon(
              Icons.refresh,
              color: Colors.grey[600],
              size: 20,
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Container(
          height: 1,
          color: Colors.grey[200],
        ),
      ),
    );
  }

  buildChatList() {
    if (_isInitial && _list.isEmpty) {
      return SingleChildScrollView(
        child: ShimmerHelper().buildListShimmer(
          item_count: 10,
          item_height: 100.0,
        ),
      );
    } else if (_list.isNotEmpty) {
      return SingleChildScrollView(
        child: ListView.builder(
          key: lastKey,
          controller: _chatScrollController,
          itemCount: _list.length,
          scrollDirection: Axis.vertical,
          physics: NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          reverse: true,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: buildChatItem(index),
            );
          },
        ),
      );
    } else if (_totalData == 0) {
      return Center(
        child: Text(AppLocalizations.of(context)!.no_data_is_available),
      );
    } else {
      return Container();
    }
  }

  buildChatItem(index) {
    return _list[index].user_id == uid
        ? getSenderView(
          ChatBubbleClipper5(type: BubbleType.sendBubble),
          context,
          _list[index].message,
          _list[index].date,
          _list[index].time,
        )
        : getReceiverView(
          ChatBubbleClipper5(type: BubbleType.receiverBubble),
          context,
          _list[index].message,
          _list[index].date,
          _list[index].time,
        );
  }

  Row buildMessageSendingRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        SizedBox(
          height: 40,
          width: (MediaQuery.of(context).size.width - 32) * (4 / 5),
          child: TextField(
            autofocus: false,
            maxLines: null,
            controller: _chatTextController,
            decoration: InputDecoration(
              filled: true,
              fillColor: Color.fromRGBO(251, 251, 251, 1),
              hintText: AppLocalizations.of(context)!.type_your_message_here,
              hintStyle: TextStyle(
                fontSize: 14.0,
                color: MyTheme.textfield_grey,
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: MyTheme.textfield_grey,
                  width: 0.5,
                ),
                borderRadius: const BorderRadius.all(Radius.circular(35.0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: MyTheme.medium_grey, width: 0.5),
                borderRadius: const BorderRadius.all(Radius.circular(35.0)),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () {
              onTapSendMessage();
            },
            child: Container(
              width: 40,
              height: 40,
              margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
              decoration: BoxDecoration(
                color: MyTheme.accent_color,
                borderRadius: BorderRadius.circular(35),
                border: Border.all(
                  color: Color.fromRGBO(112, 112, 112, .3),
                  width: 1,
                ),
              ),
              child: Center(
                child: Icon(Icons.send, color: Colors.white, size: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  getSenderView(
    CustomClipper clipper,
    BuildContext context,
    String text,
    String date,
    String time,
  ) {
    return ChatBubble(
      elevation: 2.0,
      clipper: clipper,
      alignment: Alignment.topRight,
      margin: EdgeInsets.only(top: 10),
      backGroundColor: MyTheme.accent_color,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              text,
              style: TextStyle(
                color: Colors.white, 
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 4),
            Text(
              '$date $time',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7), 
                fontSize: 10,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  getReceiverView(
    CustomClipper clipper,
    BuildContext context,
    text,
    date,
    time,
  ) => ChatBubble(
    elevation: 2.0,
    clipper: clipper,
    backGroundColor: Colors.grey[100],
    margin: EdgeInsets.only(top: 10),
    child: Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.6,
        minWidth: MediaQuery.of(context).size.width * 0.6,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: Text(
              text,
              textAlign: TextAlign.left,
              style: TextStyle(
                color: Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ),
          SizedBox(height: 4),
          Text(
            date + " " + time,
            style: TextStyle(
              color: Colors.grey[600], 
              fontSize: 10,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    ),
  );

  conversations() {
    return SingleChildScrollView(
      reverse: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: 80),
        child: ListView.builder(
          reverse: true,
          itemCount: _list.length,
          shrinkWrap: true,
          padding: const EdgeInsets.only(top: 10, bottom: 10),
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            return Container(
              padding: const EdgeInsets.only(
                left: 14,
                right: 14,
                top: 10,
                bottom: 10,
              ),
              child: Column(
                children: [
                  (index == _list.length - 1) ||
                          _list[index].year != _list[index + 1].year ||
                          _list[index].month != _list[index + 1].month
                      ? UsefulElements().customContainer(
                        width: 100,
                        height: 20,
                        borderRadius: 5,
                        child: Text(
                          "${_list[index].date}",
                          style: const TextStyle(
                            fontSize: 8,
                            color: Color(0xff999999),
                          ),
                        ),
                      )
                      : Container(),
                  const SizedBox(height: 5),
                  Align(
                    alignment:
                        (_list[index].sendType == "customer"
                            ? Alignment.topRight
                            : Alignment.topLeft),
                    child: smsContainer(index),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Container smsContainer(int index) {
    return Container(
      constraints: BoxConstraints(
        minWidth: 80,
        maxWidth: DeviceInfo(context).width! / 1.6,
      ),
      padding: const EdgeInsets.only(top: 8, bottom: 3, right: 10, left: 10),
      decoration: BoxDecoration(
        border: Border.all(width: 1, color: MyTheme.noColor),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomLeft:
              _list[index].sendType == "customer"
                  ? Radius.circular(16)
                  : Radius.circular(0),
          bottomRight:
              _list[index].sendType == "customer"
                  ? Radius.circular(0)
                  : Radius.circular(16),
        ),
        color:
            (_list[index].sendType == "customer"
                ? const Color(0xffE62E04)
                : Colors.white),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.08),
            blurRadius: 20,
            spreadRadius: 0.0,
            offset: Offset(0.0, 10.0),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            bottom: 3,
            right: _list[index].sendType == "customer" ? 2 : 2,
            //left: _list[index].sendType == "customer" ? 2 : null,
            child: Text(
              _list[index].time.toString(),
              style: TextStyle(
                fontSize: 8,
                color:
                    (_list[index].sendType == "customer"
                        ? MyTheme.light_grey
                        : const Color(0xff707070)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 15.0),
            child: Text(
              " ${_list[index].message}",
              style: TextStyle(
                fontSize: 12,
                color:
                    (_list[index].sendType == "customer"
                        ? MyTheme.white
                        : Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget typeSmsSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: TextField(
                  controller: _chatTextController,
                  textAlign: TextAlign.start,
                  maxLines: 4,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: "Mesajınızı yazın...",
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ),
            SizedBox(width: 12),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    MyTheme.accent_color,
                    MyTheme.accent_color.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: MyTheme.accent_color.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 0,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: !_isSendingMessage && _chatTextController.text.trim().isNotEmpty
                      ? () {
                          onTapSendMessage();
                        }
                      : null,
                  child: _isSendingMessage
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                ),
              ),
            ),
          ],
        ),
    );
  }

  chatShimmer() {
    return SingleChildScrollView(
      reverse: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: 60),
        child: ListView.builder(
          reverse: true,
          itemCount: 10,
          shrinkWrap: true,
          padding: const EdgeInsets.only(top: 10, bottom: 10),
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            //print(_messages[index+1].year.toString());
            return Container(
              padding: const EdgeInsets.only(
                left: 14,
                right: 14,
                top: 10,
                bottom: 10,
              ),
              child: Align(
                alignment:
                    (index.isOdd ? Alignment.topRight : Alignment.topLeft),
                child: smsShimmer(index),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget smsShimmer(int index) {
    return Shimmer.fromColors(
      baseColor: MyTheme.shimmer_base,
      highlightColor: MyTheme.shimmer_highlighted,
      child: Container(
        constraints: BoxConstraints(
          minWidth: 150,
          maxWidth: DeviceInfo(context).width! / 1.6,
        ),
        padding: const EdgeInsets.only(top: 8, bottom: 3, right: 10, left: 10),
        decoration: BoxDecoration(
          border: Border.all(
            width: 1,
            color: index.isOdd ? MyTheme.accent_color : MyTheme.grey_153,
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: index.isOdd ? Radius.circular(16) : Radius.circular(0),
            bottomRight: index.isOdd ? Radius.circular(0) : Radius.circular(16),
          ),
          color: (index.isOdd ? MyTheme.accent_color : MyTheme.accent_color),
        ),
        child: Stack(
          children: [
            Positioned(
              bottom: 2,
              right: index.isOdd ? 2 : null,
              left: index.isOdd ? null : 2,
              child: Text(
                "    ",
                style: TextStyle(
                  fontSize: 8,
                  color: (index.isOdd ? MyTheme.light_grey : MyTheme.grey_153),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 15.0),
              child: Text(
                "    ",
                style: TextStyle(
                  fontSize: 12,
                  color: (index.isOdd ? MyTheme.white : Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
