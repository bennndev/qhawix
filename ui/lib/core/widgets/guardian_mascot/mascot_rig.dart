// Data model of the mascot artwork. The instances are generated from the SVG rig by
// ui/tool/guardian_mascot/generate.dart (see generated/guardian_mascot_rig_data.dart), so the
// widget never parses SVG at runtime. Pure Dart: no Flutter imports.

/// The two colours the mascot may use. Both come from the host as parameters.
enum RigColor { body, line }

/// Path commands stored as a flat list: `0 x y` move, `1 x y` line, `2 x1 y1 x2 y2 x y` cubic,
/// `3 x1 y1 x y` quadratic and `4` close. Coordinates are absolute, in viewBox units.
class RigPath {
  const RigPath(this.ops);

  static const int move = 0;
  static const int line = 1;
  static const int cubic = 2;
  static const int quad = 3;
  static const int close = 4;

  final List<num> ops;
}

abstract class RigShape {
  const RigShape();
}

class RigPathShape extends RigShape {
  const RigPathShape(this.path);

  final RigPath path;
}

/// Circle that starts at (cx + r, cy) and runs clockwise, like an SVG `<circle>`.
class RigCircleShape extends RigShape {
  const RigCircleShape(this.cx, this.cy, this.r);

  final double cx;
  final double cy;
  final double r;
}

/// Fill-box of a part: the geometry bounds without stroke, used for transform origins.
class RigBounds {
  const RigBounds(this.left, this.top, this.right, this.bottom);

  final double left;
  final double top;
  final double right;
  final double bottom;

  double get width => right - left;
  double get height => bottom - top;
}

class RigClip {
  const RigClip(this.path, {this.evenOdd = false});

  final RigPath path;
  final bool evenOdd;
}

/// Equivalent of an SVG mask that paints a black stroke over a path: the stroked band is erased
/// from the element it is attached to.
class RigKnockout {
  const RigKnockout(this.path, this.strokeWidth);

  final RigPath path;
  final double strokeWidth;
}

class RigElement {
  const RigElement({
    required this.shape,
    this.fill,
    this.stroke,
    this.strokeWidth = 0,
    this.dash,
    this.clip,
    this.knockout,
    this.drawProgress = false,
  });

  final RigShape shape;
  final RigColor? fill;
  final RigColor? stroke;
  final double strokeWidth;

  /// Dash pattern (on, off) in viewBox units; strokes use round caps like the SVG.
  final List<double>? dash;
  final RigClip? clip;
  final RigKnockout? knockout;

  /// The stroke is revealed from its start by the part's `d` pose value.
  final bool drawProgress;
}

/// A group or a single element. When [part] is set, the node takes its transform and opacity
/// from that spec part, rotating and scaling about the fill-box fraction in the part spec.
class RigNode {
  const RigNode.group({this.part, this.bounds, required this.children})
      : element = null;

  const RigNode.leaf(RigElement this.element, {this.part, this.bounds})
      : children = const [];

  final String? part;
  final RigBounds? bounds;
  final RigElement? element;
  final List<RigNode> children;
}

class GuardianMascotRig {
  const GuardianMascotRig({required this.viewBox, required this.nodes});

  /// Side of the square coordinate space.
  final double viewBox;
  final List<RigNode> nodes;

  /// Every part name that has a node in the rig.
  Set<String> get partNames {
    final names = <String>{};
    void visit(RigNode node) {
      if (node.part != null) names.add(node.part!);
      node.children.forEach(visit);
    }

    nodes.forEach(visit);
    return names;
  }
}
