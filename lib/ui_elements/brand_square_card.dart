import 'package:neurom_bilisim_store/my_theme.dart';
import 'package:flutter/material.dart';
import 'package:neurom_bilisim_store/screens/brand_products.dart';
import 'package:neurom_bilisim_store/custom/box_decorations.dart';

class BrandSquareCard extends StatefulWidget {
  int? id;
  String slug;
  String? image;
  String? name;

  BrandSquareCard(
      {super.key, this.id, this.image, required this.slug, this.name});

  @override
  _BrandSquareCardState createState() => _BrandSquareCardState();
}

class _BrandSquareCardState extends State<BrandSquareCard> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return BrandProducts(slug: widget.slug);
        }));
      },
      child: Container(
        decoration: BoxDecorations.buildBoxDecoration_1(),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Flexible(
                  flex: 1,
                  //height: 60,
                  //width: double.infinity,
                  child: ClipRRect(
                      borderRadius: BorderRadius.vertical(
                          top: Radius.circular(16), bottom: Radius.zero),
                      child: FadeInImage.assetNetwork(
                        placeholder: 'assets/placeholder.png',
                        image: widget.image!,
                        fit: BoxFit.cover,
                      ))),
              SizedBox(
                height: 40,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Text(
                    widget.name!,
                    textAlign: TextAlign.left,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: TextStyle(
                        color: MyTheme.font_grey,
                        fontSize: 14,
                        height: 1.6,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ]),
      ),
    );
  }
}
