import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'package:http/http.dart' as http;
import 'api_config.dart';

class ApiService {
  // دالة تصدير النسخة الاحتياطية (JSON) باستخدام التوكن المشفر
  static Future<bool> exportBackup(String username, String token) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/export');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final blob = html.Blob([response.bodyBytes], 'application/json');
        final blobUrl = html.Url.createObjectUrlFromBlob(blob);

        html.AnchorElement(href: blobUrl)
          ..setAttribute('download', 'nexus_omni_${username}_backup.json')
          ..click();

        html.Url.revokeObjectUrl(blobUrl);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // دالة تصدير تقرير Excel (CSV) باستخدام التوكن المشفر
  static Future<bool> exportCsvReport(String username, String token) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/export/csv');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final blob = html.Blob([response.bodyBytes], 'text/csv;charset=utf-8');
        final blobUrl = html.Url.createObjectUrlFromBlob(blob);

        html.AnchorElement(href: blobUrl)
          ..setAttribute('download', 'nexus_omni_${username}_report.csv')
          ..click();

        html.Url.revokeObjectUrl(blobUrl);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // دالة استيراد النسخة الاحتياطية باستخدام التوكن المشفر
  static Future<dynamic> importBackup(String token) async {
    final completer = Completer<dynamic>();
    final uploadInput = html.FileUploadInputElement()..accept = '.json';
    uploadInput.click();

    uploadInput.onChange.listen((event) {
      final files = uploadInput.files;
      if (files == null || files.isEmpty) {
        completer.complete({'success': false, 'message': 'لم يتم اختيار أي ملف'});
        return;
      }

      final file = files[0];
      final reader = html.FileReader();
      reader.readAsText(file);

      reader.onLoadEnd.listen((e) async {
        try {
          final jsonContent = reader.result as String;
          final decodedData = jsonDecode(jsonContent);

          final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/import');
          final response = await http.post(
            url,
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(decodedData),
          );

          final responseData = jsonDecode(utf8.decode(response.bodyBytes));

          if (response.statusCode == 200) {
            completer.complete({
              'success': true,
              'message': responseData['message'] ?? 'تمت الاستعادة بنجاح',
            });
          } else {
            completer.complete({
              'success': false,
              'message': responseData['error'] ?? 'فشل استيراد النسخة الاحتياطية',
            });
          }
        } catch (err) {
          completer.complete({
            'success': false,
            'message': 'تأكد من اختيار ملف JSON صالح للنسخة الاحتياطية',
          });
        }
      });
    });

    return completer.future;
  }
}