import 'package:neurom_bilisim_store/app_config.dart';
import 'package:neurom_bilisim_store/data_model/blog_mode.dart';
import 'package:neurom_bilisim_store/helpers/shared_value_helper.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BlogProvider with ChangeNotifier {
  List<BlogModel> _blogs = [];

  List<BlogModel> get blogs {
    return _blogs;
  }

  Future<void> fetchBlogs() async {
    final url = ("${AppConfig.BASE_URL}/blog-list");
    final response = await http.get(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${access_token.$}",
        "System-Key": AppConfig.system_key
      },
    );
    print(response.body);
    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);

      final List<BlogModel> loadedBlogs = [];
      jsonData['blogs']['data'].forEach((blogData) {
        loadedBlogs.add(BlogModel.fromJson(blogData));
      });
      _blogs = loadedBlogs;
      notifyListeners();
    } else {
      print('Failed to load blogs');
    }
  }
}
