import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CategoryFilterWidget extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final Function(String) onCategorySelected;

  const CategoryFilterWidget({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selectedCategory == category;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: FilterChip(
              label: Text(
                category,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                onCategorySelected(category);
              },
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFF1E293B),
              checkmarkColor: Colors.white,
              side: BorderSide(
                color: isSelected
                    ? const Color(0xFF1E293B)
                    : Colors.grey.shade300,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          );
        },
      ),
    );
  }
}