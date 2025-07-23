import 'package:flutter/material.dart';
import 'package:meeting_summarizer_app/FinalizeSendPage.dart';
import 'package:meeting_summarizer_app/widgets/GenerationOption.dart';
import 'package:meeting_summarizer_app/BackendCalls.dart';
import 'package:meeting_summarizer_app/HomePage.dart';

class AddGenerationsPage extends StatefulWidget {
  const AddGenerationsPage({super.key});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  State<AddGenerationsPage> createState() => _AddGenerationsPageState();
}

class _AddGenerationsPageState extends State<AddGenerationsPage> {

  final Map<String, dynamic> json = {
    'location': false, // not dealt with on server end
    'summary': false,
    'transcript': true,
    'action': true,
    'decisions': false,
    'names': false,
    'topics':false,
    'purpose':false,
    'next_steps':false,
    'corrections':false,
    'questions':false
  };

  void goToFinalizeSendPage(){
    setState(() {
      Navigator.of(context).push(MaterialPageRoute(builder: (context) => FinalizeSendPage(json: json)));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(child: 
      Column(
        children: [
          Padding(padding: EdgeInsets.fromLTRB(0, MediaQuery.paddingOf(context).top, 0, 0), child: Text("Choose Insights", style: TextStyle(fontSize: 24))),
          SizedBox(
            height: 550,
            width: MediaQuery.of(context).size.width,
            child: ListView(
              shrinkWrap: true,
              scrollDirection: Axis.vertical,
              children: [
                GenerationOption(value: json['location'], name: "Location", setValue: () => setState(() {json['location'] = !json['location'];})),
                GenerationOption(value: json['summary'], name: "Summary", setValue: () => setState(() {json['Summary'] = !json['Summary'];})),
                GenerationOption(value: json['transcript'], name: "Transcript", setValue: () => setState(() {json['transcript'] = !json['transcript'];})),
                GenerationOption(value: json['action'], name: "Action Items", setValue: () => setState(() {json['action'] = !json['action'];})),
                GenerationOption(value: json['decisions'], name: "Decisions Made", setValue: () => setState(() {json['decisions'] = !json['decisions'];})),
                GenerationOption(value: json['names'], name: "Names of Participants", setValue: () => setState(() {json['names'] = !json['names'];})),
                GenerationOption(value: json['topics'], name: "Topics Covered", setValue: () => setState(() {json['topics'] = !json['topics'];})),
                GenerationOption(value: json['purpose'], name: "Purpose of Meeting", setValue: () => setState(() {json['purpose'] = !json['purpose'];})),
                GenerationOption(value: json['next_steps'], name: "Next Steps", setValue: () => setState(() {json['next_steps'] = !json['next_steps'];})),
                GenerationOption(value: json['corrections'], name: "Corrections to Previous Meetings", setValue: () => setState(() {json['corrections'] = !json['corrections'];})),
                GenerationOption(value: json['questions'], name: "Questions Asked", setValue: () => setState(() {json['questions'] = !json['questions'];})),
              ],
            )
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              width: 250,
              height: 75,
              child: ElevatedButton(
                onPressed: () => {
                  genListReady = false,
                  genList.clear(),
                  uploadWAVtoS3(recordingFilePaths.last, json),
                  goToFinalizeSendPage()
                }, // Assumes that the last WAV is the current WAV
                style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(Colors.blue),
                padding: MaterialStateProperty.all<EdgeInsets>(EdgeInsets.all(20)),
                textStyle: MaterialStateProperty.all<TextStyle>(TextStyle(fontSize: 20)),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                )),
                child: Center(child: Text("Generate", style: TextStyle(color: Colors.white, fontSize: 20)))
              ),
            )
          )
        ]
      )
    );
  }
}