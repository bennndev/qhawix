import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import 'mascot_engine.dart';
import 'mascot_rig.dart';

/// Paints the rig at the engine's current pose. Only transforms and opacity change per frame.
class GuardianMascotPainter extends CustomPainter {
  GuardianMascotPainter({
    required this.engine,
    required this.rig,
    required this.bodyColor,
    required this.lineColor,
    super.repaint,
  });

  final MascotEngine engine;
  final GuardianMascotRig rig;
  final Color bodyColor;
  final Color lineColor;

  // Built once per const path: the rig data is immutable.
  static final Map<Object, ui.Path> _paths = Map.identity();

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    if (side <= 0) return;
    canvas.save();
    canvas.translate((size.width - side) / 2, (size.height - side) / 2);
    canvas.scale(side / rig.viewBox);
    for (final node in rig.nodes) {
      _paintNode(canvas, node);
    }
    canvas.restore();
  }

  void _paintNode(Canvas canvas, RigNode node) {
    final part = node.part;
    var opacity = 1.0;
    if (part != null) {
      final pose = engine.poseOf(part);
      opacity = pose.o.clamp(0.0, 1.0);
      if (opacity <= 0) return;
      canvas.save();
      _applyTransform(canvas, node, pose);
      if (opacity < 1) {
        canvas.saveLayer(null, Paint()..color = bodyColor.withValues(alpha: opacity));
      }
    }
    final element = node.element;
    if (element != null) {
      _paintElement(canvas, element, node);
    } else {
      for (final child in node.children) {
        _paintNode(canvas, child);
      }
    }
    if (part != null) {
      if (opacity < 1) canvas.restore();
      canvas.restore();
    }
  }

  void _applyTransform(Canvas canvas, RigNode node, MascotPose pose) {
    final bounds = node.bounds;
    final origin = engine.spec.parts[node.part]?.origin;
    final ox = (bounds?.left ?? 0) + (origin?[0] ?? 0.5) * (bounds?.width ?? 0);
    final oy = (bounds?.top ?? 0) + (origin?[1] ?? 0.5) * (bounds?.height ?? 0);
    canvas.translate(ox + pose.x, oy + pose.y);
    canvas.rotate(pose.r * 3.141592653589793 / 180);
    canvas.scale(pose.sx, pose.sy);
    canvas.translate(-ox, -oy);
  }

  Color _color(RigColor color) => color == RigColor.body ? bodyColor : lineColor;

  ui.Path _pathOf(RigPath data) => _paths.putIfAbsent(data, () {
        final p = ui.Path();
        final ops = data.ops;
        var i = 0;
        while (i < ops.length) {
          switch (ops[i].toInt()) {
            case RigPath.move:
              p.moveTo(ops[i + 1].toDouble(), ops[i + 2].toDouble());
              i += 3;
            case RigPath.line:
              p.lineTo(ops[i + 1].toDouble(), ops[i + 2].toDouble());
              i += 3;
            case RigPath.cubic:
              p.cubicTo(
                ops[i + 1].toDouble(),
                ops[i + 2].toDouble(),
                ops[i + 3].toDouble(),
                ops[i + 4].toDouble(),
                ops[i + 5].toDouble(),
                ops[i + 6].toDouble(),
              );
              i += 7;
            case RigPath.quad:
              p.quadraticBezierTo(
                ops[i + 1].toDouble(),
                ops[i + 2].toDouble(),
                ops[i + 3].toDouble(),
                ops[i + 4].toDouble(),
              );
              i += 5;
            case RigPath.close:
              p.close();
              i += 1;
            default:
              throw StateError('Unknown rig op ${ops[i]}');
          }
        }
        return p;
      });

  ui.Path _shapePath(RigShape shape) {
    if (shape is RigPathShape) return _pathOf(shape.path);
    final circle = shape as RigCircleShape;
    return _paths.putIfAbsent(circle, () {
      return ui.Path()
        ..addOval(Rect.fromCircle(center: Offset(circle.cx, circle.cy), radius: circle.r));
    });
  }

  void _paintElement(Canvas canvas, RigElement element, RigNode node) {
    final clip = element.clip;
    final knockout = element.knockout;
    if (clip != null) {
      canvas.save();
      final clipPath = ui.Path.from(_pathOf(clip.path))
        ..fillType = clip.evenOdd ? ui.PathFillType.evenOdd : ui.PathFillType.nonZero;
      canvas.clipPath(clipPath);
    }
    if (knockout != null) canvas.saveLayer(null, Paint());
    _drawShape(canvas, element, node);
    if (knockout != null) {
      canvas.drawPath(
        _pathOf(knockout.path),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = knockout.strokeWidth
          ..strokeJoin = StrokeJoin.round
          ..blendMode = BlendMode.clear,
      );
      canvas.restore();
    }
    if (clip != null) canvas.restore();
  }

  void _drawShape(Canvas canvas, RigElement element, RigNode node) {
    final path = _shapePath(element.shape);
    final fill = element.fill;
    if (fill != null) {
      canvas.drawPath(path, Paint()..color = _color(fill));
    }
    final stroke = element.stroke;
    if (stroke == null || element.strokeWidth <= 0) return;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = _color(stroke)
      ..strokeWidth = element.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final dash = element.dash;
    if (element.drawProgress) {
      final progress = engine.poseOf(node.part!).d.clamp(0.0, 1.0);
      if (progress <= 0) return;
      for (final metric in path.computeMetrics()) {
        canvas.drawPath(metric.extractPath(0, metric.length * progress), paint);
      }
    } else if (dash != null) {
      for (final metric in path.computeMetrics()) {
        var at = 0.0;
        while (at < metric.length) {
          final end = at + dash[0] < metric.length ? at + dash[0] : metric.length;
          canvas.drawPath(metric.extractPath(at, end), paint);
          at += dash[0] + dash[1];
        }
      }
    } else {
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(GuardianMascotPainter old) =>
      old.engine != engine ||
      old.rig != rig ||
      old.bodyColor != bodyColor ||
      old.lineColor != lineColor;
}
