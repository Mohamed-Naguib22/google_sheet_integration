import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:googleapis/sheets/v4.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'constants.dart';

class GoogleSheetsApi {
  String? spreadsheetId;
  String? gid;

  void extractGidAndIdFromUrl(String url) {
    Uri uri = Uri.parse(url);

    String path = uri.path;
    List<String> pathSegments = path.split('/');

    if (pathSegments.length > 2) {
      spreadsheetId = pathSegments[3];
    }

    String fragment = uri.fragment;

    if (fragment.contains("gid=")) {
      gid = fragment.split("gid=")[1];
    }
  }

  Future<dynamic> getGoogleSheetData() async {
    extractGidAndIdFromUrl(Constants.URL);

    final client = await _getClientViaServiceAccount();
    final sheets = SheetsApi(client);

    try {
      final sheet = await _getSheet(client, sheets);

      final range = '${sheet?.properties?.title}';

      var response =
          await sheets.spreadsheets.values.get(spreadsheetId!, range);

      return response;
    } finally {
      client.close();
    }
  }

  Future<void> insertDataIntoGoogleSheet(List<List<Object>> values) async {
    extractGidAndIdFromUrl(Constants.URL);

    final client = await _getClientViaServiceAccount();

    final sheets = SheetsApi(client);

    try {
      final sheet = await _getSheet(client, sheets);

      final range = '${sheet?.properties?.title}';

      ValueRange valueRange = ValueRange(
        range: range,
        values: values,
      );

      await sheets.spreadsheets.values.append(
        valueRange,
        spreadsheetId!,
        range,
        valueInputOption: 'RAW',
      );
    } finally {
      client.close();
    }
  }

  Future<AutoRefreshingAuthClient> _getClientViaServiceAccount() async {
    final jsonCredentials =
        await rootBundle.loadString('assets/credentials.json');
    final credentials =
        ServiceAccountCredentials.fromJson(json.decode(jsonCredentials));

    return await clientViaServiceAccount(
        credentials, [SheetsApi.spreadsheetsScope]);
  }

  Future<Sheet?> _getSheet(
      AutoRefreshingAuthClient client, SheetsApi sheets) async {
    var allTabSheets = await sheets.spreadsheets.get(spreadsheetId!);

    return allTabSheets.sheets?.firstWhere((sheet) {
      return sheet.properties?.sheetId.toString() == gid;
    });
  }
}
