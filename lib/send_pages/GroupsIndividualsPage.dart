import 'package:flutter/material.dart';

import 'package:meeting_summarizer_app/backendCalls.dart';
import 'package:meeting_summarizer_app/classes/GroupClass.dart';
import 'package:meeting_summarizer_app/send_pages/IndividualsPage.dart';
import 'package:meeting_summarizer_app/send_pages/GroupsPage.dart';

class GroupsIndividualsPage extends StatefulWidget {
  const GroupsIndividualsPage({super.key});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  State<GroupsIndividualsPage> createState() => _GroupsIndividualsPageState();
}

class _GroupsIndividualsPageState extends State<GroupsIndividualsPage> {

  void goToGroupsPage() {
    setState(() {
      Navigator.of(context).push(MaterialPageRoute(builder: (context) => GroupsPage()));
    });
  }

  void goToIndividualsPage() {
    setState(() {
      Navigator.of(context).push(MaterialPageRoute(builder: (context) => IndividualsPage(group: noGroup, addToIndividuals: () => {},)));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(padding: EdgeInsets.all(70), child:
          ElevatedButton(
            onPressed: () => goToGroupsPage(),
            style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all<Color>(Colors.blue),
            padding: MaterialStateProperty.all<EdgeInsets>(EdgeInsets.all(70)),
            textStyle: MaterialStateProperty.all<TextStyle>(TextStyle(fontSize: 20)),
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
            )),
            child: Center(child: Text("Groups", style: TextStyle(color: Colors.white, fontSize: 20)))
          )
        ),
        Padding(padding: EdgeInsets.all(70), child:
          ElevatedButton(
            onPressed: () => goToIndividualsPage(),
            style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all<Color>(Colors.blue),
            padding: MaterialStateProperty.all<EdgeInsets>(EdgeInsets.all(70)),
            textStyle: MaterialStateProperty.all<TextStyle>(TextStyle(fontSize: 20)),
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
            )),
            child: Center(child: Text("Individuals", style: TextStyle(color: Colors.white, fontSize: 20)))
          )
        )
      ]
    ));
  }
}