class Damage {
  final bool damage;
  final double ucl;
  final List<double> history;

  final int cableForce;
  final int force_freq1;
  final int force_freq2;
  final int force_freq3;
  final List<double> forces;
  final List<double> pdf;
  final int countForces;

  Damage({required this.damage, required this.ucl, required this.history,this.cableForce = 0,this.force_freq1=0,this.force_freq2=0,this.force_freq3=0,this.forces = const [],this.pdf = const [],this.countForces = 0});
}