import 'package:examen_civique/models/home_tile_item.dart';
import 'package:examen_civique/widgets/errors_badge.dart';
import 'package:flutter/material.dart';

List<HomeTileItem> buildHomeMenuItems(BuildContext context, int nbErrors) {
  return [
    HomeTileItem(
      title: 'Séries simples',
      imageAsset: 'assets/images/serie_simple.png',
    ),
    HomeTileItem(
      title: 'Examens blancs',
      imageAsset: 'assets/images/examen_blanc.png',
    ),
    HomeTileItem(
      title: 'Séries thématiques',
      imageAsset: 'assets/images/examen_thematique.png',
    ),
    HomeTileItem(
      title: 'Mes erreurs',
      imageAsset: 'assets/images/mes_erreurs.png',
      trailing: ErrorBadge(nbErrors: nbErrors),
    ),
    HomeTileItem(
      title: 'Statistiques',
      imageAsset: 'assets/images/statistiques.png',
    ),
    HomeTileItem(
      title: "L'examen civique ?",
      imageAsset: 'assets/images/a_propos.png',
    ),
  ];
}
