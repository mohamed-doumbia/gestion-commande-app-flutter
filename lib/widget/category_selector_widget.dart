import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CategorySelectorWidget extends StatefulWidget {
  final List<String> categories;
  final String? selectedCategory;
  final Function(String) onCategorySelected;
  final Function(String) onAddCategory;

  const CategorySelectorWidget({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.onAddCategory,
  });

  @override
  State<CategorySelectorWidget> createState() =>
      _CategorySelectorWidgetState();
}

class _CategorySelectorWidgetState extends State<CategorySelectorWidget> {
  final TextEditingController _customCategoryController =
  TextEditingController();
  bool _showCustomInput = false;

  @override
  void dispose() {
    _customCategoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<String> displayCategories = List.from(widget.categories);
    if (!displayCategories.contains('Autre')) {
      displayCategories.add('Autre');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: widget.selectedCategory,
              hint: Text(
                "Sélectionner une catégorie",
                style: GoogleFonts.poppins(color: Colors.grey.shade400),
              ),
              isExpanded: true,
              items: displayCategories.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Row(
                    children: [
                      if (value == 'Autre')
                        const Icon(
                          Icons.add_circle_outline,
                          size: 18,
                          color: Colors.blue,
                        ),
                      if (value == 'Autre') const SizedBox(width: 8),
                      Text(
                        value,
                        style: GoogleFonts.poppins(
                          color: value == 'Autre' ? Colors.blue : Colors.black,
                          fontWeight: value == 'Autre'
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (newValue) {
                if (newValue == 'Autre') {
                  setState(() {
                    _showCustomInput = true;
                  });
                } else {
                  setState(() {
                    _showCustomInput = false;
                  });
                  widget.onCategorySelected(newValue!);
                }
              },
            ),
          ),
        ),
        if (_showCustomInput) ...[
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Nouvelle catégorie",
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade900,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _customCategoryController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: "Ex: Cosmétiques, Meubles...",
                    hintStyle: GoogleFonts.poppins(
                      color: Colors.grey.shade400,
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 12,
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      onPressed: _validateAndAddCategory,
                    ),
                  ),
                  textCapitalization: TextCapitalization.words,
                  onSubmitted: (_) => _validateAndAddCategory(),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _showCustomInput = false;
                          _customCategoryController.clear();
                        });
                      },
                      child: Text(
                        "Annuler",
                        style: GoogleFonts.poppins(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        if (!_showCustomInput && widget.selectedCategory != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  size: 16,
                  color: Colors.green,
                ),
                const SizedBox(width: 6),
                Text(
                  "Catégorie: ${widget.selectedCategory}",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _validateAndAddCategory() {
    final categoryName = _customCategoryController.text.trim();

    if (categoryName.isEmpty) {
      _showErrorSnackbar("Veuillez entrer un nom de catégorie");
      return;
    }

    if (categoryName.length < 2) {
      _showErrorSnackbar("Le nom doit contenir au moins 2 caractères");
      return;
    }

    final exists = widget.categories.any(
          (cat) => cat.toLowerCase() == categoryName.toLowerCase(),
    );

    if (exists) {
      _showErrorSnackbar("Cette catégorie existe déjà");
      return;
    }

    widget.onAddCategory(categoryName);

    setState(() {
      _showCustomInput = false;
      _customCategoryController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Catégorie \"$categoryName\" ajoutée avec succès",
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}