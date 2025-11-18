import 'package:examen_civique/design/style/app_colors.dart';
import 'package:examen_civique/design/style/app_text_styles.dart';
import 'package:examen_civique/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum _ViewMode { week, month }

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});
  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  _ViewMode _viewMode = _ViewMode.week;

  @override
  void initState() {
    super.initState();
  }

  get _monday {
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day - (now.weekday - DateTime.monday),
    );
  }

  get _month {
    return DateTime(DateTime.now().year, DateTime.now().month, 1);
  }

  String _fmtWeek(DateTime monday) {
    final DateFormat formatter = DateFormat('d MMMM', 'fr_FR');
    final sunday = monday.add(const Duration(days: 6));
    return '${formatter.format(monday)} – ${formatter.format(sunday)}';
  }

  String _fmtMonth(DateTime month) {
    final DateFormat formatter = DateFormat('MMMM yyyy', 'fr_FR');
    return formatter.format(month);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryGreyLight,
      appBar: buildAppBar(
        'Statistiques',
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
          color: AppColors.primaryGrey,
          iconSize: 25,
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              elevation: 2.0,
              child: _ModeToggle(
                mode: _viewMode,
                onChanged: (m) => setState(() => _viewMode = m),
              ),
            ),
          ),
          Text(
            _viewMode == _ViewMode.week ? _fmtWeek(_monday) : _fmtMonth(_month),
            style: AppTextStyles.regular16,
          ),
        ],
      ),
    );
  }
}

class _ModeToggle extends StatefulWidget {
  final _ViewMode mode;
  final ValueChanged<_ViewMode> onChanged;
  const _ModeToggle({required this.mode, required this.onChanged});
  @override
  State<_ModeToggle> createState() => _ModeToggleState();
}

class _ModeToggleState extends State<_ModeToggle> {
  @override
  Widget build(BuildContext context) {
    final bool isweek = widget.mode == _ViewMode.week;

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.superSilver,
        borderRadius: BorderRadius.circular(6.0),
      ),
      padding: const EdgeInsets.all(4.0),
      child: Stack(
        children: [
          AnimatedAlign(
            alignment: isweek ? Alignment.centerLeft : Alignment.centerRight,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primaryNavyBlue,
                  borderRadius: BorderRadius.circular(6.0),
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => setState(() => widget.onChanged(_ViewMode.week)),
                  child: Center(
                    child: Text(
                      'Cette semaine',
                      style: AppTextStyles.bold14.copyWith(
                        color: isweek ? AppColors.white : AppColors.primaryGrey,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () =>
                      setState(() => widget.onChanged(_ViewMode.month)),
                  child: Center(
                    child: Text(
                      'Ce mois-ci',
                      style: AppTextStyles.bold14.copyWith(
                        color: !isweek
                            ? AppColors.white
                            : AppColors.primaryGrey,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
