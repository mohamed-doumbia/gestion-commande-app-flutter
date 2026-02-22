import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../data/models/product_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../widget/category_selector_widget.dart';
import '../../../widget/image_picker_widget.dart';


class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _descController = TextEditingController();

  String? _selectedCategory;
  final List<String?> _imagePaths = [null, null, null];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    await Provider.of<ProductProvider>(context, listen: false).loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Ajouter un produit",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel("Photos du produit (jusqu'à 3)"),
              const SizedBox(height: 10),
              Row(
                children: List.generate(
                  3,
                      (index) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: index < 2 ? 10 : 0),
                      child: ImagePickerWidget(
                        imagePath: _imagePaths[index],
                        onImagePicked: (path) {
                          setState(() => _imagePaths[index] = path);
                        },
                        onImageRemoved: () {
                          setState(() => _imagePaths[index] = null);
                        },
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              _buildLabel("Nom du produit"),
              _buildInput(_nameController, "Ex: Riz parfumé 25kg"),

              _buildLabel("Catégorie"),
              Consumer<ProductProvider>(
                builder: (context, provider, child) {
                  return CategorySelectorWidget(
                    categories: provider.categories,
                    selectedCategory: _selectedCategory,
                    onCategorySelected: (category) {
                      setState(() => _selectedCategory = category);
                    },
                    onAddCategory: (newCategory) async {
                      // Utiliser Future.microtask pour éviter setState pendant build
                      await provider.addCategory(newCategory);
                      if (mounted) {
                        Future.microtask(() {
                          if (mounted) {
                            setState(() => _selectedCategory = newCategory);
                          }
                        });
                      }
                    },
                  );
                },
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel("Prix (FCFA)"),
                        _buildInput(_priceController, "5000", isNumber: true),
                      ],
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel("Stock initial"),
                        _buildInput(_stockController, "10", isNumber: true),
                      ],
                    ),
                  ),
                ],
              ),

              _buildLabel("Description"),
              _buildInput(_descController, "Détails du produit...",
                  maxLines: 4),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _submitProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "Publier le produit",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
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

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 10),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1E293B),
        ),
      ),
    );
  }

  Widget _buildInput(
      TextEditingController controller,
      String hint, {
        bool isNumber = false,
        int maxLines = 1,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(
            color: Colors.grey.shade400,
            fontSize: 13,
          ),
          filled: true,
          fillColor: const Color(0xFFF5F7FA),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        validator: (value) => value!.isEmpty ? "Requis" : null,
      ),
    );
  }

  Future<void> _submitProduct() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Veuillez sélectionner une catégorie",
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final user =
          Provider.of<AuthProvider>(context, listen: false).currentUser;
      if (user == null || user.id == null) return;

      // Filtrer les images non nulles
      final imagesList =
      _imagePaths.where((path) => path != null).cast<String>().toList();

      final newProduct = ProductModel(
        vendorId: user.id!,
        name: _nameController.text,
        category: _selectedCategory!,
        price: double.parse(_priceController.text),
        stockQuantity: int.parse(_stockController.text),
        description: _descController.text,
        images: imagesList,
      );

      // Ajouter le produit de manière asynchrone
      await Provider.of<ProductProvider>(context, listen: false)
          .addProduct(newProduct);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Produit ajouté avec succès",
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Retourner true pour indiquer qu'un produit a été ajouté
      Navigator.pop(context, true);
    }
  }
}