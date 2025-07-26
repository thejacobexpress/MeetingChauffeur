import 'package:flutter/material.dart';

import 'package:meeting_summarizer_app/backendCalls.dart';
import 'package:meeting_summarizer_app/classes/GroupClass.dart';
import 'package:meeting_summarizer_app/classes/IndividualClass.dart';

class NewIndividualPage extends StatefulWidget {
  final Function addNewIndividual;

  const NewIndividualPage({super.key, required this.addNewIndividual});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  State<NewIndividualPage> createState() => _NewIndividualPageState();
}

class _NewIndividualPageState extends State<NewIndividualPage> {

  IndividualClass individual = IndividualClass("", "");

  TextEditingController nameController = TextEditingController();
  TextEditingController contactController = TextEditingController();

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: individual.name);
    contactController = TextEditingController(text: individual.contact);
    nameController.addListener(() => individual.name = nameController.text);
    contactController.addListener(() => individual.contact = contactController.text);
  }

  @override
  void dispose() {
    nameController.dispose();
    contactController.dispose();
    super.dispose();
  }

  void addNewIndividual() {
    if(nameController.text != "" && contactController.text != "") {
      indivToAdd = individual;
      widget.addNewIndividual();
    }
  }

  void goBack() {
    setState(() {
      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(padding: EdgeInsets.all(50), child: 
          TextField(
            decoration: InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
            controller: nameController,
          ),
        ),
        Padding(padding: EdgeInsets.all(20), child:
          Text(
            'Contact',
            style: TextStyle(fontSize: 20),
          ),
        ),
        Padding(padding: EdgeInsets.all(20), child:
          TextField(
            decoration: InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
            controller: contactController,
          ),
        ),
        Padding(padding: EdgeInsets.fromLTRB(100, 50, 100, 0), child:
          ElevatedButton(
            onPressed: () => addNewIndividual(),
            style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all<Color>(Colors.blue),
            padding: MaterialStateProperty.all<EdgeInsets>(EdgeInsets.all(20)),
            textStyle: MaterialStateProperty.all<TextStyle>(TextStyle(fontSize: 20)),
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
            )),
            child: Center(child: Text("Add", style: TextStyle(color: Colors.white, fontSize: 20)))
          )
        ),
        Padding(padding: EdgeInsets.fromLTRB(100, 50, 100, 0), child:
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
      ],
    ));
  }
}