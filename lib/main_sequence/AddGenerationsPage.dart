import 'package:flutter/material.dart';
import 'package:meeting_summarizer_app/main_sequence/FinalizeSendPage.dart';
import 'package:meeting_summarizer_app/widgets/GenerationOption.dart';
import 'package:meeting_summarizer_app/BackendCalls.dart';
import 'package:meeting_summarizer_app/main_sequence/HomePage.dart';

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
    GenerationType.LOCATION.value: false, // not dealt with on server end
    GenerationType.SUMMARY.value: false,
    GenerationType.TRANSCRIPT.value: true,
    GenerationType.ACTION.value: true,
    GenerationType.DECISION.value: false,
    GenerationType.NAMES.value: false,
    GenerationType.TOPICS.value:false,
    GenerationType.PURPOSE.value:false,
    GenerationType.NEXT_STEPS.value:false,
    GenerationType.CORRECTIONS.value:false,
    GenerationType.QUESTIONS.value:false
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
                GenerationOption(value: json[GenerationType.LOCATION.value], name: GenerationType.LOCATION.name, setValue: () => setState(() {json[GenerationType.LOCATION.value] = !json[GenerationType.LOCATION.value];})),
                GenerationOption(value: json[GenerationType.SUMMARY.value], name: GenerationType.SUMMARY.name, setValue: () => setState(() {json[GenerationType.SUMMARY.value] = !json[GenerationType.SUMMARY.value];})),
                GenerationOption(value: json[GenerationType.TRANSCRIPT.value], name: GenerationType.TRANSCRIPT.name, setValue: () => setState(() {json[GenerationType.TRANSCRIPT.value] = !json[GenerationType.TRANSCRIPT.value];})),
                GenerationOption(value: json[GenerationType.ACTION.value], name: GenerationType.ACTION.name, setValue: () => setState(() {json[GenerationType.ACTION.value] = !json[GenerationType.ACTION.value];})),
                GenerationOption(value: json[GenerationType.DECISION.value], name: GenerationType.DECISION.name, setValue: () => setState(() {json[GenerationType.DECISION.value] = !json[GenerationType.DECISION.value];})),
                GenerationOption(value: json[GenerationType.NAMES.value], name: GenerationType.NAMES.name, setValue: () => setState(() {json[GenerationType.NAMES.value] = !json[GenerationType.NAMES.value];})),
                GenerationOption(value: json[GenerationType.TOPICS.value], name: GenerationType.TOPICS.name, setValue: () => setState(() {json[GenerationType.TOPICS.value] = !json[GenerationType.TOPICS.value];})),
                GenerationOption(value: json[GenerationType.PURPOSE.value], name: GenerationType.PURPOSE.name, setValue: () => setState(() {json[GenerationType.PURPOSE.value] = !json[GenerationType.PURPOSE.value];})),
                GenerationOption(value: json[GenerationType.NEXT_STEPS.value], name: GenerationType.NEXT_STEPS.name, setValue: () => setState(() {json[GenerationType.NEXT_STEPS.value] = !json[GenerationType.NEXT_STEPS.value];})),
                GenerationOption(value: json[GenerationType.CORRECTIONS.value], name: GenerationType.CORRECTIONS.name, setValue: () => setState(() {json[GenerationType.CORRECTIONS.value] = !json[GenerationType.CORRECTIONS.value];})),
                GenerationOption(value: json[GenerationType.QUESTIONS.value], name: GenerationType.QUESTIONS.name, setValue: () => setState(() {json[GenerationType.QUESTIONS.value] = !json[GenerationType.QUESTIONS.value];})),
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