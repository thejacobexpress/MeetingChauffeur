import 'package:flutter/material.dart';

var isSelected = false;

class Individual extends StatefulWidget {
  final String individualName;
  final Color individualColor;

  const Individual({super.key, required this.individualName, required this.individualColor});


  @override
  State<Individual> createState() => _IndividualState();

}

class _IndividualState extends State<Individual> {
  @override
  Widget build(BuildContext context) {
      return GestureDetector(
        onTap: () => setState(() {
          isSelected = !isSelected;
        }),
        child: Container(
          child: Padding(
            padding: EdgeInsets.all(0),
            child: Column(
              children: [
                SizedBox(
                  height: 50,
                  width: MediaQuery.of(context).size.width,
                  child: Container(
                    decoration: BoxDecoration(color: widget.individualColor),
                    child: Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(widget.individualName, style: TextStyle(fontSize: 16)), 
                      Checkbox(value: isSelected, onChanged: (value) => setState(() {
                        isSelected = value!;
                      }))
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