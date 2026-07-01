import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'theme.dart';

String fmtPrice(num amount) {
  final f = NumberFormat('#,###', 'fr_FR');
  return '${f.format(amount)} F CFA';
}

String fmtDate(dynamic ts) {
  if (ts == null) return '';
  DateTime dt;
  if (ts is Timestamp) dt = ts.toDate();
  else if (ts is DateTime) dt = ts;
  else if (ts is String) dt = DateTime.tryParse(ts) ?? DateTime.now();
  else return '';
  return DateFormat('dd MMM yyyy', 'fr_FR').format(dt);
}

String fmtDateHour(dynamic ts) {
  if (ts == null) return '';
  DateTime dt;
  if (ts is Timestamp) dt = ts.toDate();
  else if (ts is DateTime) dt = ts;
  else return '';
  return DateFormat('dd MMM yyyy, HH:mm', 'fr_FR').format(dt);
}

const Map<String, String> kCategories = {
  'all':           'Tout',
  'electronique':  'Electronique',
  'electromenager':'Electromenager',
  'maison':        'Maison',
  'sport':         'Sport',
  'auto':          'Auto',
  'beaute':        'Beaute',
  'alimentation':  'Alimentation',
  'bebe':          'Bébé',
  'jardin':        'Jardin',
  'mode':          'Mode',
};

const Map<String, String> kCategoryIcons = {
  'all':           'shopping_bag',
  'appliances':    'kitchen',
  'electromenager':'kitchen',
  'electronics':   'phone_android',
  'electronique':  'phone_android',
  'fashion':       'checkroom',
  'mode':          'checkroom',
  'home':          'chair',
  'maison':        'chair',
  'beauty':        'face',
  'beaute':        'face',
  'auto':          'directions_car',
  'bebe':          'child_care',
  'jardin':        'park',
  'alimentation':  'restaurant',
  'food':          'restaurant',
  'sport':       'sports_soccer',
  'food':        'restaurant',
  'other':       'inventory_2',
};

const Map<String, String> kStates = {
  'new':      'Neuf',
  'like-new': 'Comme neuf',
  'good':     'Bon etat',
  'used':     'Occasion',
};

const Map<String, String> kOrderStatus = {
  'confirmed':  'Confirmee',
  'processing': 'En preparation',
  'shipped':    'En livraison',
  'delivered':  'Livree',
  'cancelled':  'Annulee',
};

const Map<String, String> kArticleStatus = {
  'pending':    'En attente',
  'processing': 'En traitement',
  'published':  'Publie',
  'rejected':   'Refuse',
};

const Map<String, String> kPlanStatus = {
  'pending':  'En attente',
  'active':   'Actif',
  'expired':  'Expire',
  'inactive': 'Inactif',
};

const Map<String, String> kWithdrawalStatus = {
  'pending':  'En attente',
  'approved': 'Approuve',
  'rejected': 'Refuse',
};

const List<Map<String, String>> kOperators = [
  {'value': 'wave',   'label': 'Wave CI',         'emoji': '🌊'},
  {'value': 'mtn',    'label': 'MTN Mobile Money', 'emoji': '🟡'},
  {'value': 'orange', 'label': 'Orange Money',     'emoji': '🟠'},
  {'value': 'moov',   'label': 'Moov Money',       'emoji': '🔵'},
];

const List<String> kCities = [
  'Abidjan', 'Bouake', 'Daloa', 'San-Pedro',
  'Korhogo', 'Yamoussoukro', 'Man', 'Gagnoa',
  'Abengourou', 'Divo', 'Bondoukou', 'Agboville',
];

Color statusColor(String status) {
  switch (status) {
    case 'published': case 'delivered': case 'approved': case 'active':
      return EgcColors.ok;
    case 'pending': case 'confirmed':
      return EgcColors.gold;
    case 'processing': case 'shipped':
      return EgcColors.blue;
    case 'rejected': case 'cancelled': case 'expired':
      return EgcColors.err;
    default: return EgcColors.ink3;
  }
}

Color statusBgColor(String status) {
  switch (status) {
    case 'published': case 'delivered': case 'approved': case 'active':
      return EgcColors.okBg;
    case 'pending': case 'confirmed':
      return EgcColors.goldBg;
    case 'processing': case 'shipped':
      return EgcColors.blueBg;
    case 'rejected': case 'cancelled': case 'expired':
      return EgcColors.errBg;
    default: return EgcColors.bg3;
  }
}

void showSnack(BuildContext context, String msg, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
    backgroundColor: isError ? EgcColors.err : EgcColors.ink,
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    duration: const Duration(seconds: 3),
  ));
}

String? validateEmail(String? v) {
  if (v == null || v.trim().isEmpty) return 'Email requis';
  if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$').hasMatch(v.trim())) return 'Email invalide';
  return null;
}

String? validateRequired(String? v, [String field = 'Ce champ']) {
  if (v == null || v.trim().isEmpty) return '$field est requis';
  return null;
}

String? validatePhone(String? v) {
  if (v == null || v.trim().isEmpty) return 'Telephone requis';
  if (v.trim().length < 8) return 'Numero trop court';
  return null;
}

String? validatePassword(String? v) {
  if (v == null || v.isEmpty) return 'Mot de passe requis';
  if (v.length < 6) return '6 caracteres minimum';
  return null;
}

String generateReferralCode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final code = List.generate(6, (i) => chars[(DateTime.now().microsecond + i * 37) % chars.length]);
  return 'EGC${code.join()}';
}
