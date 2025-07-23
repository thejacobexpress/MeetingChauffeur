import 'package:flutter/material.dart';
import 'package:meeting_summarizer_app/widgets/Group.dart';
import 'package:meeting_summarizer_app/widgets/Individual.dart';
import 'package:meeting_summarizer_app/AddGenerationsPage.dart';

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

  void goToGenerationsPage() {
    setState(() {
      Navigator.of(context).push(MaterialPageRoute(builder: (context) => AddGenerationsPage()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Column(
        children: [
          Padding(padding: EdgeInsets.all(MediaQuery.paddingOf(context).top), child: Text('Choose Recipients',style: TextStyle(fontSize: 24))),
          Padding(padding: EdgeInsets.all(0), child: Text('Groups',style: TextStyle(fontSize: 20))),
          SizedBox(
            height: 150,
            width: MediaQuery.of(context).size.width,
            child: ListView(
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              children: [
                Group(groupName: "finance", groupColor: Colors.amber), 
                Group(groupName: "marketing", groupColor: Colors.black26), 
                Group(groupName: "executive", groupColor: Colors.red),
                Group(groupName: "software", groupColor: Colors.orange),
                Group(groupName: "people", groupColor: Colors.greenAccent),
              ],
            )
          ),
          Padding(padding: EdgeInsetsGeometry.directional(top: 20), child: Text('Individuals',style: TextStyle(fontSize: 20))),
          SizedBox(
            height: 250,
            width: MediaQuery.of(context).size.width,
            child: ListView(
              shrinkWrap: true,
              scrollDirection: Axis.vertical,
              children: [
                Individual(individualName: "Alexander Hamilton", individualColor: Colors.amber), 
                Individual(individualName: "Alexander Hamilton", individualColor: Colors.black26), 
                Individual(individualName: "Alexander Hamilton", individualColor: Colors.red),
                Individual(individualName: "Alexander Hamilton", individualColor: Colors.orange),
                Individual(individualName: "Alexander Hamilton", individualColor: Colors.greenAccent),
              ],
            )
          ),
          Padding(
            padding: EdgeInsets.all(16),
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
          )
        ]
      )
    );
  }
}