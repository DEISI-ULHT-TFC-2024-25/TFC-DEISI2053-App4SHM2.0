import 'dart:convert';
import 'package:app4shm/models/structure.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:app4shm/util/http_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StructuresService {
  Future<List<Structure>> getStructures() async {
    var response = await http.get(Uri.parse(dotenv.env['BASE_URL']! + dotenv.env['STRUCTURES_URL']!), headers: {
      'Authorization': 'Token ${(await SharedPreferences.getInstance()).getString('token')!}',
    });
    if (response.statusCode == 200) {
      var structuresJson = jsonDecode(response.body) as List<dynamic>;
      var structures = structuresJson.map((structureJson) => Structure(
          id: structureJson['id'],
          name: utf8.decode(structureJson['name'].toString().codeUnits),
          count: structureJson['count'],
          structure_type: utf8.decode(structureJson['structure_type'].toString().codeUnits),
          cable_length: (structureJson['cable_length'] ?? 0.0).toDouble(),
          cable_mass: (structureJson['cable_mass'] ?? 0.0).toDouble(),
          training: false
      )).toList();
      print(structuresJson);
      return structures;
    } else if (response.statusCode == 401) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.remove('token');
      throw Exception('Unauthorized');
    } else {
      throw Exception('Failed to load structures');
    }
  }
}