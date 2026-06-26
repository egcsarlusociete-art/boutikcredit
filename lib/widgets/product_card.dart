import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../models/article_model.dart';
import '../utils/helpers.dart';
import '../utils/theme.dart';

class ProductCard extends StatelessWidget {
  final ArticleModel article;
  final VoidCallback? onAddToCart;

  const ProductCard({super.key, required this.article, this.onAddToCart});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/product/${article.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: EgcColors.bg2,
          borderRadius: EgcRadius.mdBorder,
          border: Border.all(color: EgcColors.line, width: 1.5),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Image
          Stack(children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: EgcRadius.md, topRight: EgcRadius.md),
              child: AspectRatio(
                aspectRatio: 1,
                child: article.hasImage
                  ? CachedNetworkImage(
                      imageUrl: article.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: EgcColors.bg3, child: const Center(child: Icon(Icons.image_outlined, color: EgcColors.ink3, size: 32))),
                      errorWidget: (_, __, ___) => _noImage(),
                    )
                  : _noImage(),
              ),
            ),
            // Badge remise
            Positioned(
              top: 8, left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: EgcColors.err, borderRadius: EgcRadius.smBorder),
                child: Text('-${article.discount.toInt()}%', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
          // Infos
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(kCategories[article.category] ?? article.category,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: EgcColors.primary, letterSpacing: 0.4)),
              const SizedBox(height: 2),
              Text(article.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: EgcColors.ink, height: 1.3)),
              const SizedBox(height: 6),
              Row(children: [
                Text(fmtPrice(article.price), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: EgcColors.ink)),
                const SizedBox(width: 4),
                Text(fmtPrice(article.oldPrice), style: const TextStyle(fontSize: 10, color: EgcColors.ink3, decoration: TextDecoration.lineThrough)),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.star, size: 12, color: Color(0xFFF59E0B)),
                const SizedBox(width: 2),
                const Text('4.8', style: TextStyle(fontSize: 10, color: EgcColors.ink3)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: EgcColors.okBg, borderRadius: EgcRadius.pill),
                  child: Text('+${article.cashback.toInt()}%', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: EgcColors.ok)),
                ),
              ]),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: onAddToCart,
                child: Container(
                  width: double.infinity,
                  height: 34,
                  decoration: BoxDecoration(color: EgcColors.primary, borderRadius: EgcRadius.smBorder),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.add, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('Ajouter', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _noImage() => Container(
    color: EgcColors.bg3,
    child: const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text('📦', style: TextStyle(fontSize: 36)),
      SizedBox(height: 4),
      Text('Photo à venir', style: TextStyle(fontSize: 10, color: EgcColors.ink3)),
    ])),
  );
}
