import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/network_service.dart';
import 'dart:async';
import 'package:provider/provider.dart';

class NetworkSlavePage extends StatefulWidget {
  final String networkId;

  const NetworkSlavePage({
    Key? key,
    required this.networkId,
  }) : super(key: key);

  @override
  State<NetworkSlavePage> createState() => _NetworkSlavePageState();
}

class _NetworkSlavePageState extends State<NetworkSlavePage> {
  late NetworkService service;
  bool _loaded = false;
  int? selectedLocation;
  Timer? _statusCheckTimer;

  @override
  void initState() {
    super.initState();
    _startStatusPolling(); // Inicia o polling ao montar a tela
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel(); // Cancela o timer ao desmontar a tela
    super.dispose();
  }

  Future<void> _confirmExit() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirm selection"),
        content: Text("Are you sure you want to exit this network?"),
        actions: [
          TextButton(
            child: Text("Cancel"),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
              child: Text("Exit", style: TextStyle(color: Colors.red)),
              onPressed: () => {
                Navigator
                    .of(context).pop(true),
              }
          ),
        ],
      ),
    );

    if (shouldExit == true) {
      try {
        await service.disconnectNetwork(widget.networkId,selectedLocation!);
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Network abandoned.")),
        );

        Navigator.pushNamedAndRemoveUntil(
          context,
          '/structures',
              (route) => false,
        );
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error exiting: $e")),
        );
      }
    }
  }



  void _startStatusPolling() {
    _statusCheckTimer = Timer.periodic(Duration(seconds: 1), (timer) async {
      try {
        final status = await NetworkService().fetchNetworkStatus(
            widget.networkId);
        if (status == 'reading') {
          _statusCheckTimer?.cancel();
          if (!mounted) return;
          Navigator.pushReplacementNamed(
            context,
            '/timeSeriesSlaveNetwork',
            arguments: {
              'networkId': widget.networkId,
              'selectedLocation': selectedLocation,
            },
          );
        }
      } catch (e) {
        print("Erro ao verificar status: $e");
      }
    });
  }

  Future<void> _loadCurrentPosition() async {
    try {
      final data = await service.fetchPositions(widget.networkId);

      final pos = service.selectedPosition;
      print('service.selectedPosition na network slave');
      print(service.selectedPosition);
      if (pos == null) {
        setState(() {
          selectedLocation = null;
        });
        return;
      }

      final matched = data.firstWhere(
            (p) =>
        p['structure_position']['position_location'] == pos &&
            p['structure_position']['status'] == 'connected',
        orElse: () => <String, dynamic>{},
      );

      setState(() {
        selectedLocation = matched.isNotEmpty ? pos : null;
      });
    } catch (e) {
      print("❌ Erro ao carregar posição: $e");
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      service = context.read<NetworkService>();
      _loadCurrentPosition();
      _loaded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          await _confirmExit();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text('Network Info')),
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text("Code: ${widget.networkId}", style: TextStyle(fontSize: 20)),
                      SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.copy, size: 20),
                        tooltip: "Copy Code",
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: widget.networkId));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Code copied to clipboard')),
                          );
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  if (selectedLocation != null)
                    Text(
                      "Connected to position: ${selectedLocation!.toStringAsFixed(1)} meters",
                      style: TextStyle(fontSize: 18, color: Colors.green[700]),
                    )
                  else
                    Text("Not connected to any position", style: TextStyle(fontSize: 18)),
                  Spacer(),
                  Center(
                    child: IconButton(
                      icon: Icon(Icons.close, color: Colors.red, size: 32),
                      onPressed: _confirmExit,
                    ),
                  ),
                ],
              ),
            ),
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "This device is on standby.\nAwaiting synchronization command from the master device",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}