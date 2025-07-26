import 'package:flutter/material.dart';
import 'package:meeting_summarizer_app/classes/GroupClass.dart';
import 'package:meeting_summarizer_app/send_pages/NewGroupPage.dart';
import 'package:meeting_summarizer_app/send_pages/NewIndividualPage.dart';
import 'package:meeting_summarizer_app/send_pages/SingleGroupPage.dart';
import 'package:meeting_summarizer_app/widgets/Group.dart';
import 'package:meeting_summarizer_app/widgets/Individual.dart';
import 'package:meeting_summarizer_app/classes/IndividualClass.dart';

class GroupsPage extends StatefulWidget {
  const GroupsPage({super.key});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {

  void addNewGroup() {
    setState(() {
      groups.add(groupToAdd);
      groupToAdd = noGroup;
      goBack();
    });
  }

  List<Widget> getGroupWidgets() {
    List<Widget> list = [];
    for(final group in groups) {
      list.add(Group(groupClass: group, groupColor: Colors.blue.shade300, checkable: false));
    }
    return list;
  }

  void goBack() {
    setState(() {
      Navigator.of(context).pop();
    });
  }

  void goToNewGroupPage() {
    setState(() {
      Navigator.of(context).push(MaterialPageRoute(builder: (context) => NewGroupPage(addNewGroup: addNewGroup,)));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(child: Column(
      children: [
        Padding(padding: EdgeInsets.fromLTRB(0, MediaQuery.paddingOf(context).top, 0, 0), child: Text("Groups", style: TextStyle(fontSize: 24))),
        Padding(padding: EdgeInsets.fromLTRB(30, 20, 30, 10), child: 
          ElevatedButton(
            onPressed: () => goToNewGroupPage(),
            style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all<Color>(Colors.blue),
            padding: MaterialStateProperty.all<EdgeInsets>(EdgeInsets.all(20)),
            textStyle: MaterialStateProperty.all<TextStyle>(TextStyle(fontSize: 20)),
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
            )),
            child: Center(child: Text("Add New Group", style: TextStyle(color: Colors.white, fontSize: 20)))
          )
        ),
        SizedBox(
          height: 476,
          width: MediaQuery.of(context).size.width,
          child: ListView(
            shrinkWrap: true,
            scrollDirection: Axis.vertical,
            children: getGroupWidgets(),
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