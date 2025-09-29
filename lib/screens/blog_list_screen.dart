import 'package:neurom_bilisim_store/custom/device_info.dart';
import 'package:neurom_bilisim_store/custom/useful_elements.dart';
import 'package:neurom_bilisim_store/helpers/shimmer_helper.dart';
import 'package:neurom_bilisim_store/my_theme.dart';
import 'package:neurom_bilisim_store/providers/blog_provider.dart';
import 'package:neurom_bilisim_store/screens/blog_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:neurom_bilisim_store/l10n/app_localizations.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';

class BlogListScreen extends StatefulWidget {
  const BlogListScreen({super.key});

  @override
  State<BlogListScreen> createState() => _BlogListScreenState();
}

class _BlogListScreenState extends State<BlogListScreen> {
  bool _showSearchBar = false;
  final TextEditingController _searchController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context),
      body: buildBlogList(context),
      backgroundColor: MyTheme.mainColor,
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      scrolledUnderElevation: 0.0,
      backgroundColor: MyTheme.mainColor,
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(0.0),
        child: AnimatedContainer(
          //color: MyTheme.textfield_grey,
          duration: Duration(milliseconds: 500),
        ),
      ),
      title: buildAppBarTitle(context),
      elevation: 0.0,
      titleSpacing: 0,
    );
  }

  Widget buildAppBarTitle(BuildContext context) {
    return AnimatedCrossFade(
      firstChild: buildAppBarTitleOption(context),
      secondChild: buildAppBarSearchOption(context),
      firstCurve: Curves.fastOutSlowIn,
      secondCurve: Curves.fastOutSlowIn,
      crossFadeState:
          _showSearchBar ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      duration: Duration(milliseconds: 500),
    );
  }

  Container buildAppBarTitleOption(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 37),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: UsefulElements.backButton(context, color: "black"),
          ),
          Container(
            padding: EdgeInsets.only(left: 10),
            width: DeviceInfo(context).width! / 2,
            child: Text(
              AppLocalizations.of(context)!.all_blogs_ucf,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Spacer(),
          SizedBox(
            width: 20,
            child: GestureDetector(
              onTap: () {
                _showSearchBar = true;
                setState(() {});
              },
              child: Image.asset('assets/search.png'),
            ),
          ),
        ],
      ),
    );
  }

  Container buildAppBarSearchOption(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18),
      width: DeviceInfo(context).width,
      height: 40,
      child: TextField(
        controller: _searchController,
        onTap: () {},
        onChanged: (txt) {},
        onSubmitted: (txt) {},
        autofocus: false,
        decoration: InputDecoration(
          suffixIcon: IconButton(
            onPressed: () {
              _showSearchBar = false;
              setState(() {});
            },
            icon: Icon(Icons.clear, color: MyTheme.grey_153),
          ),
          filled: true,
          fillColor: MyTheme.white.withOpacity(0.6),
          hintText: "Search in Blogs...", //widget.category_name!
          hintStyle: TextStyle(fontSize: 14.0, color: MyTheme.font_grey),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: MyTheme.noColor, width: 0.0),
            borderRadius: BorderRadius.circular(6),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: MyTheme.noColor, width: 0.0),
            borderRadius: BorderRadius.circular(6),
          ),
          contentPadding: EdgeInsets.all(8.0),
        ),
      ),
    );
  }

  buildBlogList(context) {
    return FutureBuilder(
      future: Provider.of<BlogProvider>(context, listen: false).fetchBlogs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ShimmerHelper().buildListShimmer(
            item_count: 10,
            item_height: 100.0,
          );
        } else {
          return Consumer<BlogProvider>(
            builder: (context, blogProvider, child) {
              return MasonryGridView.count(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                crossAxisCount: 2,
                itemCount: blogProvider.blogs.length,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => BlogDetailsScreen(
                                blog: blogProvider.blogs[index],
                              ),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16.0),
                        image: DecorationImage(
                          image: NetworkImage(
                            blogProvider.blogs[index].banner,
                          ), // Replace with your image asset
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          16.0,
                        ), // Ensure the gradient follows the border radius
                        child: Stack(
                          children: [
                            // Gradient overlay
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.white.withOpacity(0.5),
                                      Colors.black.withOpacity(0.5),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Centering the text content
                            Container(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  10,
                                  113,
                                  10,
                                  18,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      blogProvider.blogs[index].title,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      blogProvider.blogs[index].title,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontStyle: FontStyle.italic,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    Text(
                                      blogProvider
                                          .blogs[index]
                                          .shortDescription,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.white,
                                      ),
                                      maxLines: 3,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        }
      },
    );
  }
}
