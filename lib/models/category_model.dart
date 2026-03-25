class CategoryModel {
  final String id;
  final String name;
  final String image;
  final String icon;

  CategoryModel({
    required this.id,
    required this.name,
    required this.image,
    required this.icon,
  });

  factory CategoryModel.fromMap(
    String id,
    Map<String, dynamic> data,
  ) {
    return CategoryModel(
      id: id,
      name: data['name'] ?? '',
      image: data['image'] ?? '',
      icon: data['icon'] ?? '',
    );
  }
}
