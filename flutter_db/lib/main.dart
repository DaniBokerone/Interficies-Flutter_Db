import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import "package:http/http.dart" as http;
import 'dart:async';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ResponsiveHomePage(),
      debugShowCheckedModeBanner:false,
    );
  }
}

class ResponsiveHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 600) {
            return CategoryListView();
          } else {
            return CategoryListView();
          }
        },
      ),
    );
  }
}

class CategoryListView extends StatefulWidget {
  @override
  _CategoryListViewState createState() => _CategoryListViewState();
}

class _CategoryListViewState extends State<CategoryListView> {
  late Future<List<Category>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = loadCategories();
  }

  Future<List<Category>> loadCategories() async {
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Category>>(
      future: _categoriesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error loading categories: ${snapshot.error}'));
        } else if (snapshot.hasData) {
          final categories = snapshot.data!;
          return ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return ListTile(
                title: Text(category.name),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ItemListView(categoryId: category.id.toString()),
                    ),
                  );
                },
              );
            },
          );
        } else {
          return Center(child: Text('No categories found'));
        }
      },
    );
  }
}

class ItemListView extends StatefulWidget {
  final String categoryId;

  ItemListView({required this.categoryId});

  @override
  _ItemListViewState createState() => _ItemListViewState();
}

class _ItemListViewState extends State<ItemListView> {
  late Future<List<Item>> _itemsFuture;
  TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _itemsFuture = loadItems(widget.categoryId, ''); // Cargar todos los items inicialmente
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  // Función que se llama cada vez que cambia el texto del campo de búsqueda
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _itemsFuture = loadItems(widget.categoryId, _searchController.text); // Filtrar los items según el texto
      });
    });
  }

  // Función para cargar los items de una categoría y buscar según el texto ingresado
  Future<List<Item>> loadItems(String categoryId, String searchText) async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Items')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search for items...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Item>>(
              future: _itemsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error loading items: ${snapshot.error}'));
                } else if (snapshot.hasData) {
                  final items = snapshot.data!;
                  return ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ListTile(
                        title: Text(item.name),
                        subtitle: Text(item.description),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ItemDetailView(item: item),
                            ),
                          );
                        },
                      );
                    },
                  );
                } else {
                  return Center(child: Text('No items found'));
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ItemDetailView extends StatefulWidget {
  final Item item;

  ItemDetailView({required this.item});

  @override
  _ItemDetailViewState createState() => _ItemDetailViewState();
}

class _ItemDetailViewState extends State<ItemDetailView> {
  late Future<Uint8List> _imageFuture;

  @override
  void initState() {
    super.initState();
    _imageFuture = fetchImage(widget.item.image);
  }

  Future<Uint8List> fetchImage(String imageUrl) async {
    final imageUri = Uri.parse('http://localhost:3000/$imageUrl');
    final response = await http.get(imageUri);

    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Failed to load image');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.item.name)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<Uint8List>( 
              future: _imageFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error loading image: ${snapshot.error}'));
                } else if (snapshot.hasData) {
                  return Center(
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        image: DecorationImage(
                          image: MemoryImage(snapshot.data!),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  );
                } else {
                  return Center(child: Text('No image available'));
                }
              },
            ),
            SizedBox(height: 16),
            Text(widget.item.name, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Text(widget.item.description, style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}

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