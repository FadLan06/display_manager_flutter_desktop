class DisplayConfig {
  int? id;
  String displayId;
  bool fullscreen;

  DisplayConfig({
    this.id,
    required this.displayId,
    required this.fullscreen,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'display_id': displayId,
      'fullscreen': fullscreen ? 1 : 0,
    };
  }

  factory DisplayConfig.fromMap(Map<String, dynamic> map) {
    return DisplayConfig(
      id: map['id'],
      displayId: map['display_id'].toString(),
      fullscreen: map['fullscreen'] == 1,
    );
  }
}