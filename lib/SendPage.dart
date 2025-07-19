import 'package:flutter/material.dart';

import 'backendCalls.dart';

class SendPage extends StatefulWidget {
  const SendPage({super.key});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  State<SendPage> createState() => _SendPageState();
}

class _SendPageState extends State<SendPage> {

  final controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(padding: EdgeInsets.all(50), child: 
          TextField(
            decoration: InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
            controller: controller,
          ),
        ),
        Padding(padding: EdgeInsets.all(20), child:
          Text(
            'Contact',
            style: TextStyle(fontSize: 20),
          ),
        ),
        Padding(padding: EdgeInsets.all(20), child:
          TextField(
            decoration: InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        // Expanded(flex: 0, child: 
          Padding(padding: EdgeInsets.all(70), child:
            ElevatedButton(
              onPressed: () => {},
              style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all<Color>(Colors.blue),
              padding: MaterialStateProperty.all<EdgeInsets>(EdgeInsets.all(20)),
              textStyle: MaterialStateProperty.all<TextStyle>(TextStyle(fontSize: 20)),
              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
              )),
              child: Center(child: Text("Send Meeting", style: TextStyle(color: Colors.white, fontSize: 20)))
            )
          )
        // )
      ],
    ));
  }
}