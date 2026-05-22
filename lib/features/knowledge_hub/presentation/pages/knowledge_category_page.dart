import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/widgets/responsive_widgets.dart';
import '../../../../core/navigation/app_router.dart';
import '../../data/services/knowledge_service.dart';
import '../../data/demo_articles.dart';
import '../../domain/models/knowledge_article.dart';

class KnowledgeCategoryPage extends StatelessWidget {
  final String categoryTitle;
  final IconData categoryIcon;
  final Color categoryColor;

  const KnowledgeCategoryPage({
    super.key,
    required this.categoryTitle,
    required this.categoryIcon,
    required this.categoryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MaatriColors.warmCream,
      body: ResponsivePageWrapper(
        useSafeArea: false, // Handle safe area manually in CustomScrollView
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverAppBar(context),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSearchBar(),
                    const SizedBox(height: 32),
                    _buildArticleList(),
                    const SizedBox(height: 48), // Bottom padding
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200.0,
      floating: false,
      pinned: true,
      backgroundColor: categoryColor,
      iconTheme: const IconThemeData(color: MaatriColors.pureWhite),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Text(
          categoryTitle,
          style: MaatriTypography.titleLarge.copyWith(
            color: MaatriColors.pureWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Gradient Background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [categoryColor, categoryColor.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // Decorative Icon
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                categoryIcon,
                size: 150,
                color: MaatriColors.pureWhite.withOpacity(0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
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
        decoration: InputDecoration(
          hintText: 'Search $categoryTitle articles...',
          hintStyle: MaatriTypography.bodyMedium.copyWith(color: MaatriColors.mediumGray),
          prefixIcon: Icon(Icons.search_rounded, color: categoryColor),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildArticleList() {
    return StreamBuilder<List<KnowledgeArticle>>(
      stream: KnowledgeService().streamArticlesByCategory(categoryTitle),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: MaatriColors.coral));
        }

        List<KnowledgeArticle> articles = snapshot.data ?? [];

        // Hybrid Fallback: If empty or error, use local demo articles
        if (snapshot.hasError || articles.isEmpty) {
          articles = demoArticles
              .where((a) => a.category.toLowerCase() == categoryTitle.toLowerCase())
              .toList();
        }

        if (articles.isEmpty) {
          return _buildEmptyState();
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final double cardWidth = (constraints.maxWidth - 16 - 1) / 2;
            return Wrap(
              spacing: 16,
              runSpacing: 20,
              alignment: WrapAlignment.start,
              children: articles.map((article) {
                return SizedBox(
                  key: ValueKey(article.id),
                  width: cardWidth,
                  child: _CategoryArticleCard(article: article, categoryColor: categoryColor),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48.0),
        child: Column(
          children: [
            Icon(categoryIcon, size: 64, color: MaatriColors.mediumGray.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'No articles found',
              style: MaatriTypography.titleMedium.copyWith(color: MaatriColors.slate),
            ),
            const SizedBox(height: 8),
            Text(
              'More $categoryTitle educational content is coming soon!',
              style: MaatriTypography.bodyMedium.copyWith(color: MaatriColors.mediumGray),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryArticleCard extends StatelessWidget {
  final KnowledgeArticle article;
  final Color categoryColor;

  const _CategoryArticleCard({super.key, required this.article, required this.categoryColor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.articleDetail, extra: article),
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Container(
              height: 120,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: article.imageUrl.isNotEmpty
                    ? (article.imageUrl.startsWith('assets/')
                        ? Image.asset(
                            article.imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                          )
                        : Image.network(
                            article.imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                          ))
                    : _buildPlaceholder(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          article.trimester,
                          style: MaatriTypography.labelSmall.copyWith(
                            color: categoryColor,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
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

  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [categoryColor.withOpacity(0.6), categoryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.health_and_safety_rounded,
          color: MaatriColors.pureWhite.withOpacity(0.5),
          size: 40,
        ),
      ),
    );
  }
}
