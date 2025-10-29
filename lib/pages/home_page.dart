import 'package:examen_civique/data/home_menu_items.dart';
import 'package:examen_civique/design/style/app_colors.dart';
import 'package:examen_civique/design/style/app_text_styles.dart';
import 'package:examen_civique/widgets/home_tile_widget.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 7 will be replaced by the number of errors dynamically.
    final items = buildHomeMenuItems(context, 0);

    return Scaffold(
      backgroundColor: AppColors.primaryGreyLight,
      appBar: AppBar(
        elevation: 0.0,
        scrolledUnderElevation: 0,
        toolbarHeight: 50.0,
        title: const Text('Mon Examen Civique', style: AppTextStyles.regular18),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.menu),
            color: AppColors.primaryGrey,
            iconSize: 25,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2.0),
          child: Container(
            decoration: const BoxDecoration(
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
                  margin: const EdgeInsets.only(top: 20.0, bottom: 0.0),
                  child: Image.asset(
                    "assets/marianne/marianne_bonjour.png",
                    height: 120.0,
                    width: 120.0,
                  ),
                ),
                ...items.map(
                  (item) => HomeTile(
                    title: item.title,
                    imagePath: item.imageAsset,
                    trailing: item.trailing,
                    onTap: item.onTap,
                  ),
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
    return const Row(
      children: [
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
