
// Fragment à ajouter dans register_screen.dart
// Dans la classe _RegisterScreenState, ajouter :
//
// String? _creditCat; // identifiant Cat A..J
//
// Et dans le formulaire, après le champ ville :
//
// EgcDropdown<String>(
//   label: 'Catégorie de crédit *',
//   value: _creditCat,
//   items: kCategories.map((c) => DropdownMenuItem(
//     value: c.id,
//     child: Row(children: [
//       Text(c.id, style: const TextStyle(fontWeight: FontWeight.w700)),
//       const SizedBox(width: 8),
//       Text('— Plafond ${fmtPrice(c.plafond)}',
//         style: const TextStyle(fontSize: 12, color: EgcColors.ink3)),
//     ]),
//   )).toList(),
//   onChanged: (v) => setState(() => _creditCat = v),
//   validator: (v) => v == null ? 'Choisissez une catégorie' : null,
// ),
//
// Et ajouter dans le Map de création de compte :
//   'creditCategory': _creditCat,
//   'creditPlafond': kCategories.firstWhere((c) => c.id == _creditCat).plafond,
//   'cgvAccepted': false,



// Dans home_screen.dart, envelopper le Scaffold avec CgvGuard :
//
// return CgvGuard(
//   child: Scaffold(
//     body: child,
//     bottomNavigationBar: ...,
//   ),
// );
//
// Et dans profile_screen.dart, ajouter un menu item :
//
// _menuItem(Icons.description_outlined, 'Conditions Générales (CGV)',
//   'Lire ou re-signer les CGV',
//   () => Navigator.push(context, MaterialPageRoute(
//     builder: (_) => const CgvScreen(isRequired: false)))),
