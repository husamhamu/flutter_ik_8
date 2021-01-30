import 'package:flutter/material.dart';

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Roboter-arm'),
        actions: [
          PopupMenuButton(
            elevation: 10,
            icon: Icon(Icons.menu),
            onSelected: (_) {
              //
            },
            itemBuilder: (context) {
              return [
                PopupMenuItem(
                  value: 'Hii',
                  child: Text('change the language'),
                ),
                PopupMenuItem(
                  value: 'Hii',
                  child: Text('change the language'),
                ),
                PopupMenuItem(
                  value: 'Hii',
                  child: Text('change the language'),
                ),
              ];
            },
            offset: Offset(-10, 40),
          ),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                selectedIndex = index;
              });
            },
            backgroundColor: Colors.white,
            elevation: 10,
            labelType: NavigationRailLabelType.selected,
            leading: FloatingActionButton(
              child: Icon(Icons.plus_one),
              onPressed: () {},
            ),
            minWidth: 100,
            destinations: [
              NavigationRailDestination(
                icon: Icon(Icons.bluetooth),
                label: Text('Connection'),
                selectedIcon: Icon(Icons.bluetooth_audio),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.desktop_mac_outlined),
                label: Text('Connection'),
                selectedIcon: Icon(Icons.desktop_windows),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.control_camera_outlined),
                label: Text('Connection'),
                selectedIcon: Icon(Icons.control_camera),
              ),
            ],
          ),
          Expanded(
            child: Container(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FlatButton(
                    color: Colors.blue,
                    child: const Text('show snackbar'),
                    onPressed: () {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('hi this is a snackbar'),
                          elevation: 5,
                          duration: const Duration(seconds: 1),
                          backgroundColor: Colors.blue,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
