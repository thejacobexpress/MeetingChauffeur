import 'package:flutter/material.dart';

import 'package:meeting_summarizer_app/backendCalls.dart';
import 'package:meeting_summarizer_app/classes/GroupClass.dart';
import 'package:meeting_summarizer_app/classes/IndividualClass.dart';
import 'package:meeting_summarizer_app/send_pages/IndividualsPage.dart';
import 'package:meeting_summarizer_app/widgets/Individual.dart';

class NewGroupPage extends StatefulWidget {
  final Function addNewGroup;

  const NewGroupPage({super.key, required this.addNewGroup});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  State<NewGroupPage> createState() => _NewGroupPageState();
}

class _NewGroupPageState extends State<NewGroupPage> {

  GroupClass group = GroupClass("", []);

  TextEditingController nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: group.name);
    nameController.addListener(() => group.name = nameController.text);
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  void addNewGroup() {
    if(nameController.text != "" && group.individuals.isNotEmpty) {
      groupToAdd = group;
      widget.addNewGroup();
    }
  }

  void addToIndividuals() {
    setState(() {
      if(indivToAdd != noIndividual) {
        group.individuals.add(indivToAdd);
        indivToAdd = noIndividual;
        goBack();
      }
    });
  }

  void goBack() {
    setState(() {
      Navigator.of(context).pop();
    });
  }

  void goToIndividualsPage() {
    setState(() {
      Navigator.of(context).push(MaterialPageRoute(builder: (context) => IndividualsPage(group: group, addToIndividuals: addToIndividuals,)));
    });
  }

  List<Widget> getIndividualWidgets() {
    List<Widget> list = [];
    for(final individual in group.individuals) {
      list.add(Individual(indivClass: individual, individualColor: Colors.blue.shade300, checkable: false, newGroup: noGroup, addToIndividuals: () => {},)); // noGroup because already added individual to this group.
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(padding: EdgeInsets.fromLTRB(50, MediaQuery.paddingOf(context).top, 50, 20), child: 
          TextField(
            decoration: InputDecoration(
              labelText: 'Group Name',
              border: OutlineInputBorder(),
            ),
            controller: nameController,
            style: TextStyle(fontSize: 20),
          ),
        ),
        Padding(padding: EdgeInsets.fromLTRB(20, 0, 20, 10), child:
          Text(
            'Individuals',
            style: TextStyle(fontSize: 20),
          ),
        ),
        SizedBox(
          height: 329,
          width: MediaQuery.of(context).size.width,
          child: ListView(
            shrinkWrap: true,
            scrollDirection: Axis.vertical,
            children: getIndividualWidgets(),
          )
        ),
        Padding(padding: EdgeInsets.fromLTRB(50, 10, 50, 0), child:
          ElevatedButton(
            onPressed: () => goToIndividualsPage(),
            style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all<Color>(Colors.blue),
            padding: MaterialStateProperty.all<EdgeInsets>(EdgeInsets.all(20)),
            textStyle: MaterialStateProperty.all<TextStyle>(TextStyle(fontSize: 20)),
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
            )),
            child: Center(child: Text("Add New Individual", style: TextStyle(color: Colors.white, fontSize: 20)))
          )
        ),
        Padding(padding: EdgeInsets.fromLTRB(100, 10, 100, 0), child:
          ElevatedButton(
            onPressed: () => addNewGroup(),
            style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all<Color>(Colors.blue),
            padding: MaterialStateProperty.all<EdgeInsets>(EdgeInsets.all(20)),
            textStyle: MaterialStateProperty.all<TextStyle>(TextStyle(fontSize: 20)),
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
            )),
            child: Center(child: Text("Add Group", style: TextStyle(color: Colors.white, fontSize: 20)))
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
      ],
    ));
  }
}