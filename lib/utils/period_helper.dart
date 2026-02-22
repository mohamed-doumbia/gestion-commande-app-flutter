import 'package:intl/intl.dart';

/// ============================================
/// UTILITAIRE : PeriodHelper
/// ============================================
/// Description : Gestion centralisée des périodes (semaine, mois, année)
/// Usage : Évite la répétition de code pour calculer les dates de période

class PeriodHelper {
  /// Types de périodes disponibles
  static const String week = 'week';
  static const String month = 'month';
  static const String year = 'year';

  /// Liste des types de périodes
  static const List<String> periodTypes = [week, month, year];

  /// ============================================
  /// CALCULER LES DATES D'UNE PÉRIODE
  /// ============================================
  /// Retourne les dates de début et fin pour une période donnée
  /// 
  /// [periodType] : 'week', 'month', ou 'year'
  /// [referenceDate] : Date de référence (par défaut = aujourd'hui)
  /// 
  /// Retourne : Map avec 'start' et 'end' (DateTime)
  static Map<String, DateTime> calculatePeriodDates({
    required String periodType,
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    
    switch (periodType) {
      case week:
        return _calculateWeekDates(now);
      case month:
        return _calculateMonthDates(now);
      case year:
        return _calculateYearDates(now);
      default:
        throw ArgumentError('Type de période invalide: $periodType');
    }
  }

  /// ============================================
  /// CALCULER LES DATES D'UNE SEMAINE
  /// ============================================
  static Map<String, DateTime> _calculateWeekDates(DateTime date) {
    // Début de la semaine (lundi)
    final start = date.subtract(Duration(days: date.weekday - 1));
    // Fin de la semaine (dimanche)
    final end = start.add(const Duration(days: 6));
    
    return {
      'start': DateTime(start.year, start.month, start.day),
      'end': DateTime(end.year, end.month, end.day, 23, 59, 59),
    };
  }

  /// ============================================
  /// CALCULER LES DATES D'UN MOIS
  /// ============================================
  static Map<String, DateTime> _calculateMonthDates(DateTime date) {
    final start = DateTime(date.year, date.month, 1);
    final end = DateTime(date.year, date.month + 1, 0, 23, 59, 59);
    
    return {
      'start': start,
      'end': end,
    };
  }

  /// ============================================
  /// CALCULER LES DATES D'UNE ANNÉE
  /// ============================================
  static Map<String, DateTime> _calculateYearDates(DateTime date) {
    final start = DateTime(date.year, 1, 1);
    final end = DateTime(date.year, 12, 31, 23, 59, 59);
    
    return {
      'start': start,
      'end': end,
    };
  }

  /// ============================================
  /// NAVIGUER VERS LA PÉRIODE PRÉCÉDENTE
  /// ============================================
  /// Retourne les dates de la période précédente
  static Map<String, DateTime> getPreviousPeriod({
    required String periodType,
    required DateTime currentStart,
  }) {
    switch (periodType) {
      case week:
        final prevStart = currentStart.subtract(const Duration(days: 7));
        final prevEnd = prevStart.add(const Duration(days: 6));
        return {
          'start': prevStart,
          'end': DateTime(prevEnd.year, prevEnd.month, prevEnd.day, 23, 59, 59),
        };
      
      case month:
        final prevStart = DateTime(currentStart.year, currentStart.month - 1, 1);
        final prevEnd = DateTime(currentStart.year, currentStart.month, 0);
        return {
          'start': prevStart,
          'end': DateTime(prevEnd.year, prevEnd.month, prevEnd.day, 23, 59, 59),
        };
      
      case year:
        final prevStart = DateTime(currentStart.year - 1, 1, 1);
        final prevEnd = DateTime(currentStart.year - 1, 12, 31);
        return {
          'start': prevStart,
          'end': DateTime(prevEnd.year, prevEnd.month, prevEnd.day, 23, 59, 59),
        };
      
      default:
        throw ArgumentError('Type de période invalide: $periodType');
    }
  }

  /// ============================================
  /// NAVIGUER VERS LA PÉRIODE SUIVANTE
  /// ============================================
  /// Retourne les dates de la période suivante
  static Map<String, DateTime> getNextPeriod({
    required String periodType,
    required DateTime currentStart,
  }) {
    switch (periodType) {
      case week:
        final nextStart = currentStart.add(const Duration(days: 7));
        final nextEnd = nextStart.add(const Duration(days: 6));
        return {
          'start': nextStart,
          'end': DateTime(nextEnd.year, nextEnd.month, nextEnd.day, 23, 59, 59),
        };
      
      case month:
        final nextStart = DateTime(currentStart.year, currentStart.month + 1, 1);
        final nextEnd = DateTime(currentStart.year, currentStart.month + 2, 0);
        return {
          'start': nextStart,
          'end': DateTime(nextEnd.year, nextEnd.month, nextEnd.day, 23, 59, 59),
        };
      
      case year:
        final nextStart = DateTime(currentStart.year + 1, 1, 1);
        final nextEnd = DateTime(currentStart.year + 1, 12, 31);
        return {
          'start': nextStart,
          'end': DateTime(nextEnd.year, nextEnd.month, nextEnd.day, 23, 59, 59),
        };
      
      default:
        throw ArgumentError('Type de période invalide: $periodType');
    }
  }

  /// ============================================
  /// FORMATER L'AFFICHAGE D'UNE PÉRIODE
  /// ============================================
  /// Retourne une chaîne formatée pour l'affichage
  static String formatPeriodDisplay({
    required DateTime start,
    required DateTime end,
    String? format,
  }) {
    final dateFormat = format ?? 'dd/MM/yyyy';
    final startFormat = DateFormat(dateFormat);
    final endFormat = DateFormat(dateFormat);
    
    return '${startFormat.format(start)} - ${endFormat.format(end)}';
  }

  /// ============================================
  /// OBTENIR LE LABEL D'UN TYPE DE PÉRIODE
  /// ============================================
  /// Retourne le nom affiché d'un type de période
  static String getPeriodTypeLabel(String periodType) {
    switch (periodType) {
      case week:
        return 'Semaine';
      case month:
        return 'Mois';
      case year:
        return 'Année';
      default:
        return periodType;
    }
  }

  /// ============================================
  /// OBTENIR LE LABEL PLURIEL D'UN TYPE DE PÉRIODE
  /// ============================================
  static String getPeriodTypeLabelPlural(String periodType) {
    switch (periodType) {
      case week:
        return 'Semaines';
      case month:
        return 'Mois';
      case year:
        return 'Années';
      default:
        return periodType;
    }
  }

  /// ============================================
  /// VÉRIFIER SI UN TYPE DE PÉRIODE EST VALIDE
  /// ============================================
  static bool isValidPeriodType(String periodType) {
    return periodTypes.contains(periodType);
  }

  /// ============================================
  /// CALCULER LA PÉRIODE PRÉCÉDENTE POUR COMPARAISON
  /// ============================================
  /// Utilisé pour comparer la période actuelle avec la précédente
  static Map<String, DateTime> getPreviousPeriodForComparison({
    required String periodType,
    required DateTime currentStart,
    required DateTime currentEnd,
  }) {
    return getPreviousPeriod(
      periodType: periodType,
      currentStart: currentStart,
    );
  }
}

