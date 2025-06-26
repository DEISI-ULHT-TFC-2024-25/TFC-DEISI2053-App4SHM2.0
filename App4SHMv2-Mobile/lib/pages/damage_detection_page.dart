import 'package:app4shm/components/breadcrumb.dart';
import 'package:app4shm/models/damage.dart';
import 'package:app4shm/providers/app_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';

class DamageDetectionPage extends StatefulWidget {
  const DamageDetectionPage({Key? key}) : super(key: key);

  @override
  State<DamageDetectionPage> createState() => _DamageDetectionPageState();
}

class _DamageDetectionPageState extends State<DamageDetectionPage> {
  Damage _damage = Damage(damage: false, ucl: 0, history: []);
  late User _user;

  @override
  void initState() {
    _damage = Provider.of<AppProvider>(context, listen: false).damage;
    _user = Provider.of<AppProvider>(context, listen: false).user;
    super.initState();
  }

  void _nextPage({Function? onFinished}) {
    Navigator.pushNamedAndRemoveUntil(context, '/structures', (route) => false);
  }

  double _calculateMinY() {
    if (_damage.history.length > 1) {
      double min = _damage.history.first;
      for (int i = 0; i < _damage.history.length; i++) {
        if (_damage.history[i] < min) {
          min = _damage.history[i];
        }
      }
      return min;
    }
    return 0;
  }

  double _calculateMaxY() {
    if (_damage.history.length > 1) {
      double max = _damage.history.first;
      for (int i = 0; i < _damage.history.length; i++) {
        if (_damage.history[i] > max) {
          max = _damage.history[i];
        }
      }
      return max;
    }
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Damage Detection')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: ScatterChart(
                ScatterChartData(
                  // x is the array index, y is the value of the array
                  scatterSpots: _damage.history
                      .asMap()
                      .entries
                      .map((e) => ScatterSpot(
                            e.key.toDouble(),
                            e.value,
                            dotPainter: FlDotCirclePainter(
                                radius: e.key == _damage.history.length - 1 ? 6 : 4,
                                color: e.key == _damage.history.length - 1
                                    ? (e.value >= _damage.ucl ? Colors.red : Colors.green)
                                    : Theme.of(context).colorScheme.onSurface),
                          ))
                      .toList(),
                  minX: 0,
                  maxX: _damage.history.length.toDouble() - 1,
                  minY: _calculateMinY(),
                  maxY: _calculateMaxY() < _damage.ucl ? _damage.ucl + 1 : _calculateMaxY(),
                  borderData: FlBorderData(
                    show: false,
                  ),
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: _damage.ucl / 2,
                    drawHorizontalLine: true,
                    getDrawingHorizontalLine: (value) {
                      return value == _damage.ucl
                          ? FlLine(
                              color: Theme.of(context).colorScheme.primary,
                              strokeWidth: 2,
                              dashArray: [10, 10],
                            )
                          : FlLine(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                              strokeWidth: 1,
                              dashArray: [5, 5],
                            );
                    },
                  ),
                  scatterTouchData: ScatterTouchData(
                    enabled: true,
                    touchTooltipData: ScatterTouchTooltipData(
                        getTooltipColor: (ScatterSpot touchedBarSpot) => Theme.of(context).colorScheme.background,
                        tooltipRoundedRadius: 8),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      axisNameSize: 20,
                      axisNameWidget: const Text(
                        'Damage Indicator (DI)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Text(
              _damage.damage ? 'No damage detected!' : 'Damage detected!',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(
              height: 20,
            ),
            Text(
              'Threshold: ${_damage.ucl.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(
              height: 20,
            ),
            _user.userid == 'guest'
                ? const Text(
                    'Disclaimer: Since you are using a testing structure, the damage detection is not '
                    'reliable and is just shown for demonstration purposes',
                    style: TextStyle(color: Colors.red, fontSize: 12.0),
                    textAlign: TextAlign.center)
                : const SizedBox.shrink(), // empty widget
            BreadCrumb(pageType: PageType.result, onNext: _nextPage, text: "FINISH"),
          ],
        ),
      ),
    );
  }
}
