import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  final String baseUrl = 'http://192.168.0.46:8000';

  Future<Map<String, dynamic>> fetchPrediction() async {
    final String apiUrl = '$baseUrl/predict/';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
            'Failed to get prediction. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get prediction: $e');
    }
  }

  Future<http.Response> fetchSuggestion(String userId) async {
    final response = await http.post(
      Uri.parse("$baseUrl/generate_suggestion/"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"user_id": userId}),
    );
    return response;
  }
}
