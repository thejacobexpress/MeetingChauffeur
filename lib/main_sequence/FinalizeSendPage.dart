import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:meeting_summarizer_app/BackendCalls.dart';
import 'package:meeting_summarizer_app/main_sequence/AddRecipientsPage.dart';
import 'package:meeting_summarizer_app/main_sequence/EmailSendingPage.dart';
import 'package:meeting_summarizer_app/widgets/Generation.dart';
import 'package:meeting_summarizer_app/classes/Recipient.dart';

Future<int> response = Future.value(0);

class FinalizeSendPage extends StatefulWidget {
  final Map<String, dynamic> json;

  const FinalizeSendPage({super.key, required this.json});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  State<FinalizeSendPage> createState() => _FinalizeSendPageState();
}

class _FinalizeSendPageState extends State<FinalizeSendPage> {

  Future<int> getEmailResponse() async {
    return await sendEmail(genMap);
  }

  void goToEmailSendingPage() {
    setState(() {
      Navigator.of(context).push(MaterialPageRoute(builder: (context) => EmailSendingPage()));
    });
  }

  void goBack() {
    setState(() {
      Navigator.of(context).pop();
    });
  }

  // Get a list of widgets(shows text generations) that reflect what the user chose to generate in previous page.
  List<Widget> getGenerations() {
    List<Widget> widgetList = [];
    for (final (index, entry) in widget.json.entries.indexed) {
      if(entry.value) {
        widgetList.add(Generation(name: GenerationType.values[index].name, genValue: GenerationType.values[index].value));
      }
    }
    return widgetList;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Column(
        children: [
          Padding(padding: EdgeInsets.fromLTRB(0, MediaQuery.paddingOf(context).top, 0, 0), child: Text("Generations", style: TextStyle(fontSize: 24))),
          Padding(padding: EdgeInsets.all(10), child: Text("This is what your recipients will receive.", style: TextStyle(fontSize: 16, color: Colors.grey))),
          SizedBox(
            height: 442,
            width: MediaQuery.of(context).size.width,
            child: ListView(
              shrinkWrap: true,
              scrollDirection: Axis.vertical,
              children: getGenerations(),
            )
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: SizedBox(
              width: 250,
              height: 75,
              child: ElevatedButton(
                onPressed: () => {
                  if(genListReady && recipients.isNotEmpty) {
                    response = getEmailResponse(),
                    goToEmailSendingPage(),
                  }
                }, // Assumes that the last WAV is the current WAV
                style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(Colors.blue),
                padding: MaterialStateProperty.all<EdgeInsets>(EdgeInsets.all(20)),
                textStyle: MaterialStateProperty.all<TextStyle>(TextStyle(fontSize: 20)),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                )),
                child: Center(child: Text("Send", style: TextStyle(color: Colors.white, fontSize: 20)))
              ),
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
      )
    );
  }
}