import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:noriskclient/main.dart';

class NoRiskApi {
  static const String baseUrl = 'https://api.norisk.gg/api/v1/';
  static const String baseExperimentalUrl =
      'https://api-staging.norisk.gg/api/v1/';

  String getBaseUrl(bool experimental, String project) {
    return (experimental ? baseExperimentalUrl : baseUrl) + project;
  }

  String getAssetUrl() {
    return 'https://assets.norisk.gg/api/v1/assets/mcreal';
  }
  
  Future<T?> _fetchData<T>(String backend, String endpoint) async {
    final response = await http.get(
      Uri.parse(
          '${getBaseUrl(getUserData['experimental'], backend)}/$endpoint?uuid=${getUserData['uuid']}'),
      headers: {'Authorization': 'Bearer ${getUserData['token']}'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes)) as T;
    } else if (response.statusCode == 401) {
      getUpdateStream.sink.add(['signOut']);
    } else {
      throw Exception('Failed to load data: ${response.body}');
    }
  }

  Future<Map> getUserProfile(String uuid) async {
    if (getCache['profiles']?.containsKey(uuid) ?? false) {
      return getCache['profiles']![uuid];
    }

    Map? profileData = await _fetchData<Map>('mcreal', 'user/profile/$uuid');
    if (profileData == null) {
      return {};
    } else {
      getUpdateStream.sink.add(['cacheProfile', uuid, profileData]);
      return profileData;
    }
  }
}
