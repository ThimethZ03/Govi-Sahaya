import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/weather_provider.dart';

class WeatherDetailScreen extends StatefulWidget {
  const WeatherDetailScreen({super.key});

  @override
  State<WeatherDetailScreen> createState() => _WeatherDetailScreenState();
}

class _WeatherDetailScreenState extends State<WeatherDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<WeatherProvider>().fetchWeather('Colombo');
    });
  }

  @override
  Widget build(BuildContext context) {
    final weatherProvider = context.watch<WeatherProvider>();
    final weather = weatherProvider.weather;

    if (weatherProvider.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Weather')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (weatherProvider.errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Weather')),
        body: Center(child: Text(weatherProvider.errorMessage!)),
      );
    }

    if (weather == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Weather')),
        body: const Center(child: Text('No weather data')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Weather')),
      body: const Center(child: Text('Weather data loaded')),
    );
  }
}