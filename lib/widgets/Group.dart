import 'package:flutter/material.dart';

var isSelected = false;

class Group extends StatefulWidget {
  final String groupName;
  final Color groupColor;

  const Group({super.key, required this.groupName, required this.groupColor});


  @override
  State<Group> createState() => _GroupState();

}

class _GroupState extends State<Group> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() {
        isSelected = !isSelected;
      }),
      child: Container(
        decoration: BoxDecoration(color: isSelected? const Color.fromARGB(255, 186, 224, 255) :  Colors.white),
        child: Padding(
          padding: EdgeInsets.all(10),
          child: Column(
            children: [
              SizedBox(
                height: 100,
                width: 100,
                child: Container(
                  decoration: BoxDecoration(color: widget.groupColor),
                ),
              ),
              Text(widget.groupName, style: TextStyle(fontSize: 16),)
            ],
          )
        )
      )
    );
  }
}