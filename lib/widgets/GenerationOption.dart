import 'package:flutter/material.dart';

class GenerationOption extends StatefulWidget {
  var value;
  final String name;
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