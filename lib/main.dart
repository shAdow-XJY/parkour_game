import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Parkour Game',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: const StickmanRunningPage(),
    );
  }
}

class StickmanRunningPage extends StatefulWidget {
  const StickmanRunningPage({super.key});

  @override
  State<StickmanRunningPage> createState() => _StickmanRunningPageState();
}

class _StickmanRunningPageState extends State<StickmanRunningPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final FocusNode _focusNode = FocusNode();
  double _obstacleX = 1.0; // 障碍物的初始位置
  bool _isJumping = false;
  bool _gameOver = false;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // 障碍物的移动逻辑
    _controller.addListener(() {
      setState(() {
        _obstacleX -= 0.01;
        if (_obstacleX < -0.2) {
          _obstacleX = 1.0;
        }

        // 碰撞检测逻辑
        if (_obstacleX < 0.2 && _obstacleX > 0.1 && !_isJumping) {
          _gameOver = true;
          _controller.stop();
        }
      });
    });
    _controller.repeat();

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        RawKeyboard.instance.addListener(_handleKeyPress);
      } else {
        RawKeyboard.instance.removeListener(_handleKeyPress);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _jump() {
    if (!_isJumping && !_gameOver) {
      setState(() {
        _isJumping = true;
        Future.delayed(const Duration(milliseconds: 500), () {
          setState(() => _isJumping = false);
        });
      });
    }
  }

  void _restartGame() {
    setState(() {
      _gameOver = false;
      _obstacleX = 1.0;
      _controller.repeat();
    });
  }

  void _handleKeyPress(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.space) {
        _jump();
      }
      if (_gameOver && event.logicalKey == LogicalKeyboardKey.keyR) {
        _restartGame();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parkour Game'),
      ),
      body: RawKeyboardListener(
        focusNode: _focusNode,
        onKey: _handleKeyPress,
        child: GestureDetector(
          onTap: _gameOver ? _restartGame : _jump,
          child: Stack(
            children: [
              // 地面和障碍物
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    painter: GroundPainter(_obstacleX),
                    child: Container(),
                  );
                },
              ),
              // 火柴人
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    painter: StickmanPainter(_controller.value, _isJumping),
                    child: Container(),
                  );
                },
              ),
              // 游戏提示
              Center(
                child: Text(
                  (_gameOver ? 'Game Over - Click Or Tap \'R\' to Restart 🤣🤣🤣' : 'Gaming - Click Or Tap \'Space\' to Jump 🤣🤣🤣'),
                  style: const TextStyle(fontSize: 24, color: Colors.red),
                ),
              ), 
            ],
          ),
        ),
      ),
    );
  }
}

class StickmanPainter extends CustomPainter {
  final double progress;
  final bool isJumping;

  StickmanPainter(this.progress, this.isJumping);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2;

    var groundY = size.height * 0.8; // 地面的高度
    var jumpHeight = isJumping ? 30.0 : 0.0; // 跳跃时的垂直位移

    // 火柴人的中心位置
    var stickmanHeight = 45.0; // 火柴人的总高度
    var center =
        Offset(size.width * 0.2, groundY - stickmanHeight - jumpHeight);

    // 头部
    var headRadius = 10.0;
    canvas.drawCircle(center, headRadius, paint);

    // 身体
    var bodyLength = 20.0;
    var bodyStart = center.translate(0, headRadius);
    var bodyEnd = bodyStart.translate(0, bodyLength);
    canvas.drawLine(bodyStart, bodyEnd, paint);

    // 腿部
    var legsLength = 15.0;
    var legLeftStart = bodyEnd;
    var legRightStart = bodyEnd;
    var legMovement = (progress * 20 - 10).abs(); // 加快腿部动画速度
    var legLeftEnd = legLeftStart.translate(legMovement, legsLength);
    var legRightEnd = legRightStart.translate(-legMovement, legsLength);
    canvas.drawLine(legLeftStart, legLeftEnd, paint);
    canvas.drawLine(legRightStart, legRightEnd, paint);

    // 手臂
    var armLeftStart = bodyStart.translate(0, 5);
    var armRightStart = bodyStart.translate(0, 5);
    var armLeftEnd = armLeftStart.translate(-10, 0); // 固定手臂位置
    var armRightEnd = armRightStart.translate(10, 0); // 固定手臂位置
    canvas.drawLine(armLeftStart, armLeftEnd, paint);
    canvas.drawLine(armRightStart, armRightEnd, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class GroundPainter extends CustomPainter {
  final double obstacleX;

  GroundPainter(this.obstacleX);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = Colors.brown // 地面颜色
      ..style = PaintingStyle.fill;

    var groundY = size.height * 0.8; // 地面的高度

    // 绘制地面
    canvas.drawRect(
        Rect.fromLTWH(0, groundY, size.width, size.height - groundY), paint);

    // 绘制三角形障碍物
    var obstacleSize = 20.0;
    var obstaclePath = Path()
      ..moveTo(size.width * obstacleX, groundY)
      ..lineTo(size.width * obstacleX + obstacleSize, groundY)
      ..lineTo(size.width * obstacleX, groundY - obstacleSize)
      ..close();
    canvas.drawPath(obstaclePath, Paint()..color = Colors.red);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
