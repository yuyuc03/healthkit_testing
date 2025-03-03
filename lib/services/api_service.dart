import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {

  Future<Map<String, dynamic>> getPrediction() async {
  final String apiUrl = 'http://localhost:8000/predict';
  
  try {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to get prediction. Status code: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Failed to get prediction: $e');
  }
}
}
