import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

class FadeAnimatedTextKit extends StatefulWidget {
  /// List of [String] that would be displayed subsequently in the animation.
  final List text;

  /// Gives [TextStyle] to the text strings.
  final TextStyle textStyle;

  /// Define the [Duration] of the pause between texts
  ///
  /// By default it is set to 500 milliseconds.
  final Duration pause;

  /// Override the [Duration] of the animation by setting the duration parameter.
  ///
  /// This will set the total duration for the animated widget.
  /// For example, if text = ["a", "b", "c"] and if you want that each animation
  /// should take 3 seconds then you have to set [duration] to 3 seconds.
  final Duration duration;

  /// Adds the onTap [VoidCallback] to the animated widget.
  final VoidCallback onTap;

  /// Adds the onFinished [VoidCallback] to the animated widget.
  ///
  /// This method will run only if [isRepeatingAnimation] is set to false.
  final VoidCallback onFinished;

  /// Adds the onNext [VoidCallback] to the animated widget.
  ///
  /// Will be called right before the next text, after the pause parameter
  final Function onNext;

  /// Adds the onNextBeforePause [VoidCallback] to the animated widget.
  ///
  /// Will be called at the end of n-1 animation, before the pause parameter
  final Function onNextBeforePause;

  /// Adds [AlignmentGeometry] property to the text in the widget.
  ///
  /// By default it is set to [AlignmentDirectional.topStart]
  final AlignmentGeometry alignment;

  /// Adds [TextAlign] property to the text in the widget.
  ///
  /// By default it is set to [TextAlign.start]
  final TextAlign textAlign;

  /// Sets the number of times animation should repeat
  ///
  /// By default it is set to 3
  final int totalRepeatCount;

  /// Sets if the animation should repeat forever. [isRepeatingAnimation] also
  /// needs to be set to true if you want to repeat forever.
  ///
  /// By default it is set to false, if set to true, [totalRepeatCount] is ignored.
  final bool repeatForever;

  /// Set if the animation should not repeat by changing the value of it to false.
  ///
  /// By default it is set to true.
  final bool isRepeatingAnimation;

  /// Should the animation ends up early and display full text if you tap on it ?
  ///
  /// By default it is set to false.
  final bool displayFullTextOnTap;

  /// If on pause, should a tap remove the remaining pause time ?
  ///
  /// By default it is set to false.
  final bool stopPauseOnTap;

  const FadeAnimatedTextKit(
      {Key key,
      @required this.text,
      this.duration,
      this.textStyle,
      this.pause,
      this.displayFullTextOnTap = false,
      this.stopPauseOnTap = false,
      this.onTap,
      this.onNext,
      this.onNextBeforePause,
      this.onFinished,
      this.totalRepeatCount = 3,
      this.alignment = AlignmentDirectional.topStart,
      this.textAlign = TextAlign.start,
      this.repeatForever = false,
      this.isRepeatingAnimation = true})
      : super(key: key);

  @override
  _RotatingTextState createState() => new _RotatingTextState();
}

class _RotatingTextState extends State<FadeAnimatedTextKit>
    with TickerProviderStateMixin {
  Animation _fadeIn, _fadeOut;

  AnimationController _controller;
  List<Widget> textWidgetList = [];

  Duration _pause;

  List<Map> _texts = [];

  int _index;

  bool _isCurrentlyPausing = false;

  Timer _timer;

  int _currentRepeatCount;

  Duration _duration;

  @override
  void initState() {
    super.initState();

    _pause = widget.pause ?? Duration(milliseconds: 500);

    _index = -1;

    _currentRepeatCount = 0;

    if (widget.duration == null) {
      _duration = Duration(milliseconds: 2000);
    } else {
      _duration = widget.duration;
    }

    for (int i = 0; i < widget.text.length; i++) {
      try {
        if (widget.text[i] is Map<String, dynamic>) {
          if (!widget.text[i].containsKey('text')) throw new Error();
        }

        _texts.add({
          'text': widget.text[i]['text'],
          'pause': widget.text[i].containsKey('pause')
              ? widget.text[i]['pause']
              : _pause
        });
      } catch (e) {
        _texts.add({'text': widget.text[i], 'pause': _pause});
      }
    }
    _nextAnimation();
  }

  @override
  void dispose() {
    _controller?.stop();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: _onTap,
        child: _isCurrentlyPausing || !_controller.isAnimating
            ? Text(
                _texts[_index]['text'],
                style: widget.textStyle,
                textAlign: widget.textAlign,
              )
            : AnimatedBuilder(
                animation: _controller,
                builder: (BuildContext context, Widget child) {
                  return Opacity(
                    opacity: !(_fadeIn.value == 1.0)
                        ? _fadeIn.value
                        : _fadeOut.value,
                    child: Text(
                      _texts[_index]['text'],
                      style: widget.textStyle,
                      textAlign: widget.textAlign,
                    ),
                  );
                },
              ));
  }

  void _nextAnimation() {
    bool isLast = _index == widget.text.length - 1;

    _isCurrentlyPausing = false;

    // Handling onNext callback
    if (_index > -1) {
      if (widget.onNext != null) widget.onNext(_index, isLast);
    }

    if (isLast) {
      if (widget.isRepeatingAnimation &&
          (widget.repeatForever ||
              _currentRepeatCount != (widget.totalRepeatCount - 1))) {
        _index = 0;
        if (!widget.repeatForever) {
          _currentRepeatCount++;
        }
      } else {
        if (widget.onFinished != null) widget.onFinished();
        return;
      }
    } else {
      _index++;
    }

    if (mounted) setState(() {});

    _controller = new AnimationController(
      duration: _duration,
      vsync: this,
    );

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _controller, curve: Interval(0.0, 0.5, curve: Curves.linear)));

    _fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(CurvedAnimation(
        parent: _controller, curve: Interval(0.8, 1.0, curve: Curves.linear)))
      ..addStatusListener(_animationEndCallback);

    _controller.forward();
  }

  void _setPause() {
    bool isLast = _index == widget.text.length - 1;

    _isCurrentlyPausing = true;
    if (mounted) setState(() {});

    // Handle onNextBeforePause callback
    if (widget.onNextBeforePause != null)
      widget.onNextBeforePause(_index, isLast);
  }

  void _animationEndCallback(state) {
    if (state == AnimationStatus.completed) {
      _isCurrentlyPausing = true;
      _timer = Timer(_texts[_index]['pause'], _nextAnimation);
    }
  }

  void _onTap() {
    int pause;
    int left;

    if (widget.displayFullTextOnTap) {
      if (_isCurrentlyPausing) {
        if (widget.stopPauseOnTap) {
          _timer?.cancel();
          _nextAnimation();
        }
      } else {
        pause = _texts[_index]['pause'].inMilliseconds;
        left = widget.duration.inMilliseconds;

        _controller?.stop();

        _setPause();

        _timer =
            Timer(Duration(milliseconds: max(pause, left)), _nextAnimation);
      }
    }

    if (widget.onTap != null) {
      widget.onTap();
    }
  }
}
