import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'ik/bone.dart';
import 'ik/anchor.dart';
import 'view-transformation.dart';

const Color kArmColor = Colors.redAccent;

Offset kEndPosition = Offset(0, 240);

const double jointRadius = 25;

const double kstrokeWidth = 10;

class ArmPainter extends CustomPainter {
  final Anchor anchor;
  final ViewTransformation vt;
  ArmPainter(this.anchor, this.vt);

  @override
  void paint(Canvas canvas, Size size) {
    //
    kEndPosition = vt.forward(anchor.child.child.getAttachPoint()) -
        vt.forward(anchor.loc);
    //draw smile
    Paint smailePaint = Paint()
      ..color = kArmColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = kstrokeWidth;
    Paint smailePaint2 = Paint()
      ..color = Color(0xFF752727)
      ..style = PaintingStyle.stroke
      ..strokeWidth = kstrokeWidth;

    Paint blueFill = Paint()
      ..color = kArmColor
      ..style = PaintingStyle.fill;

    Paint redFill = Paint()
      ..color = kArmColor
      ..style = PaintingStyle.fill
      ..strokeWidth = kstrokeWidth;

    Paint blackFill = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;

    Paint blackStroke = Paint()
      ..color = kArmColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = (jointRadius / 2) / vt.xm;
    //
    //
    Paint blackStroke2 = Paint()
      ..color = Color(0xFF752727)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (jointRadius / 1.2) / vt.xm;

    Bone dummyVeriable = anchor.child;
    Bone endBone = anchor.child.child;
    Bone child = anchor.child;

    canvas.drawArc(
        Rect.fromCircle(
            center: vt.forward(anchor.child.child.child.getAttachPoint()),
            radius: 30),
        (anchor.child.child.child.len - anchor.child.child.child.angle) + 1.4,
        4,
        false,
        smailePaint2);

    canvas.drawArc(
        Rect.fromCircle(
            center: vt.forward(anchor.child.child.child.getAttachPoint()),
            radius: 25),
        (anchor.child.child.child.len - anchor.child.child.child.angle) + 1.4,
        4,
        false,
        smailePaint);
    canvas.drawLine(vt.forward(anchor.child.getLoc()),
        vt.forward(anchor.child.getAttachPoint()), blackStroke2);
    canvas.drawLine(vt.forward(anchor.child.child.getLoc()),
        vt.forward(anchor.child.child.getAttachPoint()), blackStroke2);
    while (child.child != null) {
      canvas.drawLine(vt.forward(child.getLoc()),
          vt.forward(child.getAttachPoint()), blackStroke);

      canvas.drawCircle(vt.forward(child.getAttachPoint()),
          jointRadius / vt.xm * 0.8, redFill);

      if (child.child.child == null) {
        Offset data = vt.forward(child.getAttachPoint());
        canvas.drawCircle(
            Offset(data.dx, data.dy), jointRadius / vt.xm * 0.4, blackFill);
        canvas.drawCircle(vt.forward(dummyVeriable.getAttachPoint()),
            jointRadius / vt.xm * 0.4, blackFill);
      }
      child = child.child;
    }

    canvas.drawCircle(
        vt.forward(anchor.loc), jointRadius / vt.xm * 1, blueFill);
    canvas.drawCircle(
        vt.forward(anchor.loc), jointRadius / vt.xm * 0.5, blackFill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class Arm extends StatelessWidget {
  final Anchor anchor;
  final ViewTransformation vt;
  const Arm({Key key, this.anchor, this.vt}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ArmPainter(anchor, vt),
    );
  }
}

//        canvas.drawArc(
//             Rect.fromCircle(
//                 center: vt.forward(child.getAttachPoint()) + Offset(-60, -10),
//                 radius: 40),
//             5,
//             3.2,
//             false,
//             smailePaint);

//        canvas.drawArc(
//             Rect.fromCircle(
//                 center: vt.shift(child.getAttachPoint()), radius: 40),
//             (child.len - child.angle) + 4.5,
//             3.5,
//             false,
//             smailePaint);

//        canvas.drawArc(
//             Rect.fromCircle(
//                 center: vt.shift(child.getAttachPoint()), radius: 40),
//             (child.len - child.angle) - 0.4,
//             3.5,
//             false,
//             smailePaint);

// print(vt.forward(endBone.getAttachPoint()) -Offset(632.8, 511.8));

// origin: Offset(632.8, 511.8)

//        // canvas.drawArc(
//         //     Rect.fromCircle(
//         //         center: vt.shift(child.getAttachPoint()), radius: 40),
//         //     (child.len - child.angle) - 0.4,
//         //     3.5,
//         //     false,
//         //     smailePaint);
