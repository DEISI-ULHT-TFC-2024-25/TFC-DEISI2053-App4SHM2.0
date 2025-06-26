import 'dart:ffi';

import 'package:app4shm/models/damage.dart';
import 'package:app4shm/models/structure.dart';
import 'package:app4shm/models/welch.dart';
import 'package:flutter/material.dart';

import '../models/user.dart';

class AppProvider extends ChangeNotifier {
  Structure _structure = Structure(
      id: 0,
      name: '',
      cable_mass: 0,
      cable_length: 0,
      structure_type: 'structure',
      training: true,
      count: 0);

  Structure get structure => _structure;

  Welch _welch = Welch(id: 0, meanLocal: [], welchF: [], welchZ: []);

  Welch get welch => _welch;

  Damage _damage = Damage(damage: false, ucl: 0, history: []);

  Damage get damage => _damage;

  User _user = User('');

  User get user => _user;

  int _cableForce = 0;

  int get cableForce => _cableForce;

  int _freqForce1 = 0;

  int get freqForce1 => _freqForce1;

  int _freqForce2 = 0;

  int get freqForce2 => _freqForce2;

  int _freqForce3 = 0;

  int get freqForce3 => _freqForce3;

  double _freq1 = 0;

  double get freq1 => _freq1;

  double _freq2 = 0;

  double get freq2 => _freq2;

  double _freq3 = 0;

  double get freq3 => _freq3;

  List<double> _pdf = [];

  List<double> get pdf => _pdf;

  List<double> _forces = [];

  List<double> get forces => _forces;

  int _countForces = 0;
  int get countForces => _countForces;

  setUser(User value) {
    _user = value;
  }

  void setWelch(Welch welch) {
    _welch = welch;
    notifyListeners();
  }

  void setStructure(Structure structure) {
    _structure = structure;
    notifyListeners();
  }

  void setDamage(Damage damage) {
    _damage = damage;
    notifyListeners();
  }

  void setCableForce(int cableForce) {
    _cableForce = cableForce;
    notifyListeners();
  }

  void setfreq1(double x) {
    _freq1 = x;
    notifyListeners();
  }

  void setfreq2(double x) {
    _freq2 = x;
    notifyListeners();
  }

  void setfreq3(double x) {
    _freq3 = x;
    notifyListeners();
  }

  void setfreqForce1(int x) {
    _freqForce1 = x;
    notifyListeners();
  }

  void setfreqForce2(int x) {
    _freqForce2 = x;
    notifyListeners();
  }

  void setfreqForce3(int x) {
    _freqForce3 = x;
    notifyListeners();
  }

  void setPdf(List<double> list){
    _pdf = list;
    notifyListeners();
  }

  void setForces(List<double> list){
    _forces = list;
    notifyListeners();
  }

  void setCountForces(int x){
    _countForces = x;
    notifyListeners();
  }



  void clear() {
    _welch = Welch(id: 0, meanLocal: [], welchF: [], welchZ: []);

    // don't clear structure
    // _structure = Structure(id: 0, name: '', count: 0, training: false);
    _damage = Damage(damage: false, ucl: 0, history: []);
    notifyListeners();
  }

  void clearStructure() {
    _structure = Structure(
        id: 0,
        name: '',
        cable_mass: 0,
        cable_length: 0,
        structure_type: 'structure',
        training: true,
        count: 0);
    notifyListeners();
  }
}
