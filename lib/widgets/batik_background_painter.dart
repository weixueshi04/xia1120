import 'package:flutter/material.dart';

/// 蜡染纹样背景绘制器
class BatikPatternPainter extends CustomPainter {
  final Color color;

  BatikPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // 绘制多层蜡染纹样
    _drawWavePattern(canvas, size, paint, 0);
    _drawWavePattern(canvas, size, paint, size.height * 0.3);
    _drawWavePattern(canvas, size, paint, size.height * 0.6);
    
    _drawCirclePattern(canvas, size, paint);
    _drawDiamondPattern(canvas, size, paint);
  }

  /// 波浪纹样
  void _drawWavePattern(Canvas canvas, Size size, Paint paint, double offsetY) {
    final path = Path();
    path.moveTo(0, offsetY);
    
    for (double x = 0; x < size.width; x += 40) {
      path.quadraticBezierTo(
        x + 20, offsetY - 15,
        x + 40, offsetY,
      );
    }
    
    canvas.drawPath(path, paint);
  }

  /// 圆形纹样
  void _drawCirclePattern(Canvas canvas, Size size, Paint paint) {
    for (double y = 100; y < size.height; y += 150) {
      for (double x = 50; x < size.width; x += 120) {
        canvas.drawCircle(
          Offset(x, y),
          20,
          paint..style = PaintingStyle.stroke,
        );
        canvas.drawCircle(
          Offset(x, y),
          15,
          paint,
        );
      }
    }
  }

  /// 菱形纹样
  void _drawDiamondPattern(Canvas canvas, Size size, Paint paint) {
    for (double y = 180; y < size.height; y += 150) {
      for (double x = 110; x < size.width; x += 120) {
        final path = Path();
        path.moveTo(x, y - 15);
        path.lineTo(x + 15, y);
        path.lineTo(x, y + 15);
        path.lineTo(x - 15, y);
        path.close();
        
        canvas.drawPath(path, paint..style = PaintingStyle.stroke);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}