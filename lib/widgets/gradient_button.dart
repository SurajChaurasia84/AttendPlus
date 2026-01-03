import 'package:flutter/material.dart';

Widget gradientButton({
  required String text,
  required VoidCallback? onPressed,
  bool loading = false,
  double height = 48,
  BorderRadius borderRadius = const BorderRadius.all(Radius.circular(12)),
}) {
  return SizedBox(
    width: double.infinity,
    height: height,
    child: InkWell(
      onTap: loading ? null : onPressed,
      borderRadius: borderRadius,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          gradient: LinearGradient(
            colors: [
              const Color(0xFF7925F6),
              const Color(0xFF9D5CFF),
            ],
          ),
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    ),
  );
}
