import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'package:record/record.dart';

import 'package:flutter_file_dialog/flutter_file_dialog.dart';

import 'package:amplify_flutter/amplify_flutter.dart';

import 'BackendCalls.dart';
import 'main.dart';
import 'AddRecipientsPage.dart';

var localAudioFileName;
var filePath = "";
List<String> recordingFilePaths = List.empty(growable: true); // Assumes that the last WAV is the current WAV

class MyHomePage extends StatefulWidget {

  const MyHomePage({super.key});


  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  bool isRecording = false;
  int currentInputIndex = 0;
  List<InputDevice> availableInputs = List.empty(growable: true);
  bool inputSelected = false;
  final record = AudioRecorder();
  String tempWavPath = "";

  Future<void> configureInputs(bool checkMissing) async {
    final inputs = await record.listInputDevices();
    if (inputs.isEmpty) {
      safePrint("No audio inputs available");
      return;
    } else {

      if (checkMissing) {
        final previousInputId = availableInputs[currentInputIndex].id;
        final previousInputIndex = currentInputIndex;
        var previousInCurrent = false;

        availableInputs.clear();

        for(final (index, input) in inputs.indexed) {
          availableInputs.add(input);
          if (input.id == previousInputId) {
            previousInCurrent = true;
            if(previousInputIndex != currentInputIndex) {
              setState(() {
                currentInputIndex = index; // Restore previous index if it exists
              });
            }
          }
        }
        if (!previousInCurrent) {
          setState(() {
            currentInputIndex = 0; // Reset to first input if previous was not found
          });
        }
      } else {
        availableInputs.clear();
        for(InputDevice input in inputs) {
          availableInputs.add(input);
        }
      }
      safePrint("Available inputs: ${availableInputs.map((e) => e.label).join(', ')}");
    }
  }

  @override
  initState() {
    super.initState();

    configureInputs(false);
    setState(() {
      currentInputIndex = 0;
    });
  }

  void startRecording() {

    configureInputs(true).then((_) async {
      if (await record.hasPermission()) {
        // Start recording
        RecordConfig recordConfig = RecordConfig(
          sampleRate: 44100,
          bitRate: 128000,
          numChannels: 2,
          encoder: AudioEncoder.pcm16bits,
          device: availableInputs[currentInputIndex],
        );
        final appDocDir = await getApplicationDocumentsDirectory();
        final dir = Directory('${appDocDir.path}/recordings');
        if(dir.existsSync()) {
        }else {
          dir.create();
        }
        tempWavPath = '${dir.path}/recording${recordingFilePaths.length.toString()}.WAV';
        File(tempWavPath).deleteSync();
        recordingFilePaths.add(tempWavPath);
        await record.start(recordConfig, path: tempWavPath);
        safePrint("Recording temporarily saved in app files");
      } else {
        safePrint("Permission denied");
      }
    });

  }
  
  void goToAddRecipientsPage() {
    setState(() {
      Navigator.of(context).push(MaterialPageRoute(builder: (context) => AddRecipientsPage()));
    });
  }

  void stopRecording() async {
    safePrint("Stop Recording");
    record.stop();

    showDialog(context: context, builder: (BuildContext context) {
      return AlertDialog(
        content: Text("Do you want to send out parts of this meeting?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text("No"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              goToAddRecipientsPage();
            },
            child: Text("Yes"),
          ),
        ],
      );
    });

    // uploadWAVtoS3();
  }

  void recordPressed() {
    setState(() {
      inputSelected = true;

      isRecording = !isRecording;
      if (isRecording) {
        startRecording();
      } else {
        stopRecording();
      }

    });
  }

  void inputPressed() {

    configureInputs(true).then((_) {
      if (availableInputs.isEmpty) {
        safePrint("No audio inputs available");
        return;
      }
   
      showMenu(
        context: context,
        position: RelativeRect.fromLTRB(0, 500, 0, 0), // Adjust as needed
        items: [
          for (int index = 0; index < availableInputs.length; index++)
            PopupMenuItem<int>(
              value: index,
              child: Text(availableInputs[index].label),
            ),
        ],
      ).then((selectedIndex) {
        if (selectedIndex != null) {
          setState(() {
            currentInputIndex = selectedIndex;
            inputSelected = true;
            safePrint("Selected input: ${availableInputs[currentInputIndex].label}");
          });
        }
      });
    });

  }

  @override
  Widget build(BuildContext context) {
    return Center(child:
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(padding: EdgeInsets.all(50), child:
            SizedBox(
              width: 225,
              height: 225,
              child: ElevatedButton(
                onPressed: recordPressed,
                style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(Colors.blue),
                padding: MaterialStateProperty.all<EdgeInsets>(EdgeInsets.all(20)),
                textStyle: MaterialStateProperty.all<TextStyle>(TextStyle(fontSize: 20)),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                )),
                child: Center(child: Text(isRecording ? 'Stop Recording' : 'Start Recording', style: TextStyle(color: Colors.white, fontSize: 20)))
              ),
            ),
          ),
          Padding(padding: EdgeInsets.all(50), child:
            SizedBox(
              width: 250,
              height: 75,
              child: ElevatedButton(
                onPressed: inputPressed,
                style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(Colors.blue),
                padding: MaterialStateProperty.all<EdgeInsets>(EdgeInsets.all(20)),
                textStyle: MaterialStateProperty.all<TextStyle>(TextStyle(fontSize: 20)),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                )),
                child: Center(child: Text(inputSelected ? availableInputs[currentInputIndex].label : "Select Input", style: TextStyle(color: Colors.white, fontSize: 20)))
              ),
            ),
          )
        ]
      )
    );
  }
}
