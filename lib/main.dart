import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:meeting_summarizer_app/widgets/NavBar.dart';

import 'HomePage.dart';
import 'SendPage.dart';
import 'MeetingsPage.dart';

String localFilePath = "";

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meeting Summarizer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: Scaffold(body: Center(child:MyPage())),
    );
  }
}

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(bottomNavigationBar: navBar(),
    body: <Widget>[MyHomePage(), MeetingsPage(), SendPage()][pageIndex]);
  }
}

void main() {
  runApp(const MyApp());
}