import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:app4shm/components/breadcrumb.dart';
import 'package:app4shm/models/data.dart';
import 'package:app4shm/models/welch.dart';
import 'package:app4shm/services/readings_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../components/alert_dialogs.dart';
import '../models/structure.dart';
import '../models/user.dart';
import '../providers/app_provider.dart';
import '../services/network_service.dart';

class TimeSeriesSlaveNetwork extends StatefulWidget {
  final String networkId;
  final int selectedLocation;
  const TimeSeriesSlaveNetwork({super.key, required this.networkId,required this.selectedLocation});

  @override
  State<TimeSeriesSlaveNetwork> createState() => _TimeSeriesSlaveNetworkState();
}

class _TimeSeriesSlaveNetworkState extends State<TimeSeriesSlaveNetwork> {
  Structure _structure = Structure(id: 0, name: '',cable_mass: 0,cable_length:0,structure_type: 'structure', training: true, count: 0);
  late User _user;
  final List<FlSpot> _accelerometerSpots = [const FlSpot(0, 0)];
  String _readingsText = '';
  bool _running = false;
  static bool _shownInstructionsDialog = false;
  Timer? _statusCheckTimer;


  final int readingInterval = 20;
  double elapsedTime = 0.0;
  StreamSubscription<AccelerometerEvent>? accelerometerStream;

  Map<String, dynamic>? _readingsInfo;

  @override
  void initState() {
    super.initState();

    _structure = Provider.of<AppProvider>(context, listen: false).structure;
    _user = Provider.of<AppProvider>(context, listen: false).user;
    _fetchReadings();
    _startAccelerometer();
    _startStatusPolling();

    if (_user.userid == 'guest' && !_shownInstructionsDialog) {
      Future.delayed(const Duration(milliseconds: 500), () {
        showAlertDialog(
          context: context,
          title: 'Instructions',
          content: 'Lay your phone on a flat surface of the structure and press the play button on the top right corner.',
        ).then((value) => _shownInstructionsDialog = true);
      });
    }
  }

  void _startStatusPolling() {
    _statusCheckTimer = Timer.periodic(Duration(seconds: 1), (timer) async {
      try {
        final status = await NetworkService().fetchNetworkStatus(widget.networkId);
        if (status == 'reading') {
          if (!mounted|| _running) return; /// if the accelerometer is already runnig we dont wanna call the function
          _startAccelerometer();
        }

        if (status == 'waiting') {
          if (!mounted) return;
          _stopAccelerometer();
        }
        if (status == 'completed') {
          _statusCheckTimer?.cancel();
          if (!mounted) return;
          _stopAccelerometer();
          _sendData();
        }
      } catch (e) {
        print("Error checking status: $e");
      }
    });
  }

  Future<void> _fetchReadings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) throw Exception("Utilizador não autenticado.");

      final Uri url = Uri.parse(
        '${dotenv.env['BASE_URL']!}/network/readings/?networkId=${widget.networkId}',
      );

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() => _readingsInfo = data);
      } else {
        throw Exception('Error fetching network data: ${response.body}');
      }
    } catch (e) {
      print(e);
    }
  }



  _startAccelerometer() {

    // prevent the screen from turning off
    WakelockPlus.enable();

    int lastWritten = 0;
    final startTime = DateTime.now().millisecondsSinceEpoch;

    setState(() => {
      _running = true,
      _readingsText = '',
      _accelerometerSpots.clear(),
      lastWritten = 0
    });

    accelerometerStream = accelerometerEvents.listen((AccelerometerEvent event) {
      if (_running && DateTime.now().millisecondsSinceEpoch - lastWritten >= 20) {
        if (_accelerometerSpots.length > 100000) {
          _accelerometerSpots.removeAt(0);
        } else if (_accelerometerSpots.length > 1 && _accelerometerSpots.first.y == 0) {
          _accelerometerSpots.removeAt(0);
        }

        Data reading = Data(
            id: _structure.id.toString(),
            timeStamp: DateTime.now().millisecondsSinceEpoch,
            x: event.x,
            y: event.y,
            z: event.z,
            group: _structure.name
        );
        _readingsText += reading.toCSV();
        lastWritten = DateTime.now().millisecondsSinceEpoch;

        final currentTime = DateTime.now().millisecondsSinceEpoch;
        elapsedTime = (currentTime - startTime) / 1000.0;

        setState(() {
          _accelerometerSpots.add(FlSpot(elapsedTime, event.z));
        });
      }
    });
  }

  double _calculateminY() {
    if (_accelerometerSpots.length > 1) {
      double min = _accelerometerSpots.first.y;
      for (int i = 0; i < _accelerometerSpots.length; i++) {
        if (_accelerometerSpots[i].y < min) {
          min = _accelerometerSpots[i].y;
        }
      }
      return min - 1;
    } else {
      return -1;
    }
  }

  double _calculatemaxY() {
    if (_accelerometerSpots.length > 1) {
      double max = _accelerometerSpots.first.y;
      for (int i = 0; i < _accelerometerSpots.length; i++) {
        if (_accelerometerSpots[i].y > max) {
          max = _accelerometerSpots[i].y;
        }
      }
      return max + 1;
    } else {
      return 1;
    }
  }

  _stopAccelerometer({bool updateUI = true}) {

    // enable the device sleeping
    WakelockPlus.disable();

    elapsedTime = 0.0;
    accelerometerStream?.cancel();
    if (updateUI) {
      setState(() => _running = false);
    } else {
      _running = false;
    }
  }

  bool _canContinue() {
    return _accelerometerSpots.length > 1 && !_running;
  }

  Future<void> _sendData({Function? onFinished}) async {
    final String date = DateTime.now().toString().substring(0, 16);
    final String fileName = 'readings-${_structure.id}-$date.csv';

    try {
      final File file = await ReadingsService().writeToFile(fileName, _readingsText);

      try {
        Welch welch = await ReadingsService().uploadReadings(
          file,
          _structure.id.toString(),
          _structure.name,
        );

        int readingId = welch.id;

        await NetworkService().allocateReading(
          networkId: widget.networkId,
          location: widget.selectedLocation,
          readingId: readingId,
        );

        _setWelch(welch);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Reading alocated sucessfuly (ID: $readingId)"),
          ),
        );

        await _nextPage();
      } catch (e) {
        debugPrint(e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Error alocating reading'),
          ),
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reading saved as $fileName'),
        ),
      );
    } catch (e) {
      debugPrint(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving reading as $fileName'),
        ),
      );
    } finally {
      if (onFinished != null) {
        onFinished();
      }
    }
  }



  _setWelch(Welch welch) {
    Provider.of<AppProvider>(context, listen: false).setWelch(welch);
  }

  _nextPage() async {
    Provider.of<AppProvider>(context, listen: false).clear();
    await Navigator.of(context).pushNamed('/structures');
  }

  @override
  void dispose() {
    _stopAccelerometer(updateUI: false);
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentStructure = Provider.of<AppProvider>(context).structure;


    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Time Series'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Position: ${widget.selectedLocation.toStringAsFixed(1)} meters",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),

                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.55,
                    child: LineChart(
                      LineChartData(
                        minX: 0,
                        minY: _calculateminY(),
                        maxY: _calculatemaxY(),
                        lineBarsData: [
                          LineChartBarData(
                            dotData: FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).colorScheme.primary.withOpacity(0.5),
                                  Colors.transparent,
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                            color: Theme.of(context).colorScheme.primary,
                            spots: _accelerometerSpots,
                            isCurved: true,
                            barWidth: 2,
                            isStrokeCapRound: true,
                          ),
                        ],
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: true, reservedSize: 30),
                            axisNameWidget: const Text('Time (s)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                          leftTitles: AxisTitles(
                            axisNameSize: 20,
                            axisNameWidget: const Text('Acceleration (m/s²)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            sideTitles: SideTitles(showTitles: true, reservedSize: 50),
                          ),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: true,
                          drawHorizontalLine: true,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: Theme.of(context).colorScheme.secondary,
                            strokeWidth: 0.5,
                          ),
                          getDrawingVerticalLine: (value) => FlLine(
                            color: Colors.transparent,
                            strokeWidth: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Align(
              alignment: Alignment.bottomCenter,
              child: BreadCrumb(
                pageType: PageType.reader,
                structureType: Provider.of<AppProvider>(context).structure.structure_type.toLowerCase(),
                onNext: () {},
                disabled: true,
              ),
            ),
          ],
        ),
      ),
    );

  }
}