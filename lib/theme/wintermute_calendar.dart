import 'dart:math';
import 'package:flutter/material.dart';
import 'colors.dart';

/// Wintermute Calendar Theme - Cyberpunk aesthetic for peptide protocol calendar
/// 
/// Critical: Maintains consistency with Dashboard, Protocols, Research, Labs tabs
/// Color palette: Neon cyan (#00FFFF), neon green (#39FF14), pure black backgrounds
/// Typography: JetBrains Mono (monospace) for all text
/// Effects: Scanlines, film grain, selective neon glow

class WintermuteCalendar {
  // ==================== CALENDAR-SPECIFIC COLORS ====================
  
  /// Status colors for dose tracking
  static const Color statusOnTrack = Color(0xFF39FF14);   // Green - all doses logged
  static const Color statusPending = Color(0xFF00FFFF);   // Cyan - upcoming/pending
  static const Color statusMissed = Color(0xFFFF0000);    // Red - missed doses
  static const Color statusOverdue = Color(0xFFFF6600);   // Orange - warning
  
  /// Border colors (25% opacity for subtle borders)
  static const Color borderCyan = Color(0x4000FFFF);
  static const Color borderGreen = Color(0x4039FF14);
  static const Color borderRed = Color(0x40FF0000);
  static const Color borderOrange = Color(0x40FF6600);
  
  /// Glow colors (40% opacity for selective neon effects)
  static const Color glowCyan = Color(0x6600FFFF);
  static const Color glowGreen = Color(0x6639FF14);
  static const Color glowRed = Color(0x66FF0000);
  
  // ==================== TEXT STYLES (JetBrains Mono) ====================
  
  /// Week header ("MON TUE WED THU FRI SAT SUN")
  static const TextStyle weekHeaderStyle = TextStyle(
    fontFamily: 'JetBrains Mono',
    fontSize: 11,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,  // Cyan
    letterSpacing: 1.5,
  );
  
  /// Date range header ("MAR 10-16, 2026")
  static const TextStyle dateRangeStyle = TextStyle(
    fontFamily: 'JetBrains Mono',
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,  // Cyan
    letterSpacing: 1.0,
  );
  
  /// Day number in grid cell (e.g., "10", "11", "12")
  static const TextStyle dayNumberStyle = TextStyle(
    fontFamily: 'JetBrains Mono',
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.textLight,  // White
  );
  
  /// Dose count indicator (e.g., "3 doses", "1 dose")
  static const TextStyle doseCountStyle = TextStyle(
    fontFamily: 'JetBrains Mono',
    fontSize: 10,
    fontWeight: FontWeight.normal,
    color: AppColors.accent,  // Green
  );
  
  /// Bottom sheet title
  static const TextStyle sheetTitleStyle = TextStyle(
    fontFamily: 'JetBrains Mono',
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,  // Cyan
    letterSpacing: 1.0,
  );
  
  /// Filter chip label (cycle filter)
  static const TextStyle filterChipStyle = TextStyle(
    fontFamily: 'JetBrains Mono',
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: AppColors.accent,  // Green
    letterSpacing: 0.5,
  );
  
  // ==================== GLOW EFFECTS (SELECTIVE) ====================
  
  /// Cyan glow - for selected day cells, pending doses
  static const List<BoxShadow> neonGlowCyan = [
    BoxShadow(
      color: Color(0x4D00FFFF),  // 30% opacity
      blurRadius: 8,
      spreadRadius: 0,
      offset: Offset(0, 0),
    ),
  ];
  
  /// Green glow - for on-track day cells, logged doses
  static const List<BoxShadow> neonGlowGreen = [
    BoxShadow(
      color: Color(0x4D39FF14),  // 30% opacity
      blurRadius: 8,
      spreadRadius: 0,
      offset: Offset(0, 0),
    ),
  ];
  
  /// Red glow - for missed dose indicators
  static const List<BoxShadow> neonGlowRed = [
    BoxShadow(
      color: Color(0x4DFF0000),  // 30% opacity
      blurRadius: 8,
      spreadRadius: 0,
      offset: Offset(0, 0),
    ),
  ];
  
  // ==================== COMPONENT DECORATIONS ====================
  
  /// Day cell (normal state) - black background, subtle cyan border
  static BoxDecoration dayCellDecoration({bool isToday = false}) {
    return BoxDecoration(
      color: AppColors.background,
      border: Border.all(
        color: isToday ? AppColors.primary : borderCyan,
        width: isToday ? 2 : 1,
      ),
      borderRadius: BorderRadius.circular(4),
    );
  }
  
  /// Day cell (selected state) - dark surface, cyan border + glow
  static BoxDecoration dayCellSelectedDecoration({Color? statusColor}) {
    return BoxDecoration(
      color: AppColors.surface,
      border: Border.all(
        color: statusColor ?? AppColors.primary,
        width: 1,
      ),
      borderRadius: BorderRadius.circular(4),
      boxShadow: statusColor == statusOnTrack ? neonGlowGreen : neonGlowCyan,
    );
  }
  
  /// Day cell (has doses) - add subtle glow based on status
  static BoxDecoration dayCellWithDosesDecoration({
    required Color statusColor,
    bool isSelected = false,
  }) {
    List<BoxShadow>? glow;
    if (statusColor == statusOnTrack) glow = neonGlowGreen;
    else if (statusColor == statusMissed) glow = neonGlowRed;
    else if (statusColor == statusPending) glow = neonGlowCyan;
    
    return BoxDecoration(
      color: isSelected ? AppColors.surface : AppColors.background,
      border: Border.all(
        color: statusColor.withOpacity(0.5),
        width: 1,
      ),
      borderRadius: BorderRadius.circular(4),
      boxShadow: isSelected ? glow : null,
    );
  }
  
  /// Filter chip (cycle selector) - black bg, green text, cyan border
  static BoxDecoration filterChipDecoration({bool isSelected = false}) {
    return BoxDecoration(
      color: isSelected ? AppColors.surface : AppColors.background,
      border: Border.all(
        color: isSelected ? AppColors.primary : borderCyan,
        width: 1,
      ),
      borderRadius: BorderRadius.circular(16),
      boxShadow: isSelected ? neonGlowCyan : null,
    );
  }
  
  /// Bottom sheet - black background, cyan header, scanlines
  static BoxDecoration bottomSheetDecoration() {
    return BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      border: Border(
        top: BorderSide(color: AppColors.primary, width: 2),
      ),
    );
  }
  
  /// Status indicator chip (in day cell or bottom sheet)
  static BoxDecoration statusChipDecoration(Color statusColor) {
    return BoxDecoration(
      color: AppColors.background,
      border: Border.all(
        color: statusColor.withOpacity(0.6),
        width: 1,
      ),
      borderRadius: BorderRadius.circular(4),
    );
  }
  
  // ==================== ANIMATION DURATIONS ====================
  
  static const Duration tapAnimationDuration = Duration(milliseconds: 200);
  static const Duration glowAnimationDuration = Duration(milliseconds: 300);
  static const Curve animationCurve = Curves.easeOut;
  
  // ==================== HELPER METHODS ====================
  
  /// Get status color based on dose compliance
  static Color getStatusColor({
    required int scheduledDoses,
    required int loggedDoses,
    required DateTime date,
  }) {
    final now = DateTime.now();
    final isToday = date.year == now.year && 
                    date.month == now.month && 
                    date.day == now.day;
    final isPast = date.isBefore(now) && !isToday;
    
    if (loggedDoses >= scheduledDoses) {
      return statusOnTrack;  // Green - all doses logged
    } else if (isPast) {
      return statusMissed;   // Red - missed doses
    } else if (isToday && loggedDoses < scheduledDoses) {
      return statusOverdue;  // Orange - due today, not logged
    } else {
      return statusPending;  // Cyan - upcoming
    }
  }
  
  /// Get status text label
  static String getStatusLabel({
    required int scheduledDoses,
    required int loggedDoses,
  }) {
    if (loggedDoses >= scheduledDoses) return 'ON TRACK';
    if (loggedDoses > 0) return 'PARTIAL';
    return 'PENDING';
  }
  
  /// Get glow for status color
  static List<BoxShadow>? getGlowForStatus(Color statusColor) {
    if (statusColor == statusOnTrack) return neonGlowGreen;
    if (statusColor == statusMissed) return neonGlowRed;
    if (statusColor == statusPending) return neonGlowCyan;
    return null;
  }
}

// ==================== CUSTOM PAINTERS ====================

/// Film grain overlay for calendar (subtle texture)
class FilmGrainPainter extends CustomPainter {
  final double opacity;
  
  FilmGrainPainter({this.opacity = 0.03});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(opacity)
      ..style = PaintingStyle.fill;
    
    // Simple random noise pattern
    final random = Random(42);  // Seeded for consistency
    for (int i = 0; i < 200; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), 0.5, paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Film grain overlay widget
class FilmGrainOverlay extends StatelessWidget {
  final Widget child;
  final double opacity;
  
  const FilmGrainOverlay({
    Key? key,
    required this.child,
    this.opacity = 0.03,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: FilmGrainPainter(opacity: opacity),
            ),
          ),
        ),
      ],
    );
  }
}
