import 'package:flutter/material.dart';
import 'package:meeting_summarizer_app/backendCalls.dart';
import 'package:meeting_summarizer_app/widgets/Generation.dart';
import 'dart:async';

Map<String, bool> displayedHolders = {};

/// Initializes the ```displayedHolders``` map with all emails as keys and false as values.
initDisplayedHolders() {
  for(final email in getEmails()) {
    displayedHolders[email] = false;
  }
  displayedHolders["General"] = false; // General is the holder for generations that are not tailored to any specific recipient.
}

/// Returns the [name] string with the first letter of each word capitalized.
String getCapitalizedName(String name) {
  return name.split(" ").map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase()).join(" ");
}

class GenerationHolder extends StatefulWidget {

  /// The name of the generation holder, typically the recipient's name or "General".
  final String name;

  /// The contact email of the recipient or "General".
  final String contact;

  /// The ```genMap``` present in other places in the app, just passed here for convenience.
  final Map<String, Map<String, dynamic>> genMap;

  /// The JSON object containing information about the desired generations, present in the ```AddGenerationsPage.dart``` page.
  final Map<String, dynamic> json;

  GenerationHolder({super.key, required this.name, required this.contact, required this.genMap, required this.json});

  @override
  State<GenerationHolder> createState() => _GenerationHolderState();
}

class _GenerationHolderState extends State<GenerationHolder> {

  /// Returns an ```IconData``` based on whether the holder is expanded or not.
  IconData getDropdownIcon() {
    return displayedHolders[widget.contact]! ? Icons.arrow_drop_down : Icons.arrow_drop_up;
  }

  Timer? timer;

  /// Using ```genMap```, Returns a widget list of type ```Generation``` that each contain a generation type to be generated for a specific recipient or "General".
  List<Widget> getGenWidgets() {
    List<Widget> widgets = [];
    if(displayedHolders[widget.contact]!) {
      List<Widget> widge = [];
      if(widget.genMap.isNotEmpty) {
        if(widget.contact != "General" && widget.genMap[widget.contact] != null) {
          for(final entry in widget.genMap[widget.contact]!.entries) {
            if(!nonTailorableStrings.contains(entry.key)) {
              widge.add(Generation(contact: widget.contact, name: getCapitalizedName(entry.key.replaceAll("_", " ")), genValue: entry.key));
            }
          }
        } else if(widget.contact == "General" && widget.genMap[widget.contact] != null) {
          for(final entry in widget.genMap[widget.contact]!.entries) {
            if(nonTailorableStrings.contains(entry.key) || !widget.json['tailored'] || infolessRecipientExistsOutsideGroup()) {
              widge.add(Generation(contact: widget.contact, name: getCapitalizedName(entry.key.replaceAll("_", " ")), genValue: entry.key));
            }
          }
        }
        widgets = widge;
      } else {
        widgets= [];
      }
    } else {
      widgets = [];
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      GestureDetector(
        onTap: () => setState(() {
          displayedHolders[widget.contact] = !displayedHolders[widget.contact]!;
        }),
        child: Row(children: [
          Padding(padding: EdgeInsets.all(10), child: Text(widget.name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
          Icon(getDropdownIcon(), size: 20, color: Colors.black),
        ]),
      ),
      ...getGenWidgets(),
    ]);
  }
}