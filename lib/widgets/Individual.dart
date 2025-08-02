import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:meeting_summarizer_app/classes/GroupClass.dart';
import 'package:meeting_summarizer_app/main_sequence/AddRecipientsPage.dart';
import 'package:meeting_summarizer_app/send_pages/NewGroupPage.dart';
import 'package:meeting_summarizer_app/send_pages/SingleGroupPage.dart';
import 'package:meeting_summarizer_app/send_pages/SingleIndividualPage.dart';
import 'package:meeting_summarizer_app/classes/IndividualClass.dart';
import 'package:meeting_summarizer_app/classes/Recipient.dart';

class Individual extends StatefulWidget {
  final IndividualClass indivClass;
  final Color individualColor;
  final bool checkable;
  final GroupClass newGroup; // Group that this individual will be added to (if user is adding this individual to a new group)
  final Function addToIndividuals;

  const Individual({super.key, required this.indivClass, required this.individualColor, required this.checkable, required this.newGroup, required this.addToIndividuals});


  @override
  State<Individual> createState() => _IndividualState();

}

class _IndividualState extends State<Individual> {

  var isSelected = false;

  void goToIndividualPage(IndividualClass individual) {
    setState(() {
      Navigator.of(context).push(MaterialPageRoute(builder: (context) => SingleIndividualPage(individual: individual)));
    });
  }

  void goBack() {
    setState(() {
      Navigator.of(context).pop();
    });
  }

  Widget getCheckboxWidget() {
    if(widget.checkable) {
      return Checkbox(value: isSelected, onChanged: (value) => setState(() {isSelected = value!;}));
    } else {
      return Center();
    }
  }

  @override
  Widget build(BuildContext context) {
      return GestureDetector(
        onTap: () => setState(() {
          if(widget.checkable) {
            isSelected = !isSelected;
            if(isSelected) {
              recipients.add(widget.indivClass);
              safePrint("New Recipient: ${widget.indivClass.contact}");
            } else {
              recipients.remove(widget.indivClass);
              safePrint("Removed Recipient: ${widget.indivClass.contact}");
            }
          } else if (widget.newGroup != noGroup) {
            indivToAdd = widget.indivClass;
            widget.addToIndividuals();
          } else {
            goToIndividualPage(widget.indivClass);
          }
        }),
        child: Container(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 5, 20, 0),
            child: Column(
              children: [
                SizedBox(
                  height: 50,
                  width: MediaQuery.of(context).size.width,
                  child: Container(
                    decoration: BoxDecoration(color: widget.individualColor),
                    child: Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(widget.indivClass.name, style: TextStyle(fontSize: 16)), 
                      getCheckboxWidget()
                    ]))
                  ),
                ),
              ],
            )
          )
        )
      );
  }
}