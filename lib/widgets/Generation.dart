import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:meeting_summarizer_app/BackendCalls.dart';
import 'dart:async';

Map<String, bool> genDisplayed = {};

void initGenDisplayed() {
  genDisplayed.clear();
  for(final entry in genList.entries) {
    genDisplayed[entry.key] = false;
  }
}

class Generation extends StatefulWidget {
  final String name;
  final String genValue;

  Generation({super.key, required this.name, required this.genValue});

  @override
  State<Generation> createState() => _GenerationState();
}

class _GenerationState extends State<Generation> {
  Timer? timer;

  Widget getGenWidget() { // Returns either loading or generated string based on progress
    timer = Timer.periodic(Duration(seconds: 1), (Timer t) {
      if (genList[widget.genValue] != null && genDisplayed[widget.genValue] == false) {
        runZonedGuarded(() => 
          setState(() {
            genDisplayed[widget.genValue] = true;
          }),
          (error, stacktrace) {
            safePrint("Failed to display generation.");
          }
        );
      }
    });
    return Padding(padding: EdgeInsets.all(10), child: (genDisplayed[widget.genValue] == false || genList[widget.genValue] == null) ? CircularProgressIndicator() : Text(genList[widget.genValue]!, style: TextStyle(fontSize: 18)));
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: EdgeInsets.all(10), child: Text(widget.name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
      getGenWidget(),
    ]);
  }
}