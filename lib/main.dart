import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter_ik_8/about_screen.dart';
import 'package:flutter_ik_8/chatPage.dart';
import 'package:flutter_ik_8/connection.dart';
import 'package:flutter_ik_8/constants.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: TextTheme(
          bodyText2: TextStyle(color: Colors.white, fontSize: 16),
        ),
        iconTheme: ThemeData.light().iconTheme.copyWith(color: Colors.white),
      ),
      home: FutureBuilder(
        future: FlutterBluetoothSerial.instance.requestEnable(),
        builder: (context, future) {
          if (future.connectionState == ConnectionState.waiting) {
            return Scaffold(
              body: Container(
                height: double.infinity,
                child: Center(
                  child: Icon(
                    Icons.bluetooth_disabled,
                    size: 200.0,
                    color: Colors.blue,
                  ),
                ),
              ),
            );
          } else if (future.data == false) {
            // return MyHomePage(title: 'Flutter Demo Home Page');
            Future.delayed(const Duration(milliseconds: 500), () {
              SystemChannels.platform.invokeMethod('SystemNavigator.pop');
            });
            return Container();
          } else {
            return Home();
          }
        },
        // child: MyHomePage(title: 'Flutter Demo Home Page'),
      ),
    );
  }
}

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Connection'),
        elevation: 10,
      ),
      floatingActionButton: FloatingActionButton(
        child: FittedBox(
          child: Icon(
            Icons.info_outline_rounded,
            size: 200,
          ),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                return AboutScreen();
              },
            ),
          );
        },
      ),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            children: [
              FittedBox(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(180)),
                    child: Image(
                      height: 100,
                      width: 100,
                      image: AssetImage('images/logo.png'),
                    ),
                  ),
                ),
              ),
              Divider(
                height: 10,
              ),
              ListTile(
                contentPadding: EdgeInsets.all(10),
                title: Text(
                  'About',
                  style: kNormalTextStyle.copyWith(color: Colors.black),
                ),
                leading: Icon(Icons.phone_android),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return AboutScreen();
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: SelectBondedDevicePage(
          onCahtPage: (device1) {
            BluetoothDevice device = device1;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) {
                  return ChatPage(
                    server: device,
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

// class MyHomePage extends StatefulWidget {
//   MyHomePage({Key key, this.title}) : super(key: key);
//   final String title;
//
//   @override
//   _MyHomePageState createState() => _MyHomePageState();
// }
//
// class _MyHomePageState extends State<MyHomePage> {
//   int _currentStep = 0;
//   BluetoothDevice device;
//
//   void onStepContinue() async {
//     if (_currentStep == 0) {
//       setState(() {
//         _currentStep = 1;
//       });
//     }
//   }
//
//   void onStepCancel() {
//     if (_currentStep == 1) {
//       setState(() {
//         _currentStep = 0;
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     List<Step> _steps = [
//       Step(
//         title: Text('Connection'),
//         content: Container(
//           height: 500,
//           child: SelectBondedDevicePage(
//             onCahtPage: (BluetoothDevice device) {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) {
//                     return ChatPage(server: device);
//                   },
//                 ),
//               );
//             },
//           ),
//         ),
//         state: StepState.editing,
//         isActive: true,
//       ),
//       Step(
//         title: Text('Led'),
//         content: Container(
//             // child: onCahtPage,
//             ),
//       ),
//     ];
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.title),
//       ),
//       body: Stepper(
//         steps: _steps,
//         type: StepperType.horizontal,
//         currentStep: _currentStep,
//         onStepContinue: onStepContinue,
//         onStepCancel: onStepCancel,
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           //
//         },
//         tooltip: 'Increment',
//         child: Icon(Icons.search),
//       ), // This trailing comma makes auto-formatting nicer for build methods.
//     );
//   }
// }
