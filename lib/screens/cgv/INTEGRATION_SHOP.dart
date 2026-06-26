
// ── EXEMPLE D'INTÉGRATION dans shop_screen.dart ──────────────────
//
// Remplacer le onAddToCart direct par :
//
// onAddToCart: () async {
//   final ok = await requireAccountAndCgv(context);
//   if (ok && mounted) {
//     ref.read(cartProvider.notifier).add(filtered[i]);
//     showSnack(context, '${filtered[i].name} ajouté au panier ✓');
//   }
// },
//
// ── DANS cart_screen.dart, bouton "Passer la commande" ────────────
//
// onPressed: () async {
//   final ok = await requireAccountAndCgv(context);
//   if (ok && mounted) context.push('/checkout');
// },
//
// ── DANS referral_screen.dart, bouton "Partager" ─────────────────
//
// onPressed: () async {
//   final ok = await requireAccountAndCgv(context);
//   if (ok && mounted) Share.share(link);
// },
//
// ── DANS withdrawal_screen.dart, bouton "Envoyer la demande" ──────
//
// onTap: () async {
//   final ok = await requireAccountAndCgv(context);
//   if (ok) _submit(user);
// },
//
// ── RÈGLE GÉNÉRALE ───────────────────────────────────────────────
// Toute action qui nécessite un compte appelle d'abord :
//   final ok = await requireAccountAndCgv(context);
//   if (!ok) return;
//   // ... faire l'action
