import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shop_model.dart';
import '../models/product_model.dart';

class ShopService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Fetch shops filtered by category
  Future<List<ShopModel>> getShopsByCategory(String categoryId) async {
    final snapshot = await _db
        .collection('shops')
        .where('categoryId', isEqualTo: categoryId)
        .where('isOpen', isEqualTo: true)
        .get();

    return snapshot.docs
        .map((doc) => ShopModel.fromMap(doc.id, doc.data()))
        .toList();
  }

  // Fetch products subcollection inside a shop
  Future<List<ProductModel>> getProducts(String shopId) async {
    final snapshot = await _db
        .collection('shops')
        .doc(shopId)
        .collection('products')
        .get();

    return snapshot.docs
        .map((doc) => ProductModel.fromMap(doc.id, doc.data()))
        .toList();
  }
}