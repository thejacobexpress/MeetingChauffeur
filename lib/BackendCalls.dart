import 'dart:io';

// Amplify Flutter Packages
import 'package:amplify_flutter/amplify_flutter.dart';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'main.dart';

import 'homePage.dart';

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
        localAudioFileName = fileResult.files.single.name;

        // Upload the file to S3
        final result = await Amplify.Storage.uploadFile(
          localFile: AWSFile.fromPath(file.path),
          path: StoragePath.fromString('public/recordings/$localAudioFileName'),
        ).result;
        safePrint('File uploaded: ${result.uploadedItem}');

        retrieveSummary();
      }
    } on StorageException catch (e) {
      safePrint('Error uploading file: ${e.message}');
    }
  }

  void retrieveSummary() async {
    await Future.delayed(Duration(seconds: 3));
    try{
      final dir = await getApplicationDocumentsDirectory();
      final localPath = localFilePath + "/" + localAudioFileName.replaceAll('.WAV', '.txt');
      final result = await Amplify.Storage.downloadFile(
        path: StoragePath.fromString('public/summaries/${localAudioFileName.replaceAll('.WAV', '.txt')}'),
        localFile: AWSFile.fromPath(localPath),
      ).result;
      safePrint('File downloaded: ${result.downloadedItem}');
      File(localPath).readAsString().then((content) {
        safePrint('Summary content: $content');
      });

      // Delete the summary file in the s3 after retrieving it
      final deleteResult = await Amplify.Storage.remove(
        path: StoragePath.fromString('public/summaries/${localAudioFileName.replaceAll('.WAV', '.txt')}'),
        options: StorageRemoveOptions(bucket: StorageBucket.fromBucketInfo(BucketInfo(bucketName: 'meetingsummarizerapp3e62d7c6d4654f17bc7d042793aca958-dev', region: 'us-west-2'))),
      ).result;

    } on StorageAccessDeniedException catch (e) {
      safePrint('Access denied: ${e.message}');
      await Future.delayed(Duration(seconds: 1)); // Retry after a second
      retrieveSummary();
    }
  }

  void retrieveTranscript() async {
    await Future.delayed(Duration(seconds: 3));
    try{
      final localPath = localFilePath + "/" + localAudioFileName.replaceAll('.WAV', '.txt');
      final result = await Amplify.Storage.downloadFile(
        path: StoragePath.fromString('public/transcriptions/${localAudioFileName.replaceAll('.WAV', '.txt')}'),
        localFile: AWSFile.fromPath(localPath),
      ).result;
      safePrint('File downloaded: ${result.downloadedItem}');
      File(localPath).readAsString().then((content) {
        safePrint('Transcript content: $content');
      });

      // Delete the transcription file in the s3 after retrieving it
      final deleteResult = await Amplify.Storage.remove(
        path: StoragePath.fromString('public/transcriptions/${localAudioFileName.replaceAll('.WAV', '.txt')}'),
        options: StorageRemoveOptions(bucket: StorageBucket.fromBucketInfo(BucketInfo(bucketName: 'meetingsummarizerapp3e62d7c6d4654f17bc7d042793aca958-dev', region: 'us-west-2'))),
      ).result;

    } on StorageAccessDeniedException catch (e) {
      safePrint('Access denied: ${e.message}');
      await Future.delayed(Duration(seconds: 1)); // Retry after a second
      retrieveTranscript();
    }
  }