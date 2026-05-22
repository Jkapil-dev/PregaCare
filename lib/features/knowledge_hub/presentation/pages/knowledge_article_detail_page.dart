import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/widgets/responsive_widgets.dart';
import '../../domain/models/knowledge_article.dart';

class KnowledgeArticleDetailPage extends StatelessWidget {
  final KnowledgeArticle article;

  const KnowledgeArticleDetailPage({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MaatriColors.warmCream,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Banner Image & App Bar
          SliverAppBar(
            expandedHeight: 250.0,
            pinned: true,
            backgroundColor: MaatriColors.warmCream,
            foregroundColor: MaatriColors.charcoal,
            flexibleSpace: FlexibleSpaceBar(
              background: article.imageUrl.isNotEmpty
                  ? Image.network(
                      article.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
                    )
                  : _buildImagePlaceholder(),
            ),
          ),
          
          // Article Content
          SliverToBoxAdapter(
            child: ResponsivePageWrapper(
              useSafeArea: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badges row
                    Row(
                      children: [
                        _buildBadge(article.category, MaatriColors.tealLight, MaatriColors.tealDark),
                        const SizedBox(width: 8),
                        _buildBadge(article.trimester, MaatriColors.lavenderLight, MaatriColors.lavenderDark),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Title
                    Text(
                      article.title,
                      style: MaatriTypography.headlineLarge.copyWith(
                        color: MaatriColors.charcoal,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Meta row
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 16, color: MaatriColors.mediumGray),
                        const SizedBox(width: 6),
                        Text(
                          '${article.readTime} min read',
                          style: MaatriTypography.bodyMedium.copyWith(color: MaatriColors.slate),
                        ),
                        const Spacer(),
                        const Icon(Icons.calendar_today_rounded, size: 16, color: MaatriColors.mediumGray),
                        const SizedBox(width: 6),
                        Text(
                          '${article.createdAt.day}/${article.createdAt.month}/${article.createdAt.year}',
                          style: MaatriTypography.bodyMedium.copyWith(color: MaatriColors.slate),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    // Description (Subtitle)
                    if (article.description.isNotEmpty) ...[
                      Text(
                        article.description,
                        style: MaatriTypography.titleMedium.copyWith(
                          color: MaatriColors.darkGray,
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Divider(color: MaatriColors.lightGray.withOpacity(0.5)),
                      const SizedBox(height: 24),
                    ],

                    // Content
                    Text(
                      article.content,
                      style: MaatriTypography.bodyLarge.copyWith(
                        color: MaatriColors.charcoal,
                        height: 1.8,
                      ),
                    ),
                    const SizedBox(height: 64), // Bottom padding
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
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
          colors: [MaatriColors.lavenderLight, MaatriColors.lavenderDark.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          getCategoryIcon(article.category),
          color: MaatriColors.pureWhite.withOpacity(0.5),
          size: 64,
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: MaatriTypography.labelSmall.copyWith(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
