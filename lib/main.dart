import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Material App',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Material App Bar'),
        ),
        body: Center(
          // ignore: avoid_unnecessary_containers
          child: Container(
            child: const Text('Hello World'),
          ),
        ),
      ),
    );
  }
}
