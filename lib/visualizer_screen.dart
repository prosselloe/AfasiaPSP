import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:logopeda/full_screen_image_screen.dart';
import 'package:logopeda/services/asset_loader_service.dart';
import 'package:logopeda/widgets/hybrid_image.dart'; // Importam el widget

// El codi de HybridImage s'ha mogut a lib/widgets/hybrid_image.dart

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
  final PageController _pageController = PageController();
  List<dynamic> _pagesData = [];
  List<String> _allCategories = [];
  Map<String, List<Map<String, dynamic>>> _itemsByCategory = {};
  bool _isLoading = true;
  String? _error;
  final ValueNotifier<int> _currentPage = ValueNotifier(0);
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadAndProcessData();
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
          await AssetLoaderService.instance.loadString('assets/data/comunicador.json');
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

      if(mounted){
        setState(() {
          _pagesData = jsonData;
          _allCategories = categoriesList;
          _itemsByCategory = itemsMap;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      developer.log('Error loading data', error: e, stackTrace: stackTrace);
      if(mounted){
        setState(() {
          _error = 'Error loading data: $e';
          _isLoading = false;
        });
      }
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
        _buildPageIndicator(),
      ],
    );
  }
  
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
            child: HybridImage(imagePath: imagePath, fit: BoxFit.contain),
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
                      ? HybridImage(imagePath: imagePath, fit: BoxFit.contain) 
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
