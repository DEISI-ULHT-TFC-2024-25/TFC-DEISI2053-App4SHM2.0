import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app4shm/util/http_client.dart';

class NetworkService {
  int? selectedPosition;

  Future<String> createNetwork(int structureId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');
    if (token == null) {
      throw Exception("User not authenticated.");
    }

    final Uri url = Uri.parse('${dotenv.env['BASE_URL']!}/network/create/');

    final response = await httpClient.post(
      url,
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'structureId': structureId}),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['networkId'];
    } else {
      throw Exception('Error creating network: ${response.body}');
    }
  }

  Future<void> joinNetwork(String networkId, int location) async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');
    if (token == null) throw Exception("User not authenticated.");

    final url = Uri.parse('${dotenv.env['BASE_URL']!}/network/join/');

    final response = await httpClient.post(
      url,
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'networkId': networkId,
        'location': location,
      }),
    );

    if (response.statusCode == 200) {
      selectedPosition = location;
    } else {
      throw Exception("Error connecting: ${response.body}");
    }
  }

  Future<void> disconnectNetwork(String networkId, int location) async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');
    if (token == null) throw Exception("User not authenticated.");

    final url = Uri.parse('${dotenv.env['BASE_URL']!}/network/disconnect/');

    final response = await httpClient.post(
      url,
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'networkId': networkId,
        'location': location,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Error disconnecting: ${response.body}");
    }

    selectedPosition = null;
  }

  Future<List<Map<String, dynamic>>> fetchPositions(String networkId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');
    if (token == null) {
      throw Exception("User not authenticated.");
    }

    final Uri url = Uri.parse('${dotenv.env['BASE_URL']!}/network/info/?networkId=$networkId');

    final response = await httpClient.get(
      url,
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['locations']);
    } else {
      throw Exception('Error fetching positions: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> fetchReadingsInfo(String networkId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');
    if (token == null) {
      throw Exception("User not authenticated.");
    }

    final Uri url = Uri.parse('${dotenv.env['BASE_URL']!}/network/readings/?networkId=$networkId');

    final response = await httpClient.get(
      url,
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error fetching network info: ${response.body}');
    }
  }

  Future<void> sendNetworkStatusUpdate({
    required String networkId,
    required String status,
    String? startDate,
    String? endDate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');

    if (token == null) throw Exception("Utilizador não autenticado.");

    final Uri url = Uri.parse('${dotenv.env['BASE_URL']!}/network/set-status/');

    final Map<String, dynamic> body = {
      'networkId': networkId,
      'status': status,
    };

    if (status == 'reading') {
      if (startDate == null) {
        throw Exception("startDate is mandatory for 'reading'.");
      }
      body['startDate'] = startDate;
    } else if (status == 'completed') {
      if (endDate == null) {
        throw Exception("endDate is mandatory for 'completed'.");
      }
      body['endDate'] = endDate;
    }

    final response = await httpClient.post(
      url,
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('Falha ao atualizar o status da network: ${response.body}');
    }
  }

  Future<String> fetchNetworkStatus(String networkId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');

    if (token == null) {
      throw Exception("Utilizador não autenticado.");
    }

    final Uri url = Uri.parse('${dotenv.env['BASE_URL']!}/network/set-status/?networkId=$networkId');

    final response = await httpClient.get(
      url,
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['status'];
    } else if (response.statusCode == 404) {
      throw Exception('Network não encontrada.');
    } else {
      throw Exception('Erro ao obter status da network: ${response.body}');
    }
  }

  Future<void> allocateReading({
    required String networkId,
    required int location,
    required int readingId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');

    if (token == null) {
      throw Exception("User not authenticated.");
    }

    final Uri url = Uri.parse('${dotenv.env['BASE_URL']!}/network/readings/');

    final response = await httpClient.post(
      url,
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'networkId': networkId,
        'location': location,
        'reading': readingId,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Error allocating reading: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> fetchNetworkReadings(String networkId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');

    if (token == null) {
      throw Exception("User not authenticated.");
    }

    final Uri url = Uri.parse('${dotenv.env['BASE_URL']!}/network/readings/?networkId=$networkId');

    final response = await httpClient.get(
      url,
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      } else {
        throw Exception("Unexpected response format: ${response.body}");
      }
    } else if (response.statusCode == 404) {
      throw Exception('Network not found.');
    } else if (response.statusCode == 500) {
      throw Exception('No valid readings.');
    } else {
      throw Exception('Error obtaining data from network: ${response.body}');
    }
  }

  Future<void> deleteNetwork(String networkId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');

    if (token == null) {
      throw Exception("User not authenticated.");
    }

    final Uri url = Uri.parse('${dotenv.env['BASE_URL']!}/network/delete/');

    final response = await httpClient.delete(
      url,
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'networkId': networkId}),
    );

    if (response.statusCode != 200) {
      throw Exception('Error deleting network: ${response.body}');
    }
  }
}
