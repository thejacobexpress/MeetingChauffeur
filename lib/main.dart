import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';

import 'HomePage.dart';
import 'SendPage.dart';
import 'MeetingsPage.dart';

import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'amplifyconfiguration.dart';

String localFilePath = "";

int pageIndex = 0;

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

  Future<void> _configureAmplify() async {

    // Add any Amplify plugins you want to use
    final authPlugin = AmplifyAuthCognito();
    final api = AmplifyAPI();
    final storage = AmplifyStorageS3();
    await Amplify.addPlugin(authPlugin);
    await Amplify.addPlugin(api);
    await Amplify.addPlugin(storage);

    // Once Plugins are added, configure Amplify
    // Note: Amplify can only be configured once.
    try {
      await Amplify.configure(amplifyconfig);
      safePrint('Successfully configured Amplify 🎉');
    } on AmplifyAlreadyConfiguredException {
      safePrint("Tried to reconfigure Amplify; this can occur when your app restarts on Android.");
    }
  }

  @override
  initState() {
    super.initState();
    _configureAmplify();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(bottomNavigationBar: NavigationBar(destinations: 
      [
        NavigationDestination(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.people),
          label: 'Meetings',
        ),
        NavigationDestination(
          icon: Icon(Icons.send),
          label: 'Send',
        ),
      ],
      onDestinationSelected: (int index) {
        setState(() {
          pageIndex = index;
        });
        safePrint("Selected destination: $index");
      },
    ),
    body: <Widget>[MyHomePage(), MeetingsPage(), SendPage()][pageIndex]);
  }
}

void main() {
  runApp(const MyApp());
}