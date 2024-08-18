import 'dart:html' as html;
import 'dart:ui_web';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'constants.dart';
import 'google_sheets_api.dart';

void main() {
  runApp(MaterialApp(
    home: Center(child: WebViewScreen()),
  ));
}

class WebViewScreen extends StatefulWidget {
  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  @override
  void initState() {
    super.initState();
    _fetchAndInsertData();
  }

  @override
  Widget build(BuildContext context) {
    platformViewRegistry.registerViewFactory(
      'iframeElement',
      (int viewId) => html.IFrameElement()
        ..src = Constants.URL
        ..style.border = '2px solid black'
        ..style.width = '800px'
        ..style.height = '800px',
    );
    return const Scaffold(
      body: HtmlElementView(
        viewType: 'iframeElement',
      ),
    );
  }

  Future<void> _fetchAndInsertData() async {
    try {
      final apiResponse = await Dio()
          .get('https://admission.must.edu.eg/UGAPI/api/College/GetAll');
      List<List<Object>> values = [];

      for (var item in apiResponse.data) {
        List<Object> row = [
          item['name'],
          item['bannerCode'],
        ];
        values.add(row);
      }

      GoogleSheetsApi googleSheetsApiData = GoogleSheetsApi();
      await googleSheetsApiData.insertDataIntoGoogleSheet(values);
    } catch (e) {
      print(e.toString());
    }
  }
}
