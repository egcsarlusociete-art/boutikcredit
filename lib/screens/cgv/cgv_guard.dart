
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cgv_screen.dart';

/// Enveloppe toutes les pages protégées :
/// si l'utilisateur n'a pas signé les CGV, affiche CgvScreen en premier.
class CgvGuard extends ConsumerWidget {
  final Widget child;
  const CgvGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return child;

    return FutureBuilder<bool>(
      future: _hasSigned(uid),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFFEA580C))));
        }
        final signed = snap.data ?? false;
        if (!signed) {
          return WillPopScope(
            onWillPop: () async => false,
            child: const CgvScreen(isRequired: true),
          );
        }
        return child;
      },
    );
  }

  Future<bool> _hasSigned(String uid) async {
    final db = FirebaseFirestore.instance;
    DocumentSnapshot snap = await db.collection('users').doc(uid).get();
    if (!snap.exists) snap = await db.collection('vendeurs').doc(uid).get();
    if (!snap.exists) return false;
    final data = snap.data() as Map<String, dynamic>?;
    return data?['cgvAccepted'] == true;
  }
}
