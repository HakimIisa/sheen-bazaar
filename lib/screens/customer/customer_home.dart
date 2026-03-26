import 'package:flutter/material.dart';
import '../../services/category_service.dart';
import '../../models/category_model.dart';
import 'shops_list.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'cart_icon_button.dart';
import '../auth/login_page.dart';
import 'ai_assistant.dart';

class CustomerHome extends StatefulWidget {
  const CustomerHome({super.key});

  @override
  State<CustomerHome> createState() =>
      _CustomerHomeState();
}

class _CustomerHomeState
    extends State<CustomerHome> {
  late Future<List<CategoryModel>> _categories;

  @override
  void initState() {
    super.initState();
    _categories = CategoryService()
        .getCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sheen Bazaar'),
        actions: [
          CartIconButton(), // add this
          IconButton(
            icon: const Icon(
              Icons.logout,
              color: Color(0xFFF5EDE0),
            ),
            // In customer_home.dart logout:
            onPressed: () async {
              await FirebaseAuth.instance
                  .signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const LoginPage(),
                  ),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<List<CategoryModel>>(
        future: _categories,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return const Center(
              child: Text("No categories found"),
            );
          }

          final categories = snapshot.data!;

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];

              return GestureDetector(
                onTap: () {
                  // Replace your existing Navigator.push with this:
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ShopsList(
                        categoryId: category.id,
                        categoryName: category
                            .name, // add this
                      ),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(16),
                    image: DecorationImage(
                      image: NetworkImage(
                        category.image,
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                  alignment:
                      Alignment.bottomCenter,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(
                      8,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      borderRadius:
                          BorderRadius.vertical(
                            bottom:
                                Radius.circular(
                                  16,
                                ),
                          ),
                    ),
                    child: Text(
                      category.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton:
          FloatingActionButton.extended(
            backgroundColor: const Color(
              0xFF3D2B1F,
            ),
            icon: const Text(
              '✨',
              style: TextStyle(fontSize: 18),
            ),
            label: const Text(
              'AI Assistant',
              style: TextStyle(
                color: Color(0xFFC9A55A),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const AiAssistant(),
              ),
            ),
          ),
    );
  }
}
