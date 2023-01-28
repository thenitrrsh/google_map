class Coordinate {
  Coordinate({
    this.latitude,
    this.longitude,
  });

  double? latitude;
  double? longitude;

  factory Coordinate.fromJson(Map<String, dynamic> json) => Coordinate(
        latitude: json["Latitude"].toDouble(),
        longitude: json["Longitude"].toDouble(),
      );

  Map<String, dynamic> toJson() => {
        "Latitude": latitude,
        "Longitude": longitude,
      };
}
