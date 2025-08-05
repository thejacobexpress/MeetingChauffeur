import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:meeting_summarizer_app/main_sequence/AddRecipientsPage.dart';
import 'package:location/location.dart';
import 'package:meeting_summarizer_app/classes/Recipient.dart';

/// Name (not the path) of the current/latest local audio file being used to create generations, send emails, etc.
/// 
/// This is a string ending in ".m4a".
var localAudioFileName;

/// List of all the local audio files that have been recorded.
List<String> recordingFilePaths = List.empty(growable: true); // Assumes that the last m4a is the current m4a

/// Start time of the current/latest recording.
DateTime startTime = DateTime(DateTime.now().year);

/// End time of the current/latest recording.
DateTime endTime = DateTime(DateTime.now().year);

/// A ```Future<LocationData>``` variable that holds the location data of the current/latest recording.
var locationData;

class MyHomePage extends StatefulWidget {

  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  bool isRecording = false;
  int currentInputIndex = 0;
  List<InputDevice> availableInputs = List.empty(growable: true);
  bool inputSelected = false;
  final record = AudioRecorder();

  /// The local path of the current/latest recording in m4a format.
  String tempm4aPath = "";

  /// Loads all of the available audio inputs into the ```availableInputs``` list.
  /// 
  /// If [checkMissing] is true, the function will check if the last audio input used is now missing. If it is missing, it will reset ```currentInputIndex``` to 0. If it is not, the function will find the index of the last audio input used and set ```currentInputIndex``` to that index.
  ///
  /// If [checkMissing] is false, it will simply load all available inputs without checking for missing audio inputs and keep ```currentInputIndex``` at its current value.
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

  /// Gets the current location of the device using the ```location``` package.
  void getLocation() async {
    Location location = Location();

    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    locationData = await location.getLocation();
  }

  @override
  initState() {
    super.initState();

    configureInputs(false);
    setState(() {
      currentInputIndex = 0;
    });
    recipients = <Recipient>[];
  }

  /// Starts writing the recording to a m4a file in the local storage with name defined by ```localAudioFileName``` and path defined by ```tempm4aPath```.
  void startRecording() {

    startTime = DateTime.now();
    getLocation();

    configureInputs(true).then((_) async {
      if (await record.hasPermission()) {
        // Start recording
        RecordConfig recordConfig = RecordConfig(
          sampleRate: 44100,
          bitRate: 128000,
          numChannels: 2,
          encoder: AudioEncoder.aacLc,
          device: availableInputs[currentInputIndex],
        );
        final appDocDir = await getApplicationDocumentsDirectory();
        final dir = Directory('${appDocDir.path}/recordings');
        if(dir.existsSync()) {
        } else {
          dir.create();
        }
        tempm4aPath = '${dir.path}/recording${recordingFilePaths.length.toString()}.m4a';
        try{
          File(tempm4aPath).deleteSync();
        } on PathNotFoundException {}
        recordingFilePaths.add(tempm4aPath);
        await record.start(recordConfig, path: tempm4aPath);
        safePrint("Recording being written to $tempm4aPath");
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

  /// Stops the recording and shows a dialog asking the user if they want to continue with sending the recording.
  /// 
  /// If they choose "Yes", it will navigate to the ```AddRecipientsPage.dart```.
  /// If they choose "No", it will simply close the dialog and do nothing.
  void stopRecording() async {
    safePrint("Stop Recording");
    record.stop();

    endTime = DateTime.now();

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

    // uploadM4aToS3();
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

  /// Calls ```configureInputs``` before opening a popup menu to select an audio input from the list of available inputs.
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
