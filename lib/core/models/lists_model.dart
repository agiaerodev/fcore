class Station {
  final int id;
  final String name;
  final String? fullName;
  final String? code;

  Station({
    required this.id,
    required this.name,
    this.fullName,
    this.code,
  });

  factory Station.fromJson(Map<String, dynamic> json) => Station(
        id: json["id"] ?? 0,
        name: json["name"] ?? "",
        fullName: json["fullName"] ?? json["full_name"],
        code: json["code"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "fullName": fullName,
        "code": code,
      };
}

class FlightType {
  final int id;
  final String name;

  FlightType({
    required this.id,
    required this.name,
  });

  factory FlightType.fromJson(Map<String, dynamic> json) => FlightType(
        id: json["id"] ?? 0,
        name: json["name"] ?? "",
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
      };
}

class GreetStatus {
  final int id;
  final String name;
  final bool? status;
  final String? color;

  GreetStatus({
    required this.id,
    required this.name,
    this.status,
    this.color,
  });

  factory GreetStatus.fromJson(Map<String, dynamic> json) => GreetStatus(
        id: json["id"] ?? 0,
        name: json["name"] ?? "",
        status: json["status"],
        color: json["color"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "status": status,
        "color": color,
      };
}
