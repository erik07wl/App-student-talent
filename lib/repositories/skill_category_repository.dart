import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Repository für die dynamische Verwaltung von Skill-Kategorien.
///
/// Speichert und lädt semantische Skill-Gruppierungen aus Firebase.
/// Collection: `skill_categories`
///
/// Dokument-Struktur:
/// ```json
/// {
///   "name": "Frontend",
///   "icon": "web",
///   "color": "#3B82F6",
///   "keywords": ["flutter", "dart", "react", "angular", ...],
///   "order": 0
/// }
/// ```
class SkillCategoryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'skill_categories';

  /// Lädt alle Skill-Kategorien aus Firebase, sortiert nach `order`.
  Future<List<SkillCategory>> getCategories() async {
    final snapshot = await _firestore
        .collection(_collection)
        .orderBy('order')
        .get();

    return snapshot.docs
        .map((doc) => SkillCategory.fromFirestore(doc))
        .toList();
  }

  /// Stream für Echtzeit-Updates der Kategorien.
  Stream<List<SkillCategory>> streamCategories() {
    return _firestore
        .collection(_collection)
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SkillCategory.fromFirestore(doc))
            .toList());
  }

  /// Erstellt eine neue Kategorie.
  Future<void> addCategory(SkillCategory category) async {
    await _firestore.collection(_collection).add(category.toMap());
  }

  /// Aktualisiert eine bestehende Kategorie.
  Future<void> updateCategory(SkillCategory category) async {
    await _firestore
        .collection(_collection)
        .doc(category.id)
        .update(category.toMap());
  }

  /// Fügt ein Keyword zu einer bestehenden Kategorie hinzu.
  Future<void> addKeyword(String categoryId, String keyword) async {
    await _firestore.collection(_collection).doc(categoryId).update({
      'keywords': FieldValue.arrayUnion([keyword.toLowerCase().trim()]),
    });
  }

  /// Entfernt ein Keyword aus einer Kategorie.
  Future<void> removeKeyword(String categoryId, String keyword) async {
    await _firestore.collection(_collection).doc(categoryId).update({
      'keywords': FieldValue.arrayRemove([keyword.toLowerCase().trim()]),
    });
  }

  /// Löscht eine Kategorie.
  Future<void> deleteCategory(String categoryId) async {
    await _firestore.collection(_collection).doc(categoryId).delete();
  }

  /// Prüft ob die Collection leer ist und befüllt sie mit
  /// Standard-Kategorien, falls ja.
  ///
  /// Wird beim ersten App-Start aufgerufen, damit sofort
  /// sinnvolle Kategorien vorhanden sind.
  Future<void> seedDefaultCategoriesIfEmpty() async {
    final snapshot = await _firestore.collection(_collection).limit(1).get();

    if (snapshot.docs.isEmpty) {
      final batch = _firestore.batch();

      for (int i = 0; i < _defaultCategories.length; i++) {
        final ref = _firestore.collection(_collection).doc();
        batch.set(ref, {
          ..._defaultCategories[i],
          'order': i,
        });
      }

      await batch.commit();
    }
  }

  /// Standard-Kategorien für den ersten App-Start.
  static final List<Map<String, dynamic>> _defaultCategories = [
    {
      'name': 'Frontend',
      'icon': 'web',
      'color': '#3B82F6',
      'keywords': [
        'flutter', 'dart', 'react', 'react native', 'angular', 'vue',
        'vue.js', 'javascript', 'typescript', 'html', 'css', 'sass',
        'tailwind', 'bootstrap', 'svelte', 'next.js', 'nuxt.js',
        'jquery', 'webpack', 'responsive design', 'swiftui',
        'jetpack compose',
      ],
    },
    {
      'name': 'Backend',
      'icon': 'dns',
      'color': '#10B981',
      'keywords': [
        'node.js', 'express', 'django', 'flask', 'spring', 'spring boot',
        'java', 'python', 'ruby', 'rails', 'ruby on rails', 'php',
        'laravel', 'go', 'golang', 'rust', 'c#', '.net', 'asp.net',
        'graphql', 'rest', 'rest api', 'api', 'microservices', 'grpc',
        'nestjs', 'fastapi',
      ],
    },
    {
      'name': 'Datenbanken',
      'icon': 'storage',
      'color': '#F59E0B',
      'keywords': [
        'sql', 'mysql', 'postgresql', 'postgres', 'mongodb', 'firebase',
        'firestore', 'redis', 'sqlite', 'oracle', 'dynamodb', 'cassandra',
        'neo4j', 'supabase', 'nosql', 'mariadb',
      ],
    },
    {
      'name': 'DevOps & Cloud',
      'icon': 'cloud',
      'color': '#8B5CF6',
      'keywords': [
        'docker', 'kubernetes', 'aws', 'azure', 'gcp', 'google cloud',
        'ci/cd', 'jenkins', 'github actions', 'terraform', 'ansible',
        'linux', 'nginx', 'heroku', 'vercel', 'netlify', 'cloud', 'devops',
      ],
    },
    {
      'name': 'Data Science & KI',
      'icon': 'psychology',
      'color': '#EF4444',
      'keywords': [
        'python', 'machine learning', 'deep learning', 'tensorflow',
        'pytorch', 'pandas', 'numpy', 'scikit-learn', 'r',
        'data analysis', 'datenanalyse', 'ki', 'ai',
        'artificial intelligence', 'nlp', 'computer vision', 'jupyter',
        'matlab', 'statistik', 'statistics', 'big data', 'spark', 'hadoop',
      ],
    },
    {
      'name': 'Mobile',
      'icon': 'phone_android',
      'color': '#06B6D4',
      'keywords': [
        'flutter', 'dart', 'react native', 'swift', 'swiftui', 'kotlin',
        'jetpack compose', 'android', 'ios', 'mobile', 'xamarin', 'ionic',
        'capacitor',
      ],
    },
    {
      'name': 'Design & UI/UX',
      'icon': 'palette',
      'color': '#EC4899',
      'keywords': [
        'figma', 'sketch', 'adobe xd', 'photoshop', 'illustrator', 'ui',
        'ux', 'ui/ux', 'design', 'prototyping', 'wireframing',
        'user research', 'accessibility', 'barrierefreiheit',
      ],
    },
  ];
}

/// Model-Klasse für eine Skill-Kategorie.
///
/// Enthält Name, Icon, Farbe und die zugehörigen Keywords,
/// mit denen Studenten-Skills automatisch zugeordnet werden.
class SkillCategory {
  final String? id;
  final String name;
  final String icon;
  final String color;
  final List<String> keywords;
  final int order;

  SkillCategory({
    this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.keywords,
    this.order = 0,
  });

  /// Erstellt eine [SkillCategory] aus einem Firestore-Dokument.
  factory SkillCategory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SkillCategory(
      id: doc.id,
      name: data['name'] ?? '',
      icon: data['icon'] ?? 'code',
      color: data['color'] ?? '#6B7280',
      keywords: List<String>.from(data['keywords'] ?? []),
      order: data['order'] ?? 0,
    );
  }

  /// Konvertiert die Kategorie in eine Map für Firestore.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'icon': icon,
      'color': color,
      'keywords': keywords,
      'order': order,
    };
  }

  /// Gibt die passende [IconData] basierend auf dem Icon-String zurück.
  IconData get iconData {
    switch (icon) {
      case 'web':
        return Icons.web;
      case 'dns':
        return Icons.dns;
      case 'storage':
        return Icons.storage;
      case 'cloud':
        return Icons.cloud;
      case 'psychology':
        return Icons.psychology;
      case 'phone_android':
        return Icons.phone_android;
      case 'palette':
        return Icons.palette;
      case 'more_horiz':
        return Icons.more_horiz;
      case 'security':
        return Icons.security;
      case 'gamepad':
        return Icons.gamepad;
      case 'build':
        return Icons.build;
      case 'analytics':
        return Icons.analytics;
      case 'language':
        return Icons.language;
      case 'devices':
        return Icons.devices;
      default:
        return Icons.code;
    }
  }

  /// Parst den Farb-Hex-String zu einer [Color].
  Color get colorValue {
    final hex = color.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }
}