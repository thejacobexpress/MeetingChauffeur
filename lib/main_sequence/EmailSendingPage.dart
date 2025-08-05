import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:meeting_summarizer_app/BackendCalls.dart';
import 'package:meeting_summarizer_app/main_sequence/FinalizeSendPage.dart';
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

  /// Returns a list of ```Widget``` that informs the user if their message is sending, sent successfully, or failed to send.
  List<Widget> getCurrentSend() {
    if(load && !sent) {
      return loading();
    } else if (!load && sent) {
      return done();
    } else {
      return failed();
    }
  }

  void goToHomePage() async {
    Timer? timer;
    timer = Timer.periodic(Duration(seconds: 1), (Timer t) async {
      try {
        if(await response == 200 && !sent) {
          sent = true;
          response = Future.value(0);
          timer!.cancel();
          setState(() {
            load = false;
          });
          safePrint("Email sent successfully!");
          await Future.delayed(Duration(seconds: 1));
          setState(() {
            Navigator.of(context).popUntil((route) {
              // Check for the custom data in the route's settings
              return route.settings.arguments != null && (route.settings.arguments as Map<String, dynamic>)['targetRoute'] == true;
            });
          });
        } else if (await response != 200 && !sent) {
          setState(() {
            load = false;
          });
          safePrint("Email did not send successfully.");
        }
      } on Exception {
        if(mounted) {
          setState(() {
            load = false;
            getCurrentSend();
          });
        }
      }
    });
  }

  /// Calls ```Pop``` until the Navigator is back to ```HomePage.dart```.
  void goBack() {
    setState(() {
      Navigator.of(context).popUntil((route) {
        // Check for the custom data in the route's settings
        return route.settings.arguments != null && (route.settings.arguments as Map<String, dynamic>)['targetRoute'] == true;
      });
    });
  }

  /// Attempts to send the email again.
  void tryAgain() {
    response = sendEmail(genMap);
    setState(() {
      load = true;
      getCurrentSend();
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
          Center(child:Padding(padding: EdgeInsets.all(10), child: Text("Sending...", style: TextStyle(fontSize: 20)))),
        ];
  }

  List<Widget> done() {
    return [
          Center(child:Padding(padding: EdgeInsets.all(10), child: Text("Sent!", style: TextStyle(fontSize: 20)))),
        ];
  }

  List<Widget> failed() {
    return [
          Center(child:Padding(padding: EdgeInsets.fromLTRB(0, 0, 0, 0), child: Text("Sorry, your message failed to send.", style: TextStyle(fontSize: 20)))),
          Center(child: Padding(padding: EdgeInsets.fromLTRB(100, 20, 100, 0), child: ElevatedButton(
            onPressed: () => tryAgain(),
            style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all<Color>(Colors.blue),
            padding: MaterialStateProperty.all<EdgeInsets>(EdgeInsets.all(20)),
            textStyle: MaterialStateProperty.all<TextStyle>(TextStyle(fontSize: 20)),
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
            )),
            child: Center(child: Text("Try Again", style: TextStyle(color: Colors.white, fontSize: 20)))
            )
          )),
          Center(child: Padding(padding: EdgeInsets.fromLTRB(75, 10, 75, 0), child: ElevatedButton(
            onPressed: () => goBack(),
            style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all<Color>(Colors.blue),
            padding: MaterialStateProperty.all<EdgeInsets>(EdgeInsets.all(20)),
            textStyle: MaterialStateProperty.all<TextStyle>(TextStyle(fontSize: 20)),
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
            )),
            child: Center(child: Text("Go to Home Page", style: TextStyle(color: Colors.white, fontSize: 20)))
            )
          )),
        ];
  }

  @override
  Widget build(BuildContext context) {
    return Material(child:
      Column(mainAxisAlignment: MainAxisAlignment.center,
        children: getCurrentSend()
      )
    );
  }
}