import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter_ik_8/view-transformation.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';

import 'arm_widget.dart';
import 'ik/anchor.dart';
import 'ik/bone.dart';

const double gravity = -100;
const double ballSize = 10;
const double ballBuffer = 50;
const double armLength1 = 100;
const double armLength2 = armLength1 * 0.75;

class ChatPage extends StatefulWidget {
  final BluetoothDevice server;

  const ChatPage({this.server});
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _Message {
  int whom;
  String text;

  _Message(this.whom, this.text);
}

class _ChatPageState extends State<ChatPage>
    with SingleTickerProviderStateMixin {
  Anchor arm;
  Offset ballWorldLoc = Offset(0, 0);
  Offset ballWorldVelocity = Offset(0, 0);

  AnimationController _controller;

  bool _ballFrozen = true;
  bool _armLocked = true;

  Duration _lastUpdateCall = Duration();
  Offset _lastBallLoc = Offset(0, 0);
  double _maxScoreY;
  double _scoreOffsets = 0;
  double _currentScoreOpacity = 0;

  int _scoreLock;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: Duration(days: 99));
    _controller.forward();
    _initializeArms();
    _controller.addListener(_update);
    //
    //
    BluetoothConnection.toAddress(widget.server.address).then((_connection) {
      print('Connected to the device');
      connection = _connection;
      setState(() {
        isConnecting = false;
        isDisconnecting = false;
      });
      connection.input.listen(_onDataReceived).onDone(() {
        if (isDisconnecting) {
          print('Disconnecting locally!');
        } else {
          print('Disconnected remotely!');
        }
        if (this.mounted) {
          setState(() {});
        }
      });
    }).catchError((error) {
      print('Cannot connect, exception occured');
      print(error);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    //
    // Avoid memory leak (`setState` after dispose) and disconnect
    if (isConnected) {
      isDisconnecting = true;
      connection.dispose();
      connection = null;
    }
    super.dispose();
  }

  _update() {
    if (!_controller.isAnimating) {
      return;
    }

    double elapsedSeconds =
        (_controller.lastElapsedDuration - _lastUpdateCall).inMilliseconds /
            1000;

    Size screenSize = MediaQuery.of(context).size;
    if (!_ballFrozen) {
      ballWorldLoc += ballWorldVelocity * elapsedSeconds;
      if (_maxScoreY == null || ballWorldLoc.dy > _maxScoreY) {
        setState(() {
          _maxScoreY = ballWorldLoc.dy;
        });
      }
      ballWorldVelocity =
          ballWorldVelocity.translate(0, gravity * elapsedSeconds);
    }

    Offset overlap = arm.overlaps(ballWorldLoc, ballSize / 2);
    if (overlap != null) {
      _ballFrozen = false;
      setState(() {
        _scoreOffsets = .1;
        _currentScoreOpacity = 1;
        _scoreLock = null;
      });
      ballWorldLoc -= overlap;

      if (elapsedSeconds > 0) {
        ballWorldVelocity = (ballWorldLoc - _lastBallLoc) / elapsedSeconds;
      }
    }

    if (ballWorldLoc.dx < ballSize / 2 ||
        ballWorldLoc.dx > screenSize.width - ballSize / 2 ||
        ballWorldLoc.dy < -ballSize / 2) {
      _ballFrozen = true;
      _armLocked = true;
    }

    _lastBallLoc = ballWorldLoc;
    _lastUpdateCall = _controller.lastElapsedDuration;
  }

  _initializeArms() {
    for (int i = 0; i < 1; i++) {
      arm = Anchor(loc: Offset(0, 0));
      Bone b = Bone(armLength1, arm);
      arm.child = b;
      arm.child.angle = -pi / 2;
      Bone b2 = Bone(armLength2, b);
      b.child = b2;
      arm.child.child.angle = -pi / 2;
      Bone b3 = Bone(50.0, b2);
      b2.child = b3;
      arm.child.child.angle = -pi / 2;
    }
  }

  _reset() {
    Size screenSize = MediaQuery.of(context).size;

    setState(() {
      _currentScoreOpacity = 0;
      _scoreOffsets = 0;
      _scoreLock = ballWorldLoc.dy.round();
    });
    arm.loc = Offset(screenSize.width / 2, screenSize.height / 4);
    arm.child.angle = pi / 2;
    arm.child.child.angle = pi / 2;
    ballWorldLoc = Offset(screenSize.width / 4, screenSize.height);
    _ballFrozen = true;
    _armLocked = false;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _reset();
  }

  Rect _getWorldViewRect(Size screenSize) {
    double screenScalar =
        max((ballWorldLoc.dy + ballBuffer) / screenSize.height, 1);
    Size viewSize = screenSize * screenScalar;
    return Rect.fromLTRB(
        -(viewSize.width - screenSize.width) / 2,
        screenSize.height * screenScalar,
        screenSize.width * screenScalar -
            (viewSize.width - screenSize.width) / 2,
        0);
  }

//
  //
  static final clientID = 0;
  BluetoothConnection connection;

  List<_Message> messages = List<_Message>();
  String _messageBuffer = '';

  final TextEditingController textEditingController =
      new TextEditingController();
  final ScrollController listScrollController = new ScrollController();

  bool isConnecting = true;
  bool get isConnected => connection != null && connection.isConnected;

  bool isDisconnecting = false;

  bool gripperState = false;
  double _zAngel = 48.0;
  double _gripperAngle = 90.0;
  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    //
    double _xCoordinate = (kEndPosition.dx / (armLength1 + armLength2));
    double _yCoordinate = (kEndPosition.dy / (armLength1 + armLength2)) * -1;

    void showCoordinate() {
      String message =
          'Sending end position: (x, y, z) = ( ${_xCoordinate.toStringAsFixed(2)}, '
          '${_yCoordinate.toStringAsFixed(2)}, '
          '${(_zAngel / 180).toStringAsFixed(2)} )';
      showingSnackBar(message);
    }

    String servoAngels() {
      double angel2 = (arm.child.child.angle * 180 / pi);
      double angel1 = (arm.child.angle * 180 / pi);
      String angels = '';
      if (angel1 < 100 && angel1 > 10) {
        angels = '0';
      } else if (angel1 < 10) {
        angels = '00';
      }
      angels += angel1.round().toString();
      if (angel2 < 0) {
        if (angel1 <= 90) {
          angels += '000';
        } else {
          angels += '180';
        }
      } else {
        if (angel2 < 100 && angel2 > 10) {
          angels += '0';
          angels += angel2.round().toString();
        } else if (angel2 < 10) {
          angels += '00';
          angels += angel2.round().toString();
        } else {
          angels += angel2.round().toString();
        }
      }
      if (_zAngel < 100 && _zAngel > 10) {
        angels += '0';
        angels += _zAngel.round().toString();
      } else if (_zAngel < 10) {
        angels += '00';
        angels += _zAngel.round().toString();
      } else {
        angels += _zAngel.round().toString();
      }
      print(angels);
      return angels;
    }

    void showingAngels() {
      double angel2 = (arm.child.child.angle * 180 / pi);
      double angel1 = (arm.child.angle * 180 / pi);
      String message = 'Sending ';
      // if (angel1 < 0) {
      //   angel1 = 360 + angel1;
      // }
      // if (angel2 < 0) {
      //   angel2 = 360 + angel2;
      // }

      message += 'α = ${angel1.round()}°, ';
      message += 'β = ${angel2.round()}°, ';
      message += 'z = ${_zAngel.round()}° ';
      showingSnackBar(message);
    }

    String postionCoordinat() {
      String message = '';

      int x = ((_xCoordinate * 100) - 1).round();
      int y = ((_yCoordinate * 100) - 1).round();
      int z = ((_zAngel - 1)).round();
      print(z);
      if (x == 0) {
        message = '00';
      } else if (x < 10 && x > 0) {
        message += '0';
        message += x.toString();
      } else {
        message += x.toString();
      }
      if (y == 0 || y < 0) {
        message += '00';
      } else if (y < 10) {
        message += '0';
        message += y.toString();
      } else {
        message += y.toString();
      }
      if (z == 0 || z < 0) {
        message += '00';
      } else if (z < 10) {
        message += '0';
        message += z.toString();
      } else {
        message += z.toString();
      }
      print(message);
      return message;
    }

    return Scaffold(
      body: Stack(
        children: [
          Stack(
            children: [
              Positioned(
                left: screenSize.width * 0.025,
                top: screenSize.height * 0.5,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                        topRight: Radius.circular(280),
                        topLeft: Radius.circular(280)),
                    color: Color(0xFF64b5f6),
                  ),
                  width: screenSize.width * 0.95,
                  height: 250,
                ),
              ),
              // Positioned(
              //   left: screenSize.width * 0.01,
              //   top: screenSize.height * 0.51,
              //   child: Container(
              //     decoration: BoxDecoration(
              //       borderRadius: BorderRadius.only(
              //           topRight: Radius.circular(280),
              //           topLeft: Radius.circular(280)),
              //     ),
              //     width: screenSize.width * 0.98,
              //     height: screenSize.height * 0.3,
              //     child: ClipRRect(
              //       borderRadius: BorderRadius.only(
              //           topLeft: Radius.circular(280),
              //           topRight: Radius.circular(280)),
              //       child: SizedBox(
              //         width: screenSize.width,
              //         child: Image(
              //           image: AssetImage('images/coo.png'),
              //         ),
              //       ),
              //     ),
              //   ),
              // ),
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanEnd: (DragEndDetails deets) {
                  String message = servoAngels();
                  _sendMessage(message);
                  showingAngels();
                  print('first ${arm.child.angle * 180 / pi}');
                  print(arm.child.child.angle * 180 / pi);
                },
                onPanUpdate: (DragUpdateDetails deets) {
                  // if ((arm.child.child.angle * 180 / pi) < 0) {
                  //   if ((arm.child.angle * 180 / pi) <= 90) {
                  //     arm.child.child.angle = 0.0;
                  //   } else {
                  //     arm.child.child.angle = 3.14159;
                  //   }
                  // }
                  if (deets.globalPosition.dy < 680) {
                    setState(() {
                      if (!_armLocked) {
                        ViewTransformation vt = ViewTransformation(
                            from: Rect.fromLTRB(
                                0, 0, screenSize.width, screenSize.height),
                            to: _getWorldViewRect(screenSize));
                        arm.solve(vt.forward(deets.globalPosition));
                      }
                    });
                  }
                },
                onPanStart: (DragStartDetails deets) {
                  if (deets.globalPosition.dy < 670) {
                    setState(() {
                      if (!_armLocked) {
                        ViewTransformation vt = ViewTransformation(
                            from: Rect.fromLTRB(
                                0, 0, screenSize.width, screenSize.height),
                            to: _getWorldViewRect(screenSize));
                        arm.solve(vt.forward(deets.globalPosition));
                      }
                    });
                  }
                },
                onTap: () {
                  _reset();
                },
                child: Stack(children: [
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        double screenScalar = max(
                            (ballWorldLoc.dy + ballBuffer) / screenSize.height,
                            1);
                        ViewTransformation vt = ViewTransformation(
                            to: Rect.fromLTRB(
                                0, 0, screenSize.width, screenSize.height),
                            from: _getWorldViewRect(screenSize));

                        Offset ballScreenLoc = vt.forward(ballWorldLoc);
                        List<Widget> stackChildren = [
                          Positioned.fill(child: Arm(anchor: arm, vt: vt)),
                          // Positioned(
                          //   left: ballScreenLoc.dx - (ballSize / screenScalar) / 2,
                          //   top: ballScreenLoc.dy - (ballSize / screenScalar) / 2,
                          //   child: Container(
                          //     width: ballSize / screenScalar,
                          //     height: ballSize / screenScalar,
                          //     decoration: BoxDecoration(
                          //         color: Colors.red,
                          //         borderRadius:
                          //             BorderRadius.all(Radius.circular(9999))),
                          //   ),
                          // ),
                        ];
                        return Stack(
                            alignment: Alignment.center,
                            children: stackChildren);
                      },
                    ),
                  ),
                ]),
              ),
              Positioned(
                child: Container(
                  width: screenSize.width,
                  height: AppBar().preferredSize.height + 33,
                  child: AppBar(
                    title: Text('Control'),
                    elevation: 10,
                  ),
                ),
              ),
              Positioned(
                child: SizedBox(
                  width: screenSize.width,
                  height: screenSize.height,
                  child: Padding(
                    padding: EdgeInsets.only(
                        top: screenSize.height * 0.2, right: 10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              margin: EdgeInsets.only(left: 10),
                              padding: EdgeInsets.symmetric(vertical: 5),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Padding(
                                    padding:
                                        EdgeInsets.only(left: 10, bottom: 15),
                                    child: FlatButton.icon(
                                      splashColor: Colors.white,
                                      color: Theme.of(context).primaryColor,
                                      label: Padding(
                                          padding: EdgeInsets.all(10),
                                          child: Text(
                                            'Gripper',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyText2
                                                .copyWith(color: Colors.white),
                                          )),
                                      icon: Icon(
                                        Icons.offline_bolt_outlined,
                                        color:
                                            Theme.of(context).iconTheme.color,
                                      ),
                                      onPressed: () {
                                        gripperState = !gripperState;
                                        if (gripperState) {
                                          showingSnackBar('Gripper: on');
                                          _sendMessage('1');
                                        } else {
                                          showingSnackBar('Gripper: off');
                                          _sendMessage('0');
                                        }
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    // splashColor: Colors.white,
                                    color: Colors.blue,
                                    icon: Icon(
                                      Icons.info_outline,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () {
                                      //
                                      showDialog(
                                        context: context,
                                        child: AlertDialog(
                                          title: Text('Gripper'),
                                          content: Container(
                                            // height: 300,
                                            // width: 300,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(45)),
                                            ),
                                            child: Text(
                                                'This will send 1 to close the gripper and 0 to open it again'),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(
                                  top: 15, bottom: 15, left: 20),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'G = ${_gripperAngle.round()}°',
                                    style: TextStyle(color: Colors.black),
                                  ),
                                  SizedBox(
                                    width: screenSize.width * 0.63,
                                    child: Slider(
                                      label:
                                          'gripper angel = ${_gripperAngle.round()}°',
                                      divisions: 180,
                                      value: _gripperAngle,
                                      max: 180,
                                      min: 0,
                                      onChanged: (value) {
                                        setState(() {
                                          _gripperAngle = value;
                                        });
                                      },
                                      onChangeEnd: (value) {
                                        String message = 'Moving the gripper: ';
                                        message += value.toString();
                                        message += '°';
                                        showingSnackBar(message);
                                        message = 'g';
                                        if (value < 100 && value > 10) {
                                          message += '0';
                                          message += value.round().toString();
                                        } else if (value.round() < 10) {
                                          message += '00';
                                          message += value.round().toString();
                                        } else {
                                          message += value.round().toString();
                                        }
                                        print(message);
                                        _sendMessage(message);
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.info_outline,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () {
                                      //
                                      showDialog(
                                        context: context,
                                        child: AlertDialog(
                                          title: Text('Grippers\'s angel'),
                                          content: Container(
                                            // height: 300,
                                            // width: 300,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(45)),
                                            ),
                                            child: Text(
                                                'This slider will send the angel of the gripper between 0° and 180° degree'),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(
                                  top: 15, bottom: 15, left: 20),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Z = ${_zAngel.round()}°',
                                    style: TextStyle(color: Colors.black),
                                  ),
                                  SizedBox(
                                    width: screenSize.width * 0.63,
                                    child: Slider(
                                      label: 'z angel = ${_zAngel.round()}°',
                                      divisions: 180,
                                      value: _zAngel,
                                      max: 180,
                                      min: 0,
                                      onChanged: (value) {
                                        setState(() {
                                          _zAngel = value;
                                        });
                                      },
                                      onChangeEnd: (value) {
                                        showingAngels();
                                        String message = servoAngels();
                                        _sendMessage(message);
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.info_outline,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () {
                                      //
                                      showDialog(
                                        context: context,
                                        child: AlertDialog(
                                          title: Text('Z-angel'),
                                          content: Container(
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(45)),
                                            ),
                                            child: Text(
                                                'The value of Z will be between 0° and 180°'),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            // Row(
                            //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            //   children: [
                            //     Padding(
                            //       padding: EdgeInsets.only(left: 10),
                            //       child: Column(
                            //         children: [
                            //           Container(
                            //             padding: EdgeInsets.only(
                            //                 left: 10,
                            //                 right: 10,
                            //                 top: 15,
                            //                 bottom: 15),
                            //             decoration: BoxDecoration(),
                            //             child: Text(
                            //               'Y = ${_yCoordinate.toStringAsFixed(2)} × arm length',
                            //               style: Theme.of(context)
                            //                   .textTheme
                            //                   .bodyText2
                            //                   .copyWith(color: Colors.black),
                            //             ),
                            //           ),
                            //           Container(
                            //             padding: EdgeInsets.only(
                            //                 left: 10,
                            //                 right: 10,
                            //                 top: 15,
                            //                 bottom: 15),
                            //             decoration: BoxDecoration(),
                            //             child: Text(
                            //               'X = ${_xCoordinate.toStringAsFixed(2)} × arm length',
                            //               style: Theme.of(context)
                            //                   .textTheme
                            //                   .bodyText2
                            //                   .copyWith(color: Colors.black),
                            //             ),
                            //           ),
                            //         ],
                            //       ),
                            //     ),
                            //     IconButton(
                            //       // splashColor: Colors.white,
                            //       color: Colors.blue,
                            //       icon: Icon(
                            //         Icons.info_outline,
                            //         color: Colors.blue,
                            //       ),
                            //       onPressed: () {
                            //         //
                            //         showDialog(
                            //           context: context,
                            //           child: AlertDialog(
                            //             title: Text('titel'),
                            //             content: Container(
                            //               height: 300,
                            //               width: 300,
                            //               decoration: BoxDecoration(
                            //                 borderRadius: BorderRadius.all(
                            //                     Radius.circular(45)),
                            //               ),
                            //               child: Image(
                            //                 image: NetworkImage(
                            //                     'https://compote.slate.com/images/697b023b-64a5-49a0-8059-27b963453fb1.gif'),
                            //               ),
                            //             ),
                            //           ),
                            //         );
                            //       },
                            //     ),
                            //   ],
                            // ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 70),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(left: 10),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(5),
                                      decoration: BoxDecoration(),
                                      child: Text(
                                        'β = ${(arm.child.child.angle * 180 / pi).toStringAsFixed(2)}°',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyText2
                                            .copyWith(color: Colors.black),
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.all(5),
                                      decoration: BoxDecoration(),
                                      child: Text(
                                        'α = ${(arm.child.angle * 180 / pi).toStringAsFixed(2)}°',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyText2
                                            .copyWith(color: Colors.black),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                // splashColor: Colors.white,
                                color: Colors.blue,
                                icon: Icon(
                                  Icons.info_outline,
                                  color: Colors.blue,
                                ),
                                onPressed: () {
                                  //
                                  showDialog(
                                    context: context,
                                    child: AlertDialog(
                                      title: Text('α and β-angels'),
                                      content: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(45)),
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                                'The value of α will be between 0° and 360° and β will be between 0° and 180°'),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 20),
                                              child: Image(
                                                  image: AssetImage(
                                                      'images/angels.png')),
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Visibility(
          //   visible: isConnected ? false : true,
          //   child: Scaffold(
          //     appBar: AppBar(
          //       title: Text(
          //           'Connecting to ${widget.server.name == null ? '' : widget.server.name} ...'),
          //     ),
          //     body: ModalProgressHUD(
          //       inAsyncCall: isConnected ? false : true,
          //       child: Center(),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  void showingSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        elevation: 5,
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _onDataReceived(Uint8List data) {
    // Allocate buffer for parsed data
    int backspacesCounter = 0;
    data.forEach((byte) {
      if (byte == 8 || byte == 127) {
        backspacesCounter++;
      }
    });
    Uint8List buffer = Uint8List(data.length - backspacesCounter);
    int bufferIndex = buffer.length;

    // Apply backspace control character
    backspacesCounter = 0;
    for (int i = data.length - 1; i >= 0; i--) {
      if (data[i] == 8 || data[i] == 127) {
        backspacesCounter++;
      } else {
        if (backspacesCounter > 0) {
          backspacesCounter--;
        } else {
          buffer[--bufferIndex] = data[i];
        }
      }
    }

    // Create message if there is new line character
    String dataString = String.fromCharCodes(buffer);
    int index = buffer.indexOf(13);
    if (~index != 0) {
      setState(() {
        messages.add(
          _Message(
            1,
            backspacesCounter > 0
                ? _messageBuffer.substring(
                    0, _messageBuffer.length - backspacesCounter)
                : _messageBuffer + dataString.substring(0, index),
          ),
        );
        _messageBuffer = dataString.substring(index);
      });
    } else {
      _messageBuffer = (backspacesCounter > 0
          ? _messageBuffer.substring(
              0, _messageBuffer.length - backspacesCounter)
          : _messageBuffer + dataString);
    }
  }

  void _sendMessage(String text) async {
    text = text.trim();
    textEditingController.clear();
    // DateTime dateTime = DateTime.now();
    // print(DateTime.now().subtract(Duration(seconds: 4)));
    // print(DateTime.now());
    // text += ', ';
    // print(DateTime.now().subtract(Duration(seconds: 2)));
    // print(DateTime.now());
    // text += DateTime.now()
    //     .subtract(Duration(seconds: 3, milliseconds: 500))
    //     .toString()
    //     .substring(10);

    if (text.length > 0) {
      try {
        connection.output.add(utf8.encode(text + "\r\n"));
        await connection.output.allSent;

        setState(() {
          messages.add(_Message(clientID, text));
        });

        Future.delayed(Duration(milliseconds: 333)).then((_) {
          listScrollController.animateTo(
              listScrollController.position.maxScrollExtent,
              duration: Duration(milliseconds: 333),
              curve: Curves.easeOut);
        });
      } catch (e) {
        // Ignore error, but notify state
        setState(() {});
      }
    }
  }
}
