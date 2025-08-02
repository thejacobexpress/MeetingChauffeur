import 'dart:io';

// Amplify Flutter Packages
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:location/location.dart';
import 'package:meeting_summarizer_app/classes/GroupClass.dart';
import 'package:meeting_summarizer_app/classes/IndividualClass.dart';
import 'package:meeting_summarizer_app/classes/Recipient.dart';
import 'package:meeting_summarizer_app/main_sequence/AddGenerationsPage.dart';
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

List<GenerationType> nonTailorable = [
  GenerationType.DATE_TIME,
  GenerationType.LOCATION,
  GenerationType.TRANSCRIPT,
  GenerationType.NAMES,
  GenerationType.PURPOSE
];

List<String> nonTailorableStrings = [
  GenerationType.DATE_TIME.value,
  GenerationType.LOCATION.value,
  GenerationType.TRANSCRIPT.value,
  GenerationType.NAMES.value,
  GenerationType.PURPOSE.value
];

String bucket = "meetingsummarizerapp3e62d7c6d4654f17bc7d042793aca958-dev";
String region = "us-west-2";

// Map of contacts as keys and their generation names as values surrounding a map with values of the generations.
Map<String, Map<String, dynamic>> genMap = {};

bool genListReady = false;

List<String> emails = [];

void initGenDisplayed() {
  genDisplayed.clear();
  for(final entry in genMap.entries) {
    for(final type in genMap[entry.key]!.keys) {
      if(!nonTailorable.contains(GenerationType.values.firstWhere((e) => e.value == type, orElse: () => GenerationType.NONE))) {
        genDisplayed[entry.key] = {};
        genDisplayed[entry.key]![type] = false;
      } else {
        genDisplayed["General"] = {};
        genDisplayed["General"]![type] = false;
      }
    }
  }
}

IndividualClass? getIndividualByEmail(String email) {
  for(final recipient in recipients) {
    if(recipient is IndividualClass && recipient.contact == email) {
      return recipient;
    } else if (recipient is GroupClass) {
      for(final individual in recipient.individuals) {
        if(individual.contact == email) {
          return individual;
        }
      }
    }
  }
  return null;
}

List<String> getEmails() {
  emails = [];
  for(final recipient in recipients) {
    if(recipient is IndividualClass) {
      emails.add(recipient.contact);
    } else if (recipient is GroupClass){
      for(final individual in recipient.individuals) {
        emails.add(individual.contact);
      }
    }
  }
  return emails;
}

String removeSpecialChars(String input) {
  String newText = "";
  for(final char in input.split("")) {
    if(char != "." && char != "@") {
      newText += char;
    }
  }
  return newText;
}

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

bool infolessRecipientExists() {
  for(final recipient in recipients) {
    if(recipient is IndividualClass && (recipient.info == null || recipient.info == "")) {
      return true;
    } else if (recipient is GroupClass) {
      for(final individual in recipient.individuals) {
        if(individual.info == null || individual.info == "") {
          return true;
        }
      }
    }
  }
  return false;
}

bool infolessRecipientExistsOutsideGroup() {
  for(final recipient in recipients) {
    if(recipient is IndividualClass) {
      if(recipient.info == "" && recipient.getGroups().isEmpty) {
        return true;
      }
    }
  }
  return false;
}

String getMeetingTimeString(DateTime startTime, DateTime endTime) {
  String startTimeString = "";
  String endTimeString = "";
  if(startTime.hour > 12) {
    startTimeString = "${startTime.hour - 12}:${startTime.minute < 10 ? "0${startTime.minute.toString()}" : startTime.minute} PM";
  } else {
    startTimeString = "${startTime.hour}:${startTime.minute < 10 ? "0${startTime.minute.toString()}" : startTime.minute} AM";
  }
  if(endTime.hour > 12) {
    endTimeString = "${endTime.hour - 12}:${endTime.minute < 10 ? "0${endTime.minute.toString()}" : endTime.minute} PM";
  } else {
    endTimeString = "${endTime.hour}:${endTime.minute < 10 ? "0${endTime.minute.toString()}" : endTime.minute} AM";
  }
  return "Meeting lasted from $startTimeString to $endTimeString";
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

Future<void> uploadTailorJson(Map<String, dynamic> json) async {
  //Deterine if user wants generations to be tailored to recipients using the 'tailored' key in the json,
  // if so, then add the recipients' info to a new json object that will be sent to the API Gateway.
  if(json['tailored'] != null) {
    json['tailored'] = json['tailored'] ? true : false;
    safePrint("Tailored: ${json['tailored']}");
    if(json['tailored']) {
      Map<String, String> tailoredMap = {};
      for(final email in getEmails()) {
        for(final recipient in recipients) {
          if(recipient is IndividualClass && recipient.contact == email && !tailoredMap.containsKey(recipient.contact)) {
            List<String> groupInfo = [];
            for(final group in recipient.getGroups()) {
              safePrint("Group that ${recipient.name} is in: ${group.name}");
              groupInfo.add("${group.name}: ${group.info}");
            }
            String groupInfoString = recipient.getGroups().isEmpty ? "" : " This person is involved with these groups: ${recipient.getGroups().map((group) => group.name).join(", ")}. Details about each group this individual is involved in: ${groupInfo.join(", ")}.";
            tailoredMap[email] = "${recipient.info}$groupInfoString";
            break;
          } else if (recipient is GroupClass) {
            for(final individual in recipient.individuals) {
              if(individual.contact == email && !tailoredMap.containsKey(individual.contact)) {
                List<String> groupInfo = [];
                for(final group in individual.groupsList) {
                  groupInfo.add("${group.name}: ${group.info}");
                }
                String groupInfoString = individual.getGroups().isEmpty ? "" : " This person is involved with these groups: ${individual.getGroups().map((group) => group.name).join(", ")}. Details about each group this individual is involved in: ${groupInfo.join(", ")}.";
                tailoredMap[email] = "${recipient.info}$groupInfoString";
                break;
              }
            }
          }
        }
      }
      safePrint("Tailored Map: $tailoredMap");
      await uploadJsonToS3("recording${recordingFilePaths.length-1}_tailor", tailoredMap);
    }
  }
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

  // Upload the tailor json to S3 if the user has selected the tailored option.
  if(json['tailored'] != null && json['tailored']) {
    await uploadTailorJson(json);
  }

  // Upload the json that contains user selected generation specifications to S3 with the name of the recording file.
  final newJson = await uploadJsonToS3(path.split("/").last.replaceAll(".WAV", ""), json);

  // Ask user to select a WAV file if no path is provided.
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
        // await retrieveDataFromS3AndLocal(newJson);

        // await sendEmail(responses);

      } on Exception catch (e) {
        safePrint("error: $e");
      }
    }
}

Future<String> downloadFileContent(String localDir, String serverDir, String type) async {
  int retries = 0;
  while(retries < 10) {
    try {
      final result = await Amplify.Storage.downloadFile(
        path: StoragePath.fromString(serverDir),
        localFile: AWSFile.fromPath(localDir),
      ).result;
      safePrint('File downloaded: ${result.downloadedItem}');

      // Delete the file in the s3 after retrieving it
      bool deletedFile = false;
      for(int i = 0; i < 10; i++) {
        final deleteResult = await Amplify.Storage.remove(
          path: StoragePath.fromString(serverDir),
          options: StorageRemoveOptions(bucket: StorageBucket.fromBucketInfo(BucketInfo(bucketName: bucket, region: region))),
        ).result;

        String parentServerDir;
        List<String> list = serverDir.split('/');
        list.removeAt(list.length-1);
        parentServerDir = "${list.join("/")}/";
        try{
          final result = await Amplify.Storage.list(
            path: StoragePath.fromString(parentServerDir),
            options: StorageListOptions(
              bucket: StorageBucket.fromBucketInfo(BucketInfo(bucketName: bucket, region: region)),
              pluginOptions: S3ListPluginOptions.listAll()
            )
          ).result;

          if(result.items.isEmpty) {
            deletedFile = true;
            break;
          }
          
        } on StorageException catch(e) {
          safePrint("error listing items in s3: $e");
        }
      }

      if(!deletedFile) {
        safePrint("File could not be deleted from s3: $serverDir");
      } else {
        safePrint("File successfully deleted from s3: $serverDir");
      }

      final content = await File(localDir).readAsString();
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

Future<Map<String, Map<String, dynamic>>> retrieveDataFromS3AndLocal(Map<String, dynamic> json) async {
  final appDocDir = await getApplicationDocumentsDirectory();
  var localParentDir;
  var localDir;
  var serverDir;
  GenerationType type = GenerationType.NONE;
  var canAddEntry = false;
  bool downloadedGeneral = false;

  // Initialize the map for general generations (generations that are not tailored to recipients)
  genMap["General"] = {};
  
  // Check if a general generation is requested
  if ((json['tailored'] != null && !json['tailored']) || (infolessRecipientExists() && !downloadedGeneral)) {
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
            localParentDir = Directory('${appDocDir.path}/summaries/');
            localDir = Directory('${appDocDir.path}/summaries/${localAudioFileName.replaceAll('.WAV', '.txt')}');
            serverDir = 'public/summaries/${localAudioFileName.replaceAll('.WAV', '.txt')}';
            type = GenerationType.SUMMARY;
            if(localParentDir.existsSync()) {} else {
              localParentDir.create();
            }
            canAddEntry = true;
          }
        case ("transcript"):
          if (entry.value) {
            localParentDir = Directory('${appDocDir.path}/transcriptions/');
            localDir = Directory('${appDocDir.path}/transcriptions/${localAudioFileName.replaceAll('.WAV', '.txt')}');
            serverDir = 'public/transcriptions/${localAudioFileName.replaceAll('.WAV', '.txt')}';
            type = GenerationType.TRANSCRIPT;
            if(localParentDir.existsSync()) {} else {
              localParentDir.create();
            }
            canAddEntry = true;
          }
        case ("action"):
          if (entry.value) {
            localParentDir = Directory('${appDocDir.path}/action/');
            localDir = Directory('${appDocDir.path}/action/${localAudioFileName.replaceAll('.WAV', '.txt')}');
            serverDir = 'public/action/${localAudioFileName.replaceAll('.WAV', '.txt')}';
            type = GenerationType.ACTION;
            if(localParentDir.existsSync()) {} else {
              localParentDir.create();
            }
            canAddEntry = true;
          }
        case ("decisions"):
          if (entry.value) {
            localParentDir = Directory('${appDocDir.path}/decisions/');
            localDir = Directory('${appDocDir.path}/decisions/${localAudioFileName.replaceAll('.WAV', '.txt')}');
            serverDir = 'public/decisions/${localAudioFileName.replaceAll('.WAV', '.txt')}';
            type = GenerationType.DECISION;
            if(localParentDir.existsSync()) {} else {
              localParentDir.create();
            }
            canAddEntry = true;
          }
        case ("names"):
          if (entry.value) {
            localParentDir = Directory('${appDocDir.path}/names/');
            localDir = Directory('${appDocDir.path}/names/${localAudioFileName.replaceAll('.WAV', '.txt')}');
            serverDir = 'public/names/${localAudioFileName.replaceAll('.WAV', '.txt')}';
            type = GenerationType.NAMES;
            if(localParentDir.existsSync()) {} else {
              localParentDir.create();
            }
            canAddEntry = true;
          }
        case ("topics"):
          if (entry.value) {
            localParentDir = Directory('${appDocDir.path}/topics/');
            localDir = Directory('${appDocDir.path}/topics/${localAudioFileName.replaceAll('.WAV', '.txt')}');
            serverDir = 'public/topics/${localAudioFileName.replaceAll('.WAV', '.txt')}';
            type = GenerationType.TOPICS;
            if(localParentDir.existsSync()) {} else {
              localParentDir.create();
            }
            canAddEntry = true;
          }
        case ("purpose"):
          if (entry.value) {
            localParentDir = Directory('${appDocDir.path}/purpose/');
            localDir = Directory('${appDocDir.path}/purpose/${localAudioFileName.replaceAll('.WAV', '.txt')}');
            serverDir = 'public/purpose/${localAudioFileName.replaceAll('.WAV', '.txt')}';
            type = GenerationType.PURPOSE;
            if(localParentDir.existsSync()) {} else {
              localParentDir.create();
            }
            canAddEntry = true;
          }
        case ("next_steps"):
          if (entry.value) {
            localParentDir = Directory('${appDocDir.path}/next_steps/');
            localDir = Directory('${appDocDir.path}/next_steps/${localAudioFileName.replaceAll('.WAV', '.txt')}');
            serverDir = 'public/next_steps/${localAudioFileName.replaceAll('.WAV', '.txt')}';
            type = GenerationType.NEXT_STEPS;
            if(localParentDir.existsSync()) {} else {
              localParentDir.create();
            }
            canAddEntry = true;
          }
        case ("corrections"):
          if (entry.value) {
            localParentDir = Directory('${appDocDir.path}/corrections/');
            localDir = Directory('${appDocDir.path}/corrections/${localAudioFileName.replaceAll('.WAV', '.txt')}');
            serverDir = 'public/corrections/${localAudioFileName.replaceAll('.WAV', '.txt')}';
            type = GenerationType.CORRECTIONS;
            if(localParentDir.existsSync()) {} else {
              localParentDir.create();
            }
            canAddEntry = true;
          }
        case ("questions"):
          if (entry.value) {
            localParentDir = Directory('${appDocDir.path}/questions/');
            localDir = Directory('${appDocDir.path}/questions/${localAudioFileName.replaceAll('.WAV', '.txt')}');
            serverDir = 'public/questions/${localAudioFileName.replaceAll('.WAV', '.txt')}';
            type = GenerationType.QUESTIONS;
            if(localParentDir.existsSync()) {} else {
              localParentDir.create();
            }
            canAddEntry = true;
          }
        }

        if((entry.key == GenerationType.DATE_TIME.value || entry.key == GenerationType.LOCATION.value) && canAddEntry) {
          switch(entry.key) {
            case ("date_time"):
              genMap["General"]![entry.key] = "${startTime.month}/${startTime.day}/${startTime.year} - ${getMeetingTimeString(startTime, endTime)}";
            case ("location"):
              double lat = double.parse(locationData.toString().split(':')[1].substring(1).replaceAll(", long", ""));
              double long = double.parse(locationData.toString().split(':')[2].substring(1).replaceAll(">", ""));
              String address = await getAddress(lat, long);
              genMap["General"]![entry.key] = address.replaceAll(", , ", ", ");
          }
        } else if(canAddEntry) {
          genMap["General"]![type.value] = await downloadFileContent(localDir.path, serverDir, type.value);
        }
      }
      downloadedGeneral = true;
    }
    if (json['tailored'] != null && json['tailored']) {

      int iteration = 0;

      bool changeDownloadedGeneralSoon = false;

      for(final email in getEmails()) {

        iteration++;
        
        // Initialize the map for each recipient
        genMap[email] = {};

        // Check if the recipient has info, if there is no info AND there was already general generations downloaded, then skip to the next recipient.
        try {
          if(getIndividualByEmail(email)!.info == "" && getIndividualByEmail(email)!.getGroups().isEmpty && downloadedGeneral) {
            genMap[email] = genMap["General"]!;
            continue;
          }
        } on Exception catch(e) {
          safePrint("error: $e");
        }

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
                localParentDir = Directory('${appDocDir.path}/summaries/');
                localDir = Directory('${appDocDir.path}/summaries/${localAudioFileName.replaceAll('.WAV', '_${removeSpecialChars(email)}.txt')}');
                serverDir = 'public/summaries/${localAudioFileName.replaceAll('.WAV', '_${removeSpecialChars(email)}.txt')}';
                type = GenerationType.SUMMARY;
                if(localParentDir.existsSync()) {} else {
                  localParentDir.create();
                }
                canAddEntry = true;
              }
            case ("transcript"):
              if (entry.value) {
                localParentDir = Directory('${appDocDir.path}/transcriptions/');
                localDir = Directory('${appDocDir.path}/transcriptions/${localAudioFileName.replaceAll('.WAV', '_${removeSpecialChars(email)}.txt')}');
                serverDir = 'public/transcriptions/${localAudioFileName.replaceAll('.WAV', '.txt')}';
                type = GenerationType.TRANSCRIPT;
                if(localParentDir.existsSync()) {} else {
                  localParentDir.create();
                }
                canAddEntry = true;
              }
            case ("action"):
              if (entry.value) {
                localParentDir = Directory('${appDocDir.path}/action/');
                localDir = Directory('${appDocDir.path}/action/${localAudioFileName.replaceAll('.WAV', '_${removeSpecialChars(email)}.txt')}');
                serverDir = 'public/action/${localAudioFileName.replaceAll('.WAV', '_${removeSpecialChars(email)}.txt')}';
                type = GenerationType.ACTION;
                if(localParentDir.existsSync()) {} else {
                  localParentDir.create();
                }
                canAddEntry = true;
              }
            case ("decisions"):
              if (entry.value) {
                localParentDir = Directory('${appDocDir.path}/decisions/');
                localDir = Directory('${appDocDir.path}/decisions/${localAudioFileName.replaceAll('.WAV', '_${removeSpecialChars(email)}.txt')}');
                serverDir = 'public/decisions/${localAudioFileName.replaceAll('.WAV', '_${removeSpecialChars(email)}.txt')}';
                type = GenerationType.DECISION;
                if(localParentDir.existsSync()) {} else {
                  localParentDir.create();
                }
                canAddEntry = true;
              }
            case ("names"):
              if (entry.value) {
                localParentDir = Directory('${appDocDir.path}/names/');
                localDir = Directory('${appDocDir.path}/names/${localAudioFileName.replaceAll('.WAV', '_${removeSpecialChars(email)}.txt')}'); 
                serverDir = 'public/names/${localAudioFileName.replaceAll('.WAV', '.txt')}';
                type = GenerationType.NAMES;
                if(localParentDir.existsSync()) {} else {
                  localParentDir.create();
                }
                canAddEntry = true;
              }
            case ("topics"):
              if (entry.value) {
                localParentDir = Directory('${appDocDir.path}/topics/');
                localDir = Directory('${appDocDir.path}/topics/${localAudioFileName.replaceAll('.WAV', '_${removeSpecialChars(email)}.txt')}');
                serverDir = 'public/topics/${localAudioFileName.replaceAll('.WAV', '_${removeSpecialChars(email)}.txt')}';
                type = GenerationType.TOPICS;
                if(localParentDir.existsSync()) {} else {
                  localParentDir.create();
                }
                canAddEntry = true;
              }
            case ("purpose"):
              if (entry.value) {
                localParentDir = Directory('${appDocDir.path}/purpose/');
                localDir = Directory('${appDocDir.path}/purpose/${localAudioFileName.replaceAll('.WAV', '_${removeSpecialChars(email)}.txt')}');
                serverDir = 'public/purpose/${localAudioFileName.replaceAll('.WAV', '.txt')}';
                type = GenerationType.PURPOSE;
                if(localParentDir.existsSync()) {} else {
                  localParentDir.create();
                }
                canAddEntry = true;
              }
            case ("next_steps"):
              if (entry.value) {
                localParentDir = Directory('${appDocDir.path}/next_steps/');
                localDir = Directory('${appDocDir.path}/next_steps/${localAudioFileName.replaceAll('.WAV', '_${removeSpecialChars(email)}.txt')}');
                serverDir = 'public/next_steps/${localAudioFileName.replaceAll('.WAV', '_${removeSpecialChars(email)}.txt')}';
                type = GenerationType.NEXT_STEPS;
                if(localParentDir.existsSync()) {} else {
                  localParentDir.create();
                }
                canAddEntry = true;
              }
            case ("corrections"):
              if (entry.value) {
                localParentDir = Directory('${appDocDir.path}/corrections/');
                localDir = Directory('${appDocDir.path}/corrections/${localAudioFileName.replaceAll('.WAV', '_${removeSpecialChars(email)}.txt')}');
                serverDir = 'public/corrections/${localAudioFileName.replaceAll('.WAV', '_${removeSpecialChars(email)}.txt')}';
                type = GenerationType.CORRECTIONS;
                if(localParentDir.existsSync()) {} else {
                  localParentDir.create();
                }
                canAddEntry = true;
              }
            case ("questions"):
              if (entry.value) {
                localParentDir = Directory('${appDocDir.path}/questions/');
                localDir = Directory('${appDocDir.path}/questions/${localAudioFileName.replaceAll('.WAV', '_${removeSpecialChars(email)}.txt')}');
                serverDir = 'public/questions/${localAudioFileName.replaceAll('.WAV', '_${removeSpecialChars(email)}.txt')}';
                type = GenerationType.QUESTIONS;
                if(localParentDir.existsSync()) {} else {
                  localParentDir.create();
                }
                canAddEntry = true;
              }
          }
          if((entry.key == GenerationType.DATE_TIME.value || entry.key == GenerationType.LOCATION.value) && canAddEntry) {
            switch(entry.key) {
              case ("date_time"):
                if (iteration > 1) {
                  genMap[email]![type.value] = genMap["General"]![type.value];
                } else {
                 genMap[email]![type.value] = genMap["General"]![entry.key] = "${startTime.month}/${startTime.day}/${startTime.year} - ${getMeetingTimeString(startTime, endTime)}";
                }
              case ("location"):
                if (iteration > 1) {
                  genMap[email]![type.value] = genMap["General"]![type.value];
                } else {
                  double lat = double.parse(locationData.toString().split(':')[1].substring(1).replaceAll(", long", ""));
                  double long = double.parse(locationData.toString().split(':')[2].substring(1).replaceAll(">", ""));
                  String address = await getAddress(lat, long);
                  genMap[email]![type.value] = genMap["General"]![entry.key] = address.replaceAll(", , ", ", ");
                }
            }
          } else if(canAddEntry) {
            // If the generation is non-tailorble, then add it to the general generations map as well to allow other recipients within genMap to access it.
            if(nonTailorable.contains(type) && downloadedGeneral) {
              genMap[email]![type.value] = genMap["General"]![type.value];
            } else if(nonTailorable.contains(type) && iteration == 1 && !downloadedGeneral) {
              genMap[email]![type.value] = genMap["General"]![type.value] = await downloadFileContent(localDir.path, serverDir, type.value);
              changeDownloadedGeneralSoon = true;
            } else {
              genMap[email]![type.value] = await downloadFileContent(localDir.path, serverDir, type.value);
            }
            
          }
        }

        // If the general generations were downloaded within the above if statement, then set the downloadedGeneral to true so that it can be used in the next iteration.
        if(changeDownloadedGeneralSoon) {
          downloadedGeneral = true;
          changeDownloadedGeneralSoon = false;
        }

      }

    }

  genMap["tailorFilePath"] = {};
  genMap["tailorFilePath"]!["path"] = "public/jsons/${localAudioFileName.replaceAll(".WAV", "_tailor.json")}";

  initGenDisplayed();
  genListReady = true;
  safePrint("genMap: $genMap");
  return genMap;

}

// Returns status code
Future<int> sendEmail(Map<String, Map<String, dynamic>> content) async {
  final res = Amplify.API.post(
    "/sendEmails",
    apiName: "MeetingSummarizerAPI",
    body: HttpPayload.json(content)
  );
  final response = await res.response;
  return response.statusCode;
}