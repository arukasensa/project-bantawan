// ============================================================================
// 🌤️ BANTAWAN Weather & PM2.5 Tactical Dashboard: WeatherDetailScreen
// 
// หน้าจอรายละเอียดสภาพอากาศและมลพิษ (Weather & Air Quality Detail Screen)
// แสดงกราฟแนวโน้มมลพิษ PM2.5 ตลอด 24 ชั่วโมง พร้อมแอนิเมชันอนุภาคฝุ่นลอย
// คำแนะนำด้านสุขภาพสำหรับกลุ่มเสี่ยง และคำเตือนดัชนี UV
// ============================================================================

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/weather_service.dart';
import '../widgets/weather_painter.dart';

/// 🌤️ หน้าจอแดชบอร์ดสภาพอากาศและระดับมลพิษ PM2.5 เชิงลึก (Weather Detail Screen)
class WeatherDetailScreen extends StatefulWidget {
  final WeatherData weatherData;

  const WeatherDetailScreen({super.key, required this.weatherData});

  @override
  State<WeatherDetailScreen> createState() => _WeatherDetailScreenState();
}

/// 🌫️ State ควบคุมรอบแอนิเมชันอนุภาคฝุ่น PM2.5 และการวาดกราฟ fl_chart
class _WeatherDetailScreenState extends State<WeatherDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<WeatherParticle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _particles = WeatherParticle.generate(widget.weatherData.particleCount);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final weatherData = widget.weatherData;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: _getBackgroundColors(weatherData.pm25),
                ),
              ),
            ),
          ),

          // Dynamic Particles
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: WeatherParticlePainter(
                    particles: _particles,
                    animationValue: _controller.value,
                    baseColor: weatherData.pm25 > 50
                        ? Colors.redAccent
                        : Colors.blueAccent,
                  ),
                );
              },
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 30),

                  // Main Radar Display
                  Center(child: _buildMainRadar(weatherData)),

                  const SizedBox(height: 40),
                  _buildSectionLabel('ENVIRONMENTAL MONITORING'),
                  const SizedBox(height: 16),
                  _buildPollutantsGrid(weatherData),

                  const SizedBox(height: 40),
                  _buildSectionLabel('PM 2.5 TRENDS (24H)'),
                  const SizedBox(height: 20),
                  _buildTrendChart(weatherData),

                  const SizedBox(height: 40),
                  _buildSectionLabel('SURVIVAL RECOMMENDATIONS'),
                  const SizedBox(height: 16),
                  _buildHealthRecommendations(weatherData),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _getBackgroundColors(double pm25) {
    if (pm25 > 50) {
      return [const Color(0xFF3B0000), const Color(0xFF1A0505)]; // Dark Red
    } else if (pm25 > 25) {
      return [const Color(0xFF2E1C00), const Color(0xFF140D00)]; // Dark Orange
    }
    return [
      const Color(0xFF0F0F23),
      const Color(0xFF050510),
    ]; // Default Dark Blue
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        const Spacer(),
        const Icon(Icons.location_on, color: Colors.white54, size: 16),
        const SizedBox(width: 4),
        const Text(
          'สภาพอากาศวันนี้',
          style: TextStyle(color: Colors.white54, fontSize: 14),
        ),
        const Spacer(),
        // Just for balance
        const SizedBox(width: 44),
      ],
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.3),
        fontSize: 12,
        letterSpacing: 2,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildMainRadar(WeatherData data) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulsing Rings
        ...List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              double val = (_controller.value + index / 3) % 1.0;
              return Container(
                width: 200 + (val * 100),
                height: 200 + (val * 100),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.blueAccent.withValues(
                      alpha: (1.0 - val) * 0.2,
                    ),
                    width: 2,
                  ),
                ),
              );
            },
          );
        }),
        // Main Core
        Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.05),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(data.weatherIcon, style: const TextStyle(fontSize: 48)),
              const SizedBox(height: 8),
              Text(
                '${data.temperature}°C',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 54,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                data.description,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.greenAccent.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  'AQI: ${data.aqiValue.toInt()}',
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPollutantsGrid(WeatherData weatherData) {
    final items = [
      {
        'label': 'PM 2.5',
        'value': weatherData.pm25,
        'unit': 'µg/m³',
        'color': Colors.orangeAccent,
      },
      {
        'label': 'CO',
        'value': weatherData.co,
        'unit': 'µg/m³',
        'color': Colors.blueAccent,
      },
      {
        'label': 'NO2',
        'value': weatherData.no2,
        'unit': 'µg/m³',
        'color': Colors.greenAccent,
      },
      {
        'label': 'O3',
        'value': weatherData.o3,
        'unit': 'µg/m³',
        'color': Colors.purpleAccent,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.4,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _TacticalGauge(
          label: item['label'] as String,
          value: item['value'] as double,
          unit: item['unit'] as String,
          color: item['color'] as Color,
        );
      },
    );
  }

  Widget _buildTrendChart(WeatherData weatherData) {
    if (weatherData.hourlyPm25.isEmpty) {
      return const Center(
        child: Text("ไม่มีข้อมูลกราฟ", style: TextStyle(color: Colors.white54)),
      );
    }

    final dataPoints = weatherData.hourlyPm25
        .take(24)
        .toList()
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.white.withValues(alpha: 0.05),
              strokeWidth: 1,
            ),
          ),
          titlesData: const FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: 23,
          minY: 0,
          lineBarsData: [
            LineChartBarData(
              spots: dataPoints,
              isCurved: true,
              color: Colors.blueAccent,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.blueAccent.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthRecommendations(WeatherData weatherData) {
    List<Map<String, String>> recommendations = [];
    if (weatherData.pm25 > 50) {
      recommendations = [
        {'icon': '😷', 'text': 'สวมหน้ากาก N95 ทันทีเมื่อออกนอกอาคาร'},
        {'icon': '🏠', 'text': 'ใช้เครื่องฟอกอากาศและปิดประตูหน้าต่าง'},
      ];
    } else if (weatherData.pm25 > 25) {
      recommendations = [
        {'icon': '😷', 'text': 'กลุ่มเสี่ยงควรสวมหน้ากากอนามัย'},
        {'icon': '⏲️', 'text': 'ลดเวลาทำกิจกรรมกลางแจ้ง'},
      ];
    } else {
      recommendations = [
        {'icon': '☘️', 'text': 'อากาศบริสุทธิ์ เหมาะสำหรับกิจกรรมทุกประเภท'},
      ];
    }

    return Column(
      children: recommendations.map((item) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              Text(item['icon']!, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  item['text']!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _TacticalGauge extends StatelessWidget {
  final String label;
  final double value;
  final String unit;
  final Color color;

  const _TacticalGauge({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(Icons.analytics_outlined, color: color, size: 14),
            ],
          ),
          const Spacer(),
          Text(
            value.toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
