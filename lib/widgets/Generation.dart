import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:meeting_summarizer_app/BackendCalls.dart';
import 'dart:async';

// Keep track of the generations that have been downloaded and shown to the user.
Map<String, Map<String, bool>> genDisplayed = {};

class Generation extends StatefulWidget {

  /// The contact to which the generation belongs.
  final String contact;

  /// The name of the generation, which is displayed above the ```genValue```.
  final String name;

  /// The generated value of the generation, which is the text that is displayed below ```name```.
  final String genValue;

  Generation({super.key, required this.contact, required this.name, required this.genValue});

  @override
  State<Generation> createState() => _GenerationState();
}

class _GenerationState extends State<Generation> {
  Timer? timer;

  /// Returns either a ```CircularProgressIndicator``` widget if the generation within ```genMap``` is not yet available or a ```Text``` widget that contains the generation within ```genMap``` if it is available.
  Widget getGenWidget() {
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