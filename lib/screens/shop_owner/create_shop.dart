import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/shop_model.dart';

class CreateShop extends StatefulWidget {
  final ShopModel? existingShop;
  const CreateShop({
    super.key,
    this.existingShop,
  });

  @override
  State<CreateShop> createState() =>
      _CreateShopState();
}

class _CreateShopState extends State<CreateShop> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _coverImageCtrl = TextEditingController();
  final _logoCtrl = TextEditingController();

  String _selectedCategory = 'pashmina';
  bool _loading = false;
  bool get _isEditing =>
      widget.existingShop != null;

  final List<Map<String, String>> _categories = [
    {'id': 'pashmina', 'name': 'Pashmina'},
    {
      'id': 'papier_mache',
      'name': 'Papier Mache',
    },
    {'id': 'wood', 'name': 'Walnut Wood'},
  ];

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final s = widget.existingShop!;
      _nameCtrl.text = s.shopName;
      _descCtrl.text = s.description;
      _locationCtrl.text = s.location;
      _coverImageCtrl.text = s.coverImage;
      _logoCtrl.text = s.logo;
      _selectedCategory = s.categoryId;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _coverImageCtrl.dispose();
    _logoCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate())
      return;
    setState(() => _loading = true);

    final uid =
        FirebaseAuth.instance.currentUser!.uid;
    final data = {
      'shopName': _nameCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'location': _locationCtrl.text.trim(),
      'coverImage': _coverImageCtrl.text.trim(),
      'logo': _logoCtrl.text.trim(),
      'categoryId': _selectedCategory,
      'ownerId': uid,
      'isOpen': true,
      'rating': _isEditing
          ? widget.existingShop!.rating
          : 0.0,
      'totalReviews': _isEditing
          ? widget.existingShop!.totalReviews
          : 0,
      'createdAt': _isEditing
          ? widget.existingShop!.createdAt
          : Timestamp.now(),
    };

    try {
      if (_isEditing) {
        await FirebaseFirestore.instance
            .collection('shops')
            .doc(widget.existingShop!.id)
            .update(data);
      } else {
        await FirebaseFirestore.instance
            .collection('shops')
            .add(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Shop updated successfully!'
                  : 'Shop created successfully!',
            ),
            backgroundColor: const Color(
              0xFF3D2B1F,
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EDE0),
      appBar: AppBar(
        title: Text(
          _isEditing
              ? 'Edit Shop'
              : 'Create Shop',
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _label('Shop Name'),
              _field(
                controller: _nameCtrl,
                hint: 'e.g. Wular Pashmina House',
                validator: (v) => v!.isEmpty
                    ? 'Shop name is required'
                    : null,
              ),

              _label('Description'),
              _field(
                controller: _descCtrl,
                hint: 'Tell your story...',
                maxLines: 4,
                validator: (v) => v!.isEmpty
                    ? 'Description is required'
                    : null,
              ),

              _label('Location'),
              _field(
                controller: _locationCtrl,
                hint: 'e.g. Lal Chowk, Srinagar',
                validator: (v) => v!.isEmpty
                    ? 'Location is required'
                    : null,
              ),

              _label('Category'),
              Container(
                margin: const EdgeInsets.only(
                  bottom: 16,
                ),
                padding:
                    const EdgeInsets.symmetric(
                      horizontal: 14,
                    ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(
                      0xFF3D2B1F,
                    ),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    items: _categories
                        .map(
                          (c) => DropdownMenuItem(
                            value: c['id'],
                            child: Text(
                              c['name']!,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(
                      () =>
                          _selectedCategory = v!,
                    ),
                  ),
                ),
              ),

              _label('Cover Image URL'),
              _field(
                controller: _coverImageCtrl,
                hint: 'https://...',
              ),

              _label('Logo URL'),
              _field(
                controller: _logoCtrl,
                hint: 'https://...',
              ),

              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading
                      ? null
                      : _save,
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child:
                              CircularProgressIndicator(
                                color:
                                    Colors.white,
                                strokeWidth: 2,
                              ),
                        )
                      : Text(
                          _isEditing
                              ? 'Save Changes'
                              : 'Create Shop',
                          style: const TextStyle(
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 6,
        top: 4,
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF3D2B1F),
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 13,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }
}
