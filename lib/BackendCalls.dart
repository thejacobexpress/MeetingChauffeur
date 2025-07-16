import 'dart:io';

// Amplify Flutter Packages
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

import 'main.dart';

import 'homePage.dart';

import 'dart:convert';

import 'package:aws_signature_v4/aws_signature_v4.dart';
import 'package:dio/dio.dart';

Future<Map<String, dynamic>> uploadJsonToS3() async {

  final Map<String, dynamic> json = {
    'location': false, // not dealt with on server end
    'summary': false,
    'transcript': true,
    'action': false,
    'decisions': false,
    'names': false,
    'topics':false,
    'purpose':false,
    'next_steps':false,
    'corrections':false,
    'questions':false
  };

  try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final dir = Directory('${appDocDir.path}/jsons');
      final int fileNumAvailable = recordingFilePaths.length;
      File file;
      if(dir.existsSync()) {
        file = File('${dir.path}/recording$fileNumAvailable.json');
        file.writeAsStringSync(jsonEncode(json));
      } else {
        dir.create();
        file = File('${dir.path}/recording$fileNumAvailable.json');
        file.writeAsStringSync(jsonEncode(json));
      }
      // safePrint(file);

      String localJsonFileName = file.path.split('/').last;
      safePrint('Uploading file: $localJsonFileName');
      final result = await Amplify.Storage.uploadFile(
          localFile: AWSFile.fromPath(file.path),
          path: StoragePath.fromString('public/jsons/$localJsonFileName'),
        ).result;
      safePrint('File uploaded: ${result.uploadedItem}');

    } on StorageException catch (e) {
      safePrint('Error uploading file: ${e.message}');
    }

    return json;
}

Future<String> generatePresignedPutUrl (String fileName) async {

  final bucket = "meetingsummarizerapp3e62d7c6d4654f17bc7d042793aca958-dev";
  final key = "public/recordings/$fileName";
  final accessKey = "";
  final secretKey = "";
  final region = "us-west-2";
  
  final serviceConfiguration = S3ServiceConfiguration();
  final awsClient = AWSCredentials(accessKey, secretKey);

  final signer = AWSSigV4Signer(
    credentialsProvider: AWSCredentialsProvider(awsClient),
  );

  final request = AWSHttpRequest.put(
    Uri.https('$bucket.s3.$region.amazonaws.com', '/$key'),
    headers: {
      'Content-Type': 'audio/wav',
    },
  );

  final signedRequest = await signer.presign(
    request,
    credentialScope: AWSCredentialScope(region: region, service: AWSService("s3")),
    serviceConfiguration: serviceConfiguration,
    expiresIn: Duration(minutes: 15),
  );

  return signedRequest.toString();
}

void uploadWAVtoS3(String path) async {

  final json = await uploadJsonToS3();

  // Ask user to select a WAV file
  if(path == "") {
    try {
      FilePickerResult? fileResult = await FilePicker.platform.pickFiles(
        dialogTitle: 'Please select a file to summarize.',
        type: FileType.custom,
        allowedExtensions: ['wav']
      );
      if (fileResult != null && fileResult.files.single.path != null) {

        File file = File(fileResult.files.single.path!);
        localAudioFileName = fileResult.files.single.name;

        // Upload the file to S3
        final result = await Amplify.Storage.uploadFile(
          localFile: AWSFile.fromPath(file.path),
          path: StoragePath.fromString('public/recordings/$localAudioFileName'),
        ).result;
        safePrint('File uploaded: ${result.uploadedItem}');

        // retrieveSummary();
      }
    } on StorageException catch (e) {
      safePrint('Error uploading file: ${e.message}');
    }
  } else {
      try {
        File file = File(path);
        localAudioFileName = file.path.split('/').last;;
        safePrint('Uploading file: $localAudioFileName with size of ${file.lengthSync()/1000000}MB');

        final dio = Dio();
        final response = await dio.put(
          await generatePresignedPutUrl(localAudioFileName),
          data: file.openRead(),
          options: Options(
            headers: {
              HttpHeaders.contentTypeHeader: 'audio/wav',
              HttpHeaders.contentLengthHeader: await file.length()
            },
            sendTimeout: Duration(seconds: 300),
            receiveTimeout: Duration(seconds: 300),
          ),
          onSendProgress: (sent, total) {
            final percent = (sent / total * 100).toStringAsFixed(1);
            print('Uploading: $percent%');
          },
        );
        safePrint("file uploaded!");

        await Future.delayed(Duration(seconds: 3));
        await retrieveFilesFromS3(json);

      } on Exception catch (e, st) {
        safePrint("error: $e");
        safePrint("Stacktrace: $st");
      }
    }
}

Future<String> downloadFileContent(String localDir, String serverDir, String type) async {
  int retries = 0;
  while(retries < 10) {
    try {
      final result = await Amplify.Storage.downloadFile(
        path: StoragePath.fromString(serverDir),
        localFile: AWSFile.fromPath(localDir + localAudioFileName.replaceAll('.WAV', '.txt')),
      ).result;
      safePrint('File downloaded: ${result.downloadedItem}');

      // Delete the summary file in the s3 after retrieving it
      final deleteResult = await Amplify.Storage.remove(
        path: StoragePath.fromString('public/summaries/${localAudioFileName.replaceAll('.WAV', '.txt')}'),
        options: StorageRemoveOptions(bucket: StorageBucket.fromBucketInfo(BucketInfo(bucketName: 'meetingsummarizerapp3e62d7c6d4654f17bc7d042793aca958-dev', region: 'us-west-2'))),
      ).result;

      File(localDir + localAudioFileName.replaceAll('.WAV', '.txt')).readAsString().then((content) {
        safePrint('$type: $content');
        return content;
      });

      break;

    } on Exception catch(e) {
      safePrint("File not ready yet.");
      await Future.delayed(Duration(seconds: 1));
      retries++;
    }
  }
  return "";
}

Future<Map<String, String>> retrieveFilesFromS3(Map<String, dynamic> json) async {
  final appDocDir = await getApplicationDocumentsDirectory();
  var localDir;
  var serverDir;
  var type;
  var canAddEntry = false;

  final Map<String, String> genList = {};

  for(final entry in json.entries) {
    canAddEntry = false;
    switch(entry.key) {
      case ("summary"):
        if (entry.value) {
          localDir = Directory('${appDocDir.path}/summaries/');
          serverDir = 'public/summaries/${localAudioFileName.replaceAll('.WAV', '.txt')}';
          type = "summary";
          if(localDir.existsSync()) {} else {
            localDir.create();
          }
          canAddEntry = true;
        }
      case ("transcript"):
        if (entry.value) {
          localDir = Directory('${appDocDir.path}/transcriptions/');
          serverDir = 'public/transcriptions/${localAudioFileName.replaceAll('.WAV', '.txt')}';
          type = "transcript";
          if(localDir.existsSync()) {} else {
            localDir.create();
          }
          canAddEntry = true;
        }
      case ("action"):
        if (entry.value) {
          localDir = Directory('${appDocDir.path}/action/');
          serverDir = 'public/action/${localAudioFileName.replaceAll('.WAV', '.txt')}';
          type = "action";
          if(localDir.existsSync()) {} else {
            localDir.create();
          }
          canAddEntry = true;
        }
      case ("decisions"):
        if (entry.value) {
          localDir = Directory('${appDocDir.path}/decisions/');
          serverDir = 'public/decisions/${localAudioFileName.replaceAll('.WAV', '.txt')}';
          type = "decisions";
          if(localDir.existsSync()) {} else {
            localDir.create();
          }
          canAddEntry = true;
        }
      case ("names"):
        if (entry.value) {
          localDir = Directory('${appDocDir.path}/names/');
          serverDir = 'public/names/${localAudioFileName.replaceAll('.WAV', '.txt')}';
          type = "names";
          if(localDir.existsSync()) {} else {
            localDir.create();
          }
          canAddEntry = true;
        }
      case ("topics"):
        if (entry.value) {
          localDir = Directory('${appDocDir.path}/topics/');
          serverDir = 'public/topics/${localAudioFileName.replaceAll('.WAV', '.txt')}';
          type = "topics";
          if(localDir.existsSync()) {} else {
            localDir.create();
          }
          canAddEntry = true;
        }
      case ("purpose"):
        if (entry.value) {
          localDir = Directory('${appDocDir.path}/purpose/');
          serverDir = 'public/purpose/${localAudioFileName.replaceAll('.WAV', '.txt')}';
          type = "purpose";
          if(localDir.existsSync()) {} else {
            localDir.create();
          }
          canAddEntry = true;
        }
      case ("next_steps"):
        if (entry.value) {
          localDir = Directory('${appDocDir.path}/next_steps/');
          serverDir = 'public/next_steps/${localAudioFileName.replaceAll('.WAV', '.txt')}';
          type = "next_steps";
          if(localDir.existsSync()) {} else {
            localDir.create();
          }
          canAddEntry = true;
        }
      case ("corrections"):
        if (entry.value) {
          localDir = Directory('${appDocDir.path}/corrections/');
          serverDir = 'public/corrections/${localAudioFileName.replaceAll('.WAV', '.txt')}';
          type = "corrections";
          if(localDir.existsSync()) {} else {
            localDir.create();
          }
          canAddEntry = true;
        }
      case ("questions"):
        if (entry.value) {
          localDir = Directory('${appDocDir.path}/questions/');
          serverDir = 'public/questions/${localAudioFileName.replaceAll('.WAV', '.txt')}';
          type = "questions";
          if(localDir.existsSync()) {} else {
            localDir.create();
          }
          canAddEntry = true;
        }
      }
    
    if(canAddEntry) {
      genList['$type'] = await downloadFileContent(localDir.path, serverDir, type);
    }

  }

  return genList;

}