import 'package:flutter/material.dart';
import 'package:org_flutter/org_flutter.dart';

class AnimatedTextFlash extends StatefulWidget {
  const AnimatedTextFlash({
    required this.child,
    required this.cookie,
    super.key,
  });

  final Widget child;
  final dynamic cookie;

  @override
  State<AnimatedTextFlash> createState() => _AnimatedTextFlashState();
}

class _AnimatedTextFlashState extends State<AnimatedTextFlash>
    with SingleTickerProviderStateMixin {
  late AnimationController _animation;

  @override
  void initState() {
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    super.initState();
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AnimatedTextFlash oldWidget) {
    if (oldWidget.cookie != widget.cookie) {
      _flash();
    }
    super.didUpdateWidget(oldWidget);
  }

  void _flash() async {
    await _animation.forward();
    await _animation.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final defaultStyle = DefaultTextStyle.of(context).style;

    return DefaultTextStyleTransition(
      style: _animation.drive(
        TextStyleTween(
          begin: defaultStyle,
          end: defaultStyle.copyWith(
              backgroundColor: OrgTheme.dataOf(context).highlightColor),
        ).chain(
          CurveTween(curve: Curves.linearToEaseOut),
        ),
      ),
      child: widget.child,
    );
  }
}
