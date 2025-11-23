import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../data/models/product_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/product_provider.dart';

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

  String _selectedCategory = 'Nourriture';
  final List<String> _categories = ['Nourriture', 'Boisson', 'Vêtements', 'Électronique', 'Autre'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Ajouter un produit", style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold)),
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
              // Simulation Upload Image
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid)
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.camera_alt, color: Colors.grey, size: 30),
                      const SizedBox(height: 5),
                      Text("Ajouter photo", style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              _buildLabel("Nom du produit"),
              _buildInput(_nameController, "Ex: Riz 25kg"),

              _buildLabel("Catégorie"),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300)
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    items: _categories.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value, style: GoogleFonts.poppins()),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedCategory = newValue!;
                      });
                    },
                  ),
                ),
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
              _buildInput(_descController, "Détails du produit...", maxLines: 3),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _submitProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text("Publier le produit", style: GoogleFonts.poppins(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 10),
      child: Text(text, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
    );
  }

  Widget _buildInput(TextEditingController controller, String hint, {bool isNumber = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 13),
          filled: true,
          fillColor: const Color(0xFFF5F7FA),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: (value) => value!.isEmpty ? "Requis" : null,
      ),
    );
  }

  void _submitProduct() {
    if (_formKey.currentState!.validate()) {
      final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
      if (user == null || user.id == null) return;

      final newProduct = ProductModel(
        vendorId: user.id!,
        name: _nameController.text,
        category: _selectedCategory,
        price: double.parse(_priceController.text),
        stockQuantity: int.parse(_stockController.text),
        description: _descController.text,
      );

      Provider.of<ProductProvider>(context, listen: false).addProduct(newProduct);
      Navigator.pop(context); // Retour à la liste
    }
  }
}