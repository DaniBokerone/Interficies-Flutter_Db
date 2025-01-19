// api_data.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class ApiData {
  // Método para cargar las categorías
  static Future<List<Category>> loadCategories() async {
    final url = Uri.parse('http://localhost:3000/categories');
    try {
      final response = await http.post(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        if (jsonData['categories'] != null) {
          final List categoriesJson = jsonData['categories'];
          return categoriesJson.map((category) {
            return Category.fromJson(category);
          }).toList();
        } else {
          throw Exception('No se encontraron categorías en la respuesta.');
        }
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (error) {
      throw Exception('Error fetching categories: $error');
    }
  }

  // Método para cargar los items de una categoría y realizar búsqueda
  static Future<List<Item>> loadItems(String categoryId, String searchText) async {
    final url = Uri.parse('http://localhost:3000/items');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'categoryId': categoryId, 'search': searchText}), // Enviamos el texto de búsqueda
      );

      if (response.statusCode == 200) {
        final List itemsJson = json.decode(response.body)['items'];
        return itemsJson.map((item) => Item.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load items');
      }
    } catch (error) {
      throw Exception('Error fetching items: $error');
    }
  }

  // Método para obtener la imagen de un item
  static Future<Uint8List> fetchImage(String imageUrl) async {
    final imageUri = Uri.parse('http://localhost:3000/$imageUrl');
    final response = await http.get(imageUri);

    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Failed to load image');
    }
  }
}

// Clases de datos que recibirán las respuestas de la API
class Category {
  final String id;
  final String name;

  Category({required this.id, required this.name});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'].toString(),
      name: json['name'],
    );
  }
}

class Item {
  final String name;
  final String description;
  final String image;

  Item({required this.name, required this.description, required this.image});

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      name: json['name'],
      description: json['description'],
      image: json['image'],
    );
  }
}
