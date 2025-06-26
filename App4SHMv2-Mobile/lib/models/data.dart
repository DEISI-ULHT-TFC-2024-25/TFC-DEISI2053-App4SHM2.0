class Data {
  final String id;
  final int timeStamp;
  final double x;
  final double y;
  final double z;
  final String group;

  Data({required this.id, required this.timeStamp, required this.x, required this.y, required this.z, required this.group});

  @override
  String toString() {
    return "ID: $id | group: $group | Timestamp: $timeStamp | X: $x | Y: $y | Z: $z\n";
  }

  String JSONer() {
    return "{\"id\": \"$id\", \"timeStamp\": $timeStamp, \"x\": $x, \"y\": $y, \"z\": $z, \"group\": \"$group\"}";
  }

  String toCSV() {
  return "$timeStamp;$x;$y;$z\n";
  }
}