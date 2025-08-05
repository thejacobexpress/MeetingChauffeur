import 'dart:io';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'package:file_picker/file_picker.dart';
import 'package:meeting_summarizer_app/classes/GroupClass.dart';
import 'package:meeting_summarizer_app/classes/IndividualClass.dart';
import 'package:meeting_summarizer_app/classes/Recipient.dart';
import 'package:meeting_summarizer_app/main_sequence/AddSubjectPage.dart';
import 'package:meeting_summarizer_app/main_sequence/HomePage.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:meeting_summarizer_app/widgets/Generation.dart';
import 'package:aws_signature_v4/aws_signature_v4.dart';
import 'package:dio/dio.dart';
import 'package:geocoding/geocoding.dart';

/// The GenerationType enum defines the types of generations that can be created from a meeting recording.
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

/// Keeps track of the generation types that cannot be tailored to recipients.
List<GenerationType> nonTailorable = [
  GenerationType.DATE_TIME,
  GenerationType.LOCATION,
  GenerationType.TRANSCRIPT,
  GenerationType.NAMES,
  GenerationType.PURPOSE
];

/// Keeps track of the generation types, in their string form, that can be tailored to recipients.
List<String> nonTailorableStrings = [
  GenerationType.DATE_TIME.value,
  GenerationType.LOCATION.value,
  GenerationType.TRANSCRIPT.value,
  GenerationType.NAMES.value,
  GenerationType.PURPOSE.value
];

String bucket = "meetingsummarizerapp3e62d7c6d4654f17bc7d042793aca958-dev";
String region = "us-west-2";

/// Keeps track of the generations created by the AWS Python backend (stored as ```GenerationType``` strings).
/// 
/// Stores each recipient's email as a key, and a map of ```GenerationType``` strings and their boolean values as the value.
/// 
/// A key of "General" is used to store generations that are not tailored to any specific recipient. This could occur from several different factors:
/// The user did not select the tailored option, the generations the user selected cannot be tailored (see ```nonTailorable``` list) the recipient does not have any info, or the recipient's ```getGroups()``` method returns an empty list.
Map<String, Map<String, dynamic>> genMap = {};

/// Returns false if ```genMap``` has not been fully loaded with generations yet.
bool genListReady = false;

/// List of emails that are used to keep track of the recipients' emails, directly matching the recipients list.
List<String> emails = [];

/// Initiates the genDisplayed map, which is used to keep track of which generation types are displayed in the UI.
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

/// Returns the instance of IndividualClass that matches the provided email.
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

/// Returns a list of emails from the recipients list.
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

/// Removes special characters from the input string, specifically used to remove "." and "@" from emails.
String removeSpecialChars(String input) {
  String newText = "";
  for(final char in input.split("")) {
    if(char != "." && char != "@") {
      newText += char;
    }
  }
  return newText;
}

/// Returns the address of the location based on the latitude and longitude provided.
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

/// Checks if there are any recipients that do not have info.
bool infolessRecipientExists() {
  for(final recipient in recipients) {
    if(recipient is IndividualClass && recipient.info == "") {
      return true;
    } else if (recipient is GroupClass) {
      for(final individual in recipient.individuals) {
        if(individual.info == "") {
          return true;
        }
      }
    }
  }
  return false;
}

/// Checks if there are any recipients that do not have info and are not part of a group.
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

/// Returns a string representation of the meeting time using the start time and end time of the meeting, formatted as "Meeting lasted from HH:MM AM/PM to HH:MM AM/PM".
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

/// Uploads a JSON file to S3 with the specified file name and JSON content.
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

/// Uploads a tailored JSON file to an AWS S3 bucket that contains ```IndividualClass``` instances' emails and the info that corresponds to that individual, including ```IndividualClass``` info, associated groups' ```GroupClass``` info, and simply the groups that the individual is associated with (```IndividualClass.getGroups()```). Function only uploads JSON if the ```tailored``` key is present in the JSON passed in and set to ```true```.
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
              groupInfo.add("${group.name}: ${group.info}");
            }
            String groupInfoString = recipient.getGroups().isEmpty ? "" : " This person is involved with these groups: ${recipient.getGroups().map((group) => group.name).join(", ")}. Details about each group this individual is involved in: ${groupInfo.join(", ")}.";
            tailoredMap[email] = "${recipient.info}$groupInfoString";
            break;
          } else if (recipient is GroupClass) {
            for(final individual in recipient.individuals) {
              if(individual.contact == email && !tailoredMap.containsKey(individual.contact)) {
                List<String> groupInfo = [];
                for(final group in individual.getGroups()) {
                  groupInfo.add("${group.name}: ${group.info}");
                }
                String groupInfoString = individual.getGroups().isEmpty ? "" : " This person is involved with these groups: ${individual.getGroups().map((group) => group.name).join(", ")}. Details about each group this individual is involved in: ${groupInfo.join(", ")}.";
                tailoredMap[email] = "${individual.info}$groupInfoString";
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

/// Generates a pre-signed PUT URL for uploading a file to S3 with the specified file name.
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
      'Content-Type': 'audio/m4a',
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

/// Uploads the m4a file specified by the given path to an AWS S3 bucket, triggering a lambda function to process the file and generate the requested generations based on the provided JSON specifications. If no path is provided, it prompts the user to select a m4a file.
/// 
/// The function also uploads a tailored JSON file using ```uploadTailorJson``` function and uploads a JSON file containing user-selected generation specifications using ```uploadJsonToS3``` function.
void uploadM4aToS3(String path, Map<String, dynamic> json) async {

  // Upload the tailor json to S3 if the user has selected the tailored option.
  if(json['tailored'] != null && json['tailored']) {
    await uploadTailorJson(json);
  }

  // Upload the json that contains user selected generation specifications to S3 with the name of the recording file.
  await uploadJsonToS3(path.split("/").last.replaceAll(".m4a", ""), json);

  // Ask user to select an m4a file if no path is provided.
  if(path == "") {
    try {
      FilePickerResult? fileResult = await FilePicker.platform.pickFiles(
        dialogTitle: 'Please select a file to summarize.',
        type: FileType.custom,
        allowedExtensions: ['m4a']
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
            await dio.put(
              await generatePresignedPutUrl(localAudioFileName),
              data: file.openRead(),
              options: Options(
                headers: {
                  HttpHeaders.contentTypeHeader: 'audio/m4a',
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

/// Downloads the file content from the AWS S3 location given to the given local directory, deletes the file from S3 after retrieval, and returns the content of the file as a string.
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
        await Amplify.Storage.remove(
          path: StoragePath.fromString(serverDir),
          options: StorageRemoveOptions(bucket: StorageBucket.fromBucketInfo(BucketInfo(bucketName: bucket, region: region))),
        ).result;

        // Get the parent directory of serverDir.
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

          // Check if the S3 directory that contains the file the function is trying to delete. If not, break the for loop.
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

      // Return the content inside of the downloaded file.
      final content = await File(localDir).readAsString();
      safePrint('$type: $content');
      return content;

    } on Exception {
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

/// Retrieves generation data from S3 and local device storage based on the provided [json] specifications ([json] stores desired generations), downloading the necessary files and storing them in ```genMap``` for each recipient. It also handles general generations that are not tailored to recipients by storing them in ```genMap["General"]```.
/// 
/// Returns ```genMap```.
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
  
  // Check if a general generation is needed (if the 'tailored' key is not checked; if there is an infoless recipient)
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
            localDir = Directory('${appDocDir.path}/summaries/${localAudioFileName.replaceAll('.m4a', '.txt')}');
            serverDir = 'public/summaries/${localAudioFileName.replaceAll('.m4a', '.txt')}';
            type = GenerationType.SUMMARY;
            if(localParentDir.existsSync()) {} else {
              localParentDir.create();
            }
            canAddEntry = true;
          }
        case ("transcript"):
          if (entry.value) {
            localParentDir = Directory('${appDocDir.path}/transcriptions/');
            localDir = Directory('${appDocDir.path}/transcriptions/${localAudioFileName.replaceAll('.m4a', '.txt')}');
            serverDir = 'public/transcriptions/${localAudioFileName.replaceAll('.m4a', '.txt')}';
            type = GenerationType.TRANSCRIPT;
            if(localParentDir.existsSync()) {} else {
              localParentDir.create();
            }
            canAddEntry = true;
          }
        case ("action"):
          if (entry.value) {
            localParentDir = Directory('${appDocDir.path}/action/');
            localDir = Directory('${appDocDir.path}/action/${localAudioFileName.replaceAll('.m4a', '.txt')}');
            serverDir = 'public/action/${localAudioFileName.replaceAll('.m4a', '.txt')}';
            type = GenerationType.ACTION;
            if(localParentDir.existsSync()) {} else {
              localParentDir.create();
            }
            canAddEntry = true;
          }
        case ("decisions"):
          if (entry.value) {
            localParentDir = Directory('${appDocDir.path}/decisions/');
            localDir = Directory('${appDocDir.path}/decisions/${localAudioFileName.replaceAll('.m4a', '.txt')}');
            serverDir = 'public/decisions/${localAudioFileName.replaceAll('.m4a', '.txt')}';
            type = GenerationType.DECISION;
            if(localParentDir.existsSync()) {} else {
              localParentDir.create();
            }
            canAddEntry = true;
          }
        case ("names"):
          if (entry.value) {
            localParentDir = Directory('${appDocDir.path}/names/');
            localDir = Directory('${appDocDir.path}/names/${localAudioFileName.replaceAll('.m4a', '.txt')}');
            serverDir = 'public/names/${localAudioFileName.replaceAll('.m4a', '.txt')}';
            type = GenerationType.NAMES;
            if(localParentDir.existsSync()) {} else {
              localParentDir.create();
            }
            canAddEntry = true;
          }
        case ("topics"):
          if (entry.value) {
            localParentDir = Directory('${appDocDir.path}/topics/');
            localDir = Directory('${appDocDir.path}/topics/${localAudioFileName.replaceAll('.m4a', '.txt')}');
            serverDir = 'public/topics/${localAudioFileName.replaceAll('.m4a', '.txt')}';
            type = GenerationType.TOPICS;
            if(localParentDir.existsSync()) {} else {
              localParentDir.create();
            }
            canAddEntry = true;
          }
        case ("purpose"):
          if (entry.value) {
            localParentDir = Directory('${appDocDir.path}/purpose/');
            localDir = Directory('${appDocDir.path}/purpose/${localAudioFileName.replaceAll('.m4a', '.txt')}');
            serverDir = 'public/purpose/${localAudioFileName.replaceAll('.m4a', '.txt')}';
            type = GenerationType.PURPOSE;
            if(localParentDir.existsSync()) {} else {
              localParentDir.create();
            }
            canAddEntry = true;
          }
        case ("next_steps"):
          if (entry.value) {
            localParentDir = Directory('${appDocDir.path}/next_steps/');
            localDir = Directory('${appDocDir.path}/next_steps/${localAudioFileName.replaceAll('.m4a', '.txt')}');
            serverDir = 'public/next_steps/${localAudioFileName.replaceAll('.m4a', '.txt')}';
            type = GenerationType.NEXT_STEPS;
            if(localParentDir.existsSync()) {} else {
              localParentDir.create();
            }
            canAddEntry = true;
          }
        case ("corrections"):
          if (entry.value) {
            localParentDir = Directory('${appDocDir.path}/corrections/');
            localDir = Directory('${appDocDir.path}/corrections/${localAudioFileName.replaceAll('.m4a', '.txt')}');
            serverDir = 'public/corrections/${localAudioFileName.replaceAll('.m4a', '.txt')}';
            type = GenerationType.CORRECTIONS;
            if(localParentDir.existsSync()) {} else {
              localParentDir.create();
            }
            canAddEntry = true;
          }
        case ("questions"):
          if (entry.value) {
            localParentDir = Directory('${appDocDir.path}/questions/');
            localDir = Directory('${appDocDir.path}/questions/${localAudioFileName.replaceAll('.m4a', '.txt')}');
            serverDir = 'public/questions/${localAudioFileName.replaceAll('.m4a', '.txt')}';
            type = GenerationType.QUESTIONS;
            if(localParentDir.existsSync()) {} else {
              localParentDir.create();
            }
            canAddEntry = true;
          }
        }

        // Extra functonality here for DATE_TIME and LOCATION GenerationTypes because they are processed on the client side.
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
        // Add the downloaded generation to the genMap at the end.
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
                localDir = Directory('${appDocDir.path}/summaries/${localAudioFileName.replaceAll('.m4a', '_${removeSpecialChars(email)}.txt')}');
                serverDir = 'public/summaries/${localAudioFileName.replaceAll('.m4a', '_${removeSpecialChars(email)}.txt')}';
                type = GenerationType.SUMMARY;
                if(localParentDir.existsSync()) {} else {
                  localParentDir.create();
                }
                canAddEntry = true;
              }
            case ("transcript"):
              if (entry.value) {
                localParentDir = Directory('${appDocDir.path}/transcriptions/');
                localDir = Directory('${appDocDir.path}/transcriptions/${localAudioFileName.replaceAll('.m4a', '_${removeSpecialChars(email)}.txt')}');
                serverDir = 'public/transcriptions/${localAudioFileName.replaceAll('.m4a', '.txt')}';
                type = GenerationType.TRANSCRIPT;
                if(localParentDir.existsSync()) {} else {
                  localParentDir.create();
                }
                canAddEntry = true;
              }
            case ("action"):
              if (entry.value) {
                localParentDir = Directory('${appDocDir.path}/action/');
                localDir = Directory('${appDocDir.path}/action/${localAudioFileName.replaceAll('.m4a', '_${removeSpecialChars(email)}.txt')}');
                serverDir = 'public/action/${localAudioFileName.replaceAll('.m4a', '_${removeSpecialChars(email)}.txt')}';
                type = GenerationType.ACTION;
                if(localParentDir.existsSync()) {} else {
                  localParentDir.create();
                }
                canAddEntry = true;
              }
            case ("decisions"):
              if (entry.value) {
                localParentDir = Directory('${appDocDir.path}/decisions/');
                localDir = Directory('${appDocDir.path}/decisions/${localAudioFileName.replaceAll('.m4a', '_${removeSpecialChars(email)}.txt')}');
                serverDir = 'public/decisions/${localAudioFileName.replaceAll('.m4a', '_${removeSpecialChars(email)}.txt')}';
                type = GenerationType.DECISION;
                if(localParentDir.existsSync()) {} else {
                  localParentDir.create();
                }
                canAddEntry = true;
              }
            case ("names"):
              if (entry.value) {
                localParentDir = Directory('${appDocDir.path}/names/');
                localDir = Directory('${appDocDir.path}/names/${localAudioFileName.replaceAll('.m4a', '_${removeSpecialChars(email)}.txt')}'); 
                serverDir = 'public/names/${localAudioFileName.replaceAll('.m4a', '.txt')}';
                type = GenerationType.NAMES;
                if(localParentDir.existsSync()) {} else {
                  localParentDir.create();
                }
                canAddEntry = true;
              }
            case ("topics"):
              if (entry.value) {
                localParentDir = Directory('${appDocDir.path}/topics/');
                localDir = Directory('${appDocDir.path}/topics/${localAudioFileName.replaceAll('.m4a', '_${removeSpecialChars(email)}.txt')}');
                serverDir = 'public/topics/${localAudioFileName.replaceAll('.m4a', '_${removeSpecialChars(email)}.txt')}';
                type = GenerationType.TOPICS;
                if(localParentDir.existsSync()) {} else {
                  localParentDir.create();
                }
                canAddEntry = true;
              }
            case ("purpose"):
              if (entry.value) {
                localParentDir = Directory('${appDocDir.path}/purpose/');
                localDir = Directory('${appDocDir.path}/purpose/${localAudioFileName.replaceAll('.m4a', '_${removeSpecialChars(email)}.txt')}');
                serverDir = 'public/purpose/${localAudioFileName.replaceAll('.m4a', '.txt')}';
                type = GenerationType.PURPOSE;
                if(localParentDir.existsSync()) {} else {
                  localParentDir.create();
                }
                canAddEntry = true;
              }
            case ("next_steps"):
              if (entry.value) {
                localParentDir = Directory('${appDocDir.path}/next_steps/');
                localDir = Directory('${appDocDir.path}/next_steps/${localAudioFileName.replaceAll('.m4a', '_${removeSpecialChars(email)}.txt')}');
                serverDir = 'public/next_steps/${localAudioFileName.replaceAll('.m4a', '_${removeSpecialChars(email)}.txt')}';
                type = GenerationType.NEXT_STEPS;
                if(localParentDir.existsSync()) {} else {
                  localParentDir.create();
                }
                canAddEntry = true;
              }
            case ("corrections"):
              if (entry.value) {
                localParentDir = Directory('${appDocDir.path}/corrections/');
                localDir = Directory('${appDocDir.path}/corrections/${localAudioFileName.replaceAll('.m4a', '_${removeSpecialChars(email)}.txt')}');
                serverDir = 'public/corrections/${localAudioFileName.replaceAll('.m4a', '_${removeSpecialChars(email)}.txt')}';
                type = GenerationType.CORRECTIONS;
                if(localParentDir.existsSync()) {} else {
                  localParentDir.create();
                }
                canAddEntry = true;
              }
            case ("questions"):
              if (entry.value) {
                localParentDir = Directory('${appDocDir.path}/questions/');
                localDir = Directory('${appDocDir.path}/questions/${localAudioFileName.replaceAll('.m4a', '_${removeSpecialChars(email)}.txt')}');
                serverDir = 'public/questions/${localAudioFileName.replaceAll('.m4a', '_${removeSpecialChars(email)}.txt')}';
                type = GenerationType.QUESTIONS;
                if(localParentDir.existsSync()) {} else {
                  localParentDir.create();
                }
                canAddEntry = true;
              }
          }
          // Extra functonality here for DATE_TIME and LOCATION GenerationTypes because they are processed on the client side.
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
          // Add the downloaded generation to the genMap at the end.
          } else if(canAddEntry) {
            // If the generation is non-tailorable, then add it to the general generations map as well to allow other recipients within genMap to access it.
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

  // Add the 'recipients' key so the sendEmails AWS Lambda can still find recipients even if the user has not chosen the tailored option.
  if(json["tailored"] == null || !json["tailored"]) {
    genMap["recipients"] = {};
    genMap["recipients"]!["content"] = getEmails().join(", ");
  }

  // Add the 'tailorFilePath' key and value so the sendEmails AWS lambda can access the recipients.
  genMap["tailorFilePath"] = {};
  genMap["tailorFilePath"]!["path"] = "public/jsons/${localAudioFileName.replaceAll(".m4a", "_tailor.json")}";

  // Add the 'subject' key and value so the sendEmails AWS lambda has a subject to give emails.
  genMap["subject"] = {};
  genMap["subject"]!["content"] = subject;

  initGenDisplayed();
  genListReady = true;
  safePrint("genMap: $genMap");
  return genMap;

}

/// Sends an email with the provided [content], which should only be ```genMap```, to the recipients using the MeetingSummarizerAPI.
/// 
/// Returns the status code of the response; a successful email send will return 200.
Future<int> sendEmail(Map<String, Map<String, dynamic>> content) async {
  final res = Amplify.API.post(
    "/sendEmails",
    apiName: "MeetingSummarizerAPI",
    body: HttpPayload.json(content)
  );
  final response = await res.response;
  return response.statusCode;
}