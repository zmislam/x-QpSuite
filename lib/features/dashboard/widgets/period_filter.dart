import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/dashboard_provider.dart';

/// Horizontal scrollable row of period filter pills (Today, Yesterday, 3d...All).
/// Matches the web dashboard's time filter design.
class PeriodFilter extends StatelessWidget {
  final int selectedPeriod;
  final bool isLoading;
  final ValueChanged<int> onPeriodChanged;

  const PeriodFilter({
    super.key,
    required this.selectedPeriod,
    this.isLoading = false,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Row(
        children: [
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: DashboardProvider.periodOptions.length,
                separatorBuilder: (context, index) =>
                  const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final option = DashboardProvider.periodOptions[index];
                final isSelected = option.value == selectedPeriod;

                return GestureDetector(
                  onTap: () => onPeriodChanged(option.value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color:
                            isSelected ? AppColors.primary : AppColors.dividerLight,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        option.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
