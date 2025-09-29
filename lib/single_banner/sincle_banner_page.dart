
import 'package:neurom_bilisim_store/helpers/shimmer_helper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'photo_provider.dart';
import 'package:go_router/go_router.dart';

class PhotoWidget extends StatefulWidget {
  const PhotoWidget({super.key});

  @override
  _PhotoWidgetState createState() => _PhotoWidgetState();
}

class _PhotoWidgetState extends State<PhotoWidget> {
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  void _loadPhotos() async {
    try {
      await Provider.of<PhotoProvider>(context, listen: false).fetchPhotos();
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String extractSlug(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      final categoryIndex = segments.indexOf('category');
      if (categoryIndex != -1 && categoryIndex + 1 < segments.length) {
        return segments[categoryIndex + 1];
      }
    } catch (e) {
      print('Invalid URL: $e');
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return ShimmerHelper().buildBasicShimmer(height: 50);
    }

    if (_hasError) {
      return Center(child: Text('Error loading photos'));
    }

    return Consumer<PhotoProvider>(
      builder: (context, photoProvider, child) {
        if (photoProvider.singleBanner.isEmpty) {
          return SizedBox.shrink(); // Boş durumda hiçbir şey gösterme
        }

        final photoData = photoProvider.singleBanner[0];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10.0),
          child: GestureDetector(
            onTap: () {
              final slug = extractSlug(photoData.url);
              if (slug.isNotEmpty) {
                context.go('/category/$slug');
              } else {
                print('Raw URL: ${photoData.url}');
              }
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.network(
                photoData.photo,
                height: 252, // 202'den %25 artır (202 * 1.25 = 252.5 ≈ 252)
                width: double.infinity,
                fit: BoxFit.cover, // Eski ayara geri döndür
              ),
            ),
          ),
        );
      },
    );
  }
}
