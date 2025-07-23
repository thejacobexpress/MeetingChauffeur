import 'dart:convert';

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:flutter/material.dart';
import 'package:meeting_summarizer_app/HomePage.dart';
import 'package:meeting_summarizer_app/widgets/Group.dart';
import 'package:meeting_summarizer_app/widgets/Individual.dart';
import 'package:meeting_summarizer_app/AddGenerationsPage.dart';
import 'package:meeting_summarizer_app/FinalizeSendPage.dart';
import 'dart:async';

class EmailSendingPage extends StatefulWidget {
  const EmailSendingPage({super.key});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  State<EmailSendingPage> createState() => _EmailSendingPageState();
}

class _EmailSendingPageState extends State<EmailSendingPage> {

  var sent = false;
  var load = true;

  void goToHomePage() async {
    Timer? timer;
    timer = Timer.periodic(Duration(seconds: 1), (Timer t) async {
      if(await response == 200 && !sent) {
        sent = true;
        response = Future.value(0);
        timer!.cancel();
        setState(() {
          load = false;
        });
        await Future.delayed(Duration(seconds: 1));
        setState(() {
          Navigator.of(context).popUntil((route) {
            // Check for the custom data in the route's settings
            return route.settings.arguments != null && (route.settings.arguments as Map<String, dynamic>)['targetRoute'] == true;
          });
        });
      }
    });
  }

  @override
  initState() {
    super.initState();
    goToHomePage();
  }

  List<Widget> loading() {
    return [
          Center(child: Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator())),
          Center(child:Padding(padding: EdgeInsets.all(10), child: Text("Sending...", style: TextStyle(fontSize: 18)))),
        ];
  }

  List<Widget> done() {
    return [
          Center(child:Padding(padding: EdgeInsets.all(10), child: Text("Sent!", style: TextStyle(fontSize: 18)))),
        ];
  }

  @override
  Widget build(BuildContext context) {
    return Material(child:
      Column(mainAxisAlignment: MainAxisAlignment.center,
        children: load ? loading() : done()
      )
    );
  }
}