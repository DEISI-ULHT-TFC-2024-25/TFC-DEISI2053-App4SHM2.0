import 'dart:convert';

import 'package:app4shm/models/damage.dart';
import 'package:app4shm/models/structure.dart';
import 'package:app4shm/models/welch.dart';
import 'package:app4shm/util/http_client.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:http_parser/http_parser.dart';

class ReadingsService {
  late SharedPreferences _prefs;

  Future<Welch> uploadReadings(
      File file, String structureId, String structureName) async {
    _prefs = await SharedPreferences.getInstance();
    // Build form data
    var request = http.MultipartRequest('POST',
        Uri.parse(dotenv.env['BASE_URL']! + dotenv.env['READINGS_URL']!));
    request.headers['Authorization'] = 'Token ${_prefs.getString('token')}';
    request.fields['structure'] = structureId;
    request.files.add(await http.MultipartFile.fromPath('raw_file', file.path,
        contentType: MediaType('text', 'plain')));

    // Send request and handle response
    var response = await httpClient.send(request);
    // var response = await request.send();
    if (response.statusCode == 201) {
      String responseString = await response.stream.bytesToString();
      return await processRecievedData(responseString, structureName);
    } else {
      print(response.statusCode);
      throw Exception('Failed to upload readings');
    }
  }

  Future<Welch> processRecievedData(
      String response, String structureName) async {
    int id = 0;
    String welchText = "";
    List<double> meanLocal = [];
    List<double> welchF = [];
    List<double> welchX = [];
    List<double> welchY = [];
    List<double> welchZ = [];

    final responseObj = jsonDecode(response);

    id = responseObj['id'] as int;

    final meansArray = responseObj['mean'] as List<dynamic>;
    for (int i = 0; i < meansArray.length; i++) {
      meanLocal.add(meansArray[i].toDouble());
    }

    meanLocal.sort();

    final freqArray = responseObj['frequencies'] as List<dynamic>;
    for (int i = 0; i < freqArray.length; i++) {
      welchF.add(freqArray[i].toDouble());
    }

    final xArray = responseObj['x'] as List<dynamic>;
    for (int i = 0; i < xArray.length; i++) {
      welchX.add(xArray[i].toDouble());
    }

    final yArray = responseObj['y'] as List<dynamic>;
    for (int i = 0; i < yArray.length; i++) {
      welchY.add(yArray[i].toDouble());
    }

    final zArray = responseObj['z'] as List<dynamic>;
    for (int i = 0; i < zArray.length; i++) {
      welchZ.add(zArray[i].toDouble());
    }

    welchF = welchF;
    welchX = welchX;
    welchY = welchY;
    welchZ = welchZ;

    for (int i = 0; i < welchF.length; i++) {
      welchText += "${welchF[i]};${welchZ[i]}\n";
    }

    try {
      final String date = DateTime.now().toString().substring(0, 16);
      await writeToFile("welch-$structureName-$date.csv", welchText);
      return Welch(
          meanLocal: meanLocal, welchF: welchF, welchZ: welchZ, id: id);
    } catch (e) {
      throw Exception('Failed to write readings');
    }
  }

  Future<File> writeToFile(String fileName, String text) async {
    final directory = await getApplicationDocumentsDirectory();
    final app4shmDirectory = Directory('${directory.path}/App4SHM');
    if (!await app4shmDirectory.exists()) {
      await app4shmDirectory.create(recursive: true);
    }
    final file = File('${app4shmDirectory.path}/$fileName');
    await file.writeAsString(text);
    return file;
  }

  Future<Damage> sendPowerSpectrum(Structure structure, Welch welch,
      List<double> points, bool training) async {
    bool isCable = false;
    if (structure.structure_type.toLowerCase() == 'cable') {
      isCable = true;
    }
    _prefs = await SharedPreferences.getInstance();

    if (points.isEmpty || points.length < 3) {
      throw Exception('A lista de pontos deve conter pelo menos 3 valores de frequência.');
    }

    final String pointsJson = "[ ${points[0]}, ${points[1]}, ${points[2]}]";
    final String body = '{"structure": ${structure.id}, "reading": ${welch.id}, "frequencies": $pointsJson, "training": $training}';

    // DEBUG: Print request details
    print('=== SENDING REQUEST DEBUG ===');
    print('URL: ${dotenv.env['BASE_URL']! + dotenv.env['FREQUENCIES_URL']!}');
    print('Body: $body');
    print('Token exists: ${_prefs.getString('token') != null}');
    print('Token: ${_prefs.getString('token')}');
    print('============================');

    final response = await http.post(
      Uri.parse(dotenv.env['BASE_URL']! + dotenv.env['FREQUENCIES_URL']!),
      headers: {
        'Authorization': 'Token ${_prefs.getString('token')}',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    // DEBUG: Print response details
    print('=== RESPONSE DEBUG ===');
    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');
    print('Response Headers: ${response.headers}');
    print('===================');

    if (response.statusCode != 201) {
      // Try to get more details from the error response
      String errorDetails = 'Failed to send power spectrum';
      try {
        final errorBody = jsonDecode(response.body);
        errorDetails += ': ${errorBody.toString()}';
      } catch (e) {
        errorDetails += ': ${response.body}';
      }
      throw Exception(errorDetails);
    } else if (!training) {
      // ... rest of the method remains the same
      final responseObj = jsonDecode(response.body);
      final List<double> history = responseObj['history'].cast<double>();

      if (isCable) {
        final responseCableForce = await http.post(
          Uri.parse(dotenv.env['BASE_URL']! + dotenv.env['CABLEFORCE_URL']!),
          headers: {
            'Authorization': 'Token ${_prefs.getString('token')}',
            'Content-Type': 'application/json',
          },
          body: body,
        );

        if(responseCableForce.statusCode != 201){
          throw Exception('Failed to send power spectrum');
        }

        final responseObjCable = jsonDecode(responseCableForce.body);

        print('Response Cable Force: ${responseObjCable}');
        int cableForceValue = responseObjCable['cable_force'] ?? 0;
        int forceFreq1value = responseObjCable['force_freq1'] ?? 0;
        int forceFreq2value = responseObjCable['force_freq2'] ?? 0;
        int forceFreq3value = responseObjCable['force_freq3'] ?? 0;
        List<double> forces = List<double>.from(responseObjCable['forces'] ?? []);
        List<double> pdf = List<double>.from(responseObjCable['pdf'] ?? []);
        int countForces = responseObjCable['count'] ?? 0;

        return Damage(
            damage: responseObj['damage'],
            ucl: responseObj['ucl'],
            history: history,
            cableForce: cableForceValue,
            force_freq1: forceFreq1value,
            force_freq2: forceFreq2value,
            force_freq3: forceFreq3value,
            forces: forces,
            pdf: pdf,
            countForces: countForces
        );
      }
      return Damage(
          damage: responseObj['damage'],
          ucl: responseObj['ucl'],
          history: history);
    } else {
      if (isCable) {
        final responseCableForce = await http.post(
          Uri.parse(dotenv.env['BASE_URL']! + dotenv.env['CABLEFORCE_URL']!),
          headers: {
            'Authorization': 'Token ${_prefs.getString('token')}',
            'Content-Type': 'application/json',
          },
          body: body,
        );

        if(responseCableForce.statusCode != 201){
          throw Exception('Failed to send power spectrum');
        }

        final responseObjCable = jsonDecode(responseCableForce.body);

        print('Response Cable Force: ${responseObjCable}');

        int cableForceValue = responseObjCable['cable_force'] ?? 0;
        int forceFreq1value = responseObjCable['force_freq1'] ?? 0;
        int forceFreq2value = responseObjCable['force_freq2'] ?? 0;
        int forceFreq3value = responseObjCable['force_freq3'] ?? 0;
        int countForces = responseObjCable['count'] ?? 0;
        List<double> forces = List<double>.from(responseObjCable['forces'] ?? []);
        List<double> pdf = List<double>.from(responseObjCable['pdf'] ?? []);

        return Damage(
            damage: false,
            ucl: 0,
            history: [],
            cableForce: cableForceValue,
            force_freq1: forceFreq1value,
            force_freq2: forceFreq2value,
            force_freq3: forceFreq3value,
            forces: forces,
            pdf: pdf,
            countForces: countForces
        );
      }
      return Damage(damage: false, ucl: 0, history: []);
    }
  }
}
