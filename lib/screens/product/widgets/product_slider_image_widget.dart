import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

import '../../../helpers/shimmer_helper.dart';
import '../../../my_theme.dart';

// ignore: must_be_immutable
class ProductSliderImageWidget extends StatefulWidget {
  final List? productImageList;
  final CarouselSliderController? carouselController;
  int? currentImage;
  ProductSliderImageWidget({
    super.key,
    this.productImageList,
    this.carouselController,
    this.currentImage,
  });

  @override
  State<ProductSliderImageWidget> createState() =>
      _ProductSliderImageWidgetState();
}

class _ProductSliderImageWidgetState extends State<ProductSliderImageWidget> {
  @override
  Widget build(BuildContext context) {
    if (widget.productImageList!.isEmpty) {
      return ShimmerHelper().buildBasicShimmer(
        height: 190.0,
      );
    } else {
      return CarouselSlider(
        carouselController: widget.carouselController,
        options: CarouselOptions(
            aspectRatio: 355 / 375,
            viewportFraction: 1,
            initialPage: 0,
            autoPlay: false, // AutoPlay'i kapat performans için
        pauseAutoPlayOnTouch: true,
        pauseAutoPlayOnManualNavigate: true,
            enlargeCenterPage: false,
            scrollDirection: Axis.horizontal,
            onPageChanged: (index, reason) {
              setState(() {
                widget.currentImage = index;
              });
            }),
        items: widget.productImageList!.map(
          (i) {
            return Builder(
              builder: (BuildContext context) {
                return Container(
                  child: Stack(
                    children: <Widget>[
                      InkWell(
                        onTap: () {
                          openPhotoDialog(context,
                              widget.productImageList![widget.currentImage!]);
                        },
                        child: SizedBox(
                          height: double.infinity,
                          width: double.infinity,
                          child: CachedNetworkImage(
                            imageUrl: i,
                            fit: BoxFit.contain, // Web sitesindeki gibi orijinal oranlarında görünür
                            placeholder: (context, url) => Image.asset(
                              'assets/placeholder_rectangle.png',
                              fit: BoxFit.contain,
                            ),
                            errorWidget: (context, url, error) => Image.asset(
                              'assets/placeholder_rectangle.png',
                              fit: BoxFit.contain,
                            ),
                            memCacheWidth: 800, // Tablet için optimize edilmiş boyut
                            memCacheHeight: 600,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment(0.0, 0.9),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            widget.productImageList!.length,
                            (index) => Container(
                              width: 8.0,
                              height: 8.0,
                              margin: EdgeInsets.symmetric(
                                  vertical: 10.0, horizontal: 4.0),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: widget.currentImage == index
                                    ? Colors.black.withOpacity(0.5)
                                    : Color(0xff484848).withOpacity(0.5),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ).toList(),
      );
    }
  }

  openPhotoDialog(BuildContext context, path) => showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            child: Container(
                child: Stack(
              children: [
                PhotoView(
                  enableRotation: true,
                  heroAttributes: const PhotoViewHeroAttributes(tag: "someTag"),
                  imageProvider: NetworkImage(path),
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    decoration: ShapeDecoration(
                      color: MyTheme.medium_grey_50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(25),
                          bottomRight: Radius.circular(25),
                          topRight: Radius.circular(25),
                          topLeft: Radius.circular(25),
                        ),
                      ),
                    ),
                    width: 40,
                    height: 40,
                    child: IconButton(
                      icon: Icon(Icons.clear, color: MyTheme.white),
                      onPressed: () {
                        Navigator.of(context, rootNavigator: true).pop();
                      },
                    ),
                  ),
                ),
              ],
            )),
          );
        },
      );
}
