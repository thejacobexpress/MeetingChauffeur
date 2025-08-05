import 'package:flutter/material.dart';
import 'AddGenerationsPage.dart';

String subject = "";

class AddSubjectPage extends StatefulWidget {

  const AddSubjectPage({super.key});

  @override
  State<AddSubjectPage> createState() => _AddSubjectPageState();
}

class _AddSubjectPageState extends State<AddSubjectPage> {

  TextEditingController subjectController = TextEditingController();

  @override
  void initState() {
    super.initState();
    subjectController = TextEditingController(text: subject);
    subjectController.addListener(() => subject = subjectController.text);
  }

  @override
  void dispose() {
    subjectController.dispose();
    super.dispose();
  }

  void goBack() {
    setState(() {
      Navigator.of(context).pop();
    });
  }

  void goToGenerationsPage() {
    if(subject.isNotEmpty) {
      setState(() {
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => AddGenerationsPage()));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children:[
        Padding(padding: EdgeInsets.all(10), child: Text("Subject of your email", style: TextStyle(fontSize: 20),)),
        Padding(padding: EdgeInsets.fromLTRB(10, 0, 10, 20), child: 
          TextField(
            decoration: InputDecoration(
              labelText: 'Subject',
              border: OutlineInputBorder(),
            ),
            controller: subjectController,
            style: TextStyle(fontSize: 20),
          ),
        ),
        Padding(padding: EdgeInsets.fromLTRB(100, 0, 100, 10), child:
          ElevatedButton(
            onPressed: () => goToGenerationsPage(),
            style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all<Color>(Colors.blue),
            padding: MaterialStateProperty.all<EdgeInsets>(EdgeInsets.all(20)),
            textStyle: MaterialStateProperty.all<TextStyle>(TextStyle(fontSize: 20)),
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
            )),
            child: Center(child: Text("Next", style: TextStyle(color: Colors.white, fontSize: 20)))
          )
        ),
        Padding(padding: EdgeInsets.fromLTRB(100, 0, 100, 10), child:
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
      )
    );
  }
}