import 'dart:ui';
import 'dart:math';

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:meeting_summarizer_app/classes/IndividualClass.dart';
import 'package:meeting_summarizer_app/classes/Recipient.dart';
import 'package:meeting_summarizer_app/widgets/Group.dart';
import 'package:meeting_summarizer_app/widgets/Individual.dart';
import 'package:meeting_summarizer_app/main_sequence/AddGenerationsPage.dart';
import 'package:meeting_summarizer_app/classes/GroupClass.dart';

class AddRecipientsPage extends StatefulWidget {
  const AddRecipientsPage({super.key});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  State<AddRecipientsPage> createState() => _AddRecipientsPageState();
}

class _AddRecipientsPageState extends State<AddRecipientsPage> {

  String generateRandomHexColor() {
    Random random = Random();
    String color = '';
    for (int i = 0; i < 8; i++) {
      color += random.nextInt(16).toRadixString(16);
    }
    return color;
  }

  void goToGenerationsPage() {
    setState(() {
      Navigator.of(context).push(MaterialPageRoute(builder: (context) => AddGenerationsPage()));
    });
  }

  void goBack() {
    setState(() {
      Navigator.of(context).pop();
    });
  }

  List<Widget> getIndividualWidgets() {
    List<Widget> list = [];
    for(final individual in individuals) {
      list.add(Individual(indivClass: individual, individualColor: Colors.blue.shade300, checkable: true, newGroup: noGroup, addToIndividuals: () => {},));
    }
    return list;
  }

  List<Widget> getGroupWidgets() {
    List<Widget> list = [];
    for(final group in groups) {
      String randomHex = "0x${generateRandomHexColor()}";
      list.add(Group(groupClass: group, groupColor: Color(int.parse(randomHex)), checkable: true));
    }
    return list;
  }

  @override
  void initState() {
    super.initState();
    recipients = <Recipient>[];
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Column(
        children: [
          Padding(padding: EdgeInsets.fromLTRB(0, MediaQuery.paddingOf(context).top, 0, 20), child: Text('Choose Recipients',style: TextStyle(fontSize: 24))),
          Padding(padding: EdgeInsets.all(0), child: Text('Groups',style: TextStyle(fontSize: 20))),
          SizedBox(
            height: 150,
            width: MediaQuery.of(context).size.width,
            child: ListView(
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              children: getGroupWidgets(),
            )
          ),
          Padding(padding: EdgeInsetsGeometry.directional(top: 20), child: Text('Individuals',style: TextStyle(fontSize: 20))),
          SizedBox(
            height: 234,
            width: MediaQuery.of(context).size.width,
            child: ListView(
              shrinkWrap: true,
              scrollDirection: Axis.vertical,
              children: getIndividualWidgets(),
            )
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: SizedBox(
              width: 250,
              height: 75,
              child: ElevatedButton(
                onPressed: () => goToGenerationsPage(), // Assumes that the last WAV is the current WAV
                style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(Colors.blue),
                padding: MaterialStateProperty.all<EdgeInsets>(EdgeInsets.all(20)),
                textStyle: MaterialStateProperty.all<TextStyle>(TextStyle(fontSize: 20)),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                )),
                child: Center(child: Text("Tweak Send", style: TextStyle(color: Colors.white, fontSize: 20)))
              ),
            )
          ),
          Padding(padding: EdgeInsets.fromLTRB(100, 0, 100, 10), child:
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