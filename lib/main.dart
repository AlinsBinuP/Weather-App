import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const WeatherApp());

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Weather App",
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: Colors.transparent,
        inputDecorationTheme: const InputDecorationTheme(filled: true),
      ),
      darkTheme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.transparent,
        inputDecorationTheme: const InputDecorationTheme(filled: true),
      ),
      themeMode: ThemeMode.system,
      home: const WeatherHome(),
    );
  }
}

class WeatherHome extends StatefulWidget {
  const WeatherHome({super.key});

  @override
  State<WeatherHome> createState() => _WeatherHomeState();
}

class _WeatherHomeState extends State<WeatherHome> {
  final apiKey = 'f4b868239efe1834e1deb4766a726d89';

  String city = "London";
  String temp = "";
  String weatherMain = "";
  String iconUrl = "";
  String humidity = "";
  String wind = "";
  String pressure = "";
  String date = "";
  bool isDay = true;

  List<Map<String, String>> forecast = [];

  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchWeather(city);
  }

  Future<void> fetchWeather(String cityName) async {
    try {
      final weatherUrl =
          "https://api.openweathermap.org/data/2.5/weather?q=$cityName&appid=$apiKey&units=metric";
      final forecastUrl =
          "https://api.openweathermap.org/data/2.5/forecast?q=$cityName&appid=$apiKey&units=metric";

      final weatherResponse = await http.get(Uri.parse(weatherUrl));
      final forecastResponse = await http.get(Uri.parse(forecastUrl));

      if (weatherResponse.statusCode == 200 &&
          forecastResponse.statusCode == 200) {
        final weatherData = json.decode(weatherResponse.body);
        final forecastData = json.decode(forecastResponse.body);

        int timestamp = weatherData['dt'];
        int offset = weatherData['timezone'];
        DateTime localTime = DateTime.fromMillisecondsSinceEpoch(
            (timestamp + offset) * 1000,
            isUtc: true);
        int hour = localTime.hour;

        List<Map<String, String>> forecastList = [];
        final List forecasts = forecastData['list'];
        final now = DateTime.now().toUtc();

        // Keep 3 days only (1 per day, roughly 12:00 PM entry)
        for (var entry in forecasts) {
          final dtTxt = entry['dt_txt'];
          if (dtTxt.contains("12:00:00")) {
            final date = DateTime.parse(dtTxt);
            if (date.isAfter(now)) {
              forecastList.add({
                "date": "${date.day}/${date.month}",
                "temp": "${entry['main']['temp'].round()}°",
                "icon":
                    "https://openweathermap.org/img/wn/${entry['weather'][0]['icon']}@2x.png"
              });
            }
          }
          if (forecastList.length == 3) break;
        }

        setState(() {
          city = cityName;
          temp = "${weatherData['main']['temp'].round()}°";
          weatherMain = weatherData['weather'][0]['main'];
          iconUrl =
              "https://openweathermap.org/img/wn/${weatherData['weather'][0]['icon']}@2x.png";
          humidity = "${weatherData['main']['humidity']}%";
          wind = "${weatherData['wind']['speed']} m/s";
          pressure = "${weatherData['main']['pressure']} hPa";
          date = "${localTime.day}/${localTime.month}/${localTime.year}";
          isDay = hour >= 6 && hour < 18;
          forecast = forecastList;
        });
      } else {
        showError("City not found.");
      }
    } catch (e) {
      showError("Error fetching weather.");
    }
  }

  void showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _infoCard(String label, String value) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(fontSize: 20, color: Colors.white)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(fontSize: 14, color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _forecastCard(Map<String, String> data) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(data['date'] ?? "",
              style: const TextStyle(color: Colors.white)),
          if (data['icon'] != null)
            Image.network(data['icon']!, width: 50, height: 50),
          Text(data['temp'] ?? "",
              style: const TextStyle(color: Colors.white, fontSize: 16)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgGradient = isDay
        ? const LinearGradient(
            colors: [Color(0xFF74ebd5), Color(0xFFACB6E5)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          )
        : const LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          );

    final darkGradient = const LinearGradient(
      colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(gradient: isDark ? darkGradient : bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              TextField(
                controller: _controller,
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) fetchWeather(value.trim());
                },
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Enter city name",
                  hintStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white24,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search, color: Colors.white),
                    onPressed: () {
                      if (_controller.text.trim().isNotEmpty) {
                        fetchWeather(_controller.text.trim());
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                city,
                style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              Text(date, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 30),
              if (iconUrl.isNotEmpty)
                Image.network(iconUrl, width: 100, height: 100),
              Text(temp,
                  style: const TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.w300,
                      color: Colors.white)),
              Text(weatherMain,
                  style: const TextStyle(fontSize: 24, color: Colors.white)),
              const SizedBox(height: 30),
              if (forecast.isNotEmpty)
                SizedBox(
                  height: 140,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: forecast.map(_forecastCard).toList(),
                  ),
                ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _infoCard("Humidity", humidity),
                  _infoCard("Wind", wind),
                  _infoCard("Pressure", pressure),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}