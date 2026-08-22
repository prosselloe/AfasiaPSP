import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logopeda/full_screen_image_screen.dart';

// Model de dades per a cada categoria dins d'una pàgina
class PageCategory {
  final String name;
  final List<Map<String, dynamic>> items;

  PageCategory({required this.name, required this.items});
}

class VisualizerScreen extends StatefulWidget {
  const VisualizerScreen({super.key});

  @override
  State<VisualizerScreen> createState() => _VisualizerScreenState();
}

class _VisualizerScreenState extends State<VisualizerScreen> {
  // Controlador per a la vista de pàgines
  final PageController _pageController = PageController();

  // Llistes per als índexs
  List<dynamic> _pagesData = [];
  List<String> _allCategories = [];
  Map<String, List<Map<String, dynamic>>> _itemsByCategory = {};

  // Estat de la càrrega
  bool _isLoading = true;
  String? _error;

  // Notificador per a la pàgina actual del PageView
  final ValueNotifier<int> _currentPage = ValueNotifier(0);
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadAndProcessData();

    // Listener per actualitzar els indicadors de pàgina
    _pageController.addListener(() {
      if (_pageController.page?.round() != _currentPage.value) {
        _currentPage.value = _pageController.page!.round();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _currentPage.dispose();
    super.dispose();
  }

  Future<void> _loadAndProcessData() async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/data/comunicador.json');
      final List<dynamic> jsonData = json.decode(jsonString);

      final List<String> categoriesList = [];
      final Map<String, List<Map<String, dynamic>>> itemsMap = {};

      for (var pageData in jsonData) {
        final pageCategories = pageData['categories'] as List<dynamic>;
        for (var categoryData in pageCategories) {
          final String categoryName = categoryData['name'];
          if (!categoriesList.contains(categoryName)) {
            categoriesList.add(categoryName);
          }

          if (!itemsMap.containsKey(categoryName)) {
            itemsMap[categoryName] = [];
          }
          itemsMap[categoryName]!.addAll(List<Map<String, dynamic>>.from(categoryData['items']));
        }
      }

      setState(() {
        _pagesData = jsonData;
        _allCategories = categoriesList;
        _itemsByCategory = itemsMap;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      developer.log('Error loading data', error: e, stackTrace: stackTrace);
      setState(() {
        _error = 'Error loading data: $e';
        _isLoading = false;
      });
    }
  }

  String getAssetPath(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';
    return imagePath;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comunicador Visual'),
        actions: _isLoading
            ? []
            : [
                _buildCategoriesDropdown(),
                _buildPagesDropdown(),
              ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _buildBookView(),
    );
  }

  // Dropdown per a les pàgines
  Widget _buildPagesDropdown() {
    return ValueListenableBuilder<int>(
      valueListenable: _currentPage,
      builder: (context, currentPage, child) {
        return DropdownButton<int>(
          value: currentPage,
          hint: const Text('Pàgina'),
          icon: const Icon(Icons.source, color: Colors.white),
          dropdownColor: Theme.of(context).appBarTheme.backgroundColor,
          style: const TextStyle(color: Colors.white),
          underline: Container(),
          onChanged: (int? newPage) {
            if (newPage != null) {
              _pageController.jumpToPage(newPage);
            }
          },
          items: List.generate(_pagesData.length, (index) {
            return DropdownMenuItem<int>(
              value: index,
              child: Text('Pàgina ${index + 1}'),
            );
          }).toList(),
        );
      },
    );
  }

  // Dropdown per a les categories
  Widget _buildCategoriesDropdown() {
    return DropdownButton<String>(
      hint: const Text('Categoria'),
      icon: const Icon(Icons.category, color: Colors.white),
      dropdownColor: Theme.of(context).appBarTheme.backgroundColor,
      style: const TextStyle(color: Colors.white),
      underline: Container(),
      value: _selectedCategory,
      onChanged: (String? newCategory) {
        if (newCategory != null) {
          setState(() {
            _selectedCategory = newCategory;
          });
          // Troba la primera pàgina que conté aquesta categoria
          final pageIndex = _pagesData.indexWhere((page) => 
              (page['categories'] as List)
              .any((cat) => cat['name'] == newCategory)
          );

          if (pageIndex != -1) {
            _pageController.jumpToPage(pageIndex);
          } else {
             Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CategoryItemsScreen(
                  categoryName: newCategory,
                  items: _itemsByCategory[newCategory] ?? [],
                ),
              ),
            );
          }
        }
      },
      items: _allCategories.map((String category) {
        return DropdownMenuItem<String>(
          value: category,
          child: Text(category),
        );
      }).toList(),
    );
  }

  // Vista del llibre paginat
  Widget _buildBookView() {
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: _pagesData.length,
            itemBuilder: (context, index) {
              final pageData = _pagesData[index];
              final categories = (pageData['categories'] as List<dynamic>)
                  .map((cat) => PageCategory(name: cat['name'], items: List<Map<String, dynamic>>.from(cat['items'])))
                  .toList();

              return ListView.builder(
                itemCount: categories.length,
                itemBuilder: (context, catIndex) {
                  final category = categories[catIndex];
                  return _buildCategorySection(category);
                },
              );
            },
          ),
        ),
        // Controls de navegació del PageView
        _buildPageIndicator(),
      ],
    );
  }
  
  // Secció d'una categoria dins d'una pàgina
  Widget _buildCategorySection(PageCategory category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(category.name, style: Theme.of(context).textTheme.titleLarge),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 4.0,
            mainAxisSpacing: 4.0,
          ),
          itemCount: category.items.length,
          itemBuilder: (context, itemIndex) {
            final item = category.items[itemIndex];
            return _buildGridCard(item);
          },
        ),
      ],
    );
  }

  // Card per a la graella
  Widget _buildGridCard(Map<String, dynamic> item) {
    final imagePath = getAssetPath(item['image']);
    final text = item['text'] as String? ?? '';

    Widget cardChild;
    VoidCallback? onTapAction;

    if (imagePath.isNotEmpty) {
      cardChild = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Image.asset(
              imagePath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                developer.log('Failed to load image: $imagePath', name: 'grid.image.error');
                return const Icon(Icons.broken_image, color: Colors.grey, size: 40);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
          ),
        ],
      );
      onTapAction = () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => FullScreenImageScreen(imagePath: imagePath)));
      };
    } else {
      cardChild = Center(child: Text(text, textAlign: TextAlign.center));
      onTapAction = null;
    }

    return Card(clipBehavior: Clip.antiAlias, child: InkWell(onTap: onTapAction, child: cardChild));
  }

  // Indicador de pàgina (fletxes i punts)
  Widget _buildPageIndicator() {
    return ValueListenableBuilder<int>(
      valueListenable: _currentPage,
      builder: (context, value, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: value > 0
                  ? () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.ease)
                  : null,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.generate(_pagesData.length, (int index) {
                return Container(
                  width: 8.0, height: 8.0,
                  margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 2.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: value == index
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.secondary.withAlpha(102),
                  ),
                );
              }),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios),
              onPressed: value < _pagesData.length - 1
                  ? () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease)
                  : null,
            ),
          ],
        );
      },
    );
  }
}

// Pantalla per mostrar tots els ítems d'una categoria
class CategoryItemsScreen extends StatelessWidget {
  final String categoryName;
  final List<Map<String, dynamic>> items;

  const CategoryItemsScreen({super.key, required this.categoryName, required this.items});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(categoryName)),
      body: GridView.builder(
        padding: const EdgeInsets.all(4.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, crossAxisSpacing: 4.0, mainAxisSpacing: 4.0,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
           final item = items[index];
           final imagePath = item['image'] as String? ?? '';
           final text = item['text'] as String? ?? '';

           return Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: imagePath.isNotEmpty ? () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => FullScreenImageScreen(imagePath: imagePath)));
              } : null,
              child: Column(
                 crossAxisAlignment: CrossAxisAlignment.stretch,
                 children: [
                  Expanded(
                    child: imagePath.isNotEmpty 
                      ? Image.asset(imagePath, fit: BoxFit.contain, errorBuilder: (c, o, s) => const Icon(Icons.broken_image, size: 40)) 
                      : Center(child: Text(text, textAlign: TextAlign.center)),
                  ),
                  Padding(padding: const EdgeInsets.all(8.0), child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))),
                 ]
              )
            )
           );
        },
      ),
    );
  }
}
