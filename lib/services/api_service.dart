import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  final String baseUrl = 'https://smartcare-9a89d63cd2f1.herokuapp.com';
  
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
  String formatOpenAIResponse(String rawResponse) {
    final formattedText = rawResponse
      .replaceAllMapped(RegExp(r'(\d+\.)'), (match) => '\n${match.group(0)}')
      .trim();
  return formattedText;
  }

  Future<http.Response> fetchSuggestion(String userId) async {
    final requestData = {
      "user_id": userId,
      "format": "json",  
      "prompt": """
        Please provide 5 health suggestions for this user as a JSON array with numbered items.
        Example format:
        {
          "suggestions": [
            {"number": 1, "text": "Suggestion text here"},
            {"number": 2, "text": "Another suggestion here"}
          ]
        }
        """
    };
    
    final response = await http.post(
      Uri.parse("$baseUrl/generate_suggestion/"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestData),
    );
    
    return response;
  }
}
