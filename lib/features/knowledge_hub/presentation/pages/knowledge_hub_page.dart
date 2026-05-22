import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/widgets/responsive_widgets.dart';
import '../../../../core/navigation/app_router.dart';
import '../providers/knowledge_provider.dart';
import '../../domain/models/knowledge_article.dart';

class KnowledgeHubPage extends StatelessWidget {
  const KnowledgeHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch provider
    final provider = context.watch<KnowledgeProvider>();

    return Scaffold(
      backgroundColor: MaatriColors.warmCream,
      body: ResponsivePageWrapper(
        useSafeArea: true,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildSearchBar(context, provider),
                    const SizedBox(height: 32),
                    if (provider.isSearching) ...[
                      _buildSearchResults(provider),
                    ] else ...[
                      _buildQuickCategories(context),
                      const SizedBox(height: 32),
                      _buildFeaturedArticles(context, provider),
                      const SizedBox(height: 32),
                      _buildWeeklyGuidance(provider),
                      const SizedBox(height: 32),
                      _buildTodaysCare(),
                    ],
                    const SizedBox(height: 48), // Bottom safe spacing for FAB or bottom nav overlap
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Knowledge & Wellness',
          style: MaatriTypography.displaySmall.copyWith(
            color: MaatriColors.charcoal,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Trusted pregnancy guidance for every stage.',
          style: MaatriTypography.bodyLarge.copyWith(
            color: MaatriColors.slate,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context, KnowledgeProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: MaatriColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: MaatriColors.charcoal.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        onChanged: (value) => provider.searchArticles(value),
        decoration: InputDecoration(
          hintText: 'Search pregnancy topics...',
          hintStyle: MaatriTypography.bodyMedium.copyWith(color: MaatriColors.mediumGray),
          prefixIcon: const Icon(Icons.search_rounded, color: MaatriColors.coral),
          suffixIcon: provider.isSearching
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, color: MaatriColors.mediumGray),
                  onPressed: () {
                    FocusScope.of(context).unfocus(); 
                    provider.clearSearch();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildSearchResults(KnowledgeProvider provider) {
    final results = provider.searchResults;

    if (provider.isLoadingAll && results.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(color: MaatriColors.coral),
        ),
      );
    }

    if (results.isEmpty) {
      final recommended = provider.weeklyGuidance.take(3).toList();
      if (recommended.isEmpty) recommended.addAll(provider.allArticles.take(3));

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32.0),
              child: Column(
                children: [
                  Icon(Icons.search_off_rounded, size: 64, color: MaatriColors.mediumGray.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    'No exact matches found',
                    style: MaatriTypography.titleMedium.copyWith(color: MaatriColors.slate),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try searching symptoms, nutrition, or wellness topics.',
                    style: MaatriTypography.bodyMedium.copyWith(color: MaatriColors.mediumGray),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          if (recommended.isNotEmpty) ...[
            const SizedBox(height: 24),
            const ResponsiveSectionHeader(title: 'Recommended for you'),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recommended.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _SearchResultCard(key: ValueKey(recommended[index].id), article: recommended[index]);
              },
            ),
          ]
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveSectionHeader(title: 'Search Results (${results.length})'),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: results.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final article = results[index];
            return _SearchResultCard(key: ValueKey(article.id), article: article);
          },
        ),
      ],
    );
  }

  Widget _buildQuickCategories(BuildContext context) {
    final categories = [
      {'icon': Icons.restaurant_rounded, 'title': 'Nutrition', 'color': MaatriColors.teal},
      {'icon': Icons.fitness_center_rounded, 'title': 'Exercise', 'color': MaatriColors.coral},
      {'icon': Icons.local_hospital_rounded, 'title': 'Symptoms', 'color': MaatriColors.lavenderDark},
      {'icon': Icons.child_care_rounded, 'title': 'Baby Growth', 'color': MaatriColors.goldenAmber},
      {'icon': Icons.self_improvement_rounded, 'title': 'Wellness', 'dataCategory': 'Mental Wellness', 'color': MaatriColors.tealDark},
      {'icon': Icons.emergency_rounded, 'title': 'Emergency', 'dataCategory': 'Emergency Care', 'color': MaatriColors.danger},
      {'icon': Icons.calendar_month_rounded, 'title': 'Trimester', 'dataCategory': 'Trimester Guide', 'color': MaatriColors.infoDark},
      {'icon': Icons.medication_rounded, 'title': 'Medications', 'color': MaatriColors.coralDark},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ResponsiveSectionHeader(title: 'Quick Categories'),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final double itemWidth = (constraints.maxWidth - 36 - 1) / 4;
            return Wrap(
              spacing: 12,
              runSpacing: 20,
              alignment: WrapAlignment.start,
              children: categories.map((cat) {
                return SizedBox(
                  width: itemWidth,
                  child: _CategoryCard(
                    icon: cat['icon'] as IconData,
                    title: cat['title'] as String,
                    dataCategory: cat['dataCategory'] as String?,
                    color: cat['color'] as Color,
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFeaturedArticles(BuildContext context, KnowledgeProvider provider) {
    if (provider.isLoadingFeatured) {
      return _buildSkeletonHorizontalList('Featured Articles');
    }

    final allArticles = provider.featuredArticles;
    if (allArticles.isEmpty) {
      return const SizedBox.shrink(); // Hide if empty
    }
    
    // Limit to 5 articles on the home screen
    final articles = allArticles.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveSectionHeader(
          title: 'Featured Articles', 
          actionText: 'See All',
          onAction: () => context.push(AppRoutes.featuredArticles),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 250, // Slightly increased height to ensure no overflow
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: articles.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              return _FeaturedArticleCard(key: ValueKey(articles[index].id), article: articles[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyGuidance(KnowledgeProvider provider) {
    if (provider.isLoadingWeekly) {
      return _buildSkeletonGrid('This Week in Pregnancy');
    }

    final articles = provider.weeklyGuidance;
    if (articles.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ResponsiveSectionHeader(title: 'This Week in Pregnancy'),
        const SizedBox(height: 16),
        _WeeklyGuidanceTabs(articles: articles),
      ],
    );
  }

  Widget _buildTodaysCare() {
    // Generate a curated, personalized feeling list
    final careItems = [
      {'title': 'Morning Hydration', 'subtitle': 'Drink 2 glasses now', 'icon': Icons.water_drop_rounded, 'color': MaatriColors.info},
      {'title': 'Gentle Stretch', 'subtitle': '5 min lower back relief', 'icon': Icons.accessibility_new_rounded, 'color': MaatriColors.coral},
      {'title': 'Mindful Breathing', 'subtitle': 'Reduce morning anxiety', 'icon': Icons.air_rounded, 'color': MaatriColors.teal},
      {'title': 'Prenatal Vitamin', 'subtitle': 'Don\'t forget your iron', 'icon': Icons.medication_rounded, 'color': MaatriColors.lavenderDark},
      {'title': 'Rest Check-in', 'subtitle': 'Plan a 20m afternoon nap', 'icon': Icons.bedtime_rounded, 'color': MaatriColors.goldenAmber},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ResponsiveSectionHeader(title: 'Today\'s Care'),
        const SizedBox(height: 16),
        SizedBox(
          height: 90, // Compact height
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: careItems.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final item = careItems[index];
              return _TodaysCareCard(
                title: item['title'] as String,
                subtitle: item['subtitle'] as String,
                icon: item['icon'] as IconData,
                color: item['color'] as Color,
              );
            },
          ),
        ),
      ],
    );
  }

  // --- Skeletons ---

  Widget _buildSkeletonHorizontalList(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveSectionHeader(title: title),
        const SizedBox(height: 16),
        SizedBox(
          height: 240,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              return Container(
                width: 260,
                decoration: BoxDecoration(
                  color: MaatriColors.cloudGray,
                  borderRadius: BorderRadius.circular(20),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonGrid(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveSectionHeader(title: title),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - 16 - 1) / 2;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: List.generate(4, (index) {
                return Container(
                  width: cardWidth,
                  height: 120,
                  decoration: BoxDecoration(
                    color: MaatriColors.cloudGray,
                    borderRadius: BorderRadius.circular(16),
                  ),
                );
              }),
            );
          },
        ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? dataCategory;
  final Color color;

  const _CategoryCard({
    required this.icon,
    required this.title,
    this.dataCategory,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.push(
          AppRoutes.knowledgeCategory,
          extra: {
            'category': dataCategory ?? title,
            'icon': icon,
            'color': color,
          },
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.2), width: 1),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          ResponsiveText(
            title,
            style: MaatriTypography.bodySmall.copyWith(
              color: MaatriColors.charcoal,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _FeaturedArticleCard extends StatelessWidget {
  final KnowledgeArticle article;
  
  const _FeaturedArticleCard({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.articleDetail, extra: article),
      child: Container(
        width: 260,
        decoration: BoxDecoration(
          color: MaatriColors.pureWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: MaatriColors.charcoal.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Container(
              height: 120,
              decoration: const BoxDecoration(
                color: MaatriColors.coralLight,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: article.imageUrl.isNotEmpty
                    ? (article.imageUrl.startsWith('assets/') 
                        ? Image.asset(
                            article.imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) => _buildPlaceholder(context),
                          )
                        : Image.network(
                            article.imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) => _buildPlaceholder(context),
                          ))
                    : _buildPlaceholder(context),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: MaatriColors.tealLight.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          article.trimester,
                          style: MaatriTypography.labelSmall.copyWith(
                            color: MaatriColors.tealDark,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 14, color: MaatriColors.mediumGray),
                          const SizedBox(width: 4),
                          Text(
                            '${article.readTime}m',
                            style: MaatriTypography.labelSmall.copyWith(color: MaatriColors.slate),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ResponsiveText(
                    article.title,
                    style: MaatriTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: MaatriColors.charcoal,
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    IconData getCategoryIcon(String category) {
      switch (category.toLowerCase()) {
        case 'nutrition': return Icons.restaurant_rounded;
        case 'exercise': return Icons.fitness_center_rounded;
        case 'symptoms': return Icons.local_hospital_rounded;
        case 'baby growth': return Icons.child_care_rounded;
        case 'mental wellness': return Icons.self_improvement_rounded;
        case 'emergency care': return Icons.emergency_rounded;
        case 'trimester guide': return Icons.calendar_month_rounded;
        case 'medications': return Icons.medication_rounded;
        default: return Icons.favorite_rounded;
      }
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [MaatriColors.tealLight, MaatriColors.tealDark.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          getCategoryIcon(article.category),
          color: MaatriColors.pureWhite.withOpacity(0.5),
          size: 48,
        ),
      ),
    );
  }
}

class _WeeklyGuidanceTabs extends StatefulWidget {
  final List<KnowledgeArticle> articles;

  const _WeeklyGuidanceTabs({required this.articles});

  @override
  State<_WeeklyGuidanceTabs> createState() => _WeeklyGuidanceTabsState();
}

class _WeeklyGuidanceTabsState extends State<_WeeklyGuidanceTabs> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 48,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: MaatriColors.lightGray.withOpacity(0.3),
            borderRadius: BorderRadius.circular(24),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: MaatriColors.coral,
              borderRadius: BorderRadius.circular(20),
            ),
            labelColor: MaatriColors.pureWhite,
            unselectedLabelColor: MaatriColors.slate,
            labelStyle: MaatriTypography.labelLarge.copyWith(fontWeight: FontWeight.bold),
            unselectedLabelStyle: MaatriTypography.labelLarge,
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'Baby'),
              Tab(text: 'Mother'),
              Tab(text: 'Wellness'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Since we know the height of the card, we can use a fixed height or AnimatedSize.
        // AnimatedSize is safer.
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: AnimatedBuilder(
            animation: _tabController,
            builder: (context, child) {
              final index = _tabController.index;
              final article = widget.articles.length > index ? widget.articles[index] : null;
              
              if (article == null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32.0),
                    child: Text(
                      'More updates coming soon.',
                      style: MaatriTypography.bodyMedium.copyWith(color: MaatriColors.mediumGray),
                    ),
                  ),
                );
              }
              
              return _WeeklyGuidanceCard(key: ValueKey(article.id), article: article, isExpanded: true);
            },
          ),
        ),
      ],
    );
  }
}

class _WeeklyGuidanceCard extends StatelessWidget {
  final KnowledgeArticle article;
  final bool isExpanded;

  const _WeeklyGuidanceCard({super.key, required this.article, this.isExpanded = false});

  @override
  Widget build(BuildContext context) {
    // Map string categories back to icons (fallback to default)
    IconData getIconForCategory(String category) {
      switch (category.toLowerCase()) {
        case 'baby growth': return Icons.child_friendly_rounded;
        case 'mother health': return Icons.pregnant_woman_rounded;
        case 'nutrition': return Icons.local_dining_rounded;
        case 'mental wellness': return Icons.spa_rounded;
        default: return Icons.favorite_rounded;
      }
    }

    return GestureDetector(
      onTap: () => context.push(AppRoutes.articleDetail, extra: article),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: MaatriColors.pureWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: MaatriColors.lightGray.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: MaatriColors.charcoal.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(getIconForCategory(article.category), color: MaatriColors.coral, size: 28),
            const SizedBox(height: 12),
            ResponsiveText(
              article.title,
              style: MaatriTypography.titleSmall.copyWith(
                fontWeight: FontWeight.bold,
                color: MaatriColors.charcoal,
              ),
              maxLines: isExpanded ? 3 : 2,
            ),
            if (isExpanded) ...[
              const SizedBox(height: 8),
              ResponsiveText(
                article.description,
                style: MaatriTypography.bodySmall.copyWith(color: MaatriColors.slate),
                maxLines: 4,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final KnowledgeArticle article;

  const _SearchResultCard({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.articleDetail, extra: article),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: MaatriColors.pureWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: MaatriColors.lightGray.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: MaatriColors.charcoal.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [MaatriColors.teal.withOpacity(0.6), MaatriColors.teal],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: article.imageUrl.isNotEmpty
                    ? (article.imageUrl.startsWith('assets/')
                        ? Image.asset(
                            article.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.menu_book_rounded, color: Colors.white54),
                          )
                        : Image.network(
                            article.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.menu_book_rounded, color: Colors.white54),
                          ))
                    : const Icon(Icons.menu_book_rounded, color: Colors.white54),
              ),
            ),
            const SizedBox(width: 16),
            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: MaatriColors.teal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          article.category,
                          style: MaatriTypography.labelSmall.copyWith(color: MaatriColors.teal),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.access_time_rounded, size: 12, color: MaatriColors.mediumGray),
                      const SizedBox(width: 4),
                      Text(
                        '${article.readTime}m',
                        style: MaatriTypography.labelSmall.copyWith(color: MaatriColors.slate),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ResponsiveText(
                    article.title,
                    style: MaatriTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: MaatriColors.charcoal,
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodaysCareCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _TodaysCareCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220, // Horizontal compact width
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ResponsiveText(
                  title,
                  style: MaatriTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: MaatriColors.charcoal,
                  ),
                  maxLines: 1,
                ),
                const SizedBox(height: 2),
                ResponsiveText(
                  subtitle,
                  style: MaatriTypography.labelSmall.copyWith(color: MaatriColors.slate),
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
