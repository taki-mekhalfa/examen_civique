import 'package:examen_civique/design/style/app_colors.dart';

import 'package:examen_civique/models/series.dart';
import 'package:examen_civique/pages/home_page.dart';
import 'package:examen_civique/widgets/home_tile_widget.dart';
import 'package:flutter/material.dart';

class ThematicSelectionPage extends StatelessWidget {
  const ThematicSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryGreyLight,
      appBar: buildAppBar('Séries thématiques'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(top: 20.0),
          children: [
            _buildHeader(),
            _buildTopicTile(
              context,
              'Principes et valeurs',
              'assets/images/principes.png',
            ),
            _buildTopicTile(
              context,
              'Institutions et politique',
              'assets/images/institutions.png',
            ),
            _buildTopicTile(
              context,
              'Droits et devoirs',
              'assets/images/droits_devoirs.png',
            ),
            _buildTopicTile(
              context,
              'Histoire et culture',
              'assets/images/histoire.png',
            ),
            _buildTopicTile(context, 'Société et vie', 'assets/images/vie.png'),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.only(bottom: 20.0),
      child: Image(
        image: AssetImage("assets/marianne/marianne_themes.png"),
        height: 200.0,
        width: 200.0,
        semanticLabel: 'Illustration Thématiques',
      ),
    );
  }

  Widget _buildTopicTile(BuildContext context, String title, String imagePath) {
    return HomeTile(
      title: title,
      imagePath: imagePath,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SeriesListScreen(
              type: SeriesType.thematic,
              title: title,
              topic: title,
            ),
          ),
        );
      },
    );
  }
}
