import 'package:flutter/widgets.dart';

class DbugSpinner extends StatefulWidget {
  final double size;
  final double strokeWidth;
  final Color? color;

  const DbugSpinner({
    super.key,
    this.size = 16,
    this.strokeWidth = 2,
    this.color,
  });

  @override
  State<DbugSpinner> createState() => _DbugSpinnerState();
}

class _DbugSpinnerState extends State<DbugSpinner> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: CustomPaint(
        painter: _SpinnerPainter(
          color: widget.color,
          strokeWidth: widget.strokeWidth,
          animation: _controller,
        ),
      ),
    );
  }
}

class _SpinnerPainter extends CustomPainter {
  final Color? color;
  final double strokeWidth;
  final Animation<double> animation;

  _SpinnerPainter({required this.color, required this.strokeWidth, required this.animation})
      : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color ?? const Color(0xFFA1A1AA)
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    const sweepAngle = 5.0 * 3.14159 / 3.0;
    final startAngle = animation.value * 2 * 3.14159;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_SpinnerPainter old) => old.animation.value != animation.value;
}
