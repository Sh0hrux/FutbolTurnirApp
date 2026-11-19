import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TeamAvatar extends StatelessWidget {
  final String name;
  final int colorValue;
  final String? logoPath;
  final double size;

  const TeamAvatar({
    super.key,
    required this.name,
    required this.colorValue,
    this.logoPath,
    this.size = 44,
  });

  String get _initials {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'FC';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      final suffix = parts.last.toUpperCase();
      if (suffix == 'ФК' || suffix == 'FK' || suffix == 'FC') {
        final mainName = parts.sublist(0, parts.length - 1).join(' ');
        return mainName.length >= 3 ? mainName.substring(0, 3).toUpperCase() : mainName.toUpperCase();
      }
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    // Differentiate single word teams: Nasaf -> NAS, Navbahor -> NAV
    return trimmed.length >= 3 ? trimmed.substring(0, 3).toUpperCase() : trimmed.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final teamColor = Color(colorValue);

    return Container(
      width: size.r,
      height: size.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            teamColor,
            Color.lerp(teamColor, Colors.black, 0.3) ?? teamColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1.0.r,
        ),
      ),
      child: Center(
        child: Text(
          _initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: (size * 0.36).sp,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

