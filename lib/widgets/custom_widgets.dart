import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

// ========================================
// CUSTOM LOADING WIDGET
// ========================================
class CustomLoading extends StatelessWidget {
  final String? message;
  final Color? color;

  CustomLoading({this.message, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
      ),
      child: Center(
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SpinKitWave(
                  color: color ?? Colors.blue.shade700,
                  size: 50.0,
                ),
                if (message != null) ...[
                  SizedBox(height: 20),
                  Text(
                    message!,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ========================================
// CUSTOM SNACKBAR
// ========================================
class CustomSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    required SnackBarType type,
    Duration duration = const Duration(seconds: 3),
  }) {
    Color backgroundColor;
    IconData icon;
    
    switch (type) {
      case SnackBarType.success:
        backgroundColor = Colors.green.shade600;
        icon = Icons.check_circle;
        break;
      case SnackBarType.error:
        backgroundColor = Colors.red.shade600;
        icon = Icons.error;
        break;
      case SnackBarType.warning:
        backgroundColor = Colors.orange.shade600;
        icon = Icons.warning;
        break;
      case SnackBarType.info:
        backgroundColor = Colors.blue.shade600;
        icon = Icons.info;
        break;
    }

    HapticFeedback.lightImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.all(16),
        duration: duration,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }
}

enum SnackBarType { success, error, warning, info }

// ========================================
// PARTICLE BACKGROUND
// ========================================
class ParticleBackground extends StatefulWidget {
  final Widget child;
  final Color? particleColor;

  ParticleBackground({
    required this.child,
    this.particleColor,
  });

  @override
  _ParticleBackgroundState createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 20),
    )..repeat();

    // Generate particles
    for (int i = 0; i < 30; i++) {
      particles.add(Particle());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: ParticlePainter(
                particles: particles,
                animation: _controller.value,
                color: widget.particleColor ?? Colors.white.withOpacity(0.1),
              ),
              child: Container(),
            );
          },
        ),
        widget.child,
      ],
    );
  }
}

class Particle {
  double x = 0;
  double y = 0;
  double size = 4;
  double speedY = 0.5;
  
  Particle() {
    x = (100 * (0.5 - (DateTime.now().millisecond % 100) / 100));
    y = (100 * (DateTime.now().millisecond % 100) / 100);
    size = 2 + (DateTime.now().millisecond % 6);
    speedY = 0.3 + (DateTime.now().millisecond % 10) / 20;
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double animation;
  final Color color;

  ParticlePainter({
    required this.particles,
    required this.animation,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (var particle in particles) {
      double x = (particle.x + 50) * size.width / 100;
      double y = ((particle.y + animation * particle.speedY * 100) % 100) * size.height / 100;
      
      canvas.drawCircle(
        Offset(x, y),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}

// ========================================
// EMPTY STATE WIDGET
// ========================================
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onAction;
  final String? actionLabel;

  EmptyStateWidget({
    required this.icon,
    required this.title,
    required this.message,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: Duration(milliseconds: 600),
              builder: (context, double value, child) {
                return Transform.scale(
                  scale: value,
                  child: Icon(
                    icon,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                );
              },
            ),
            SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            if (onAction != null) ...[
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: Icon(Icons.add),
                label: Text(actionLabel ?? 'Tambah'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ========================================
// SCROLL TO TOP FAB
// ========================================
class ScrollToTopFAB extends StatefulWidget {
  final ScrollController scrollController;

  ScrollToTopFAB({required this.scrollController});

  @override
  _ScrollToTopFABState createState() => _ScrollToTopFABState();
}

class _ScrollToTopFABState extends State<ScrollToTopFAB> {
  bool _showFAB = false;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (widget.scrollController.offset > 200 && !_showFAB) {
      setState(() => _showFAB = true);
    } else if (widget.scrollController.offset <= 200 && _showFAB) {
      setState(() => _showFAB = false);
    }
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_scrollListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _showFAB ? 1.0 : 0.0,
      duration: Duration(milliseconds: 300),
      child: AnimatedScale(
        scale: _showFAB ? 1.0 : 0.0,
        duration: Duration(milliseconds: 300),
        child: FloatingActionButton(
          mini: true,
          onPressed: () {
            HapticFeedback.mediumImpact();
            widget.scrollController.animateTo(
              0,
              duration: Duration(milliseconds: 500),
              curve: Curves.easeOut,
            );
          },
          child: Icon(Icons.arrow_upward),
        ),
      ),
    );
  }
}

// ========================================
// GRADIENT BACKGROUND
// ========================================
class GradientBackground extends StatelessWidget {
  final Widget child;
  final List<Color>? colors;

  GradientBackground({
    required this.child,
    this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors ?? (isDark
            ? [
                Color(0xFF1a237e),
                Color(0xFF0d47a1),
                Color(0xFF01579b),
              ]
            : [
                Colors.blue.shade50,
                Colors.blue.shade100,
                Colors.blue.shade200,
              ]),
        ),
      ),
      child: child,
    );
  }
}

// ========================================
// BUTTON WITH HAPTIC
// ========================================
class HapticButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  final ButtonStyle? style;

  HapticButton({
    required this.onPressed,
    required this.child,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
      style: style,
      child: child,
    );
  }
}