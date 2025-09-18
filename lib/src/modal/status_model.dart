class StatusModel {
  String url;
  String userName;
  String? name;
  DateTime published;
  StatusModel({
    required this.url,
    required this.userName,
    this.name,
    required this.published,
  });

  Map<String, dynamic> toMap() {
    return {
      "url": url,
      "userName": userName,
      "name": name ?? '',
      "published": published,
    };
  }

  factory StatusModel.fromMap(Map<String, dynamic> map) {
    return StatusModel(
      url: map['url'],
      userName: map['userName'],
      published: map['published'],
      name: map['name'] ?? '',
    );
  }
}
