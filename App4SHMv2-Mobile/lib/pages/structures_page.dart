import 'package:app4shm/components/alert_dialogs.dart';
import 'package:app4shm/models/structure.dart';
import 'package:app4shm/providers/app_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app4shm/services/structures_service.dart';
import '../components/breadcrumb.dart';
import '../services/network_service.dart';

class StructuresPage extends StatefulWidget {
  const StructuresPage({Key? key}) : super(key: key);

  @override
  State<StructuresPage> createState() => _StructuresPageState();
}

class _StructuresPageState extends State<StructuresPage> {
  late SharedPreferences prefs;
  bool _training = true;
  bool _createRoom = false;
  bool _shownWarningDialog = false;
  String? selectedStructureType;

  @override
  void initState() {
    getSharedPrefs();
    super.initState();
  }

  getSharedPrefs() async {
    prefs = await SharedPreferences.getInstance();

    setState(() {
      _createRoom = false;
      _training = true;
      _shownWarningDialog = false;
    });
  }

  _onSelectStructure(Structure structure) {
    setState(() {
      selectedStructureType = structure.structure_type
          .toLowerCase(); // Stores the struc type
    });
    if (selectedStructureType == 'cable') {
      _createRoom = false;
    }
  }

  void _handleClick(String value) {
    switch (value) {
      case 'Logout':
        {
          prefs.remove('token');
          prefs.remove('structureId');
          Provider.of<AppProvider>(context, listen: false).clearStructure();
          Navigator.of(context).pushNamedAndRemoveUntil(
              '/login', (Route<dynamic> route) => false);
          break;
        }
      case 'Join Structure':
        Navigator.of(context).pushNamed('/joinStructure');
        break;

      case 'About us':
        Navigator.of(context).pushNamed('/about');
        break;
    }
  }

  _next({Function? onFinished}) async {
    final currentStructure =
        Provider.of<AppProvider>(context, listen: false).structure;

    if (currentStructure.name.startsWith('Testing structure') &&
        !_shownWarningDialog) {
      await showAlertDialog(
        context: context,
        title: 'Warning',
        content:
        'You selected the "${currentStructure.name}" which is only used for demonstration purposes. '
            'All captured data will be cleaned up and damage detection results are not reliable.',
      );
      _shownWarningDialog = true;
    }

    Provider.of<AppProvider>(context, listen: false)
        .structure
        .setTraining(_training);

    if (_createRoom) {
      try {
        final String networkId = await NetworkService().createNetwork(currentStructure.id);
        Navigator.of(context).pushNamed(
          '/networkMaster',
          arguments: {
            'networkId': networkId,
            'structure': currentStructure,
          },
        ).then((value) => onFinished?.call());
      } catch (e) {
        await showAlertDialog(
          context: context,
          title: 'Error',
          content: 'Failed to create room: ${e.toString()}',
        );
      }
    } else {
      Navigator.of(context)
          .pushNamed('/timeseries')
          .then((value) => onFinished?.call());
    }
  }


  @override
  Widget build(BuildContext context) {
    final currentStructure =
        Provider.of<AppProvider>(context, listen: false).structure;

    bool damageDetectionAvailable = currentStructure.count > 3;

    return Scaffold(
        appBar: AppBar(
          title: const Text('Structures'),
          actions: [
            PopupMenuButton<String>(
              onSelected: _handleClick,
              itemBuilder: (BuildContext context) {
                return {'Logout', 'Join Structure', 'About us'}.map((String choice) {
                  return PopupMenuItem<String>(
                    value: choice,
                    child: Text(choice),
                  );
                }).toList();
              },
            )
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      const Text(
                        'Select a structure',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      StructuresDropdown(
                        updateInitialStructure: currentStructure.id == 0
                            ? _onSelectStructure
                            : (_) => setState(() {}),
                        // ! Atualiza estrutura inicial
                        onSelectStructure:
                            _onSelectStructure, // ! Passando função de seleção correta
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        'Select type of analysis',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      CheckboxListTile(
                        title: const Text('Training data'),
                        value: _training,
                        onChanged: (value) => setState(() {
                          _training = value!;
                        }),
                      ),
                      const SizedBox(height: 10),
                      if (selectedStructureType == 'structure')
                        CheckboxListTile(
                          title: const Text('Multiple devices reading'),
                          value: _createRoom,
                          onChanged: (value) => setState(() {
                            _createRoom = value!;
                          }),
                        ),

                      damageDetectionAvailable
                          ? CheckboxListTile(
                              title: const Text('Damage detection'),
                              value: !_training,
                              onChanged: (value) => setState(() {
                                _training = !value!;
                              }),
                            )
                          : Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  const Expanded(
                                      child: Text(
                                          'Not enough data to perform damage detection',
                                          style: TextStyle(color: Colors.red))),
                                  TextButton(
                                    onPressed: () => showAlertDialog(
                                      context: context,
                                      title: 'Information',
                                      content:
                                          'The application can only perform damage detection after at least 4 readings.'
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
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: BreadCrumb(
                    pageType: PageType.structures,
                    structureType: selectedStructureType,
                    onNext: _next),
              ),
            ],
          ),
        ));
  }
}

// separate the dropdown as a widget
class StructuresDropdown extends StatefulWidget {
  final Function onSelectStructure;
  final Function? updateInitialStructure;

  const StructuresDropdown(
      {Key? key, this.updateInitialStructure, required this.onSelectStructure})
      : super(key: key);

  @override
  State<StructuresDropdown> createState() => _StructuresDropdownState();
}

class _StructuresDropdownState extends State<StructuresDropdown> {
  late SharedPreferences prefs;
  List<Structure> _structures = [];
  bool _isLoading = true;

  _initPrefs() async {
    prefs = await SharedPreferences.getInstance();
  }

  @override
  void initState() {
    updateStructures();
    super.initState();
  }

  updateStructures() async {
    _isLoading = true;
    await _initPrefs();

    try {
      final structures = await StructuresService().getStructures();
      if (structures.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No structures found'),
          ),
        );
      } else if (widget.updateInitialStructure != null) {
        Structure structure = structures.first;
        if (prefs.getInt('structureId') != null) {
          structure = structures.firstWhere(
              (element) => element.id == prefs.getInt('structureId'),
              orElse: () => structures.first);
        }

        Provider.of<AppProvider>(context, listen: false)
            .setStructure(structure);
        widget.updateInitialStructure!(structure);
      }
      setState(() {
        _structures = structures;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint(e.toString());
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Structure? currentStructure =
        Provider.of<AppProvider>(context, listen: false).structure;

    if (!_isLoading) {
      if (currentStructure.id == 0) {
        final previousSelectedStructureId = prefs.getInt('structureId');
        if (previousSelectedStructureId != null) {
          currentStructure = _structures.isNotEmpty
              ? _structures.firstWhere(
                  (element) => element.id == prefs.getInt('structureId'),
                  orElse: () => _structures.first)
              : null;
        } else {
          currentStructure = _structures.isNotEmpty ? _structures.first : null;
        }
      }
    }

    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: DropdownButton(
                isExpanded: true,
                value: currentStructure,
                hint: const Text('Structure list'),
                enableFeedback: true,
                dropdownColor: Theme.of(context).colorScheme.background,
                borderRadius: BorderRadius.circular(10),
                icon: const Icon(Icons.arrow_drop_down_circle_rounded),
                items: _structures.map((Structure structure) {
                  return DropdownMenuItem<Structure>(
                    value: structure,
                    child: Row(
                      children: [
                        Image.asset(
                          structure.structure_type.toLowerCase() == 'cable'
                              ? Theme.of(context).brightness == Brightness.light
                                  ? 'assets/cable-dark.png'
                                  : 'assets/cable-white.png'
                              : Theme.of(context).brightness == Brightness.light
                                  ? 'assets/bridge-dark.png'
                                  : 'assets/bridge-white.png',
                          width: 24,
                          height: 24,
                        ),
                        const SizedBox(
                            width: 10),
                        Text("${structure.name} (${structure.count})"),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  Provider.of<AppProvider>(context, listen: false)
                      .setStructure(value!);
                  prefs.setInt('structureId', value.id);
                  widget.onSelectStructure(value);
                },
              ),
            ),
          );
  }
}
