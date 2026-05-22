import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/services/knowledge_service.dart';
import '../../domain/models/knowledge_article.dart';
import '../../data/demo_articles.dart';
import '../../../../core/providers/user_provider.dart';

class KnowledgeProvider extends ChangeNotifier {
  final KnowledgeService _service = KnowledgeService();
  UserProvider? _userProvider;

  // State lists
  List<KnowledgeArticle> _featuredArticles = [];
  List<KnowledgeArticle> _trimesterArticles = [];
  List<KnowledgeArticle> _weeklyGuidance = [];
  List<KnowledgeArticle> _allArticles = [];
  List<KnowledgeArticle> _searchResults = [];

  // Loading states
  bool _isLoadingFeatured = true;
  bool _isLoadingTrimester = true;
  bool _isLoadingWeekly = true;
  bool _isLoadingAll = true;
  bool _isSearching = false;

  // Subscriptions
  StreamSubscription? _featuredSub;
  StreamSubscription? _trimesterSub;
  StreamSubscription? _weeklySub;
  StreamSubscription? _allSub;

  List<KnowledgeArticle> get featuredArticles => _featuredArticles;
  List<KnowledgeArticle> get trimesterArticles => _trimesterArticles;
  List<KnowledgeArticle> get weeklyGuidance => _weeklyGuidance;
  List<KnowledgeArticle> get allArticles => _allArticles;
  List<KnowledgeArticle> get searchResults => _searchResults;

  bool get isLoadingFeatured => _isLoadingFeatured;
  bool get isLoadingTrimester => _isLoadingTrimester;
  bool get isLoadingWeekly => _isLoadingWeekly;
  bool get isLoadingAll => _isLoadingAll;
  bool get isSearching => _isSearching;

  bool get isLoadingAny => _isLoadingFeatured || _isLoadingTrimester || _isLoadingWeekly || _isLoadingAll;

  KnowledgeProvider() {
    _initStreams();
    _service.seedFirestoreIfEmpty();
  }

  void update(UserProvider userProvider) {
    _userProvider = userProvider;
    // Re-initialize trimester stream if trimester changes
    _initTrimesterStream();
  }

  void _initStreams() {
    _featuredSub?.cancel();
    _weeklySub?.cancel();
    _allSub?.cancel();

    _featuredSub = _service.streamFeaturedArticles().listen((articles) {
      if (articles.isEmpty) {
        _featuredArticles = demoArticles.where((a) => a.featured).toList();
      } else {
        _featuredArticles = articles;
      }
      _isLoadingFeatured = false;
      notifyListeners();
    }, onError: (error) {
      _featuredArticles = demoArticles.where((a) => a.featured).toList();
      _isLoadingFeatured = false;
      notifyListeners();
    });

    _weeklySub = _service.streamWeeklyGuidance().listen((articles) {
      if (articles.isEmpty) {
        _weeklyGuidance = demoArticles.where((a) => a.weeklyRecommended).toList();
      } else {
        _weeklyGuidance = articles;
      }
      _isLoadingWeekly = false;
      notifyListeners();
    }, onError: (error) {
      _weeklyGuidance = demoArticles.where((a) => a.weeklyRecommended).toList();
      _isLoadingWeekly = false;
      notifyListeners();
    });

    _allSub = _service.streamAllArticles().listen((articles) {
      if (articles.isEmpty) {
        _allArticles = demoArticles;
      } else {
        _allArticles = articles;
      }
      _isLoadingAll = false;
      notifyListeners();
    }, onError: (error) {
      _allArticles = demoArticles;
      _isLoadingAll = false;
      notifyListeners();
    });

    _initTrimesterStream();
  }

  void _initTrimesterStream() {
    _trimesterSub?.cancel();
    _isLoadingTrimester = true;
    notifyListeners();

    // Determine current trimester or default to 'General'
    String currentTrimester = 'General';
    // Add logic here based on UserProvider profile if available
    // For example:
    // if (_userProvider?.profile?.pregnancyWeek != null) {
    //   int week = _userProvider!.profile!.pregnancyWeek!;
    //   if (week <= 12) currentTrimester = 'First Trimester';
    //   else if (week <= 26) currentTrimester = 'Second Trimester';
    //   else currentTrimester = 'Third Trimester';
    // }

    _trimesterSub = _service.streamArticlesByTrimester(currentTrimester).listen((articles) {
      if (articles.isEmpty) {
        // Fallback to demo articles, try finding exact trimester or fallback to 'General'
        final trimesterDemos = demoArticles.where((a) => a.trimester == currentTrimester).toList();
        _trimesterArticles = trimesterDemos.isNotEmpty 
            ? trimesterDemos 
            : demoArticles.where((a) => a.trimester == 'General').toList();
      } else {
        _trimesterArticles = articles;
      }
      _isLoadingTrimester = false;
      notifyListeners();
    }, onError: (error) {
      final trimesterDemos = demoArticles.where((a) => a.trimester == currentTrimester).toList();
      _trimesterArticles = trimesterDemos.isNotEmpty 
          ? trimesterDemos 
          : demoArticles.where((a) => a.trimester == 'General').toList();
      _isLoadingTrimester = false;
      notifyListeners();
    });
  }

  void searchArticles(String query) {
    if (query.trim().isEmpty) {
      _isSearching = false;
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isSearching = true;
    final lowercaseQuery = query.toLowerCase().trim();
    
    // Split into tokens
    final tokens = lowercaseQuery.split(RegExp(r'\s+'));

    // Expanded Synonym dictionary
    final synonyms = {
      'nausea': ['morning sickness', 'vomiting', 'sick', 'queasy', 'first trimester sickness'],
      'swelling': ['edema', 'puffiness', 'bloating', 'leg swelling', 'feet swelling'],
      'water': ['hydration', 'fluids', 'drinking', 'dehydration', 'thirst'],
      'stress': ['anxiety', 'mental', 'worry', 'emotional', 'emotional wellness', 'mental wellness'],
      'pain': ['cramps', 'ache', 'discomfort', 'soreness'],
      'exercise': ['workout', 'yoga', 'stretching', 'fitness', 'prenatal yoga', 'walking'],
      'food': ['nutrition', 'diet', 'eating', 'meal', 'meals', 'healthy meals', 'fruits', 'craving'],
      'baby': ['fetal', 'fetus', 'growth', 'ultrasound', 'development'],
    };

    // Expand tokens with synonyms
    final expandedTokens = <String>{...tokens};
    for (final token in tokens) {
      synonyms.forEach((key, values) {
        if (key == token || values.contains(token)) {
          expandedTokens.add(key);
          expandedTokens.addAll(values);
        }
      });
    }

    _searchResults = _allArticles.where((article) {
      final textToSearch = [
        article.title.toLowerCase(),
        article.description.toLowerCase(),
        article.category.toLowerCase(),
        ...article.tags.map((t) => t.toLowerCase()),
      ].join(' ');

      // If ANY expanded token matches the text, we include it
      return expandedTokens.any((token) => textToSearch.contains(token));
    }).toList();

    notifyListeners();
  }
  
  void clearSearch() {
    _isSearching = false;
    _searchResults = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _featuredSub?.cancel();
    _trimesterSub?.cancel();
    _weeklySub?.cancel();
    _allSub?.cancel();
    super.dispose();
  }
}
