
// ── MISE À JOUR router.dart ───────────────────────────────────────
// Remplacer le redirect actuel par :
//
// redirect: (context, state) {
//   // Plus de redirection forcée vers login
//   // L'app est accessible à tous en mode lecture
//   // La garde intervient uniquement sur les actions
//   final adminPages = ['/admin'];
//   final user = FirebaseAuth.instance.currentUser;
//   if (adminPages.any((p) => state.matchedLocation.startsWith(p))) {
//     if (user?.uid != kAdminUid) return '/';
//   }
//   return null;
// },
//
// Supprimer aussi les GoRoutes '/login' et '/register' du ShellRoute
// → Les gardes les déclenchent en bottom sheet, pas en page pleine
