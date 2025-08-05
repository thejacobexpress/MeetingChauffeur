import 'package:flutter/material.dart';
import 'package:meeting_summarizer_app/classes/GroupClass.dart';
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

  /// The ```GroupClass``` instance to be added to the ```groups``` list.
  GroupClass group = GroupClass("", []);

  TextEditingController nameController = TextEditingController();
  TextEditingController infoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: group.name);
    infoController = TextEditingController(text: group.info);
    nameController.addListener(() => group.name = nameController.text);
    infoController.addListener(() => group.info = infoController.text);
  }

  @override
  void dispose() {
    nameController.dispose();
    infoController.dispose();
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

  /// Returns a list of ```Individual``` widgets representing the individuals in the group.
  List<Widget> getIndividualWidgets() {
    List<Widget> list = [];
    for(final individual in group.individuals) {
      list.add(Individual(indivClass: individual, individualColor: Colors.blue.shade300, checkable: false, newGroup: noGroup, addToIndividuals: () => {},)); // noGroup because already added individual to this group.
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Center(child: SizedBox( width: MediaQuery.of(context).size.width, height: MediaQuery.of(context).size.height,
      child: ListView( scrollDirection: Axis.vertical, shrinkWrap: true,
        children: [Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(padding: EdgeInsets.fromLTRB(50, MediaQuery.paddingOf(context).top, 50, 0), child: 
            TextField(
              decoration: InputDecoration(
                labelText: 'Group Name',
                border: OutlineInputBorder(),
              ),
              controller: nameController,
              style: TextStyle(fontSize: 20),
            ),
          ),
          Padding(padding: EdgeInsets.fromLTRB(10, 20, 10, 0), child:
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
          Padding(padding: EdgeInsets.fromLTRB(10, 20, 10, 10), child:
            Text(
              'Info',
              style: TextStyle(fontSize: 20),
            ),
          ),
          Padding(padding: EdgeInsets.fromLTRB(16, 0, 16, 0), child:
            TextField(
              decoration: InputDecoration(
                labelText: 'Info about the group (optional)',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              ),
              maxLines: 5,
              style: TextStyle(fontSize: 16),
              controller: infoController,
            ),
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
          Padding(padding: EdgeInsets.fromLTRB(75, 10, 75, 0), child:
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
    )])));
  }
}