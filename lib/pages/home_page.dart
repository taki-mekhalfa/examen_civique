import 'package:examen_civique/design/style/app_colors.dart';
import 'package:examen_civique/design/style/app_text_styles.dart';
import 'package:examen_civique/widgets/home_tile_widget.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryGreyLight,
      appBar: AppBar(
        elevation: 0.0,
        scrolledUnderElevation: 0,
        toolbarHeight: 50.0,
        title: Text('Mon Examen Civique', style: AppTextStyles.regular18),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.menu),
            color: AppColors.primaryGrey,
            iconSize: 25,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(2),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.divider, width: 0.5),
                bottom: BorderSide(color: AppColors.divider, width: 0.5),
              ),
            ),
            child: const _StripedFlag(),
          ),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: ListView(
              children: [
                Container(
                  margin: EdgeInsets.only(top: 20.0, bottom: 0.0),
                  child: Image.asset(
                    "assets/marianne/marianne_bonjour.png",
                    height: 120.0,
                    width: 120.0,
                  ),
                ),
                HomeTile(
                  title: 'Séries simples',
                  imagePath: 'assets/images/serie_simple.png',
                ),
                HomeTile(
                  title: 'Examens blancs',
                  imagePath: 'assets/images/examen_blanc.png',
                ),
                HomeTile(
                  title: 'Séries thématiques',
                  imagePath: 'assets/images/examen_thematique.png',
                ),
                HomeTile(
                  title: 'Mes erreurs',
                  imagePath: 'assets/images/mes_erreurs.png',
                  trailing: _Errors(nbErrors: 7),
                ),
                HomeTile(
                  title: 'Statistiques',
                  imagePath: 'assets/images/statistiques.png',
                ),
                HomeTile(
                  title: "L'examen civique ?",
                  imagePath: 'assets/images/a_propos.png',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StripedFlag extends StatelessWidget {
  const _StripedFlag();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: Divider(
            height: 10,
            thickness: 10,
            color: AppColors.primaryBlue,
          ),
        ),
        Expanded(
          child: Divider(height: 10, thickness: 10, color: AppColors.white),
        ),
        Expanded(
          child: Divider(height: 10, thickness: 10, color: AppColors.red),
        ),
      ],
    );
  }
}

class _Errors extends StatelessWidget {
  const _Errors({required this.nbErrors});

  final int nbErrors;

  @override
  Widget build(BuildContext context) {
    if (nbErrors == 0) {
      return SizedBox.shrink();
    }

    return nbErrors > 0
        ? Container(
            padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 0.0),
            decoration: BoxDecoration(
              color: AppColors.red,
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Text(
              '$nbErrors',
              style: AppTextStyles.medium16.copyWith(
                color: AppColors.brilliantWhite,
              ),
            ),
          )
        : SizedBox.shrink();
  }
}
