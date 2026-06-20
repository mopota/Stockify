import '../models/category_model.dart';

List<Map<String, dynamic>> products = [];

List<CategoryModel> categories = [
  CategoryModel(id: 'all', name: "All"),
  CategoryModel(id: 'shoes', name: "Shoes"),
  CategoryModel(id: 'clothes', name: "Clothes"),
];

void addCategory(String name) {
  final trimmed = name.trim();

  if (trimmed.isEmpty) return;

  // منع التكرار
  if (categories.any((c) => c.name.toLowerCase() == trimmed.toLowerCase())) {
    return;
  }

  categories.add(CategoryModel(id: name.toLowerCase(), name: trimmed));
}
