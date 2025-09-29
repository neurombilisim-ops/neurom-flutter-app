import 'package:neurom_bilisim_store/app_config.dart';
import 'package:neurom_bilisim_store/custom/device_info.dart';
import 'package:neurom_bilisim_store/data_model/category_response.dart';
import 'package:neurom_bilisim_store/helpers/shared_value_helper.dart';
import 'package:neurom_bilisim_store/helpers/shimmer_helper.dart';
import 'package:neurom_bilisim_store/my_theme.dart';
import 'package:neurom_bilisim_store/presenter/bottom_appbar_index.dart';
import 'package:neurom_bilisim_store/repositories/category_repository.dart';
import 'package:neurom_bilisim_store/screens/category_list_n_product/category_products.dart';
import 'package:neurom_bilisim_store/screens/filter.dart';
import 'package:flutter/material.dart';
import 'package:neurom_bilisim_store/l10n/app_localizations.dart';

class CategoryList extends StatefulWidget {
  const CategoryList({
    super.key,
    required this.slug,
    this.is_base_category = false,
    this.is_top_category = false,
    this.bottomAppbarIndex,
  });

  final String slug;
  final bool is_base_category;
  final bool is_top_category;
  final BottomAppbarIndex? bottomAppbarIndex;

  @override
  _CategoryListState createState() => _CategoryListState();
}

class _CategoryListState extends State<CategoryList> {
  Map<int, bool> expandedCategories = {}; // Açık olan kategorileri takip et
  Map<int, List<Category>> subcategories = <int, List<Category>>{}; // Alt kategorileri cache'le
  int? selectedCategoryId; // Seçili kategori ID'si
  PageController pageController = PageController(); // Sayfa kontrolcüsü

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
          app_language_rtl.$! ? TextDirection.rtl : TextDirection.ltr,
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: PreferredSize(
              preferredSize: Size(DeviceInfo(context).width!, 50),
              child: buildAppBar(context),
            ),
            body: PageView(
              controller: pageController,
              children: [
                // Ana kategori sayfası
                buildMainCategoryPage(),
                // Alt kategori sayfası
                buildSubCategoryPage(),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(height: 0), // Alt kategoriler için bottom container gerekmez
          ),
        ],
      ),
    );
  }

  Widget buildMainCategoryPage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            MyTheme.mainColor.withOpacity(0.05),
            Color(0xffECF1F5),
            Colors.white,
          ],
        ),
      ),
      child: RefreshIndicator(
        onRefresh: _refreshCategories,
        color: MyTheme.accent_color,
        backgroundColor: Colors.white,
      child: CustomScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverList(
            delegate: SliverChildListDelegate([
                SizedBox(height: 24), // Daha fazla boşluk
              buildCategoryList(),
                SizedBox(height: 30), // Alt boşluk artırıldı
            ]),
          ),
        ],
        ),
      ),
    );
  }

  Widget buildSubCategoryPage() {
    if (selectedCategoryId == null) {
      return Container(
        color: Colors.white,
        child: Center(
          child: Text(
            "Kategori seçilmedi",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final subcategoryList = subcategories[selectedCategoryId] ?? [];
    
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Geri butonu
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    pageController.animateToPage(
                      0,
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  icon: Image.asset(
                    'assets/sol.png',
                    width: 20,
                    height: 20,
                  ),
                ),
                Text(
                  "Alt Kategoriler",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          // Alt kategori listesi
          Expanded(
            child: subcategoryList.isEmpty
                ? Center(
                    child: Text(
                      "Alt kategori bulunamadı",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: subcategoryList.length,
                    itemBuilder: (context, index) {
                      final subcategory = subcategoryList[index];
                      return Container(
                        margin: EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          leading: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey[100],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: subcategory.coverImage != null
                                  ? Image.network(
                                      subcategory.coverImage!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Icon(
                                          Icons.category,
                                          color: Colors.grey[600],
                                          size: 24,
                                        );
                                      },
                                    )
                                  : Icon(
                                      Icons.category,
                                      color: Colors.grey[600],
                                      size: 24,
                                    ),
                            ),
                          ),
                          title: Text(
                            subcategory.name ?? '',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey[400],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) {
                                  return CategoryProducts(
                                    slug: subcategory.slug ?? "",
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshCategories() async {
    setState(() {
      // State'i yenile
    });
  }

  // Alt kategorileri yükle
  Future<void> _loadSubcategories(int categoryId, String categorySlug) async {
    if (subcategories.containsKey(categoryId)) {
      return; // Zaten yüklenmiş
    }

    try {
      var response = await CategoryRepository().getCategories(parent_id: categorySlug);
      
      if (response.categories != null && response.categories!.isNotEmpty) {
        setState(() {
          subcategories[categoryId] = response.categories!;
        });
      }
    } catch (e) {
      print('Alt kategoriler yüklenirken hata: $e');
    }
  }

  // Kategoriyi aç/kapat
  void _toggleCategory(int categoryId, String categorySlug) {
    setState(() {
      // Önce tüm kategorileri kapat
      expandedCategories.clear();
      // Sonra sadece tıklanan kategoriyi aç
      expandedCategories[categoryId] = true;
    });

    // Alt kategorileri yükle (eğer yüklenmemişse)
    _loadSubcategories(categoryId, categorySlug);
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      scrolledUnderElevation: 0.0,
      centerTitle: true,
      elevation: 0,
      toolbarHeight: 92,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ortada logo
          Image.asset(
            "assets/logo.png",
            height: 22,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }

  String getAppBarTitle() {
    String name =
        widget.is_top_category
            ? AppLocalizations.of(context)!.top_categories_ucf
            : AppLocalizations.of(context)!.categories_ucf;

    return name;
  }

  buildCategoryList() {
    var data = widget.is_top_category
        ? CategoryRepository().getFeturedCategories(limit: 100)
            : CategoryRepository().getCategories(parent_id: 0); // Ana kategoriler için parent_id = 0
    
    return FutureBuilder(
      future: data,
      builder: (context, AsyncSnapshot<CategoryResponse> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SingleChildScrollView(
            child: ShimmerHelper().buildCategoryCardShimmer(
              is_base_category: widget.is_base_category,
            ),
          );
        }
        
        if (snapshot.hasError) {
          return Container(height: 10);
        } 
        
        if (snapshot.hasData) {
          if (snapshot.data!.categories == null || snapshot.data!.categories!.isEmpty) {
            return SizedBox(
              height: 100,
              child: Center(
                child: Text(
                  "Kategori bulunamadı",
                  style: TextStyle(color: MyTheme.font_grey),
                ),
            ),
          );
        }
          return Container(
            color: Colors.white,
            child: Column(
              children: snapshot.data!.categories!.map((category) {
                return Container(
                  margin: EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    leading: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey[100],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: category.coverImage != null
                            ? Image.network(
                                category.coverImage!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.category,
                                    color: Colors.grey[600],
                                    size: 24,
                                  );
                                },
                              )
                            : Icon(
                                Icons.category,
                                color: Colors.grey[600],
                                size: 24,
                              ),
                      ),
                    ),
                    title: Text(
                      category.name ?? '',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                    onTap: () {
                      final hasChildren = (category.number_of_children ?? 0) > 0;
                      
                      if (hasChildren) {
                        // Alt kategorileri yükle
                        _loadSubcategories(category.id!, category.slug ?? "");
                        
                        // Seçili kategoriyi ayarla
                        setState(() {
                          selectedCategoryId = category.id;
                        });
                        
                        // Alt kategori sayfasına geç
                        pageController.animateToPage(
                          1,
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        // Alt kategori yoksa direkt ürünlere git
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) {
                              return CategoryProducts(
                                slug: category.slug ?? "",
                              );
                            },
                          ),
                        );
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          );
        }
        return Container(height: 10); // Fallback return
      },
    );
  }

}