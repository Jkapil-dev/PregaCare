import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/widgets/responsive_widgets.dart';
import '../../../../core/navigation/app_router.dart';
import '../providers/knowledge_provider.dart';
import '../../domain/models/knowledge_article.dart';

class FeaturedArticlesPage extends StatelessWidget {
  const FeaturedArticlesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MaatriColors.warmCream,
      appBar: AppBar(
        title: Text(
          'Featured Articles',
          style: MaatriTypography.titleLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: MaatriColors.charcoal,
          ),
        ),
        backgroundColor: MaatriColors.warmCream,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: MaatriColors.charcoal, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: Consumer<KnowledgeProvider>(
        builder: (context, provider, _) {
          if (provider.isLoadingFeatured) {
            return const Center(child: CircularProgressIndicator(color: MaatriColors.coral));
          }

          final articles = provider.featuredArticles;

          if (articles.isEmpty) {
            return _buildEmptyState();
          }

          return ResponsivePageWrapper(
            useSafeArea: true,
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              itemCount: articles.length,
              separatorBuilder: (context, index) => const SizedBox(height: 20),
              itemBuilder: (context, index) {
                return _FeaturedVerticalCard(
                  key: ValueKey(articles[index].id), 
                  article: articles[index]
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome_rounded, size: 64, color: MaatriColors.mediumGray.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'No featured articles yet',
            style: MaatriTypography.titleMedium.copyWith(color: MaatriColors.slate),
          ),
        ],
      ),
    );
  }
}

class _FeaturedVerticalCard extends StatelessWidget {
  final KnowledgeArticle article;

  const _FeaturedVerticalCard({super.key, required this.article});

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
              height: 140,
              width: double.infinity,
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
                            errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                          )
                        : Image.network(
                            article.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                          ))
                    : _buildPlaceholder(),
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
                          color: MaatriColors.coralLight.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          article.category,
                          style: MaatriTypography.labelSmall.copyWith(
                            color: MaatriColors.coral,
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
                  Text(
                    article.title,
                    style: MaatriTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: MaatriColors.charcoal,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    article.description,
                    style: MaatriTypography.bodyMedium.copyWith(color: MaatriColors.slate),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
          colors: [MaatriColors.tealLight, MaatriColors.tealDark.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.auto_awesome_rounded,
          color: MaatriColors.pureWhite.withOpacity(0.5),
          size: 48,
        ),
      ),
    );
  }
}
