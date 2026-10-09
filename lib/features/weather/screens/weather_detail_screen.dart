// ============================================================================
// 🌤️ BANTAWAN Weather & Tactical Environmental Dashboard: WeatherDetailScreen
// 
// หน้าจอแดชบอร์ดสภาพอากาศ คาดการณ์ล่วงหน้า และคุณภาพอากาศแบบครบวงจร
// - พยากรณ์รายชั่วโมง 24 ชั่วโมงข้างหน้า (Hourly Forecast)
// - คาดการณ์สภาพอากาศ 7 วันล่วงหน้า (7-Day Daily Forecast)
// - ข้อมูลบรรยากาศเชิงลึก (ความชื้น, ลม, ความกดอากาศ, รังสี UV, พระอาทิตย์ขึ้น/ตก)
// - มลพิษ PM2.5, PM10, CO, NO2, O3 และกราฟแนวโน้ม 24 ชั่วโมง
// - คำแนะนำด้านสุขภาพและการเอาชีวิตรอดในสภาพแวดล้อม
// ============================================================================

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/weather_service.dart';
import '../widgets/weather_painter.dart';
import 'package:flutter1/core/utils/l10n_extensions.dart';

/// 🌤️ หน้าจอแดชบอร์ดสภาพอากาศและระดับมลพิษ PM2.5 เชิงลึก
class WeatherDetailScreen extends StatefulWidget {
  final WeatherData weatherData;

  const WeatherDetailScreen({super.key, required this.weatherData});

  @override
  State<WeatherDetailScreen> createState() => _WeatherDetailScreenState();
}

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
          // Background Gradient ตอบสนองต่อสภาพอากาศและมลพิษ
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: _getBackgroundColors(weatherData),
                ),
              ),
            ),
          ),

          // Dynamic Atmospheric Particles
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: WeatherParticlePainter(
                    particles: _particles,
                    animationValue: _controller.value,
                    baseColor: _getParticleColor(weatherData),
                  ),
                );
              },
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 20),

                  // Hero Weather Display
                  Center(child: _buildMainRadar(weatherData)),
                  const SizedBox(height: 32),

                  // ⏱️ Section: พยากรณ์อากาศ 24 ชั่วโมงข้างหน้า
                  _buildSectionHeader(
                    title: context.isThai ? 'พยากรณ์อากาศ 24 ชั่วโมง' : '24-Hour Forecast',
                    subtitle: 'HOURLY FORECAST',
                    icon: Icons.access_time_rounded,
                  ),
                  const SizedBox(height: 14),
                  _buildHourlyForecastList(weatherData),
                  const SizedBox(height: 32),

                  // 📅 Section: คาดการณ์สภาพอากาศ 7 วันล่วงหน้า
                  _buildSectionHeader(
                    title: context.isThai ? 'คาดการณ์สภาพอากาศ 7 วัน' : '7-Day Forecast',
                    subtitle: '7-DAY WEATHER FORECAST',
                    icon: Icons.calendar_month_rounded,
                  ),
                  const SizedBox(height: 14),
                  _buildDailyForecastList(weatherData),
                  const SizedBox(height: 32),

                  // 🌍 Section: สภาพบรรยากาศเชิงลึก (6 Metrics)
                  _buildSectionHeader(
                    title: context.isThai ? 'ข้อมูลบรรยากาศและสิ่งแวดล้อม' : 'Atmospheric Metrics',
                    subtitle: 'ATMOSPHERIC METRICS',
                    icon: Icons.speed_rounded,
                  ),
                  const SizedBox(height: 14),
                  _buildAtmosphereGrid(weatherData),
                  const SizedBox(height: 32),

                  // 🌫️ Section: ตรวจวัดมลพิษในอากาศ (Air Pollutants)
                  _buildSectionHeader(
                    title: context.isThai ? 'ระดับมลพิษในอากาศ' : 'Air Pollutants',
                    subtitle: 'AIR POLLUTANTS (WHO STANDARD)',
                    icon: Icons.air_rounded,
                  ),
                  const SizedBox(height: 14),
                  _buildPollutantsGrid(weatherData),
                  const SizedBox(height: 32),

                  // 📊 Section: กราฟแนวโน้ม PM2.5 (24H)
                  _buildSectionHeader(
                    title: context.isThai ? 'แนวโน้มฝุ่น PM 2.5 (24 ชม.)' : 'PM 2.5 Trend (24h)',
                    subtitle: 'PM 2.5 TREND GRAPH',
                    icon: Icons.auto_graph_rounded,
                  ),
                  const SizedBox(height: 14),
                  _buildTrendChart(weatherData),
                  const SizedBox(height: 32),

                  // 🛡️ Section: คำแนะนำด้านสุขภาพและการปฏิบัติตัว
                  _buildSectionHeader(
                    title: context.isThai ? 'คำแนะนำด้านสุขภาพและความปลอดภัย' : 'Health & Safety Tips',
                    subtitle: 'SURVIVAL RECOMMENDATIONS',
                    icon: Icons.health_and_safety_rounded,
                  ),
                  const SizedBox(height: 14),
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

  // ─── สีพื้นหลังและอนุภาคตอบสนองต่อสภาพอากาศ ───
  List<Color> _getBackgroundColors(WeatherData data) {
    if (data.pm25 > 50) {
      return [const Color(0xFF3B0000), const Color(0xFF1A0505), const Color(0xFF0D0303)];
    }
    if (data.weatherCode >= 95) {
      // พายุฝนฟ้าคะนอง: สีม่วงครามเข้ม
      return [const Color(0xFF1E1035), const Color(0xFF0F0A1F), const Color(0xFF050510)];
    }
    if (data.weatherCode >= 51 && data.weatherCode <= 82) {
      // ฝนตก: น้ำเงินอมเขียวขุ่น
      return [const Color(0xFF0D2538), const Color(0xFF081522), const Color(0xFF03080E)];
    }
    if (data.pm25 > 25) {
      return [const Color(0xFF2E1C00), const Color(0xFF140D00), const Color(0xFF0A0500)];
    }
    // ปกติ: น้ำเงินเทาทึบสไตล์ Cyberpunk
    return [const Color(0xFF0F172A), const Color(0xFF0B1120), const Color(0xFF020617)];
  }

  Color _getParticleColor(WeatherData data) {
    if (data.pm25 > 50) return Colors.redAccent;
    if (data.weatherCode >= 95) return Colors.purpleAccent;
    if (data.weatherCode >= 51) return Colors.cyanAccent;
    if (data.pm25 > 25) return Colors.orangeAccent;
    return Colors.lightBlueAccent;
  }

  // ─── Header Navigation ───
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            shape: const CircleBorder(),
          ),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.isThai ? 'เรดาร์สภาพอากาศ & สิ่งแวดล้อม' : 'Weather & Environment Radar',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.greenAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  context.isThai ? 'ข้อมูลดาวเทียม Open-Meteo สด' : 'Live Open-Meteo Satellite Data',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // ─── Section Header ───
  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
          ),
          child: Icon(icon, color: Colors.blueAccent, size: 16),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 10,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Hero Radar Display ───
  Widget _buildMainRadar(WeatherData data) {
    Color aqiColor = Colors.greenAccent;
    if (data.pm25 > 50) {
      aqiColor = Colors.redAccent;
    } else if (data.pm25 > 35) {
      aqiColor = Colors.orangeAccent;
    } else if (data.pm25 > 25) {
      aqiColor = Colors.amberAccent;
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulsing Wave Rings
        ...List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              double val = (_controller.value + index / 3) % 1.0;
              return Container(
                width: 210 + (val * 110),
                height: 210 + (val * 110),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: aqiColor.withValues(alpha: (1.0 - val) * 0.25),
                    width: 1.5,
                  ),
                ),
              );
            },
          );
        }),

        // Main Core Display
        Container(
          width: 230,
          height: 230,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF0F172A).withValues(alpha: 0.8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: aqiColor.withValues(alpha: 0.15),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(data.weatherIcon, style: const TextStyle(fontSize: 44)),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.temperature.toStringAsFixed(0),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 54,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    ),
                  ),
                  const Text(
                    '°C',
                    style: TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                context.isThai ? data.weatherConditionTh : data.weatherConditionEn,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                context.isThai
                    ? 'รู้สึกเหมือน ${data.apparentTemperature.toStringAsFixed(1)}°C'
                    : 'Feels like ${data.apparentTemperature.toStringAsFixed(1)}°C',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 10),
              // AQI Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: aqiColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: aqiColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: aqiColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'AQI: ${data.aqiValue.toInt()} • ${data.status}',
                      style: TextStyle(
                        color: aqiColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── ⏱️ พยากรณ์รายชั่วโมง (24 Hours Forecast) ───
  Widget _buildHourlyForecastList(WeatherData data) {
    if (data.hourlyForecast.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            context.isThai ? 'ไม่มีข้อมูลพยากรณ์รายชั่วโมง' : 'No hourly forecast data',
            style: const TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: data.hourlyForecast.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = data.hourlyForecast[index];
          final isNow = index == 0;
          final timeStr = isNow
              ? (context.isThai ? 'ตอนนี้' : 'Now')
              : '${item.time.hour.toString().padLeft(2, '0')}:00';

          return Container(
            width: 76,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: isNow
                  ? Colors.blueAccent.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isNow
                    ? Colors.blueAccent.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.08),
                width: isNow ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  timeStr,
                  style: TextStyle(
                    color: isNow ? Colors.blueAccent : Colors.white70,
                    fontSize: 11,
                    fontWeight: isNow ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                Text(item.weatherIcon, style: const TextStyle(fontSize: 22)),
                Text(
                  '${item.temperature.toStringAsFixed(0)}°',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Chance of rain
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.water_drop_rounded,
                      size: 10,
                      color: item.precipitationProbability > 20
                          ? Colors.cyanAccent
                          : Colors.white24,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${item.precipitationProbability}%',
                      style: TextStyle(
                        color: item.precipitationProbability > 20
                            ? Colors.cyanAccent
                            : Colors.white38,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── 📅 คาดการณ์สภาพอากาศ 7 วัน (7-Day Daily Forecast) ───
  Widget _buildDailyForecastList(WeatherData data) {
    if (data.dailyForecast.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            context.isThai ? 'ไม่มีข้อมูลพยากรณ์ 7 วัน' : 'No 7-day forecast data',
            style: const TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: data.dailyForecast.map((day) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                // Day name
                SizedBox(
                  width: 60,
                  child: Text(
                    day.getDayName(context.isThai),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Weather Icon & Condition
                SizedBox(
                  width: 32,
                  child: Text(day.weatherIcon, style: const TextStyle(fontSize: 20)),
                ),
                Expanded(
                  child: Text(
                    day.getCondition(context.isThai),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Rain chance
                if (day.precipitationProbability > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: Colors.cyanAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.water_drop_rounded, size: 10, color: Colors.cyanAccent),
                        const SizedBox(width: 2),
                        Text(
                          '${day.precipitationProbability}%',
                          style: const TextStyle(
                            color: Colors.cyanAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Temperature Range
                Text(
                  '${day.minTemp.toStringAsFixed(0)}°',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 6),
                // Visual Temp Bar
                Container(
                  width: 46,
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: const LinearGradient(
                      colors: [Colors.blueAccent, Colors.orangeAccent],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${day.maxTemp.toStringAsFixed(0)}°',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── 🌍 สภาพบรรยากาศเชิงลึก (6 Tactical Metrics) ───
  Widget _buildAtmosphereGrid(WeatherData data) {
    String uvLevel = context.isThai ? 'ปลอดภัย' : 'Safe';
    Color uvColor = Colors.greenAccent;
    if (data.uvIndex >= 11) {
      uvLevel = context.isThai ? 'อันตรายสูงสุด' : 'Extreme';
      uvColor = Colors.purpleAccent;
    } else if (data.uvIndex >= 8) {
      uvLevel = context.isThai ? 'สูงมาก' : 'Very High';
      uvColor = Colors.redAccent;
    } else if (data.uvIndex >= 6) {
      uvLevel = context.isThai ? 'สูง' : 'High';
      uvColor = Colors.orangeAccent;
    } else if (data.uvIndex >= 3) {
      uvLevel = context.isThai ? 'ปานกลาง' : 'Moderate';
      uvColor = Colors.amberAccent;
    }

    final metrics = [
      {
        'title': context.isThai ? 'ความชื้นสัมพัทธ์' : 'Relative Humidity',
        'value': '${data.humidity}%',
        'subtitle': data.humidity > 80
            ? (context.isThai ? 'ชื้นสูงมาก' : 'Very Humid')
            : (context.isThai ? 'ระดับสบายตัว' : 'Comfortable'),
        'icon': Icons.water_drop_outlined,
        'color': Colors.blueAccent,
      },
      {
        'title': context.isThai ? 'ความเร็วลม' : 'Wind Speed',
        'value': data.windSpeed.toStringAsFixed(1),
        'unit': 'km/h',
        'subtitle': data.windSpeed > 30
            ? (context.isThai ? 'ลมแรง ระวังพายุ' : 'Strong Wind')
            : (context.isThai ? 'ลมสงบ' : 'Calm'),
        'icon': Icons.air_rounded,
        'color': Colors.cyanAccent,
      },
      {
        'title': context.isThai ? 'ดัชนีรังสี UV' : 'UV Index',
        'value': data.uvIndex.toStringAsFixed(1),
        'subtitle': uvLevel,
        'icon': Icons.wb_sunny_outlined,
        'color': uvColor,
      },
      {
        'title': context.isThai ? 'ความกดอากาศ' : 'Surface Pressure',
        'value': data.surfacePressure.toStringAsFixed(0),
        'unit': 'hPa',
        'subtitle': data.surfacePressure < 1005
            ? (context.isThai ? 'ความกดต่ำ (เสี่ยงฝน)' : 'Low Pressure (Rain risk)')
            : (context.isThai ? 'เสถียร' : 'Stable'),
        'icon': Icons.compress_rounded,
        'color': Colors.indigoAccent,
      },
      {
        'title': context.isThai ? 'พระอาทิตย์ขึ้น' : 'Sunrise',
        'value': data.sunrise,
        'subtitle': context.isThai ? 'รุ่งเช้า' : 'Dawn',
        'icon': Icons.wb_twilight_rounded,
        'color': Colors.amberAccent,
      },
      {
        'title': context.isThai ? 'พระอาทิตย์ตก' : 'Sunset',
        'value': data.sunset,
        'subtitle': context.isThai ? 'พลบค่ำ' : 'Dusk',
        'icon': Icons.nights_stay_outlined,
        'color': Colors.deepOrangeAccent,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.5,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, index) {
        final m = metrics[index];
        final col = m['color'] as Color;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    m['title'] as String,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(m['icon'] as IconData, color: col, size: 16),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    m['value'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (m['unit'] != null) ...[
                    const SizedBox(width: 4),
                    Text(
                      m['unit'] as String,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                m['subtitle'] as String,
                style: TextStyle(
                  color: col,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── 🌫️ ตารางมลพิษทางอากาศ (Pollutants Grid) ───
  Widget _buildPollutantsGrid(WeatherData weatherData) {
    final items = [
      {
        'label': 'PM 2.5',
        'value': weatherData.pm25,
        'unit': 'µg/m³',
        'color': weatherData.pm25 > 35 ? Colors.redAccent : Colors.orangeAccent,
        'threshold': context.isThai ? 'มาตรฐาน: 15-37.5' : 'Standard: 15-37.5',
      },
      {
        'label': 'PM 10',
        'value': weatherData.pm10,
        'unit': 'µg/m³',
        'color': Colors.amberAccent,
        'threshold': context.isThai ? 'มาตรฐาน: < 50' : 'Standard: < 50',
      },
      {
        'label': context.isThai ? 'CO (คาร์บอนฯ)' : 'CO (Carbon)',
        'value': weatherData.co,
        'unit': 'µg/m³',
        'color': Colors.blueAccent,
        'threshold': context.isThai ? 'ปกติ: < 4000' : 'Normal: < 4000',
      },
      {
        'label': context.isThai ? 'NO2 (ไนโตรเจนฯ)' : 'NO2 (Nitrogen)',
        'value': weatherData.no2,
        'unit': 'µg/m³',
        'color': Colors.greenAccent,
        'threshold': context.isThai ? 'ปกติ: < 40' : 'Normal: < 40',
      },
      {
        'label': context.isThai ? 'O3 (โอโซน)' : 'O3 (Ozone)',
        'value': weatherData.o3,
        'unit': 'µg/m³',
        'color': Colors.purpleAccent,
        'threshold': context.isThai ? 'ปกติ: < 100' : 'Normal: < 100',
      },
      {
        'label': context.isThai ? 'ฝนสะสม' : 'Precipitation',
        'value': weatherData.precipitation,
        'unit': 'mm',
        'color': Colors.cyanAccent,
        'threshold': context.isThai ? 'ปริมาณฝนปัจจุบัน' : 'Current rainfall',
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.5,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _TacticalGauge(
          label: item['label'] as String,
          value: item['value'] as double,
          unit: item['unit'] as String,
          color: item['color'] as Color,
          threshold: item['threshold'] as String,
        );
      },
    );
  }

  // ─── 📊 กราฟแนวโน้ม PM2.5 ───
  Widget _buildTrendChart(WeatherData weatherData) {
    if (weatherData.hourlyPm25.isEmpty) {
      return Container(
        height: 140,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            context.isThai ? "ไม่มีข้อมูลกราฟแนวโน้ม" : "No trend graph data",
            style: const TextStyle(color: Colors.white54),
          ),
        ),
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
      height: 210,
      padding: const EdgeInsets.only(top: 20, right: 20, left: 10, bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.white.withValues(alpha: 0.06),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (val, meta) => Text(
                  val.toInt().toString(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 9,
                  ),
                ),
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: 6,
                getTitlesWidget: (val, meta) => Text(
                  '${val.toInt()}h',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 9,
                  ),
                ),
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (dataPoints.length - 1).toDouble(),
          minY: 0,
          lineBarsData: [
            LineChartBarData(
              spots: dataPoints,
              isCurved: true,
              color: weatherData.pm25 > 35 ? Colors.redAccent : Colors.cyanAccent,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    (weatherData.pm25 > 35 ? Colors.redAccent : Colors.cyanAccent)
                        .withValues(alpha: 0.25),
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

  // ─── 🛡️ คำแนะนำด้านสุขภาพและการปฏิบัติตัว ───
  Widget _buildHealthRecommendations(WeatherData weatherData) {
    List<Map<String, String>> recommendations = [];

    // แนะนำด้านมลพิษฝุ่น
    if (weatherData.pm25 > 50) {
      recommendations.add({
        'icon': '😷',
        'title': context.isThai ? 'เตือนภัยฝุ่นระดับวิกฤต' : 'Critical Dust Warning',
        'text': context.isThai
            ? 'สวมหน้ากาก N95 ทันทีเมื่อออกนอกอาคาร และงดกิจกรรมกลางแจ้งทุกชนิด'
            : 'Wear an N95 mask immediately when outdoors. Avoid all outdoor activities.',
      });
      recommendations.add({
        'icon': '🏠',
        'title': context.isThai ? 'ปิดผนึกพื้นที่อาศัย' : 'Seal Indoor Space',
        'text': context.isThai
            ? 'เปิดเครื่องฟอกอากาศและปิดประตูหน้าต่างให้มิดชิดเพื่อป้องกันฝุ่นเข้า'
            : 'Run air purifiers and keep doors/windows tightly closed to prevent dust ingress.',
      });
    } else if (weatherData.pm25 > 25) {
      recommendations.add({
        'icon': '😷',
        'title': context.isThai ? 'กลุ่มเสี่ยงควรระวัง' : 'Vulnerable Groups Caution',
        'text': context.isThai
            ? 'เด็ก คนชรา และผู้มีโรคทางเดินหายใจควรสวมหน้ากากอนามัย'
            : 'Children, elderly, and those with respiratory conditions should wear masks.',
      });
    }

    // แนะนำด้านสภาพอากาศ (แดด / ฝน / พายุ)
    if (weatherData.weatherCode >= 95) {
      recommendations.add({
        'icon': '⚡',
        'title': context.isThai ? 'พายุฝนฟ้าคะนองรุนแรง' : 'Severe Thunderstorm',
        'text': context.isThai
            ? 'หลีกเลี่ยงที่โล่งแจ้ง ใต้ต้นไม้ใหญ่ ป้ายโฆษณา และระวังฟ้าผ่า'
            : 'Avoid open areas, large trees, billboards, and beware of lightning strikes.',
      });
    } else if (weatherData.weatherCode >= 51) {
      recommendations.add({
        'icon': '☔',
        'title': context.isThai ? 'เตรียมร่มและเสื้อกันฝน' : 'Carry Umbrella & Raincoat',
        'text': context.isThai
            ? 'มีฝนตกในพื้นที่ ระมัดระวังถนนลื่นในการเดินทางและขับขี่'
            : 'Rain in the area. Drive carefully and watch for slippery roads.',
      });
    }

    // แนะนำด้าน UV
    if (weatherData.uvIndex >= 8) {
      recommendations.add({
        'icon': '🧴',
        'title': context.isThai ? 'รังสี UV สูงมาก' : 'Very High UV Radiation',
        'text': context.isThai
            ? 'ทาครีมกันแดด SPF30+, สวมแว่นกันแดด และหลีกเลี่ยงแดดช่วง 10:00-15:00 น.'
            : 'Apply SPF30+ sunscreen, wear sunglasses, and avoid sun between 10:00-15:00.',
      });
    }

    if (recommendations.isEmpty) {
      recommendations.add({
        'icon': '☘️',
        'title': context.isThai ? 'สภาพแวดล้อมปลอดภัย' : 'Safe Environment',
        'text': context.isThai
            ? 'อากาศบริสุทธิ์และแจ่มใส เหมาะสำหรับกิจกรรมทุกประเภท'
            : 'Clean air and fair weather, ideal for all outdoor activities.',
      });
    }

    return Column(
      children: recommendations.map((item) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item['icon']!, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title']!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item['text']!,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─── Gauge Card Widget ───
class _TacticalGauge extends StatelessWidget {
  final String label;
  final double value;
  final String unit;
  final Color color;
  final String threshold;

  const _TacticalGauge({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.threshold,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(Icons.analytics_outlined, color: color, size: 14),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value.toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 10,
                ),
              ),
            ],
          ),
          Text(
            threshold,
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
