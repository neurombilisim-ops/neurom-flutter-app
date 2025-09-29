import 'package:neurom_bilisim_store/custom/lang_text.dart';
import 'package:neurom_bilisim_store/custom/useful_elements.dart';
import 'package:neurom_bilisim_store/helpers/shared_value_helper.dart';
import 'package:neurom_bilisim_store/helpers/shimmer_helper.dart';
import 'package:neurom_bilisim_store/my_theme.dart';
import 'package:neurom_bilisim_store/repositories/chat_repository.dart';
import 'package:neurom_bilisim_store/screens/chat/chat.dart';
import 'package:flutter/material.dart';
import 'package:neurom_bilisim_store/l10n/app_localizations.dart';

class MessengerList extends StatefulWidget {
  const MessengerList({super.key});

  @override
  _MessengerListState createState() => _MessengerListState();
}

class _MessengerListState extends State<MessengerList> {
  final ScrollController _xcrollController = ScrollController();

  final List<dynamic> _list = [];
  bool _isInitial = true;
  int _page = 1;
  int? _totalData = 0;
  bool _showLoadingContainer = false;

  @override
  void initState() {
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

  fetchData() async {
    var conversatonResponse = await ChatRepository().getConversationResponse(
      page: _page,
    );
    _list.addAll(conversatonResponse.conversation_item_list);
    _isInitial = false;
    _totalData = conversatonResponse.meta.total;
    _showLoadingContainer = false;
    setState(() {});
  }

  reset() {
    _list.clear();
    _isInitial = true;
    _totalData = 0;
    _page = 1;
    _showLoadingContainer = false;
    setState(() {});
  }

  Future<void> _onRefresh() async {
    reset();
    fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
          app_language_rtl.$! ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: buildAppBar(context),
        body: Stack(
          children: [
            RefreshIndicator(
              color: MyTheme.accent_color,
              backgroundColor: Colors.white,
              onRefresh: _onRefresh,
              displacement: 0,
              child: CustomScrollView(
                controller: _xcrollController,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        buildMessengerList(),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
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
      height: _showLoadingContainer ? 60 : 0,
      width: double.infinity,
      color: Colors.grey[50],
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: 0,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(MyTheme.accent_color),
                ),
              ),
              SizedBox(width: 12),
              Text(
                _totalData == _list.length
                    ? 'Tüm mesajlar yüklendi'
                    : 'Daha fazla yükleniyor...',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      scrolledUnderElevation: 0.0,
      centerTitle: false,
      elevation: 0,
      leading: Builder(
        builder: (context) => Container(
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
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.messages_ucf,
            style: TextStyle(
              fontSize: 24,
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Mesajlarınız',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      titleSpacing: 0,
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Container(
          height: 1,
          color: Colors.grey[200],
        ),
      ),
    );
  }

  buildMessengerList() {
    if (_isInitial && _list.isEmpty) {
      return SingleChildScrollView(
        child: ShimmerHelper().buildListShimmer(
          item_count: 10,
          item_height: 100.0,
        ),
      );
    } else if (_list.isNotEmpty) {
      return ListView.builder(
        itemCount: _list.length,
        scrollDirection: Axis.vertical,
        padding: EdgeInsets.all(0.0),
        physics: NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: buildMessengerItemCard(index),
          );
        },
      );
    } else if (_totalData == 0) {
      return Container(
        height: 400,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline,
                size: 48,
                color: Colors.grey[400],
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Henüz mesajınız yok',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Satıcılarla konuşmaya başlayın',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(); // should never be happening
    }
  }

  buildMessengerItemCard(index) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return Chat(
                conversation_id: _list[index].id,
                messenger_name: _list[index].shop_name,
                messenger_title: _list[index].title,
                messenger_image: _list[index].shop_logo,
              );
            },
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 0,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Logo
            Container(
              width: 150,
              height: 60,
              child: _list[index].shop_logo != null && _list[index].shop_logo.isNotEmpty
                  ? FadeInImage.assetNetwork(
                      placeholder: 'assets/placeholder.png',
                      image: _list[index].shop_logo,
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
            SizedBox(width: 16),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _list[index].shop_name ?? 'Satıcı',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: MyTheme.accent_color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Yeni',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: MyTheme.accent_color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    _list[index].title ?? 'Mesaj',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey[400],
                      ),
                      SizedBox(width: 4),
                      Text(
                        '2 saat önce',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[400],
                        ),
                      ),
                      Spacer(),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

