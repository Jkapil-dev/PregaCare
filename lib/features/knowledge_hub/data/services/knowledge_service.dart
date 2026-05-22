import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/knowledge_article.dart';
import '../demo_articles.dart';

class KnowledgeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'knowledge_articles';

  /// Fetches the latest featured articles
  Stream<List<KnowledgeArticle>> streamFeaturedArticles() {
    return _firestore
        .collection(_collectionPath)
        .where('featured', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => KnowledgeArticle.fromFirestore(doc))
            .toList());
  }

  /// Fetches articles recommended for a specific trimester
  Stream<List<KnowledgeArticle>> streamArticlesByTrimester(String trimester) {
    return _firestore
        .collection(_collectionPath)
        .where('trimester', isEqualTo: trimester)
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => KnowledgeArticle.fromFirestore(doc))
            .toList());
  }

  /// Fetches weekly guidance articles
  Stream<List<KnowledgeArticle>> streamWeeklyGuidance() {
    return _firestore
        .collection(_collectionPath)
        .where('weeklyRecommended', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(4)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => KnowledgeArticle.fromFirestore(doc))
            .toList());
  }

  /// Fetches articles by specific category
  Stream<List<KnowledgeArticle>> streamArticlesByCategory(String category) {
    return _firestore
        .collection(_collectionPath)
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => KnowledgeArticle.fromFirestore(doc))
            .toList());
  }

  /// Fetches all articles for local search filtering
  Stream<List<KnowledgeArticle>> streamAllArticles() {
    return _firestore
        .collection(_collectionPath)
        .orderBy('createdAt', descending: true)
        .limit(50) // Limit to prevent massive reads, enough for typical apps
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => KnowledgeArticle.fromFirestore(doc))
            .toList());
  }

  /// Single fetch method for article by ID
  Future<KnowledgeArticle?> getArticleById(String id) async {
    try {
      final doc = await _firestore.collection(_collectionPath).doc(id).get();
      if (doc.exists) {
        return KnowledgeArticle.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error fetching article $id: $e');
      return null;
    }
  }

  /// Automatically seeds Firestore with demo articles if the collection is completely empty
  Future<void> seedFirestoreIfEmpty() async {
    try {
      final snapshot = await _firestore.collection(_collectionPath).limit(1).get();
      if (snapshot.docs.isEmpty) {
        final batch = _firestore.batch();
        for (final article in demoArticles) {
          final docRef = _firestore.collection(_collectionPath).doc(article.id);
          batch.set(docRef, article.toFirestore());
        }
        await batch.commit();
        print('Successfully seeded Knowledge Hub with demo articles.');
      }
    } catch (e) {
      print('Failed to seed Knowledge Hub: $e');
    }
  }
}
