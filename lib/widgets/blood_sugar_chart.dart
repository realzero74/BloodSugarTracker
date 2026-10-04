import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/blood_sugar_record.dart';
import '../theme/app_theme.dart';

class BloodSugarChart extends StatefulWidget {
  final List<BloodSugarRecord> records;

  const BloodSugarChart({
    super.key,
    required this.records,
  });

  @override
  State<BloodSugarChart> createState() => _BloodSugarChartState();
}

class _BloodSugarChartState extends State<BloodSugarChart> {
  final ScrollController _scrollController = ScrollController();
  bool _showFasting = true;
  bool _showExercise = true;
  bool _showBedtime = true;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToRight();
    });
  }

  @override
  void didUpdateWidget(covariant BloodSugarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.records != widget.records) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToRight();
      });
    }
  }

  void _scrollToRight() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Calculate 30-day timeline (29 days ago to today)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final List<DateTime> dates = List.generate(30, (i) {
      return today.subtract(Duration(days: 29 - i));
    });

    final dateFormat = DateFormat('M/d');
    final List<String> dateLabels = dates.map((d) => dateFormat.format(d)).toList();

    // Map records to dates & tags (Excluding '예외' tag from chart)
    final Map<String, List<int>> fastingMap = {};
    final Map<String, List<int>> exerciseMap = {};
    final Map<String, List<int>> bedtimeMap = {};

    int totalSum = 0;
    int totalCount = 0;

    for (final r in widget.records) {
      // '예외' 태그는 차트에 표시하지 않음
      if (r.tag == '예외') {
        continue;
      }

      final key = DateFormat('yyyy-MM-dd').format(r.measureTime.toLocal());
      totalSum += r.sugarValue;
      totalCount++;

      if (r.tag == '공복') {
        fastingMap.putIfAbsent(key, () => []).add(r.sugarValue);
      } else if (r.tag == '운동후') {
        exerciseMap.putIfAbsent(key, () => []).add(r.sugarValue);
      } else if (r.tag == '취침전') {
        bedtimeMap.putIfAbsent(key, () => []).add(r.sugarValue);
      }
    }

    final double? averageVal = totalCount > 0 ? (totalSum / totalCount) : null;

    final List<FlSpot> fastingSpots = [];
    final List<FlSpot> exerciseSpots = [];
    final List<FlSpot> bedtimeSpots = [];

    for (int i = 0; i < 30; i++) {
      final key = DateFormat('yyyy-MM-dd').format(dates[i]);

      if (fastingMap.containsKey(key)) {
        final avg = fastingMap[key]!.reduce((a, b) => a + b) / fastingMap[key]!.length;
        fastingSpots.add(FlSpot(i.toDouble(), avg));
      }
      if (exerciseMap.containsKey(key)) {
        final avg = exerciseMap[key]!.reduce((a, b) => a + b) / exerciseMap[key]!.length;
        exerciseSpots.add(FlSpot(i.toDouble(), avg));
      }
      if (bedtimeMap.containsKey(key)) {
        final avg = bedtimeMap[key]!.reduce((a, b) => a + b) / bedtimeMap[key]!.length;
        bedtimeSpots.add(FlSpot(i.toDouble(), avg));
      }
    }

    const double minY = 40;
    const double maxY = 210;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE1E8ED)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 6,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filter Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFilterBtn(
                title: '공복',
                isActive: _showFasting,
                activeColor: AppTheme.chartFasting,
                onTap: () => setState(() => _showFasting = !_showFasting),
              ),
              const SizedBox(width: 8),
              _buildFilterBtn(
                title: '운동후',
                isActive: _showExercise,
                activeColor: AppTheme.chartExercise,
                onTap: () => setState(() => _showExercise = !_showExercise),
              ),
              const SizedBox(width: 8),
              _buildFilterBtn(
                title: '취침전',
                isActive: _showBedtime,
                activeColor: AppTheme.chartBedtime,
                onTap: () => setState(() => _showBedtime = !_showBedtime),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Selected / Today's Data Header (Tag Colored Values)
          _buildDateDataHeader(_selectedDate ?? today, fastingMap, exerciseMap, bedtimeMap),
          const SizedBox(height: 12),

          // Chart Area (Fixed Y Axis + Scrollable Line Chart)
          SizedBox(
            height: 220,
            child: Row(
              children: [
                // Fixed Y-Axis
                SizedBox(
                  width: 32,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildYLabel('190'),
                      _buildYLabel('150'),
                      _buildYLabel('110'),
                      _buildYLabel('70'),
                      const SizedBox(height: 22), // Space for X-axis labels
                    ],
                  ),
                ),
                const SizedBox(width: 4),

                // Scrollable X-Axis Chart
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    physics: const ClampingScrollPhysics(),
                    child: SizedBox(
                      width: 900,
                      height: 220,
                      child: LineChart(
                        LineChartData(
                          minX: 0,
                          maxX: 29,
                          minY: minY,
                          maxY: maxY,
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: 40,
                            getDrawingHorizontalLine: (val) {
                              return const FlLine(
                                color: Color(0xFFF0F0F0),
                                strokeWidth: 1,
                              );
                            },
                          ),
                          titlesData: FlTitlesData(
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 24,
                                interval: 1,
                                getTitlesWidget: (value, meta) {
                                  final idx = value.toInt();
                                  if (idx < 0 || idx >= dateLabels.length) {
                                    return const SizedBox.shrink();
                                  }
                                  // Display label every 2 or 3 days to avoid congestion
                                  if (idx % 2 != 0 && idx != 29) {
                                    return const SizedBox.shrink();
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      dateLabels[idx],
                                      style: const TextStyle(
                                        color: Color(0xFF888888),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          extraLinesData: ExtraLinesData(
                            horizontalLines: [
                              if (averageVal != null)
                                HorizontalLine(
                                  y: averageVal,
                                  color: AppTheme.chartAverage.withValues(alpha: 0.7),
                                  strokeWidth: 2,
                                  dashArray: [5, 5],
                                  label: HorizontalLineLabel(
                                    show: true,
                                    alignment: Alignment.topRight,
                                    padding: const EdgeInsets.only(right: 6, bottom: 4),
                                    style: const TextStyle(
                                      color: AppTheme.chartAverage,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    labelResolver: (line) =>
                                        '30일 평균 (${averageVal.round()})',
                                  ),
                                ),
                            ],
                          ),
                          lineBarsData: [
                            if (_showFasting)
                              LineChartBarData(
                                spots: fastingSpots,
                                isCurved: true,
                                curveSmoothness: 0.25,
                                color: AppTheme.chartFasting,
                                barWidth: 2.5,
                                isStrokeCapRound: true,
                                dotData: const FlDotData(
                                  show: true,
                                  getDotPainter: _defaultDotPainter,
                                ),
                              ),
                            if (_showExercise)
                              LineChartBarData(
                                spots: exerciseSpots,
                                isCurved: true,
                                curveSmoothness: 0.25,
                                color: AppTheme.chartExercise,
                                barWidth: 2.5,
                                isStrokeCapRound: true,
                                dotData: const FlDotData(
                                  show: true,
                                  getDotPainter: _defaultDotPainter,
                                ),
                              ),
                            if (_showBedtime)
                              LineChartBarData(
                                spots: bedtimeSpots,
                                isCurved: true,
                                curveSmoothness: 0.25,
                                color: AppTheme.chartBedtime,
                                barWidth: 2.5,
                                isStrokeCapRound: true,
                                dotData: const FlDotData(
                                  show: true,
                                  getDotPainter: _defaultDotPainter,
                                ),
                              ),
                          ],
                          lineTouchData: LineTouchData(
                            enabled: true,
                            handleBuiltInTouches: true,
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipColor: (_) => Colors.transparent,
                              getTooltipItems: (touchedSpots) =>
                                  List.filled(touchedSpots.length, null),
                            ),
                            touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
                              if (!event.isInterestedForInteractions) {
                                return;
                              }
                              if (touchResponse != null &&
                                  touchResponse.lineBarSpots != null &&
                                  touchResponse.lineBarSpots!.isNotEmpty) {
                                final spot = touchResponse.lineBarSpots!.first;
                                final dateIdx = spot.x.round();
                                if (dateIdx >= 0 && dateIdx < dates.length) {
                                  final touchedDate = dates[dateIdx];
                                  if (_selectedDate == null ||
                                      _selectedDate!.year != touchedDate.year ||
                                      _selectedDate!.month != touchedDate.month ||
                                      _selectedDate!.day != touchedDate.day) {
                                    setState(() {
                                      _selectedDate = touchedDate;
                                    });
                                  }
                                }
                              } else if (event.localPosition != null) {
                                final dx = event.localPosition!.dx;
                                final approxIdx = (dx / 900 * 29).round().clamp(0, dates.length - 1);
                                final touchedDate = dates[approxIdx];
                                if (_selectedDate == null ||
                                    _selectedDate!.year != touchedDate.year ||
                                    _selectedDate!.month != touchedDate.month ||
                                    _selectedDate!.day != touchedDate.day) {
                                  setState(() {
                                    _selectedDate = touchedDate;
                                  });
                                }
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateDataHeader(
    DateTime date,
    Map<String, List<int>> fastingMap,
    Map<String, List<int>> exerciseMap,
    Map<String, List<int>> bedtimeMap,
  ) {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    final dateLabel = DateFormat('M/d').format(date);

    final List<InlineSpan> spans = [];

    if (fastingMap.containsKey(dateKey) && fastingMap[dateKey]!.isNotEmpty) {
      final val = (fastingMap[dateKey]!.reduce((a, b) => a + b) / fastingMap[dateKey]!.length).round();
      spans.add(TextSpan(
        text: '${val}mg/dl',
        style: const TextStyle(
          color: AppTheme.chartFasting,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ));
    }

    if (exerciseMap.containsKey(dateKey) && exerciseMap[dateKey]!.isNotEmpty) {
      final val = (exerciseMap[dateKey]!.reduce((a, b) => a + b) / exerciseMap[dateKey]!.length).round();
      if (spans.isNotEmpty) {
        spans.add(const TextSpan(
          text: ', ',
          style: TextStyle(
            color: Color(0xFF666666),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ));
      }
      spans.add(TextSpan(
        text: '${val}mg/dl',
        style: const TextStyle(
          color: AppTheme.chartExercise,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ));
    }

    if (bedtimeMap.containsKey(dateKey) && bedtimeMap[dateKey]!.isNotEmpty) {
      final val = (bedtimeMap[dateKey]!.reduce((a, b) => a + b) / bedtimeMap[dateKey]!.length).round();
      if (spans.isNotEmpty) {
        spans.add(const TextSpan(
          text: ', ',
          style: TextStyle(
            color: Color(0xFF666666),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ));
      }
      spans.add(TextSpan(
        text: '${val}mg/dl',
        style: const TextStyle(
          color: AppTheme.chartBedtime,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ));
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      alignment: Alignment.center,
      child: spans.isEmpty
          ? Text.rich(
              TextSpan(
                text: '$dateLabel ',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
                children: const [
                  TextSpan(
                    text: '기록 없음',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.normal,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : Text.rich(
              TextSpan(
                text: '$dateLabel ',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
                children: spans,
              ),
            ),
    );
  }

  static FlDotPainter _defaultDotPainter(
    FlSpot spot,
    double xPercentage,
    LineChartBarData bar,
    int index, {
    double? size,
  }) {
    return FlDotCirclePainter(
      radius: 4,
      color: bar.color ?? Colors.blue,
      strokeWidth: 1.5,
      strokeColor: Colors.white,
    );
  }

  Widget _buildYLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        color: AppTheme.textSecondary,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildFilterBtn({
    required String title,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? Colors.transparent : const Color(0xFFDDDDDD),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.white : const Color(0xFF888888),
          ),
        ),
      ),
    );
  }
}
