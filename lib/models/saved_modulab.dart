/// A Modulabs server the user has connected to before, remembered locally
/// under a custom [name] so they can tell multiple instances apart
/// (e.g. "Home", "Office", "Parents' house").
class SavedModulab {
  final String id;
  final String name;
  final String baseUrl;

  const SavedModulab({
    required this.id,
    required this.name,
    required this.baseUrl,
  });

  SavedModulab copyWith({String? name, String? baseUrl}) => SavedModulab(
        id: id,
        name: name ?? this.name,
        baseUrl: baseUrl ?? this.baseUrl,
      );

  factory SavedModulab.fromJson(Map<String, dynamic> json) => SavedModulab(
        id: json['id'] as String,
        name: json['name'] as String,
        baseUrl: json['baseUrl'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'baseUrl': baseUrl,
      };
}
