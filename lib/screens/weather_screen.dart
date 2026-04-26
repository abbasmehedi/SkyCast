import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/location_service.dart';
import '../services/weather_api.dart';
import '../services/firestore_service.dart';
import '../utils/font_styles.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  // ==================== INITIALIZATION ====================
  final WeatherApi _weatherApi = WeatherApi();
  final LocationService _locationService = LocationService();
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController cityController = TextEditingController();

  String city = "Loading...";
  String temp = "0", conditionText = "Fetching...", weatherIcon = "";
  String humidity = "0", windKph = "0", uv = "0", feelsLike = "0";
  String pressure = "0", visibility = "0";
  String sunrise = "06:00 AM", sunset = "06:00 PM";
  List forecastList = [];

  bool _isAlertDismissed = false;

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocationWeather();
  }

  // ==================== BUSINESS LOGIC ====================
  void _fetchCurrentLocationWeather() async {
    String query = await _locationService.getCurrentLocation();
    _updateUI(query);
  }

  void _updateUI(String query) async {
    final data = await _weatherApi.getWeatherData(query);
    if (data != null) {
      setState(() {
        city = data['location']['name'];
        temp = "${data['current']['temp_c'].toInt()}";
        conditionText = data['current']['condition']['text'];
        weatherIcon = "https:${data['current']['condition']['icon']}";
        humidity = "${data['current']['humidity']}%";
        windKph = "${data['current']['wind_kph']} KM/H";
        uv = "${data['current']['uv']}";
        feelsLike = "${data['current']['feelslike_c'].toInt()}°C";
        pressure = "${data['current']['pressure_mb']} hPa";
        visibility = "${data['current']['vis_km']} KM";
        sunrise = data['forecast']['forecastday'][0]['astro']['sunrise'];
        sunset = data['forecast']['forecastday'][0]['astro']['sunset'];
        forecastList = data['forecast']['forecastday'];
        _isAlertDismissed = false;
      });
    }
  }

  // ==================== MAIN UI BUILDER ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: _buildSearchBarField(),
        actions: [_buildMyLocationButton(), const SizedBox(width: 10)],
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: Stack(
        children: [
          Container(
            height: double.infinity,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/background.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: () async => _fetchCurrentLocationWeather(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    _buildSlidableAlert(),
                    const SizedBox(height: 10),
                    Text(city, style: FontStyles.cityTextStyle),
                    const SizedBox(height: 10),
                    _buildMainWeatherInfo(),
                    const SizedBox(height: 30),
                    _buildWeatherDetailsGrid(),
                    const SizedBox(height: 30),
                    _buildSunTimeCard(),
                    const SizedBox(height: 30),
                    _buildForecastSection(),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== UI Widgets ====================

  Widget _buildSearchBarField() {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextField(
        controller: cityController,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: "Search City...",
          hintStyle: TextStyle(color: Colors.white60),
          prefixIcon: Icon(Icons.search, color: Colors.white),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 10),
        ),
        onSubmitted: (value) {
          if (value.trim().isNotEmpty) {
            _updateUI(value.trim());
            cityController.clear();
          }
        },
      ),
    );
  }

  Widget _buildMyLocationButton() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        onPressed: _fetchCurrentLocationWeather,
        icon: const Icon(Icons.my_location, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildSlidableAlert() {
    if (_isAlertDismissed) return const SizedBox();
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getAlertsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
          return const SizedBox();
        var lastAlert = snapshot.data!.docs.last;
        var data = lastAlert.data() as Map<String, dynamic>;
        String message = data['msg']?.toString() ?? "";
        if (message.trim().isEmpty || message == "No alert")
          return const SizedBox();

        return Dismissible(
          key: Key(lastAlert.id),
          onDismissed: (direction) => setState(() => _isAlertDismissed = true),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.85),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white24),
            ),
            child: ListTile(
              leading: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.white,
              ),
              title: Text(
                data['title'] ?? "Alert",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainWeatherInfo() {
    return Column(
      children: [
        if (weatherIcon.isNotEmpty)
          Image.network(
            weatherIcon,
            width: 80,
            height: 80,
            errorBuilder: (c, e, s) =>
                const Icon(Icons.wb_cloudy, color: Colors.white, size: 50),
          ),
        Text('$temp°', style: FontStyles.tempTextStyle),
        Text(conditionText.toUpperCase(), style: FontStyles.conditionTextStyle),
      ],
    );
  }

  Widget _buildWeatherDetailsGrid() {
    Widget buildTile(IconData icon, String label, String value) {
      return Container(
        width: (MediaQuery.of(context).size.width - 60) / 3,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(height: 8),
            Text(label, style: FontStyles.labelTextStyle),
            Text(value, style: FontStyles.valueTextStyle),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              buildTile(Icons.thermostat, "Feels Like", feelsLike),
              buildTile(Icons.water_drop, "Humidity", humidity),
              buildTile(Icons.wb_sunny, "UV Index", uv),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              buildTile(Icons.air, "Wind", windKph),
              buildTile(Icons.speed, "Pressure", pressure),
              buildTile(Icons.visibility, "Visibility", visibility),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSunTimeCard() {
    Widget buildSunDetail(String label, String time, IconData icon) => Row(
      children: [
        Icon(icon, color: Colors.orangeAccent, size: 22),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: FontStyles.labelTextStyle),
            Text(time, style: FontStyles.valueTextStyle.copyWith(fontSize: 14)),
          ],
        ),
      ],
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          buildSunDetail("SUNRISE", sunrise, Icons.wb_sunny_outlined),
          buildSunDetail("SUNSET", sunset, Icons.nightlight_round_outlined),
        ],
      ),
    );
  }

  Widget _buildForecastSection() {
    if (forecastList.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Text('3-Days Forecasts', style: FontStyles.sectionTitleStyle),
        ),
        const SizedBox(height: 15),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: forecastList.map((dayData) {
              String dayName = DateFormat(
                'EEE',
              ).format(DateTime.parse(dayData['date']));
              return Container(
                width: (MediaQuery.of(context).size.width - 60) / 3,
                height: 130,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "${dayData['day']['avgtemp_c'].toInt()}°C",
                      style: FontStyles.valueTextStyle.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    Image.network(
                      "https:${dayData['day']['condition']['icon']}",
                      width: 35,
                      errorBuilder: (c, e, s) =>
                          const Icon(Icons.wb_cloudy, color: Colors.white24),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      dayName,
                      style: FontStyles.conditionTextStyle.copyWith(
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
