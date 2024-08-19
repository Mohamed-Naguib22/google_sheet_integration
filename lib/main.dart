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
  GoogleSheetsApi googleSheetsApiData = GoogleSheetsApi();

  @override
  void initState() {
    super.initState();
    googleSheetsApiData.clearGoogleSheetData();
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
    return Scaffold(
      body: Column(
        children: [
          const Expanded(
            child: HtmlElementView(
              viewType: 'iframeElement',
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _saveData();
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchAndInsertData() async {
    try {
      final apiResponse =
          await Dio().get('https://localhost:44384/api/Assignment/GetAll');
      List<List<Object>> values = [];

      for (var item in apiResponse.data) {
        List<Object> row = [
          item['id'],
          item['name'],
          item['description'],
        ];
        values.add(row);
      }

      await googleSheetsApiData.insertDataIntoGoogleSheet(values);
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> _saveData() async {
    try {
      final values = await googleSheetsApiData.getGoogleSheetData();
      List<Assignment> assignments = [];

      for (dynamic row in values) {
        assignments.add(
          Assignment(
            id: row[0],
            name: row[1],
            description: row[2],
          ),
        );
      }

      List<Map<String, dynamic>> assignmentMaps =
          assignments.map((assignment) => assignment.toJson()).toList();

      final response = await Dio().put(
        "https://localhost:44384/api/Assignment/UpdateMany",
        data: assignmentMaps,
        options: Options(
          contentType: Headers.jsonContentType,
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text("edited successfully"),
        ),
      );
      print(response);
    } catch (e) {
      print(e.toString());
    }
  }
}

class Assignment {
  final String id;
  final String name;
  final String description;

  Assignment({required this.id, required this.name, required this.description});
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }
}
