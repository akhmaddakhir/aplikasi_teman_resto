import 'package:flutter/material.dart';

class PartnerTheme {
  static const Color orange = Color(0xFFFF4F0F);
  static const Color text = Color(0xFF1A1A1A);
  static const Color muted = Color(0xFF888888);
  static const Color soft = Color(0xFFF4F4F4);
  static const String font = 'Inter';

  static ThemeData pageTheme(BuildContext context) {
    final base = Theme.of(context);
    return base.copyWith(
      textTheme: base.textTheme.apply(fontFamily: font),
      primaryTextTheme: base.primaryTextTheme.apply(fontFamily: font),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          textStyle: const TextStyle(fontFamily: font),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          textStyle: const TextStyle(fontFamily: font),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: const TextStyle(fontFamily: font),
        ),
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        labelStyle: base.inputDecorationTheme.labelStyle?.copyWith(
              fontFamily: font,
            ) ??
            const TextStyle(fontFamily: font),
        hintStyle: base.inputDecorationTheme.hintStyle?.copyWith(
              fontFamily: font,
            ) ??
            const TextStyle(fontFamily: font),
      ),
      tabBarTheme: base.tabBarTheme.copyWith(
        labelStyle: base.tabBarTheme.labelStyle?.copyWith(
              fontFamily: font,
            ) ??
            const TextStyle(fontFamily: font),
        unselectedLabelStyle: base.tabBarTheme.unselectedLabelStyle?.copyWith(
              fontFamily: font,
            ) ??
            const TextStyle(fontFamily: font),
      ),
    );
  }

  static Widget wrap(BuildContext context, {required Widget child}) {
    return Theme(
      data: pageTheme(context),
      child: DefaultTextStyle.merge(
        style: const TextStyle(fontFamily: font),
        child: child,
      ),
    );
  }

  static BoxDecoration cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withOpacity(0.28), width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.07),
          blurRadius: 16,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  static ButtonStyle primaryButtonStyle({Color backgroundColor = orange}) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      disabledBackgroundColor: backgroundColor.withOpacity(0.6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(50),
      ),
    );
  }

  static InputDecoration inputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF0F0F0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: orange, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  static Widget emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    double iconSize = 32,
    double containerSize = 72,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            width: containerSize,
            height: containerSize,
            decoration: BoxDecoration(
              color: orange.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: orange, size: iconSize),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontFamily: font,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: font,
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

class PartnerPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final Widget? trailing;

  const PartnerPageHeader({
    Key? key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              size: 20,
              color: Colors.black,
            ),
            onPressed: onBack ?? () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: PartnerTheme.font,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          SizedBox(width: 48, child: trailing),
        ],
      ),
    );
  }
}
