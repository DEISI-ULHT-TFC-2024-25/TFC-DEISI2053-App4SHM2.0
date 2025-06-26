class Welch {
  int id;
  List<double> meanLocal ;
  List<double> welchF;
  List<double> welchZ;
  bool isLogScale = true;

  Welch({required this.meanLocal, required this.welchF, required this.welchZ, this.isLogScale = true, required this.id});

  @override
  String toString() {
    return 'Welch(meanLocal: $meanLocal, welchF: $welchF, welchZ: $welchZ)';
  }
}