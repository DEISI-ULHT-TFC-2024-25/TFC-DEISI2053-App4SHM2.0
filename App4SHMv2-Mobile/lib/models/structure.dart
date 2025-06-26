class Structure {
  final int id;
  final String name;
  final int count;
  bool training;
  final String structure_type;
  final double cable_mass;
  final double cable_length;

  Structure({required this.id, required this.name,required this.cable_mass,required this.cable_length,required this.structure_type, required this.count, required this.training});


  @override
  String toString() {
    return 'Structure{id: $id, name: $name,type: $structure_type count: $count, training: $training}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Structure && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  void setTraining(bool training) {
    this.training = training;
  }
}