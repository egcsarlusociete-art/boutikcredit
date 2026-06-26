
class CreditCategory {
  final String id;
  final String label;
  final double plafond;
  final double interets;
  final double total;
  final int dureeJours;
  final double paiementJour;
  final double paiementSemaine;

  const CreditCategory({
    required this.id, required this.label, required this.plafond,
    required this.interets, required this.total, required this.dureeJours,
    required this.paiementJour, required this.paiementSemaine,
  });

  String get dureeLabel {
    final mois = (dureeJours / 30).round();
    return '$mois mois ($dureeJours j)';
  }
}

const List<CreditCategory> kCategories = [
  CreditCategory(id:'A', label:'Catégorie A', plafond:100000,  interets:15000,  total:115000,  dureeJours:30,  paiementJour:3833,  paiementSemaine:26833),
  CreditCategory(id:'B', label:'Catégorie B', plafond:200000,  interets:30000,  total:230000,  dureeJours:30,  paiementJour:7667,  paiementSemaine:53667),
  CreditCategory(id:'C', label:'Catégorie C', plafond:300000,  interets:45000,  total:345000,  dureeJours:60,  paiementJour:5750,  paiementSemaine:40250),
  CreditCategory(id:'D', label:'Catégorie D', plafond:400000,  interets:60000,  total:460000,  dureeJours:60,  paiementJour:7667,  paiementSemaine:53667),
  CreditCategory(id:'E', label:'Catégorie E', plafond:500000,  interets:75000,  total:575000,  dureeJours:90,  paiementJour:6389,  paiementSemaine:44722),
  CreditCategory(id:'F', label:'Catégorie F', plafond:600000,  interets:90000,  total:690000,  dureeJours:90,  paiementJour:7667,  paiementSemaine:53667),
  CreditCategory(id:'G', label:'Catégorie G', plafond:700000,  interets:105000, total:805000,  dureeJours:120, paiementJour:6708,  paiementSemaine:46958),
  CreditCategory(id:'H', label:'Catégorie H', plafond:800000,  interets:120000, total:920000,  dureeJours:120, paiementJour:7667,  paiementSemaine:53667),
  CreditCategory(id:'I', label:'Catégorie I', plafond:900000,  interets:135000, total:1035000, dureeJours:150, paiementJour:6900,  paiementSemaine:48300),
  CreditCategory(id:'J', label:'Catégorie J', plafond:1000000, interets:150000, total:1150000, dureeJours:150, paiementJour:7667,  paiementSemaine:53667),
];
