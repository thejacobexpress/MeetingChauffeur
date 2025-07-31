import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:meeting_summarizer_app/backendCalls.dart';
import 'package:meeting_summarizer_app/widgets/Generation.dart';
import 'dart:async';

Map<String, bool> displayedHolders = {};

initDisplayedHolders() {
  for(final email in getEmails()) {
    displayedHolders[email] = false;
  }
  displayedHolders["General"] = false; // General is the holder for generations that are not tailored to any specific recipient.
}

String getCapitalizedName(String name) {
  return name.split(" ").map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase()).join(" ");
}

class GenerationHolder extends StatefulWidget {
  final String name;
  final String contact;
  final Map<String, Map<String, dynamic>> genMap;

  GenerationHolder({super.key, required this.name, required this.contact, required this.genMap});

  @override
  State<GenerationHolder> createState() => _GenerationHolderState();
}

class _GenerationHolderState extends State<GenerationHolder> {

  IconData getDropdownIcon() {
    return displayedHolders[widget.contact]! ? Icons.arrow_drop_down : Icons.arrow_drop_up;
  }

  Timer? timer;

  // Specific recipients only contain generations that are specifically tailored to them.
  // "General" contain generations that are not tailored to any specific recipient. (in nonTailorable list at BackendCalls.dart: 50)
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
            if(nonTailorableStrings.contains(entry.key)) {
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