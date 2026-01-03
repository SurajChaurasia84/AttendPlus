import 'package:flutter/material.dart';

class AnimatedGradientButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool loading;
  final double height;
  final double borderRadius;

  const AnimatedGradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.loading = false,
    this.height = 52,
    this.borderRadius = 12,
  });

  @override
  State<AnimatedGradientButton> createState() =>
      _AnimatedGradientButtonState();
}

class _AnimatedGradientButtonState extends State<AnimatedGradientButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.loading;

    return SizedBox(
      width: double.infinity,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final v = _controller.value;

          return Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: InkWell(
              onTap: isDisabled ? null : widget.onPressed,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(widget.borderRadius),
                  gradient: LinearGradient(
                    begin: Alignment(-1 + v * 2, 0),
                    end: Alignment(1 + v * 2, 0),
                    colors: isDisabled
                        ? [
                            Colors.grey.shade400,
                            Colors.grey.shade500,
                          ]
                        : const [
                            Color(0xFF7925F6),
                            Color(0xFF9D5CFF),
                            Color(0xFF7925F6),
                          ],
                  ),
                  boxShadow: isDisabled
                      ? []
                      : [
                          BoxShadow(
                            color: const Color(0xFF7925F6)
                                .withOpacity(0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                ),
                child: Center(
                  child: widget.loading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          widget.text,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                          ),
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
