// // To parse this JSON data, do
// //
// //     final businessSettingListResponse = businessSettingListResponseFromJson(jsonString);

// import 'dart:convert';

// BusinessSettingListResponse businessSettingListResponseFromJson(String str) =>
//     BusinessSettingListResponse.fromJson(json.decode(str));

// String businessSettingListResponseToJson(BusinessSettingListResponse data) =>
//     json.encode(data.toJson());

// class BusinessSettingListResponse {
//   List<Datum>? data;
//   bool? success;
//   int? status;

//   BusinessSettingListResponse({
//     this.data,
//     this.success,
//     this.status,
//   });

//   factory BusinessSettingListResponse.fromJson(Map<String, dynamic> json) =>
//       BusinessSettingListResponse(
//         data: json["data"] == null
//             ? []
//             : List<Datum>.from(json["data"]!.map((x) => Datum.fromJson(x))),
//         success: json["success"],
//         status: json["status"],
//       );

//   Map<String, dynamic> toJson() => {
//         "data": data == null
//             ? []
//             : List<dynamic>.from(data!.map((x) => x.toJson())),
//         "success": success,
//         "status": status,
//       };
// }

// class Datum {
//   String? type;
//   dynamic value;

//   Datum({
//     this.type,
//     this.value,
//   });

//   factory Datum.fromJson(Map<String, dynamic> json) => Datum(
//         type: json["type"],
//         value: json["value"],
//       );

//   Map<String, dynamic> toJson() => {
//         "type": type,
//         "value": value,
//       };
// }

// class ValueElement {
//   String? type;
//   String? label;

//   ValueElement({
//     this.type,
//     this.label,
//   });

//   factory ValueElement.fromJson(Map<String, dynamic> json) => ValueElement(
//         type: json["type"],
//         label: json["label"],
//       );

//   Map<String, dynamic> toJson() => {
//         "type": type,
//         "label": label,
//       };
// }


// To parse this JSON data, do
//
//     final businessSettingListResponse = businessSettingListResponseFromJson(jsonString);

import 'dart:convert';

BusinessSettingListResponse businessSettingListResponseFromJson(String str) =>
    BusinessSettingListResponse.fromJson(json.decode(str));

String businessSettingListResponseToJson(BusinessSettingListResponse data) =>
    json.encode(data.toJson());

class BusinessSettingListResponse {
  List<Datum>? data;
  bool? success;
  int? status;

  BusinessSettingListResponse({
    this.data,
    this.success,
    this.status,
  });

  factory BusinessSettingListResponse.fromJson(Map<String, dynamic> json) =>
      BusinessSettingListResponse(
        // If json["data"] is null, the 'data' property will also be null.
        data: json["data"] == null
            ? null
            : List<Datum>.from(json["data"]!.map((x) => Datum.fromJson(x))),
        success: json["success"],
        status: json["status"],
      );

  Map<String, dynamic> toJson() => {
        // If 'data' is null, its value in the JSON will be null.
        "data": data == null
            ? null
            : List<dynamic>.from(data!.map((x) => x.toJson())),
        "success": success,
        "status": status,
      };
}

class Datum {
  String? type;
  dynamic value;

  Datum({
    this.type,
    this.value,
  });

  factory Datum.fromJson(Map<String, dynamic> json) => Datum(
        type: json["type"],
        value: json["value"],
      );

  Map<String, dynamic> toJson() => {
        "type": type,
        "value": value,
      };
}

class ValueElement {
  String? type;
  String? label;

  ValueElement({
    this.type,
    this.label,
  });

  factory ValueElement.fromJson(Map<String, dynamic> json) => ValueElement(
        type: json["type"],
        label: json["label"],
      );

  Map<String, dynamic> toJson() => {
        "type": type,
        "label": label,
      };
}
