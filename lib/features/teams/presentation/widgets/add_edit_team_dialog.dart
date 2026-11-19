import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/team_avatar.dart';
import '../../domain/entities/team_entity.dart';

class AddEditTeamDialog extends StatefulWidget {
  final TeamEntity? team;
  final Future<bool> Function({
    required String name,
    required int colorValue,
    String? logoPath,
  }) onSave;

  const AddEditTeamDialog({
    super.key,
    this.team,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    TeamEntity? team,
    required Future<bool> Function({
      required String name,
      required int colorValue,
      String? logoPath,
    }) onSave,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AddEditTeamDialog(team: team, onSave: onSave),
    );
  }

  @override
  State<AddEditTeamDialog> createState() => _AddEditTeamDialogState();
}

class _AddEditTeamDialogState extends State<AddEditTeamDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late int _selectedColor;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.team?.name ?? '');
    _selectedColor = widget.team?.colorValue ?? AppConstants.presetTeamColors.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showColorPicker() {
    Color pickerColor = Color(_selectedColor);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.selectColor),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: pickerColor,
            onColorChanged: (c) => pickerColor = c,
            paletteType: PaletteType.hsvWithHue,
            enableAlpha: false,
            labelTypes: const [],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.cancel),
          ),
            ElevatedButton(
            onPressed: () {
              setState(() {
                _selectedColor = pickerColor.toARGB32();
              });
              Navigator.of(context).pop();
            },
            child: const Text(AppStrings.confirm),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final success = await widget.onSave(
      name: _nameController.text.trim(),
      colorValue: _selectedColor,
      logoPath: widget.team?.logoPath,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.team != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: 0.85.sh),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.r),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing ? AppStrings.editTeam : AppStrings.addTeam,
                      style: TextStyle(
                        fontSize: 18.sp,
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
                SizedBox(height: 16.h),

                // Preview Avatar
                Center(
                  child: TeamAvatar(
                    name: _nameController.text.isEmpty ? 'FC' : _nameController.text,
                    colorValue: _selectedColor,
                    size: 56,
                  ),
                ),
                SizedBox(height: 20.h),

                // Name field
                Text(
                  AppStrings.teamName,
                  style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 8.h),
                TextFormField(
                  controller: _nameController,
                  enabled: !_isLoading,
                  decoration: const InputDecoration(
                    hintText: 'Masalan: Real Madrid',
                    prefixIcon: Icon(Icons.shield_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().length < 2) {
                      return AppStrings.teamNameValidation;
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),
                SizedBox(height: 18.h),

                // Color Selection Palette
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppStrings.teamColor,
                      style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
                    ),
                    TextButton.icon(
                      onPressed: _isLoading ? null : _showColorPicker,
                      icon: Icon(Icons.palette, size: 16.r, color: AppColors.primary),
                      label: Text(
                        'Boshqa rang',
                        style: TextStyle(fontSize: 12.sp, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: AppConstants.presetTeamColors.map((colorVal) {
                    final isSelected = colorVal == _selectedColor;
                    final c = Color(colorVal);
                    return GestureDetector(
                      onTap: _isLoading ? null : () => setState(() => _selectedColor = colorVal),
                      child: Container(
                        width: 32.r,
                        height: 32.r,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.transparent,
                            width: 2.5,
                          ),
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(
                                color: c.withValues(alpha: 0.6),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                          ],
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, size: 18, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 24.h),

                // Buttons
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
                    SizedBox(width: 12.w),
                    Expanded(
                      child: AppButton(
                        text: AppStrings.save,
                        isLoading: _isLoading,
                        onPressed: _handleSubmit,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

