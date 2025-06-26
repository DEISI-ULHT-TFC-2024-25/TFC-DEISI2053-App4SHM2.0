import 'package:app4shm/models/structure.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/network_service.dart';
import 'package:provider/provider.dart';

class NetworkMasterPage extends StatefulWidget {
  final String networkId;
  final Structure structure;

  const NetworkMasterPage({
    Key? key,
    required this.networkId,
    required this.structure,
  }) : super(key: key);

  @override
  State<NetworkMasterPage> createState() => _NetworkMasterPageState();
}

class _NetworkMasterPageState extends State<NetworkMasterPage> {
  List<Map<String, dynamic>> positions = [];
  List<int> availableLocations = [];
  int? selectedLocation;
  late NetworkService service;
  bool _loaded = false;
  bool _isConnecting = false;


  @override
  void initState() {
    super.initState();
    selectedLocation = null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      service = context.read<NetworkService>();

      service.selectedPosition = null;

      _loadPositions();
      _loaded = true;
    }
  }

  Future<void> _loadPositions() async {
    try {
      final data = await service.fetchPositions(widget.networkId);

      setState(() {
        positions = data;

        availableLocations = data
            .where((pos) => pos['structure_position']['status'] == 'not connected')
            .map<int>((pos) => pos['structure_position']['position_location'])
            .toList();

        selectedLocation ??= service.selectedPosition;
      });
    } catch (e) {
      print("Error loading positions: $e");
    }
  }


  @override
  void dispose() {
    service.selectedPosition = null;
    super.dispose();
  }


  Future<void> _confirmAndDelete() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirm selection"),
        content: Text("Are you sure you want to delete this network? This action can not be undone."),
        actions: [
          TextButton(
            child: Text("Cancel"),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: Text("Delete", style: TextStyle(color: Colors.red)),
            onPressed: () => {
              NetworkService().selectedPosition = null,
              selectedLocation = null,
              Navigator
            .of(context).pop(true),
            }
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        await service.deleteNetwork(widget.networkId);
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Network deleted sucessfuly.")),
        );

        Navigator.pushNamedAndRemoveUntil(
          context,
          '/structures',
              (route) => false,
        );
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error deleting network: $e")),
        );
      }
    }
  }



  Map<String, dynamic>? findPosition(int loc) {
    for (var pos in positions) {
      if (pos['structure_position']['position_location'] == loc) return pos;
    }
    return null;
  }

  Future<void> _connectToPosition(int newLocation) async {
    if (_isConnecting) return;

    setState(() {
      _isConnecting = true;
    });

    try {
      if (selectedLocation != null) {
        await service.disconnectNetwork(widget.networkId, selectedLocation!);
      }

      await service.joinNetwork(widget.networkId, newLocation);
      service.selectedPosition = newLocation;

      await _loadPositions();

      setState(() {
        selectedLocation = newLocation;
      });
    } catch (e) {
      if(e.toString().toLowerCase().contains('position occupied')){
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Position already occupied")),
        );
      }else{
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$e")),
        );
      }

    } finally {
      setState(() {
        _isConnecting = false;
      });
    }
  }

  Future<void> _disconnect() async {
    if (selectedLocation == null || _isConnecting) return;

    setState(() {
      _isConnecting = true;
    });

    try {
      await service.disconnectNetwork(widget.networkId, selectedLocation!);
      await _loadPositions();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Disconnected")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error connecting: $e")),
      );
    } finally {
      setState(() {
        _isConnecting = false;
        selectedLocation = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String structureName = widget.structure.name;
    final int structureId = widget.structure.id;
    return Scaffold(
        appBar: AppBar(title: const Text('Multiple devices configuration')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text("Structure: $structureName (ID: $structureId)", style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              Text("A devices' network has been created with the following code. Please select the position of this device.",
                  style: TextStyle(fontSize: 14, color: Colors.grey[700])),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text("Code: ${widget.networkId}", style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    tooltip: "Copy Code",
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: widget.networkId));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Code copied to clipboard')),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),


              if (selectedLocation != null)
                Container(
                  padding: const EdgeInsets.all(8.0),
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.link, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        "Connected: ${selectedLocation!.toStringAsFixed(1)} meters",
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else
                const Text("Select a Position", style: TextStyle(fontSize: 18)),

              DropdownButton<int>(
                value: null,
                hint: Text(availableLocations.isEmpty
                    ? "No position available"
                    : "Choose a position"),
                isExpanded: true,
                items: availableLocations.map((loc) {
                  final posData = findPosition(loc);
                  final meters = posData?['structure_position']?['position_location'] ?? 0.0;

                  return DropdownMenuItem<int>(
                    value: loc,
                    child: Text("${meters.toStringAsFixed(1)} meters"),
                  );
                }).toList(),
                onChanged: (_isConnecting || availableLocations.isEmpty)
                    ? null
                    : (value) {
                  if (value != null) {
                    _connectToPosition(value);
                  }
                },
              ),

              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: positions.length,
                  itemBuilder: (context, index) {
                    final pos = positions[index]['structure_position'];
                    final meters = pos['position_location'];
                    final status = pos['status'];
                    final isConnected = status == 'connected';
                    final isUserDevice = meters == selectedLocation;

                    return ListTile(
                      title: Text("${meters.toStringAsFixed(1)} meters"),
                      subtitle: Text(
                        isConnected
                            ? isUserDevice
                            ? 'Connected (Your device)'
                            : 'Connected'
                            : 'Not Connected',
                        style: TextStyle(
                          color: isConnected
                              ? (isUserDevice ? Colors.green[800] : Colors.green)
                              : Colors.grey,
                          fontWeight: isUserDevice ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      trailing: Icon(
                        isConnected ? Icons.link : Icons.link_off,
                        color: isConnected
                            ? (isUserDevice ? Colors.green[800] : Colors.green)
                            : Colors.grey,
                      ),
                    );
                  },
                ),
              ),


              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.red),
                        onPressed: _confirmAndDelete,
                      ),
                      Text("Delete", style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  Column(
                    children: [
                      IconButton(
                        icon: Icon(Icons.refresh, color: Colors.blue),
                        onPressed: _isConnecting ? null : _loadPositions,
                      ),
                      Text("Refresh", style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  if (selectedLocation != null)
                    Column(
                      children: [
                        IconButton(
                          icon: Icon(Icons.link_off, color: Colors.orange),
                          onPressed: _disconnect,
                        ),
                        Text("Disconnect", style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  Column(
                    children: [
                      IconButton(
                        icon: Icon(Icons.check, color: Colors.green),
                        onPressed: () {
                          if (selectedLocation == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please select a position before continuing.'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                            return;
                          }

                          Navigator.pushNamed(
                            context,
                            '/timeSeriesMasterNetwork',
                            arguments: {'networkId': widget.networkId, 'selectedLocation': selectedLocation},
                          );
                        },

                      ),
                      Text("Continue", style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      );
  }
}
