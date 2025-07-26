import 'package:flutter/material.dart';
import 'package:meeting_summarizer_app/classes/GroupClass.dart';
import 'package:meeting_summarizer_app/send_pages/NewIndividualPage.dart';
import 'package:meeting_summarizer_app/widgets/Individual.dart';
import 'package:meeting_summarizer_app/classes/IndividualClass.dart';

class IndividualsPage extends StatefulWidget {
  final GroupClass group;
  final Function addToIndividuals;

  const IndividualsPage({super.key, required this.group, required this.addToIndividuals});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  State<IndividualsPage> createState() => _IndividualsPageState();
}

class _IndividualsPageState extends State<IndividualsPage> {

  void addNewIndividual() {
    setState(() {
      individuals.add(indivToAdd);
      indivToAdd = noIndividual;
      goBack();
    });
  }

  List<Widget> getIndividualWidgets() {
    List<Widget> list = [];
    for(final individual in individuals) {
      list.add(Individual(indivClass: individual, individualColor: Colors.blue.shade300, checkable: false, newGroup: widget.group, addToIndividuals: widget.addToIndividuals,));
    }
    return list;
  }

  void goToNewIndividualPage() {
    setState(() {
      Navigator.of(context).push(MaterialPageRoute(builder: (context) => NewIndividualPage(addNewIndividual: addNewIndividual,)));
    });
  }

  void goBack() {
    setState(() {
      Navigator.of(context).pop();
    });
  }

  Widget getAddWidget() {
    if(widget.group == noGroup) {
      return Padding(padding: EdgeInsets.fromLTRB(30, 20, 30, 10), child: 
          ElevatedButton(
            onPressed: () => goToNewIndividualPage(),
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
        );
    } else {
      return Center();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(child: Column(
      children: [
        Padding(padding: EdgeInsets.fromLTRB(0, MediaQuery.paddingOf(context).top, 0, 0), child: Text("Individuals", style: TextStyle(fontSize: 24))),
        getAddWidget(),
        SizedBox(
          height: 476,
          width: MediaQuery.of(context).size.width,
          child: ListView(
            shrinkWrap: true,
            scrollDirection: Axis.vertical,
            children: getIndividualWidgets(),
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
    ));
  }
}