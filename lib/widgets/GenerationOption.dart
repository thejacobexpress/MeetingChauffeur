import 'package:flutter/material.dart';

// ignore: must_be_immutable
class GenerationOption extends StatefulWidget {

  /// The value of the checkbox, which should be true or false.
  var value;

  /// The name of the generation option, which will be displayed next to the checkbox.
  final String name;

  /// This function should set the value of the checkbox to true or false.
  /// 
  /// Meant to be used with a ```setState``` function to update the state of the parent widget.
  Function setValue;

  GenerationOption({super.key, required this.value, required this.name, required this.setValue});


  @override
  State<GenerationOption> createState() => _GenerationOptionState();

}

class _GenerationOptionState extends State<GenerationOption> {
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Checkbox(value: widget.value, onChanged:(bool? newValue) {
        widget.setValue();
      }),
      Text(widget.name, style: TextStyle(fontSize: 16))
    ]);
  }
}