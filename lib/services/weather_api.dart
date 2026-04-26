import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherApi {
  final String apiKey = "your_api_key";
  //if faild to get api key mail: mahmudabbasmehedi@gmail.com
  final String baseUrl = "http://api.weatherapi.com/v1/forecast.json";

  Future<Map<String, dynamic>?> getWeatherData(String query) async {
    try {
      final url = "$baseUrl?key=$apiKey&q=$query&days=3&aqi=no&alerts=no";
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print("API Error: $e");
    }
    return null;
  }
}
