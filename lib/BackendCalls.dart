import 'dart:io';

// Amplify Flutter Packages
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:location/location.dart';
import 'package:meeting_summarizer_app/classes/GroupClass.dart';
import 'package:meeting_summarizer_app/classes/IndividualClass.dart';
import 'package:meeting_summarizer_app/main_sequence/AddRecipientsPage.dart';
import 'package:meeting_summarizer_app/main_sequence/HomePage.dart';
import 'package:meeting_summarizer_app/widgets/GenerationOption.dart';
import 'package:path_provider/path_provider.dart';

import 'main.dart';

import 'dart:convert';
import 'package:meeting_summarizer_app/widgets/Generation.dart';

import 'package:aws_signature_v4/aws_signature_v4.dart';
import 'package:dio/dio.dart';

import 'package:geocoding/geocoding.dart';

const String bucket = "meetingsummarizerapp3e62d7c6d4654f17bc7d042793aca958-dev";
const String region = "us-west-2";

enum GenerationType {
  DATE_TIME('date_time', "Date and Time"), // Not dealt with on server end
  LOCATION('location', "Location"), // Not dealt with on server end
  SUMMARY('summary', "Summary"),
  TRANSCRIPT('transcript', "Transcript"),
  ACTION('action', "Action Items"),
  DECISION('decisions', "Decisions Made"),
  NAMES('names', "Names"),
  TOPICS('topics', "Topics"),
  PURPOSE('purpose', "Purpose"),
  NEXT_STEPS('next_steps', "Next Steps"),
  CORRECTIONS('corrections', "Corrections to Previous Meeting"),
  QUESTIONS('questions', "Questions Asked"),
  NONE('none', "None");

  const GenerationType(this.value, this.name);

  final String name;
  final String value;
}

Map<String, dynamic> genMap = {};
bool genListReady = false;

Future<String> getAddress(double lat, double long) async {
  String address;
  try {
    List<Placemark> placemarks = await placemarkFromCoordinates(double.parse(locationData.toString().split(':')[1].substring(1).replaceAll(", long", "")), double.parse(locationData.toString().split(':')[2].substring(1).replaceAll(">", "")));
    if (placemarks.isNotEmpty) {
      final Placemark place = placemarks.first;
      address = "${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
    } else {
      address = "No address found";
    }
  } on Exception catch (e) {
    address = "Error: $e";
  }
  return address;
}

Future<Map<String, dynamic>> uploadJsonToS3(String fileName, Map<String, dynamic> json) async {

  try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final dir = Directory('${appDocDir.path}/jsons');
      File file;
      if(dir.existsSync()) {
        file = File('${dir.path}/$fileName.json');
        file.writeAsStringSync(jsonEncode(json));
      } else {
        dir.create();
        file = File('${dir.path}/$fileName.json');
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

  final key = "public/recordings/$fileName";
  final accessKey = "";
  final secretKey = "";
  
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

void uploadWAVtoS3(String path, Map<String, dynamic> json) async {

  final newJson = await uploadJsonToS3(path.split("/").last.replaceAll(".WAV", ""), json);

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

        bool uploadSucceeded = false;
        int retries = 0;
        while(retries<10) {
          try {
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
            uploadSucceeded = true;
            safePrint("file uploaded!");
            break;
          } on DioException catch (e) {
            retries++;
            print("failed to upload: $e");
          }
        }
        if(!uploadSucceeded) {
          safePrint("Sorry, MeetingSummarizer could not process your file. Please try again.");
        }

        await Future.delayed(Duration(seconds: 3));
        Map<String, dynamic> responses = await retrieveDataFromS3AndLocal(newJson);

        // await sendEmail(responses);

      } on Exception catch (e) {
        safePrint("error: $e");
      }
    }
}

Future<String> downloadFileContent(String localDir, String serverDir, String type) async {
  int retries = 0;
  while(retries < 100) {
    try {
      final result = await Amplify.Storage.downloadFile(
        path: StoragePath.fromString(serverDir),
        localFile: AWSFile.fromPath(localDir + localAudioFileName.replaceAll('.WAV', '.txt')),
      ).result;
      safePrint('File downloaded: ${result.downloadedItem}');

      bool s3FileExists = true;
      while(s3FileExists) {
        // Delete the file in the s3 after retrieving it
        final deleteResult = await Amplify.Storage.remove(
          path: StoragePath.fromString(serverDir),
          options: StorageRemoveOptions(bucket: StorageBucket.fromBucketInfo(BucketInfo(bucketName: bucket, region: region))),
        ).result;

        String parentServerDir;
        List<String> list = serverDir.split('/');
        list.removeAt(list.length-1);
        parentServerDir = "${list.join("/")}/";
        safePrint("parentServerDir: $parentServerDir");
        safePrint("bucket: $bucket");
        safePrint("region: $region");
        safePrint("s3 file deleted: ${deleteResult.removedItem}");
        final result = await Amplify.Storage.list(
          path: StoragePath.fromString(parentServerDir),
          options: StorageListOptions(
            bucket: StorageBucket.fromBucketInfo(BucketInfo(bucketName: bucket, region: region)),
            pluginOptions: S3ListPluginOptions.listAll()
          )
        ).result;

        safePrint("items in s3 path: ${result.items}");

        if(result.items.isEmpty) {
          s3FileExists = false;
          safePrint("broke from deleting loop!!!");
        }

      }

      final content = await File(localDir + localAudioFileName.replaceAll('.WAV', '.txt')).readAsString();
      safePrint('$type: $content');
      return content;

    } on Exception catch(e) {
      safePrint("File not generated yet.");
      await Future.delayed(Duration(seconds: 2));
      retries++;
      if(retries==10) {
        safePrint("could not obtain file.");
      }
    }
  }
  return "";
}

Future<Map<String, dynamic>> retrieveDataFromS3AndLocal(Map<String, dynamic> json) async {
  final appDocDir = await getApplicationDocumentsDirectory();
  var localDir;
  var serverDir;
  GenerationType type = GenerationType.NONE;
  var canAddEntry = false;

  // Get all contacts from recipients list and put them into genMap to send to API Gateway.
  List<String> emails = [];
  for(final recipient in recipients) {
    if(recipient is IndividualClass) {
      emails.add(recipient.contact);
    } else if (recipient is GroupClass){
      for(final individual in recipient.individuals) {
        emails.add(individual.contact);
      }
    }
  }
  genMap["recipients"] = emails;

  for(final entry in json.entries) {
    canAddEntry = false;
    switch(entry.key) {
      case("date_time"):
        if(entry.value) {
          type = GenerationType.DATE_TIME;
          canAddEntry = true;
        }
      case("location"):
        if(entry.value) {
          type = GenerationType.LOCATION;
          canAddEntry = true;
        }
      case ("summary"):
        if (entry.value) {
          localDir = Directory('${appDocDir.path}/summaries/');
          serverDir = 'public/summaries/${localAudioFileName.replaceAll('.WAV', '.txt')}';
          type = GenerationType.SUMMARY;
          if(localDir.existsSync()) {} else {
            localDir.create();
          }
          canAddEntry = true;
        }
      case ("transcript"):
        if (entry.value) {
          localDir = Directory('${appDocDir.path}/transcriptions/');
          serverDir = 'public/transcriptions/${localAudioFileName.replaceAll('.WAV', '.txt')}';
          type = GenerationType.TRANSCRIPT;
          if(localDir.existsSync()) {} else {
            localDir.create();
          }
          canAddEntry = true;
        }
      case ("action"):
        if (entry.value) {
          localDir = Directory('${appDocDir.path}/action/');
          serverDir = 'public/action/${localAudioFileName.replaceAll('.WAV', '.txt')}';
          type = GenerationType.ACTION;
          if(localDir.existsSync()) {} else {
            localDir.create();
          }
          canAddEntry = true;
        }
      case ("decisions"):
        if (entry.value) {
          localDir = Directory('${appDocDir.path}/decisions/');
          serverDir = 'public/decisions/${localAudioFileName.replaceAll('.WAV', '.txt')}';
          type = GenerationType.DECISION;
          if(localDir.existsSync()) {} else {
            localDir.create();
          }
          canAddEntry = true;
        }
      case ("names"):
        if (entry.value) {
          localDir = Directory('${appDocDir.path}/names/');
          serverDir = 'public/names/${localAudioFileName.replaceAll('.WAV', '.txt')}';
          type = GenerationType.NAMES;
          if(localDir.existsSync()) {} else {
            localDir.create();
          }
          canAddEntry = true;
        }
      case ("topics"):
        if (entry.value) {
          localDir = Directory('${appDocDir.path}/topics/');
          serverDir = 'public/topics/${localAudioFileName.replaceAll('.WAV', '.txt')}';
          type = GenerationType.TOPICS;
          if(localDir.existsSync()) {} else {
            localDir.create();
          }
          canAddEntry = true;
        }
      case ("purpose"):
        if (entry.value) {
          localDir = Directory('${appDocDir.path}/purpose/');
          serverDir = 'public/purpose/${localAudioFileName.replaceAll('.WAV', '.txt')}';
          type = GenerationType.PURPOSE;
          if(localDir.existsSync()) {} else {
            localDir.create();
          }
          canAddEntry = true;
        }
      case ("next_steps"):
        if (entry.value) {
          localDir = Directory('${appDocDir.path}/next_steps/');
          serverDir = 'public/next_steps/${localAudioFileName.replaceAll('.WAV', '.txt')}';
          type = GenerationType.NEXT_STEPS;
          if(localDir.existsSync()) {} else {
            localDir.create();
          }
          canAddEntry = true;
        }
      case ("corrections"):
        if (entry.value) {
          localDir = Directory('${appDocDir.path}/corrections/');
          serverDir = 'public/corrections/${localAudioFileName.replaceAll('.WAV', '.txt')}';
          type = GenerationType.CORRECTIONS;
          if(localDir.existsSync()) {} else {
            localDir.create();
          }
          canAddEntry = true;
        }
      case ("questions"):
        if (entry.value) {
          localDir = Directory('${appDocDir.path}/questions/');
          serverDir = 'public/questions/${localAudioFileName.replaceAll('.WAV', '.txt')}';
          type = GenerationType.QUESTIONS;
          if(localDir.existsSync()) {} else {
            localDir.create();
          }
          canAddEntry = true;
        }
      }

    if((entry.key == GenerationType.DATE_TIME.value || entry.key == GenerationType.LOCATION.value) && canAddEntry) {
      switch(entry.key) {
        case ("date_time"):
          genMap[type.value] = "${startTime.month}/${startTime.day}/${startTime.year} - Meeting lasted from ${startTime.hour > 12 ? startTime.hour - 12 : startTime.hour}:${startTime.minute < 10 ? "0${startTime.minute.toString()}" : startTime.minute} to ${endTime.hour > 12 ? endTime.hour - 12 : endTime.hour}:${endTime.minute < 10 ? "0${endTime.minute.toString()}" : endTime.minute}";
        case ("location"):
          double lat = double.parse(locationData.toString().split(':')[1].substring(1).replaceAll(", long", ""));
          double long = double.parse(locationData.toString().split(':')[2].substring(1).replaceAll(">", ""));
          String address = await getAddress(lat, long);
          genMap[type.value] = address.replaceAll(", , ", ", ");
      }
    } else if(canAddEntry) {
      genMap[type.value] = await downloadFileContent(localDir.path, serverDir, type.value);
    }

  }

  initGenDisplayed();
  genListReady = true;
  safePrint("genList: $genMap");
  return genMap;

}

// Returns status code
Future<int> sendEmail(Map<String, dynamic> content) async {
  final res = Amplify.API.post(
    "/sendEmails",
    apiName: "MeetingSummarizerAPI",
    body: HttpPayload.json(content)
  );
  final response = await res.response;
  return response.statusCode;
}