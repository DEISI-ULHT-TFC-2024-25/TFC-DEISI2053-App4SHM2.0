import 'dart:math';

import 'package:app4shm/components/breadcrumb.dart';
import 'package:app4shm/models/damage.dart';
import 'package:app4shm/models/welch.dart';
import 'package:app4shm/providers/app_provider.dart';
import 'package:app4shm/services/readings_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../components/alert_dialogs.dart';
import '../models/user.dart';

class PowerSpectrumPage extends StatefulWidget {
  const PowerSpectrumPage({Key? key}) : super(key: key);

  @override
  State<PowerSpectrumPage> createState() => _PowerSpectrumPageState();
}

class _PowerSpectrumPageState extends State<PowerSpectrumPage> {
  Welch welch = Welch(id: 0, meanLocal: [], welchF: [], welchZ: []);
  late User _user;
  double _zoom = 0;
  double _zoomPinPoint = -1;
  final List<FlSpot> _touchedSpots = [];
  static bool _shownInstructionsDialog = false;

  @override
  void initState() {
    welch = Provider.of<AppProvider>(context, listen: false).welch;
    _user = Provider.of<AppProvider>(context, listen: false).user;
    super.initState();
  }

  bool _canContinue() {
    return _touchedSpots.isNotEmpty &&
        _touchedSpots.length == 3 &&
        !_touchedSpots.any((element) => element == FlSpot.nullSpot);
  }

  Future<void> _sendData({Function? onFinished}) async {
    if (_canContinue()) {
      try {
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        appProvider.setWelch(welch);
        print('welch do appprovider');
        print(welch.id);
        final structure = appProvider.structure;

        // set all x values to a list
        final List<double> points = [];
        for (int i = 0; i < _touchedSpots.length; i++) {
          points.add(_touchedSpots[i].x);
        }
        bool isCable = false;
        if (structure.structure_type.toLowerCase() == 'cable') {
          isCable = true;
        }
        Damage res = await ReadingsService().sendPowerSpectrum(
            structure, welch, points, structure.training);

        if (structure.training || res.history.isEmpty) {
          // If the structure type is cable , the user is sent to the cable force page.
          if (isCable) {
            appProvider.setCableForce(res.cableForce);
            appProvider.setfreqForce1(res.force_freq1);
            appProvider.setfreqForce2(res.force_freq2);
            appProvider.setfreqForce3(res.force_freq3);
            appProvider.setfreq1(points[0]);
            appProvider.setfreq2(points[1]);
            appProvider.setfreq3(points[2]);
            appProvider.setPdf(res.pdf);
            appProvider.setForces(res.forces);
            appProvider.setCountForces(res.countForces);

            _goToCableForce();
          } else {
            _goHome();
          }
        } else {
          appProvider.setDamage(res);

          // If the structure type is cable , the user is sent to the cable force page.
          if (isCable) {
            appProvider.setCableForce(res.cableForce);
            appProvider.setfreqForce1(res.force_freq1);
            appProvider.setfreqForce2(res.force_freq2);
            appProvider.setfreqForce3(res.force_freq3);
            appProvider.setfreq1(points[0]);
            appProvider.setfreq2(points[1]);
            appProvider.setfreq3(points[2]);
            appProvider.setPdf(res.pdf);
            appProvider.setForces(res.forces);
            appProvider.setCountForces(res.countForces);

            _goToCableForce();
          } else {
            _goToResult();
          }
        }
      } catch (e) {
        debugPrint('$e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content:
                Text(e.toString(), style: const TextStyle(color: Colors.white)),
          ),
        );
      } finally {
        if (onFinished != null) {
          onFinished();
        }
      }
    }
  }

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

  void _goToCableForce() {
    Navigator.of(context).pushNamed('/cableforce');
  }

  void _goToResult() {
    Navigator.of(context).pushNamed('/result');
  }

  void _zoomGraph(double zoom, {double frequency = 0}) {
    if (frequency > 0 && frequency != _zoomPinPoint) {
      _zoomPinPoint = frequency;
    } else if (frequency == _zoomPinPoint) {
      _zoomPinPoint = -1;
      zoom = 0;
    } else {
      _zoomPinPoint = -1;
    }

    setState(() {
      _zoom = zoom;
    });
  }

  double euclideanDistance(FlSpot a, FlSpot b) {
    double deltaX = a.x - b.x;
    double deltaY = a.y - b.y;
    return sqrt(deltaX * deltaX + deltaY * deltaY);
  }

  void _onTouchSpot(FlSpot touchedCoords, {List<FlSpot>? graph}) {
    if (touchedCoords == FlSpot.nullSpot ||
        (touchedCoords.x == 0 && touchedCoords.y == 0)) return;

    FlSpot spot = touchedCoords;
    if (graph != null && !_touchedSpots.contains(spot) && graph.isNotEmpty) {
      FlSpot nearestNeighbor = spot;
      double minDistance = 1000000.0;

      for (final neighbor in graph) {
        double distance = euclideanDistance(spot, neighbor);

        if (distance < minDistance) {
          minDistance = distance;
          nearestNeighbor = neighbor;
        }
      }

      spot = nearestNeighbor;
    }

    _updateValues(spot);
  }

  _updateValues(FlSpot spot) {
    setState(() {
      final spotIndex = _touchedSpots.indexWhere((s) => s == spot);
      if (spotIndex >= 0) {
        _touchedSpots[spotIndex] = FlSpot.nullSpot;
      } else if (_touchedSpots.isNotEmpty &&
          (_touchedSpots[0].isNull() || _touchedSpots[0] == FlSpot.nullSpot)) {
        _touchedSpots[0] = spot;
      } else if (_touchedSpots.length >= 2 &&
          (_touchedSpots[1].isNull() || _touchedSpots[1] == FlSpot.nullSpot)) {
        _touchedSpots[1] = spot;
      } else if (_touchedSpots.length >= 3 &&
          (_touchedSpots[2].isNull() || _touchedSpots[2] == FlSpot.nullSpot)) {
        _touchedSpots[2] = spot;
      } else if (_touchedSpots.length < 3) {
        _touchedSpots.add(spot);
      }
      _touchedSpots.sort((a, b) => a.x.compareTo(b.x));
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentStructure = Provider.of<AppProvider>(context).structure;

    final maxWelchF = welch.welchF.reduce((a, b) => a > b ? a : b);

    if (_user.userid == 'guest' && !_shownInstructionsDialog) {
      Future.delayed(const Duration(milliseconds: 500), () {
        showAlertDialog(
          context: context,
          title: 'Instructions',
          content:
              'Select the 3 most salient frequencies of the graph. These are the natural frequencies of this structure.',
        ).then((value) => _shownInstructionsDialog = true);
      });
    }

    return Scaffold(
        appBar: AppBar(
          title: const Text('Power Spectrum'),
          actions: [
            TextButton(
                onPressed: () => {
                      setState(() {
                        welch.isLogScale = !welch.isLogScale;
                      })
                    },
                child: Text('Log Scale: ${welch.isLogScale ? 'ON' : 'OFF'}',
                    style: TextStyle(
                        color: welch.isLogScale
                            ? Colors.green
                            : Theme.of(context).colorScheme.onSurface)))
          ],
        ),
        body: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Table(
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  defaultColumnWidth: const FixedColumnWidth(75),
                  border: TableBorder.all(
                      color: Theme.of(context).colorScheme.onSurface,
                      width: 1,
                      style: BorderStyle.solid),
                  children: [
                    // Table row with fi(Hz), Fmed(Hz), Δf(Hz)
                    const TableRow(children: [
                      Text('', textAlign: TextAlign.center),
                      Text('fi(Hz)', textAlign: TextAlign.center),
                      Text('Fmed(Hz)', textAlign: TextAlign.center),
                      Text('Δf(Hz)', textAlign: TextAlign.center),
                    ]),
                    TableRow(
                      children: [
                        const Text("1", textAlign: TextAlign.center),
                        TextButton(
                          onPressed: () => _touchedSpots.isNotEmpty
                              ? _updateValues(_touchedSpots[0])
                              : null,
                          style: ButtonStyle(
                              minimumSize: MaterialStateProperty.all(null)),
                          child: Text(
                              _touchedSpots.isNotEmpty &&
                                      _touchedSpots[0] != FlSpot.nullSpot
                                  ? _touchedSpots[0].x.toStringAsFixed(3)
                                  : '',
                              textAlign: TextAlign.center),
                        ),
                        TextButton(
                          onPressed: () => _zoomGraph(
                              _zoom > 0 ? _zoom : maxWelchF,
                              frequency: welch.meanLocal[0]),
                          style: ButtonStyle(
                              minimumSize: MaterialStateProperty.all(null)),
                          child: Text(
                            welch.meanLocal[0].toStringAsFixed(3),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface),
                          ),
                        ),
                        Text(
                            _touchedSpots.isNotEmpty
                                ? (_touchedSpots[0].x - welch.meanLocal[0])
                                    .toStringAsFixed(5)
                                : '',
                            textAlign: TextAlign.center),
                      ],
                    ),
                    TableRow(
                      children: [
                        const Text("2", textAlign: TextAlign.center),
                        TextButton(
                          onPressed: () => _touchedSpots.length > 1
                              ? _updateValues(_touchedSpots[1])
                              : null,
                          style: ButtonStyle(
                              minimumSize: MaterialStateProperty.all(null)),
                          child: Text(
                              _touchedSpots.length > 1 &&
                                      _touchedSpots[1] != FlSpot.nullSpot
                                  ? _touchedSpots[1].x.toStringAsFixed(3)
                                  : '',
                              textAlign: TextAlign.center),
                        ),
                        TextButton(
                          onPressed: () => _zoomGraph(
                              _zoom > 0 ? _zoom : maxWelchF,
                              frequency: welch.meanLocal[1]),
                          style: ButtonStyle(
                              minimumSize: MaterialStateProperty.all(null)),
                          child: Text(
                            welch.meanLocal[1].toStringAsFixed(3),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface),
                          ),
                        ),
                        Text(
                            _touchedSpots.length > 1
                                ? (_touchedSpots[1].x - welch.meanLocal[1])
                                    .toStringAsFixed(5)
                                : '',
                            textAlign: TextAlign.center),
                      ],
                    ),
                    TableRow(
                      children: [
                        const Text("3", textAlign: TextAlign.center),
                        TextButton(
                          onPressed: () => _touchedSpots.length > 2
                              ? _updateValues(_touchedSpots[2])
                              : null,
                          style: ButtonStyle(
                              minimumSize: MaterialStateProperty.all(null)),
                          child: Text(
                              _touchedSpots.length > 2 &&
                                      _touchedSpots[2] != FlSpot.nullSpot
                                  ? _touchedSpots[2].x.toStringAsFixed(3)
                                  : '',
                              textAlign: TextAlign.center),
                        ),
                        TextButton(
                          onPressed: () => _zoomGraph(
                              _zoom > 0 ? _zoom : maxWelchF,
                              frequency: welch.meanLocal[2]),
                          style: ButtonStyle(
                              minimumSize: MaterialStateProperty.all(null)),
                          child: Text(
                            welch.meanLocal[2].toStringAsFixed(3),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface),
                          ),
                        ),
                        Text(
                            _touchedSpots.length > 2
                                ? (_touchedSpots[2].x - welch.meanLocal[2])
                                    .toStringAsFixed(5)
                                : '',
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ],
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const Icon(Icons.zoom_out, size: 20),
                    SizedBox(
                      height: 130,
                      child: RotatedBox(
                        quarterTurns: 1,
                        child: Slider(
                            value: _zoom,
                            min: 0,
                            max: maxWelchF, //welch.welchF.length.toDouble() - 1
                            onChanged: (value) => _zoomGraph(value)),
                      ),
                    ),
                    const Icon(Icons.zoom_in, size: 20),
                  ],
                )
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
                child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: WelchGraph(
                  welch: welch,
                  zoom: _zoom,
                  touchedSpots: _touchedSpots,
                  touchedCallback: _onTouchSpot,
                  zoomPinPoint: _zoomPinPoint),
            )),
            const SizedBox(height: 20),
            BreadCrumb(
                pageType: PageType.powerSpectrum,
                structureType: currentStructure.structure_type.toLowerCase(),
                onNext: _sendData,
                disabled: !_canContinue())
          ],
        ));
  }
}

// separate widget for graph
class WelchGraph extends StatefulWidget {
  final Welch welch;
  double zoom = 0;
  double zoomPinPoint = 0;
  List<FlSpot> touchedSpots = [];
  final void Function(FlSpot touchedCoords, {List<FlSpot>? graph})
      touchedCallback;

  WelchGraph(
      {Key? key,
      required this.welch,
      this.zoom = 0,
      required this.touchedCallback,
      required this.touchedSpots,
      this.zoomPinPoint = 0})
      : super(key: key);

  @override
  State<WelchGraph> createState() => _WelchGraphState();
}

class _WelchGraphState extends State<WelchGraph> {
  double maxX = 0;
  double minX = 0;
  double maxY = 0;
  bool touchedSpot = false;

  @override
  void initState() {
    maxX = _maxX();
    minX = _minX();
    maxY = _maxY();
    super.initState();
  }

  @override
  void didUpdateWidget(covariant WelchGraph oldWidget) {
    if (!touchedSpot) {
      // don't update minX and maxX when a spot was touched to prevent the graph from being reset
      maxX = _maxX();
      minX = _minX();
      maxY = _maxY();
    } else {
      touchedSpot = false;
    }
    super.didUpdateWidget(oldWidget);
  }

  List<FlSpot> _spots() {
    List<FlSpot> spots = [];
    for (int i = 0; i < widget.welch.welchF.length; i++) {
      double x = widget.welch.welchF[i];
      double y = widget.welch.isLogScale
          ? log(widget.welch.welchZ[i])
          : widget.welch.welchZ[i];
      spots.add(FlSpot(x, y));
    }
    return spots;
  }

  double _minX() {
    if (widget.zoomPinPoint > 0) {
      return widget.zoomPinPoint - 1 > 0 ? widget.zoomPinPoint - 1 : 0;
    }

    double min = 0;
    for (int i = 0; i < widget.welch.welchF.length; i++) {
      if (widget.welch.welchF[i] < min) {
        min = widget.welch.welchF[i];
      }
    }
    return min;
  }

  double _maxX() {
    if (widget.zoomPinPoint > 0) {
      return widget.zoomPinPoint + 1 > widget.welch.welchF.length.toDouble() - 1
          ? widget.welch.welchF.length.toDouble() - 1
          : widget.zoomPinPoint + 1;
    }

    double max = 0;
    for (int i = 0; i < widget.welch.welchF.length; i++) {
      if (widget.welch.welchF[i] > max) {
        max = widget.welch.welchF[i] - widget.zoom > 0
            ? widget.welch.welchF[i] - widget.zoom
            : 0;
      }
    }
    return max != 0 ? max : 1;
  }

  double _maxY() {
    double max = double.negativeInfinity;
    for (int i = 0; i < widget.welch.welchZ.length; i++) {
      if (widget.welch.welchZ[i] >= max) {
        max = widget.welch.welchZ[i];
      }
    }

    return max +
        (widget.welch.isLogScale
            ? 1
            : 0.1); // add a "padding" that allows the finger to select the highest point
  }

  double _euclideanDistance(Offset a, Offset b) {
    double deltaX = a.dx - b.dx;
    double deltaY = a.dy - b.dy;
    return sqrt(deltaX * deltaX + deltaY * deltaY);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() {
          //make it slower
          double dx = details.delta.dx / 100;
          minX -= dx;
          maxX -= dx;
        });
      },
      onScaleUpdate: (details) {
        setState(() {
          minX = details.focalPoint.dx -
              details.scale * (details.focalPoint.dx - minX);
          maxX = details.focalPoint.dx +
              details.scale * (maxX - details.focalPoint.dx);
        });
      },
      child: LineChart(
        LineChartData(
          minX: minX,
          maxX: maxX,
          maxY: maxY != 10 ? maxY : null,
          lineBarsData: [
            LineChartBarData(
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.5),
                    Colors.transparent
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              color: Theme.of(context).colorScheme.primary,
              spots: _spots(),
              isCurved: false,
              barWidth: 2,
              isStrokeCapRound: false,
              dotData: FlDotData(getDotPainter: (spot, _, __, ___) {
                if (widget.touchedSpots
                    .map((spot) => spot.x)
                    .contains(spot.x)) {
                  return FlDotCirclePainter(
                    radius: 6,
                    color: Colors.red,
                    strokeWidth: 2,
                    strokeColor: Theme.of(context).colorScheme.onSurface,
                  );
                } else {
                  return FlDotCirclePainter(
                    radius: 2,
                    color: Theme.of(context).colorScheme.primary,
                    strokeWidth: 0,
                  );
                }
              }),
            )
          ],
          lineTouchData: LineTouchData(
            enabled: true,
            handleBuiltInTouches: true,
            touchSpotThreshold: 100,
            distanceCalculator: _euclideanDistance,
            touchCallback:
                (FlTouchEvent event, LineTouchResponse? touchResponse) {
              if (event is FlTapUpEvent) {
                widget.touchedCallback(
                    FlSpot(touchResponse?.lineBarSpots?.single.x ?? 0,
                        touchResponse?.lineBarSpots?.single.y ?? 0),
                    graph: _spots());
                touchedSpot = true;
              }
            },
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (LineBarSpot touchedSpot) =>
                  Theme.of(context).colorScheme.primary,
              tooltipRoundedRadius: 8,
              tooltipPadding: const EdgeInsets.all(8),
              tooltipMargin: 12,
              getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                return touchedBarSpots.map((barSpot) {
                  return LineTooltipItem(
                    '${barSpot.x.toStringAsFixed(2)} Hz\n${barSpot.y.toStringAsFixed(2)}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              axisNameSize: 20,
              axisNameWidget: const Text(
                'Frequency (Hz)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
              ),
            ),
            leftTitles: AxisTitles(
              axisNameSize: 20,
              axisNameWidget: Text(
                widget.welch.isLogScale ? 'Log(Amplitude)' : 'Amplitude',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 50,
                  getTitlesWidget: (value, meta) {
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(
                        widget.welch.isLogScale
                            ? meta.formattedValue
                            : value.toStringAsFixed(2),
                      ),
                    );
                  }),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: false,
              ),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: false,
              ),
            ),
          ),
          borderData: FlBorderData(
            show: false,
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            drawHorizontalLine: true,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Theme.of(context).colorScheme.secondary,
              strokeWidth: 0.5,
            ),
            getDrawingVerticalLine: (value) => FlLine(
              color: Theme.of(context).colorScheme.secondary,
              strokeWidth: 0.5,
            ),
          ),
          clipData: FlClipData
              .all(), // to prevent the graph from being drawn outside its boundaries, when we drag it
        ),
      ),
    );
  }
}
