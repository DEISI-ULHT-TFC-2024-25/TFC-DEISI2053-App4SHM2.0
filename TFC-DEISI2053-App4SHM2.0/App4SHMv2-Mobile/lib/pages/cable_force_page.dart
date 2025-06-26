import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app4shm/components/breadcrumb.dart';
import 'package:app4shm/providers/app_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../components/alert_dialogs.dart';

class CableForcePage extends StatefulWidget {
  const CableForcePage({Key? key}) : super(key: key);

  @override
  State<CableForcePage> createState() => _CableForcePageState();
}

class _CableForcePageState extends State<CableForcePage> {
  void _goHome() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Training information uploaded successfully"),
      ),
    );
    Provider.of<AppProvider>(context, listen: false).clear();
    Navigator.of(context)
        .pushNamedAndRemoveUntil('/structures', (route) => false);
  }

  void _goToResult() {
    Navigator.of(context).pushNamed('/result');
  }

  void _handleNext({Function? onFinished}) {
    final structure =
        Provider.of<AppProvider>(context, listen: false).structure;

    if (structure.training) {
      // if it's training, go to strucutres page
      _goHome();
    } else {
      // damage detection
      _goToResult();
    }

    // enable button
    if (onFinished != null) {
      onFinished();
    }
  }

  int cableForce = 0;
  int freqForce1 = 0;
  int freqForce2 = 0;
  int freqForce3 = 0;
  double freq1 = 0;
  double freq2 = 0;
  double freq3 = 0;
  List<double> forces = [];
  List<double> pdf = [];
  int countForces = 0;
  double closestForce = 0.0;


  @override
  void initState() {
    final provider = Provider.of<AppProvider>(context, listen: false);
    cableForce = provider.cableForce;
    freqForce1 = Provider.of<AppProvider>(context, listen: false).freqForce1;
    freqForce2 = Provider.of<AppProvider>(context, listen: false).freqForce2;
    freqForce3 = Provider.of<AppProvider>(context, listen: false).freqForce3;
    freq1 = Provider.of<AppProvider>(context, listen: false).freq1;
    freq2 = Provider.of<AppProvider>(context, listen: false).freq2;
    freq3 = Provider.of<AppProvider>(context, listen: false).freq3;
    forces = provider.forces;
    pdf = provider.pdf;
    countForces = Provider.of<AppProvider>(context, listen: false).countForces;
    super.initState();
  }

  List<FlSpot> _generateChartData() {
    if (forces.isEmpty || pdf.isEmpty || forces.length != pdf.length) return [];
    int closestIndex = -1;
    double minDifference = double.infinity;

    for (int i = 0; i < forces.length; i++) {
      double difference = (forces[i] - cableForce).abs();
      print('Comparando Force: ${forces[i]}, Difference: $difference');

      if (difference < minDifference) {
        minDifference = difference;
        closestIndex = i;
      }
    }

    if (closestIndex != -1) {
      closestForce = forces[closestIndex];
    } else {
      print('Não foi possível encontrar o closestForce!');
    }
    print("Todos os valores de forces:");
    forces.forEach((value) {
      print(value);
    });
    print("Cable Force: $cableForce");
    print("Closest Force Calculado: $closestForce");

    return List.generate(forces.length, (index) {
      return FlSpot(forces[index], pdf[index]);
    });
  }

  double get minForce => forces.isNotEmpty ? forces.reduce((a, b) => a < b ? a : b) : 0;
  double get maxForce => forces.isNotEmpty ? forces.reduce((a, b) => a > b ? a : b) : 1;
  double get minPdf => pdf.isNotEmpty ? pdf.reduce((a, b) => a < b ? a : b) : 0;
  double get maxPdf => pdf.isNotEmpty ? pdf.reduce((a, b) => a > b ? a : b) : 1;

  double get marginX => (maxForce - minForce) * 0.05;
  double get marginY => (maxPdf - minPdf) * 0.1;


  @override
  Widget build(BuildContext context) {
    final currentStructure = Provider.of<AppProvider>(context).structure;
    return Scaffold(
      appBar: AppBar(title: const Text('Cable Force')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'Cable Force Analysis',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Table(
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    border: Theme.of(context).brightness == Brightness.light
                        ? TableBorder.all(color: Colors.black, width: 1)
                        : TableBorder.all(color: Colors.white, width: 1),
                    children: [
                      const TableRow(children: [
                        Text('Mode n',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('fn (Hz)',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('Force (kN)',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ]),
                      // Exemplo de dados estáticos para exibição
                      TableRow(children: [
                        const Text('1', textAlign: TextAlign.center),
                        Text(freq1.toStringAsFixed(3),
                            textAlign: TextAlign.center),
                        Text(freqForce1.toString(),
                            textAlign: TextAlign.center),
                      ]),
                      TableRow(children: [
                        const Text('2', textAlign: TextAlign.center),
                        Text(freq2.toStringAsFixed(3),
                            textAlign: TextAlign.center),
                        Text(freqForce2.toString(),
                            textAlign: TextAlign.center),
                      ]),
                      TableRow(children: [
                        const Text('3', textAlign: TextAlign.center),
                        Text(freq3.toStringAsFixed(3),
                            textAlign: TextAlign.center),
                        Text(freqForce3.toString(),
                            textAlign: TextAlign.center),
                      ]),
                      TableRow(children: [
                        const Text('', textAlign: TextAlign.center),
                        const Text('', textAlign: TextAlign.center),
                        Text(cableForce.toString(),
                            textAlign: TextAlign.center,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      ]),
                    ],
                  ),
                  const SizedBox(height: 20),
                  currentStructure.count >= 5
                      ? Expanded(
                          child: LineChart(
                            LineChartData(
                              minX: forces.first,
                              maxX: forces.last,
                              minY: (minPdf - marginY) < 0 ? 0 : minPdf - marginY,
                              maxY: maxPdf + marginY,
                              lineBarsData: [
                                LineChartBarData(
                                  spots: _generateChartData(),
                                  isCurved: true,
                                  gradient: const LinearGradient(
                                    colors: [Colors.green, Colors.greenAccent],
                                  ),
                                  barWidth: 3,
                                  dotData: FlDotData(
                                    show: true,
                                    getDotPainter:
                                        (spot, percent, barData, index) {
                                      const double tolerance = 0.1;
                                      bool isClosest =
                                          (spot.x - closestForce).abs() <=
                                              tolerance;

                                      return isClosest
                                          ? FlDotCirclePainter(
                                              radius: 6,
                                              color: Colors.redAccent,
                                              strokeWidth: 2,
                                              strokeColor: Colors.black,
                                            )
                                          : FlDotCirclePainter(radius: 0);
                                    },
                                  ),
                                ),
                              ],
                              lineTouchData: LineTouchData(
                                touchTooltipData: LineTouchTooltipData(
                                  fitInsideHorizontally: true,
                                  fitInsideVertically: true,
                                  tooltipRoundedRadius: 8,
                                  getTooltipItems: (touchedSpots) {
                                    return touchedSpots.map((spot) {
                                      return LineTooltipItem(
                                        'X: ${spot.x.toStringAsFixed(2)}\nY: ${spot.y.toString()}',
                                        const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold),
                                      );
                                    }).toList();
                                  },
                                ),
                                handleBuiltInTouches: true,
                              ),
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  axisNameWidget: const Padding(
                                    padding: EdgeInsets.only(top: 0),
                                    child: Text(
                                      'Force (kN)',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 45,
                                    interval: ((forces.reduce(
                                                    (a, b) => a > b ? a : b) -
                                                forces.reduce(
                                                    (a, b) => a < b ? a : b)) /
                                            6)
                                        .clamp(500, double.infinity),
                                    getTitlesWidget: (value, meta) {
                                      return Transform.translate(
                                        offset: const Offset(0, 4),
                                        child: Text(
                                          value >= 1000
                                              ? '${(value / 1000).toStringAsFixed(1)}K'
                                              : value.toStringAsFixed(0),
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                leftTitles: const AxisTitles(
                                  axisNameWidget: Padding(
                                    padding: EdgeInsets.only(right: 10),
                                    child: Text(
                                      'PDF',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  sideTitles: SideTitles(
                                    showTitles: false,
                                  ),
                                ),
                                rightTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 50,
                                    interval: ((pdf.reduce(
                                                    (a, b) => a > b ? a : b) -
                                                pdf.reduce(
                                                    (a, b) => a < b ? a : b)) /
                                            10)
                                        .clamp(0.0000001, double.infinity),
                                    getTitlesWidget: (value, meta) {
                                      String formattedValue =
                                          (value.abs() < 0.01 || value > 1e6)
                                              ? value.toStringAsExponential(2)
                                              : value.toStringAsFixed(2);

                                      return Padding(
                                        padding: const EdgeInsets.only(left: 5),
                                        child: Text(
                                          formattedValue,
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(show: true),
                              gridData: FlGridData(
                                show: true,
                                horizontalInterval:
                                    ((pdf.reduce((a, b) => a > b ? a : b) -
                                                pdf.reduce(
                                                    (a, b) => a < b ? a : b)) /
                                            5)
                                        .clamp(0.05, double.infinity),
                                verticalInterval:
                                    ((forces.reduce((a, b) => a > b ? a : b) -
                                                forces.reduce(
                                                    (a, b) => a < b ? a : b)) /
                                            6)
                                        .clamp(500, double.infinity),
                              ),
                            ),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              const Expanded(
                                  child: Text(
                                      'Not enough data to display gaussian graph',
                                      style: TextStyle(color: Colors.red))),
                              TextButton(
                                onPressed: () => showAlertDialog(
                                  context: context,
                                  title: 'Information',
                                  content:
                                      'The application can only display gaussian graph after at least 5 readings.'
                                      'This structure has only ${currentStructure.count} readings.',
                                ),
                                child: const Icon(Icons.info),
                              ),
                            ],
                          ),
                        ),
                ],
              ),
            ),
            BreadCrumb(
              pageType: PageType.cableForce,
              structureType: currentStructure.structure_type.toLowerCase(),
              onNext: _handleNext,
              disabled: false,
            ),
          ],
        ),
      ),
    );
  }
}
