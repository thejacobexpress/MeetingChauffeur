import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

// Amplify Flutter Packages
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';

// Generated in previous step
import 'amplifyconfiguration.dart';

import 'package:http/http.dart' as http;

import 'package:record/record.dart';

import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  @override
  initState() {
    super.initState();
    _configureAmplify();
  }

  Future<void> _configureAmplify() async {

    // Add any Amplify plugins you want to use
    final authPlugin = AmplifyAuthCognito();
    final api = AmplifyAPI();
    final storage = AmplifyStorageS3();
    await Amplify.addPlugin(authPlugin);
    await Amplify.addPlugin(api);
    await Amplify.addPlugin(storage);

    // Once Plugins are added, configure Amplify
    // Note: Amplify can only be configured once.
    try {
      await Amplify.configure(amplifyconfig);
      print('Successfully configured Amplify 🎉');
    } on AmplifyAlreadyConfiguredException {
      safePrint("Tried to reconfigure Amplify; this can occur when your app restarts on Android.");
    }
  }

  final record = AudioRecorder();
  final tempWavPath = "/Users/jacobmckee/VSCode Projects/meeting_summarizer_app/lib/recording.WAV";

  void startRecording() async {

    if (await record.hasPermission()) {
      // Start recording
      const RecordConfig recordConfig = RecordConfig(
        sampleRate: 44100,
        bitRate: 128000,
        numChannels: 2,
        encoder: AudioEncoder.pcm16bits
      );
      await record.start(recordConfig, path: tempWavPath);
      print("Recording temporarily saved in app files");
    } else {
      print("Permission denied");
    }
  
  }

  void stopRecording() async {
    print("Stop Recording");
    record.stop();
    // Save the wav file more permanently inside of file of the users choosing
    final params = SaveFileDialogParams(sourceFilePath: tempWavPath);
    await FlutterFileDialog.saveFile(params: params);
    print("Recording saved to user selected location");
    uploadWAVtoS3();
  }

  void uploadWAVtoS3() async {
    // Ask user to select a WAV file
    try {
      FilePickerResult? fileResult = await FilePicker.platform.pickFiles(
        dialogTitle: 'Please select a file to summarize.',
        type: FileType.custom,
        allowedExtensions: ['wav']
      );
      if (fileResult != null && fileResult.files.single.path != null) {

        File file = File(fileResult.files.single.path!);
        String fileName = fileResult.files.single.name;

        // Upload the file to S3
        final result = await Amplify.Storage.uploadFile(
          localFile: AWSFile.fromPath(file.path),
          path: StoragePath.fromString('public/$fileName'),
        ).result;
        print('File uploaded: ${result.uploadedItem}');
      }
    } on StorageException catch (e) {
      print('Error uploading file: ${e.message}');
    }
  }

  // void generateSummary() async {
  //   try{
  //     final url = Uri.parse('https://b8ksadjzqa.execute-api.us-west-2.amazonaws.com/default/generateSummary-dev');
  //     final response = await http.post(
  //       url,
  //       headers: {
  //         'Content-Type': 'application/json'
  //       },
  //       body: jsonEncode({'transcript':'wordsa'}),
  //     );
  //     print("Code: ${response.body.toString()}");
  //     } on ApiException catch (e) {
  //       print(e);
  //     }
  // }

  int _counter = 0;
  bool isRecording = false;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.

      isRecording = !isRecording;
      if (isRecording) {
        startRecording();
      } else {
        stopRecording();
        // uploadWAVtoS3();
        // Pipe S3 event to SQS
        // have SQS call generateSummary lambda function
        // get summary from lambda function????
      }

      // generateSummary();

      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
