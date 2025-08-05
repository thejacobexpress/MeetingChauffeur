import 'package:flutter/material.dart';
import 'package:meeting_summarizer_app/BackendCalls.dart';
import 'package:meeting_summarizer_app/classes/GroupClass.dart';
import 'package:meeting_summarizer_app/main_sequence/EmailSendingPage.dart';
import 'package:meeting_summarizer_app/classes/Recipient.dart';
import 'package:meeting_summarizer_app/widgets/GenerationHolder.dart';
import 'package:meeting_summarizer_app/classes/IndividualClass.dart';
import 'dart:async';

Future<int> response = Future.value(0);

class FinalizeSendPage extends StatefulWidget {
  final Map<String, dynamic> json;

  const FinalizeSendPage({super.key, required this.json});

  @override
  State<FinalizeSendPage> createState() => _FinalizeSendPageState();
}

class _FinalizeSendPageState extends State<FinalizeSendPage> {

  Future<int> getEmailResponse() async {
    return await sendEmail(genMap);
  }

  void goToEmailSendingPage() {
    setState(() {
      Navigator.of(context).push(MaterialPageRoute(builder: (context) => EmailSendingPage()));
    });
  }

  void goBack() {
    setState(() {
      Navigator.of(context).pop();
    });
  }

  /// Returns a list of string values of ```GenerationType```s that the user requested to be generated that cannot be tailored to specific recipients.
  List<String> getRequestedGeneralGenTypes() {
    List<String> generalGenTypes = [];
    for(final type in widget.json.entries) {
      if(type.value && nonTailorableStrings.contains(type.key)) {
        generalGenTypes.add(type.key);
      }
    }
    return generalGenTypes;
  }

  Timer? timer;

  /// Returns a list of type ```Widget```(shows text generations) that reflect what the user chose to generate in the ```AddGenerationsPage.dart``` page.
  List<GenerationHolder> getGenerations() {
    // Add a general generation holder if the user requested any general generations.
    List<GenerationHolder> widgetList = [];
    if(getRequestedGeneralGenTypes().isNotEmpty) {
      widgetList.add(GenerationHolder(name: "General", contact: "General", genMap: genMap, json: widget.json,));
    }
    // Add a generation holder for each recipient with their tailored generations.
    if(widget.json['tailored'] != null && widget.json['tailored']) {
      for(final recipient in recipients) {
        if(recipient is GroupClass && recipient.individuals.isNotEmpty) {
          for(final individual in recipient.individuals) {
            widgetList.add(GenerationHolder(name: individual.name, contact: individual.contact, genMap: genMap, json: widget.json,));
          }
        } else if (recipient is IndividualClass && (recipient.info != '' || recipient.getGroups().isNotEmpty)) {
          widgetList.add(GenerationHolder(name: recipient.name, contact: recipient.contact, genMap: genMap, json: widget.json,));
        }
      }
    }
    return widgetList;
  }

  /// Makes use of the ```RetrieveDataFromS3AndLocal``` function to retrieve the data from S3 and local storage after waiting 3 seconds for the generations to be created.
  Future<void> retrieveData(Map<String, dynamic> json) async {
    await Future.delayed(Duration(seconds: 3));
    final result = await retrieveDataFromS3AndLocal(json);
    setState(() {
      genMap = result;
    });
  }

  @override
  void initState() {
    super.initState();
    retrieveData(widget.json);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Column(
        children: [
          Padding(padding: EdgeInsets.fromLTRB(0, MediaQuery.paddingOf(context).top, 0, 0), child: Text("Generations", style: TextStyle(fontSize: 24))),
          Padding(padding: EdgeInsets.all(10), child: Text("This is what your recipients will receive.", style: TextStyle(fontSize: 16, color: Colors.grey))),
          SizedBox(
            height: 442,
            width: MediaQuery.of(context).size.width,
            child: ListView(
              shrinkWrap: true,
              scrollDirection: Axis.vertical,
              children: getGenerations(),
            )
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: SizedBox(
              width: 250,
              height: 75,
              child: ElevatedButton(
                onPressed: () {
                  if(genListReady && recipients.isNotEmpty) {
                    goToEmailSendingPage();
                    try{
                      response = getEmailResponse();
                    } on Exception {
                      response = Future.value(400);
                    }
                  }
                }, // Assumes that the last m4a is the current m4a
                style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(Colors.blue),
                padding: MaterialStateProperty.all<EdgeInsets>(EdgeInsets.all(20)),
                textStyle: MaterialStateProperty.all<TextStyle>(TextStyle(fontSize: 20)),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                )),
                child: Center(child: Text("Send", style: TextStyle(color: Colors.white, fontSize: 20)))
              ),
            )
          ),
          Padding(padding: EdgeInsets.fromLTRB(100, 10, 100, 10), child:
          ElevatedButton(
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
            child: Center(child: Text("Back", style: TextStyle(color: Colors.white, fontSize: 20)))
          )
        )
        ]
      )
    );
  }
}