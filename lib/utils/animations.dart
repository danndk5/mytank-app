import 'package:flutter/material.dart';

class AppAnimations {
  // Slide Transition untuk Page Route
  static Route createSlideRoute(Widget page, {AxisDirection direction = AxisDirection.left}) {
    Offset begin;
    switch (direction) {
      case AxisDirection.up:
        begin = Offset(0.0, 1.0);
        break;
      case AxisDirection.down:
        begin = Offset(0.0, -1.0);
        break;
      case AxisDirection.left:
        begin = Offset(1.0, 0.0);
        break;
      case AxisDirection.right:
        begin = Offset(-1.0, 0.0);
        break;
    }

    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var tween = Tween(begin: begin, end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeInOut));
        var offsetAnimation = animation.drive(tween);
        return SlideTransition(position: offsetAnimation, child: child);
      },
      transitionDuration: Duration(milliseconds: 300),
    );
  }

  // Fade Transition untuk Page Route
  static Route createFadeRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: Duration(milliseconds: 300),
    );
  }

  // Scale Transition untuk Page Route
  static Route createScaleRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var tween = Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut));
        var scaleAnimation = animation.drive(tween);
        return ScaleTransition(scale: scaleAnimation, child: child);
      },
      transitionDuration: Duration(milliseconds: 300),
    );
  }
}

// Animated Card Widget
class AnimatedCard extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;

  AnimatedCard({
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  _AnimatedCardState createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

// Loading Animation
class LoadingAnimation extends StatelessWidget {
  final String? message;
  final Color? color;

  LoadingAnimation({this.message, this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? Theme.of(context).primaryColor,
            ),
          ),
          if (message != null) ...[
            SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ],
      ),
    );
  }
}

// Success Animation
class SuccessAnimation extends StatefulWidget {
  final VoidCallback? onComplete;

  SuccessAnimation({this.onComplete});

  @override
  _SuccessAnimationState createState() => _SuccessAnimationState();
}

class _SuccessAnimationState extends State<SuccessAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward().then((_) {
      if (mounted) {
        Future.delayed(Duration(milliseconds: 500), () {
          if (widget.onComplete != null) widget.onComplete!();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              Icons.check_circle,
              size: 80,
              color: Colors.green,
            ),
          ),
        ),
      ),
    );
  }
}

// Error Animation
class ErrorAnimation extends StatefulWidget {
  final String? message;
  final VoidCallback? onRetry;

  ErrorAnimation({this.message, this.onRetry});

  @override
  _ErrorAnimationState createState() => _ErrorAnimationState();
}

class _ErrorAnimationState extends State<ErrorAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.rotate(
                angle: _controller.value * 0.1,
                child: Icon(
                  Icons.error_outline,
                  size: 80,
                  color: Colors.red,
                ),
              );
            },
          ),
          SizedBox(height: 16),
          Text(
            widget.message ?? 'Terjadi kesalahan',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
            textAlign: TextAlign.center,
          ),
          if (widget.onRetry != null) ...[
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: widget.onRetry,
              child: Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        ],
      ),
    );
  }
}

// Staggered List Animation
class StaggeredListView extends StatelessWidget {
  final List<Widget> children;
  final Duration delay;
  final Duration itemDuration;

  StaggeredListView({
    required this.children,
    this.delay = const Duration(milliseconds: 100),
    this.itemDuration = const Duration(milliseconds: 400),
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: children.length,
      itemBuilder: (context, index) {
        return AnimatedCard(
          delay: delay * index,
          duration: itemDuration,
          child: children[index],
        );
      },
    );
  }
}