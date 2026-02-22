import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';

/// ============================================
/// ONGLET 8 : IMPORT EXCEL
/// ============================================
/// Description : Upload de fichiers Excel (clients ou ventes)
/// Phase : Département Marketing
class ExcelUploadTab extends StatefulWidget {
  final String branchId;

  const ExcelUploadTab({
    Key? key,
    required this.branchId,
  }) : super(key: key);

  @override
  State<ExcelUploadTab> createState() => _ExcelUploadTabState();
}

class _ExcelUploadTabState extends State<ExcelUploadTab> {
  String? _selectedFileType; // 'clients' ou 'ventes'
  String? _selectedFilePath;
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Text(
            'Import de Données Excel',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Téléchargez vos fichiers Excel pour importer les données de clients ou de ventes',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),

          // Sélection du type de fichier
          _buildFileTypeSelector(),
          const SizedBox(height: 24),

          // Zone d'upload
          if (_selectedFileType != null) _buildUploadZone(),

          const SizedBox(height: 24),

          // Informations sur le template
          _buildTemplateInfo(),
        ],
      ),
    );
  }

  /// ============================================
  /// SÉLECTEUR DE TYPE DE FICHIER
  /// ============================================
  Widget _buildFileTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Type de fichier',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildFileTypeCard(
                'Clients',
                'Importer la liste des clients',
                Icons.people,
                _selectedFileType == 'clients',
                () {
                  setState(() {
                    _selectedFileType = 'clients';
                    _selectedFilePath = null;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFileTypeCard(
                'Ventes',
                'Importer les données de ventes',
                Icons.shopping_cart,
                _selectedFileType == 'ventes',
                () {
                  setState(() {
                    _selectedFileType = 'ventes';
                    _selectedFilePath = null;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFileTypeCard(
    String title,
    String subtitle,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? const Color(0xFF1E293B) : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF1E293B),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: isSelected ? Colors.white70 : Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// ============================================
  /// ZONE D'UPLOAD
  /// ============================================
  Widget _buildUploadZone() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.grey.shade300,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.cloud_upload_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _selectedFilePath != null
                ? 'Fichier sélectionné'
                : 'Sélectionnez un fichier Excel',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          if (_selectedFilePath != null) ...[
            const SizedBox(height: 8),
            Text(
              _selectedFilePath!.split('/').last,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _isUploading ? null : _pickFile,
            icon: const Icon(Icons.folder_open),
            label: Text(
              _selectedFilePath != null ? 'Changer de fichier' : 'Choisir un fichier',
              style: GoogleFonts.poppins(),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E293B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          if (_selectedFilePath != null) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _uploadFile,
              icon: _isUploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.upload),
              label: Text(
                _isUploading ? 'Téléchargement...' : 'Télécharger et Analyser',
                style: GoogleFonts.poppins(),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// ============================================
  /// SÉLECTIONNER UN FICHIER
  /// ============================================
  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFilePath = result.files.single.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erreur lors de la sélection du fichier: $e',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// ============================================
  /// TÉLÉCHARGER LE FICHIER
  /// ============================================
  Future<void> _uploadFile() async {
    if (_selectedFilePath == null || _selectedFileType == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      // TODO: Implémenter la logique de traitement Excel
      // Pour l'instant, on simule juste l'upload
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Fichier téléchargé avec succès !\nLes calculs seront effectués après la création du template.',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );

        setState(() {
          _selectedFilePath = null;
          _isUploading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur lors du téléchargement: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  /// ============================================
  /// INFORMATIONS SUR LE TEMPLATE
  /// ============================================
  Widget _buildTemplateInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                'Template Excel',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Un template Excel sera bientôt disponible pour vous guider dans le formatage de vos données. '
            'Le fichier doit contenir les colonnes spécifiques selon le type sélectionné (clients ou ventes).',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.blue.shade900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Une fois le fichier téléchargé, les calculs (ROI, statistiques, etc.) seront effectués automatiquement.',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade900,
            ),
          ),
        ],
      ),
    );
  }
}

