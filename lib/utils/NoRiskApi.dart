import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:noriskclient/main.dart';

class NoRiskApi {
  static const String baseUrl = 'https://api.norisk.gg/api/v1/';
  static const String baseExperimentalUrl =
      'https://api-staging.norisk.gg/api/v1/';

  String getBaseUrl(bool experimental, String project) {
    return project == 'wordpress'
        ? 'https://blog.norisk.gg/wp-json/wp/v2'
        : (experimental ? baseExperimentalUrl : baseUrl) + project;
  }

  String getAssetUrl() {
    return 'https://assets.norisk.gg/api/v1/assets/mcreal';
  }

  Future<T?> _fetchData<T>(
      String backend, String endpoint, Map<String, dynamic>? params) async {
    final response = await http.get(
      Uri.parse(
          '${getBaseUrl(getUserData['experimental'], backend)}/$endpoint?uuid=${getUserData['uuid']}${params?.entries.map((e) => '&${e.key}=${e.value}').join() ?? ''}'),
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

    Map? profileData =
        await _fetchData<Map>('mcreal', 'user/profile/$uuid', null);
    if (profileData == null) {
      return {};
    } else {
      getUpdateStream.sink.add(['cacheProfile', uuid, profileData]);
      return profileData;
    }
  }

  Future<List<dynamic>> getBlogPostsAndChangeLogs() async {
    List<dynamic>? data = await _fetchData<List<dynamic>>(
        'wordpress', 'posts', {'categories': '21,2'});
    return data ?? [];
  }
}
