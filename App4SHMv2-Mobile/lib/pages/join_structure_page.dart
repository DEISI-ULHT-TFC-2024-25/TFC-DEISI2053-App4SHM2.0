import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/network_service.dart';

class JoinStructurePage extends StatefulWidget {
  const JoinStructurePage({Key? key}) : super(key: key);

  @override
  State<JoinStructurePage> createState() => _JoinStructurePageState();
}

class _JoinStructurePageState extends State<JoinStructurePage> {
  final TextEditingController _codeController = TextEditingController();
  List<Map<String, dynamic>> _positions = [];
  int? _selectedPosition;
  bool _isLoading = false;
  bool _hasJoined = false;
  late NetworkService _service;

  Future<void> _fetchPositions() async {
    final code = _codeController.text;
    if (code == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Invalid code.")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _positions = [];
      _selectedPosition = null;
    });

    try {
      final data = await _service.fetchPositions(code);
      final available = data.where((p) => p['structure_position']['status'] == 'not connected').toList();

      setState(() {
        _positions = available;
        _hasJoined = true;
      });
    } catch (e) {
      if(e.toString().toLowerCase().contains('network does not exists')){

      ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Invalid code")),
      );
      }else{
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error finding structure: $e")),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _connectToSelectedPosition() async {
    final code = _codeController.text;
    if (code == null || _selectedPosition == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _service.joinNetwork(code, _selectedPosition!);
      _service.selectedPosition = _selectedPosition!;
      print('_service.selectedPosition depois de fazer _service.selectedPosition = _selectedPosition!;');
      print(_service.selectedPosition);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Connected successfully!")),
      );
      Navigator.of(context).pushNamed('/networkSlave', arguments: {'networkId': code});
    } catch (e) {
      if(e.toString().toLowerCase().contains('position occupied')){
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Position already occupied")),
        );
      }
      else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error connecting: $e")),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _service = context.read<NetworkService>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Join Structure")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Structure's Code", style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "Write the code",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _fetchPositions,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightGreen,
              ),
              child: Text("JOIN"),
            ),
            SizedBox(height: 24),
            if (_hasJoined)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text("Select a Position", style: TextStyle(fontSize: 16)),
                  SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    isExpanded: true,
                    hint: Text("Choose an available position"),
                    value: _selectedPosition,
                    items: _positions.map((pos) {
                      final loc = pos['structure_position']['position_location'];
                      return DropdownMenuItem<int>(
                        value: loc,
                        child: Text("${loc.toStringAsFixed(1)} meters"),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPosition = value;
                      });
                    },
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _selectedPosition != null && !_isLoading
                        ? _connectToSelectedPosition
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedPosition != null && !_isLoading
                          ? Colors.green
                          : Colors.grey,
                      disabledBackgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.white70,
                    ),
                    child: Text("Connect"),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
