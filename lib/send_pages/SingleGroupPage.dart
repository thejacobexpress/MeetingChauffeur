import 'package:flutter/material.dart';
import 'package:meeting_summarizer_app/classes/GroupClass.dart';
import 'package:meeting_summarizer_app/send_pages/IndividualsPage.dart';
import 'package:meeting_summarizer_app/widgets/Individual.dart';

class SingleGroupPage extends StatefulWidget {
  final GroupClass group;

  const SingleGroupPage({super.key, required this.group});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  State<SingleGroupPage> createState() => _SingleGroupPageState();
}

class _SingleGroupPageState extends State<SingleGroupPage> {

  TextEditingController nameController = TextEditingController();
  TextEditingController infoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.group.name);
    infoController = TextEditingController(text: widget.group.info);
    nameController.addListener(() => widget.group.name = nameController.text);
    infoController.addListener(() => widget.group.info = infoController.text);
  }

  @override
  void dispose() {
    nameController.dispose();
    infoController.dispose();
    super.dispose();
  }

  void goBack() {
    setState(() {
      Navigator.of(context).pop();
    });
  }

  void addToIndividuals() {
    setState(() {
      if(indivToAdd != noIndividual) {
        widget.group.individuals.add(indivToAdd);
        indivToAdd = noIndividual;
        goBack();
      }
    });
  }

  void goToIndividualsPage() {
    setState(() {
      Navigator.of(context).push(MaterialPageRoute(builder: (context) => IndividualsPage(group: widget.group, addToIndividuals: addToIndividuals,)));
    });
  }

  /// Returns a list of ```Individual``` widgets that represent the individuals in the group defined in the ```SingleGroupPage.dart``` page.
  List<Widget> getIndividualWidgetsInGroup() {
    List<Widget> list = [];
    for(final indiviudal in widget.group.individuals) {
      list.add(Individual(indivClass: indiviudal, individualColor: Colors.blue.shade300, checkable: false, newGroup: noGroup, addToIndividuals: addToIndividuals,));
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
          Padding(padding: EdgeInsets.fromLTRB(0, 0, 0, 10), child:
            Text(
              'Individuals',
              style: TextStyle(fontSize: 20),
            ),
          ),
          SizedBox(
            height: 406,
            width: MediaQuery.of(context).size.width,
            child: ListView(
              shrinkWrap: true,
              scrollDirection: Axis.vertical,
              children: getIndividualWidgetsInGroup(),
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
          Padding(padding: EdgeInsets.fromLTRB(40, 10, 40, 0), child:
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