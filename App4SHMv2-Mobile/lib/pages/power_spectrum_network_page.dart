import 'dart:math';

import 'package:app4shm/components/breadcrumb.dart';
import 'package:app4shm/models/damage.dart';
import 'package:app4shm/models/welch.dart';
import 'package:app4shm/providers/app_provider.dart';
import 'package:app4shm/services/readings_service.dart';
import 'package:app4shm/services/network_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../components/alert_dialogs.dart';
import '../models/user.dart';

class PowerSpectrumNetworkPage extends StatefulWidget {
  final String networkId;
  const PowerSpectrumNetworkPage({Key? key, required this.networkId}) : super(key: key);

  @override
  State<PowerSpectrumNetworkPage> createState() => _PowerSpectrumNetworkPageState();
}

class _PowerSpectrumNetworkPageState extends State<PowerSpectrumNetworkPage> {
  Welch welch = Welch(id: 0, meanLocal: [], welchF: [], welchZ: []);
  late User _user;
  double _zoom = 0;
  double _zoomPinPoint = -1;
  final List<FlSpot> _touchedSpots = [];
  static bool _shownInstructionsDialog = false;

  // Network-related variables
  bool isLoading = true;
  bool allDone = false;
  List<Map<String, dynamic>> locations = [];
  String? errorMessage;

  final NetworkService _networkService = NetworkService();

  @override
  void initState() {
    super.initState();
    _user = Provider.of<AppProvider>(context, listen: false).user;
    if (_user.userid == 'guest' && !_shownInstructionsDialog) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          showAlertDialog(
            context: context,
            title: 'Instructions',
            content:
            'Select the 3 most salient frequencies of the graph. These are the natural frequencies of this structure.',
          ).then((value) => _shownInstructionsDialog = true);
        }
      });
    }
    final existingWelch = Provider.of<AppProvider>(context, listen: false).welch;
    if (existingWelch.id != 0) {
      welch = existingWelch;
    }
    _startPollingNetworkReadings(widget.networkId);
  }

  void _startPollingNetworkReadings(String networkId) {
    if (networkId.isEmpty) {
      setState(() {
        errorMessage = "Network ID não encontrado";
        isLoading = false;
      });
      return;
    }

    // Start polling
    _pollNetworkReadings();
  }

  Future<void> _pollNetworkReadings() async {
    try {
      var data = await _networkService.fetchNetworkReadings(widget.networkId);

      setState(() {

        locations = data['locations'] != null
            ? (data['locations'] as List)
            .whereType<Map<String, dynamic>>()
            .toList()
            : [];
        allDone = data['all_done'] == 'completed';
        errorMessage = null;
      });


      if (allDone) {

        _createWelchFromNetworkData(data);
        setState(() {
          isLoading = false;
        });
        return;
      }

      await Future.delayed(const Duration(seconds: 5));


      if (mounted) {
        _pollNetworkReadings();
      }

    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  void _createWelchFromNetworkData(Map<String, dynamic> data) {
    try {
      print('Raw network data: ${data.toString()}');

      setState(() {
        // Update the existing welch object (which should have the ID) with network data
        welch.meanLocal = data['mean'] != null ? List<double>.from(data['mean']) : [];
        welch.welchF = data['frequencies'] != null ? List<double>.from(data['frequencies']) : [];
        welch.welchZ = data['z'] != null ? List<double>.from(data['z']) : [];

        print('Welch data updated:');
        print('welch ID: ${welch.id}');
        print('welchF length: ${welch.welchF.length}');
        print('welchZ length: ${welch.welchZ.length}');

        // Initialize touched spots list
        _touchedSpots.clear();
        for (int i = 0; i < 3; i++) {
          _touchedSpots.add(FlSpot.nullSpot);
        }
      });
    } catch (e) {
      setState(() {
        errorMessage = "Error processing data: ${e.toString()}";
        isLoading = false;
      });
    }
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

        // DEBUG: Print all data before sending
        print('=== DEBUG POWER SPECTRUM NETWORK ===');
        print('Structure ID: ${structure.id}');
        print('Structure Type: ${structure.structure_type}');
        print('Welch ID: ${welch.id}');
        print('Points: $points');
        print('Training: ${structure.training}');
        print('Welch data - F length: ${welch.welchF.length}');
        print('Welch data - Z length: ${welch.welchZ.length}');
        print('Welch data - Mean length: ${welch.meanLocal.length}');
        print('==================================');

        Damage res = await ReadingsService().sendPowerSpectrum(
            structure, welch, points, structure.training);

        if (structure.training || res.history.isEmpty) {
          _goHome();
        } else {
          appProvider.setDamage(res);
          _goToResult();
        }
      } catch (e) {
        debugPrint('ERROR: $e');
        // Adicione mais detalhes do erro
        if (e.toString().contains('400')) {
          print('=== ERROR 400 DETAILS ===');
          print('This is likely a validation error');
          print('Check if all required fields are present and valid');
          print('========================');
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.red,
              content: Text(e.toString(), style: const TextStyle(color: Colors.white)),
            ),
          );
        }
      } finally {
        if (onFinished != null) {
          onFinished();
        }
      }
    } else {
      // DEBUG: Check why _canContinue() returns false
      print('=== _canContinue() DEBUG ===');
      print('_touchedSpots.isNotEmpty: ${_touchedSpots.isNotEmpty}');
      print('_touchedSpots.length: ${_touchedSpots.length}');
      print('_touchedSpots: $_touchedSpots');
      print('Has null spots: ${_touchedSpots.any((element) => element == FlSpot.nullSpot)}');
      print('===========================');
    }
  }

  void _goHome() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Training information uploaded successfully"),
        ),
      );
      Provider.of<AppProvider>(context, listen: false).clear();
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/structures', (route) => false);
    }
  }

  void _goToCableForce() {
    if (mounted) {
      Navigator.of(context).pushNamed('/cableforce');
    }
  }

  void _goToResult() {
    if (mounted) {
      Navigator.of(context).pushNamed('/result');
    }
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

  Widget _buildLoadingContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          const Text(
            'Waiting network readings...',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Check if every device has finished its reading.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          if (locations.isNotEmpty) ...[
            const Text(
              'Positions status:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...locations.map((location) {
              // Add null checks for nested data
              final structurePosition = location['structure_position'];
              if (structurePosition == null) return const SizedBox.shrink();

              final status = structurePosition['reading'] ?? 'unknown';
              final position = structurePosition['position_location'] ?? 'N/A';

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Position $position: '),
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'Completed',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, color: Colors.red, size: 64),
          const SizedBox(height: 20),
          const Text(
            'Error processing network data',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            errorMessage ?? 'Unknown error',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              setState(() {
                isLoading = true;
                errorMessage = null;
              });
              _startPollingNetworkReadings(widget.networkId);
            },
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentStructure = Provider.of<AppProvider>(context).structure;

    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Power Spectrum Network'),
        ),
        body: _buildLoadingContent(),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Power Spectrum Network'),
        ),
        body: _buildErrorContent(),
      );
    }

    // Original graph content when data is ready
    final maxWelchF = welch.welchF.isNotEmpty
        ? welch.welchF.reduce((a, b) => a > b ? a : b)
        : 0.0;



    return Scaffold(
        appBar: AppBar(
          title: const Text('Power Spectrum Network'),
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
                              frequency: welch.meanLocal.isNotEmpty ? welch.meanLocal[0] : 0),
                          style: ButtonStyle(
                              minimumSize: MaterialStateProperty.all(null)),
                          child: Text(
                            welch.meanLocal.isNotEmpty ? welch.meanLocal[0].toStringAsFixed(3) : '0.000',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface),
                          ),
                        ),
                        Text(
                            _touchedSpots.isNotEmpty && welch.meanLocal.isNotEmpty
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
                              frequency: welch.meanLocal.length > 1 ? welch.meanLocal[1] : 0),
                          style: ButtonStyle(
                              minimumSize: MaterialStateProperty.all(null)),
                          child: Text(
                            welch.meanLocal.length > 1 ? welch.meanLocal[1].toStringAsFixed(3) : '0.000',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface),
                          ),
                        ),
                        Text(
                            _touchedSpots.length > 1 && welch.meanLocal.length > 1
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
                              frequency: welch.meanLocal.length > 2 ? welch.meanLocal[2] : 0),
                          style: ButtonStyle(
                              minimumSize: MaterialStateProperty.all(null)),
                          child: Text(
                            welch.meanLocal.length > 2 ? welch.meanLocal[2].toStringAsFixed(3) : '0.000',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface),
                          ),
                        ),
                        Text(
                            _touchedSpots.length > 2 && welch.meanLocal.length > 2
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



  double _minX() {
    // Safety check for empty data
    if (widget.welch.welchF.isEmpty) return 0.0;

    if (widget.zoomPinPoint > 0) {
      double result = widget.zoomPinPoint - 1;
      return result > 0 ? result : 0.0;
    }

    double min = widget.welch.welchF.first;
    for (double freq in widget.welch.welchF) {
      if (freq.isFinite && freq < min) {
        min = freq;
      }
    }
    return min.isFinite ? min : 0.0;
  }

  double _maxX() {
    // Safety check for empty data
    if (widget.welch.welchF.isEmpty) return 1.0;

    if (widget.zoomPinPoint > 0) {
      double maxFreq = widget.welch.welchF.last;
      double result = widget.zoomPinPoint + 1;
      return result > maxFreq ? maxFreq : result;
    }

    double max = widget.welch.welchF.last;
    for (double freq in widget.welch.welchF) {
      if (freq.isFinite && freq > max) {
        max = freq;
      }
    }

    // Apply zoom safely
    if (widget.zoom > 0 && widget.zoom.isFinite) {
      double zoomedMax = max - widget.zoom;
      max = zoomedMax > 0 ? zoomedMax : max * 0.1; // Fallback to 10% of original if zoom is too aggressive
    }

    // Ensure we have a valid, positive max value
    if (!max.isFinite || max <= 0) {
      max = 1.0;
    }

    return max;
  }

  double _maxY() {
    // Safety check for empty data
    if (widget.welch.welchZ.isEmpty) return 1.0;

    double max = double.negativeInfinity;
    for (double amplitude in widget.welch.welchZ) {
      if (amplitude.isFinite && amplitude > max) {
        max = amplitude;
      }
    }

    // If no valid max found, return default
    if (!max.isFinite || max == double.negativeInfinity) {
      return 1.0;
    }

    // Add padding safely
    double padding = widget.welch.isLogScale ? 1.0 : (max * 0.1);
    double result = max + padding;

    return result.isFinite ? result : 1.0;
  }

// Also update the _spots() method to handle invalid values:
  List<FlSpot> _spots() {
    List<FlSpot> spots = [];

    // Safety check
    if (widget.welch.welchF.length != widget.welch.welchZ.length) {
      return spots;
    }

    for (int i = 0; i < widget.welch.welchF.length; i++) {
      double x = widget.welch.welchF[i];
      double rawY = widget.welch.welchZ[i];

      // Skip invalid values
      if (!x.isFinite || !rawY.isFinite || rawY <= 0) {
        continue;
      }

      double y = widget.welch.isLogScale ? log(rawY) : rawY;

      // Skip if log calculation resulted in invalid value
      if (!y.isFinite) {
        continue;
      }

      spots.add(FlSpot(x, y));
    }

    return spots;
  }

  double _euclideanDistance(Offset a, Offset b) {
    double deltaX = a.dx - b.dx;
    double deltaY = a.dy - b.dy;
    return sqrt(deltaX * deltaX + deltaY * deltaY);
  }

  @override
  Widget build(BuildContext context) {
    // Don't render graph if there's no data
    if (widget.welch.welchF.isEmpty || widget.welch.welchZ.isEmpty) {
      return const Center(
        child: Text('Waiting...'),
      );
    }

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
