import 'dart:math';

import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:meeting_summarizer_app/BackendCalls.dart';
import 'dart:async';

// Keep track of the generations that have been downloaded and shown to the user.
Map<String, Map<String, bool>> genDisplayed = {};

class Generation extends StatefulWidget {
  final String contact;
  final String name;
  final String genValue;

  Generation({super.key, required this.contact, required this.name, required this.genValue});

  @override
  State<Generation> createState() => _GenerationState();
}

class _GenerationState extends State<Generation> {
  Timer? timer;

  Widget getGenWidget() { // Returns either loading or generated string based on progress
    timer = Timer.periodic(Duration(seconds: 1), (Timer t) {
      runZonedGuarded(() => {
        if (genMap[widget.contact]![widget.genValue] != null && genDisplayed[widget.contact] != null && genDisplayed[widget.contact]![widget.genValue] == false) {
          setState(() {
            genDisplayed[widget.contact]![widget.genValue] = true;
          })
        }
      }, (error, stacktrace) {
        if(error is TypeError) {

        } else {
          safePrint("Failed to display generation");
        }
      });
    });
    return Padding(padding: EdgeInsets.all(10), child: (genDisplayed[widget.contact] == null  || genDisplayed[widget.contact]![widget.genValue] == false || genMap[widget.contact]![widget.genValue] == null) ? CircularProgressIndicator() : Text(genMap[widget.contact]![widget.genValue], style: TextStyle(fontSize: 16)));
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: EdgeInsets.all(10), child: Text(widget.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black))),
      getGenWidget(),
    ]);
  }
}