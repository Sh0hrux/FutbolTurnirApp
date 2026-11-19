import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';

class EditTimeSlotDialog extends StatefulWidget {
  final String currentTimeSlot;
  final int currentSlotIndex;
  final Future<void> Function(String newSlot, int newIndex) onSave;

  const EditTimeSlotDialog({
    super.key,
    required this.currentTimeSlot,
    required this.currentSlotIndex,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    required String currentTimeSlot,
    required int currentSlotIndex,
    required Future<void> Function(String newSlot, int newIndex) onSave,
  }) {
    return showDialog(
      context: context,
      builder: (context) => EditTimeSlotDialog(
        currentTimeSlot: currentTimeSlot,
        currentSlotIndex: currentSlotIndex,
        onSave: onSave,
      ),
    );
  }

  @override
  State<EditTimeSlotDialog> createState() => _EditTimeSlotDialogState();
}

class _EditTimeSlotDialogState extends State<EditTimeSlotDialog> {
  late int _selectedSlotIndex;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedSlotIndex = widget.currentSlotIndex;
  }

  Future<void> _handleSave() async {
    setState(() => _isLoading = true);
    final selectedSlotString = AppConstants.defaultTimeSlots[_selectedSlotIndex];
    await widget.onSave(selectedSlotString, _selectedSlotIndex);
    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      child: Padding(
        padding: EdgeInsets.all(20.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.editMatchTime,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              AppStrings.selectTimeSlot,
              style: TextStyle(
                fontSize: 13.sp,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            SizedBox(height: 14.h),
            ...List.generate(AppConstants.defaultTimeSlots.length, (idx) {
              final slot = AppConstants.defaultTimeSlots[idx];
              final isSelected = _selectedSlotIndex == idx;
              return GestureDetector(
                onTap: _isLoading ? null : () => setState(() => _selectedSlotIndex = idx),
                child: Container(
                  margin: EdgeInsets.only(bottom: 8.h),
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.grey.withValues(alpha: 0.3),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_filled,
                            size: 18.r,
                            color: isSelected ? AppColors.primary : Colors.grey,
                          ),
                          SizedBox(width: 10.w),
                          Text(
                            slot,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? AppColors.primary : null,
                            ),
                          ),
                        ],
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
                    ],
                  ),
                ),
              );
            }),
            SizedBox(height: 18.h),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: AppStrings.cancel,
                    isOutlined: true,
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    backgroundColor: Colors.grey,
                    textColor: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: AppButton(
                    text: AppStrings.save,
                    isLoading: _isLoading,
                    onPressed: _handleSave,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
