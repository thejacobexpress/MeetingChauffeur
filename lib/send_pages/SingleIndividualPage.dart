import 'package:flutter/material.dart';

import 'package:meeting_summarizer_app/backendCalls.dart';
import 'package:meeting_summarizer_app/classes/IndividualClass.dart';

class SingleIndividualPage extends StatefulWidget {
  final IndividualClass individual;

  const SingleIndividualPage({super.key, required this.individual});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  State<SingleIndividualPage> createState() => _SingleIndividualPageState();
}

class _SingleIndividualPageState extends State<SingleIndividualPage> {

  TextEditingController nameController = TextEditingController();
  TextEditingController contactController = TextEditingController();

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.individual.name);
    contactController = TextEditingController(text: widget.individual.contact);
    nameController.addListener(() => widget.individual.name = nameController.text);
    contactController.addListener(() => widget.individual.contact = contactController.text);
  }

  @override
  void dispose() {
    nameController.dispose();
    contactController.dispose();
    super.dispose();
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
        Padding(padding: EdgeInsets.fromLTRB(50, MediaQuery.paddingOf(context).top, 50, 0), child: 
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