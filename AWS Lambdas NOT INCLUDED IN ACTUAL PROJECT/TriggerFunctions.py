import json
import boto3
import os
import openai

openai.api_key = ""

def removeSpecialChars(text):
    newText = ""
    for char in text:
        if char != "@" and char != ".":
            newText += char
    return newText


def lambda_handler(event, context):

    filePath = event['Records'][0]['s3']['object']['key']

    if ".m4a" in filePath:
        bucketName = 'meetingsummarizerapp3e62d7c6d4654f17bc7d042793aca958-dev'

        fileName = ""
        for i in reversed(filePath):
            if i == '/':
                break
            fileName += i
        fileName = fileName[4:]
        fileName = "".join(reversed(fileName))

        tempJsonFilePath = '/tmp/' + fileName + ".json"
        jsonFilePath = 'public/jsons/' + fileName + ".json"
        tempm4aFilePath = '/tmp/' + fileName + ".m4a"
        m4aFilePath = 'public/recordings/' + fileName + ".m4a"

        s3 = boto3.client('s3')
        s3.download_file(bucketName, jsonFilePath, tempJsonFilePath)
        s3.download_file(bucketName, m4aFilePath, tempm4aFilePath)

        print("JSON File " + jsonFilePath + " downloaded successfully")

        transcription = openai.audio.translations.create(
            model = "whisper-1",
            file = open(tempm4aFilePath, "rb")
        )
        print("Transcription: " + transcription.text)

        os.remove(tempm4aFilePath);

        with open(tempJsonFilePath, 'r') as jsonFile:
            data = json.load(jsonFile)

            if data['tailored'] == False:
                for key, value in data.items():
                    match key:
                        case "summary":
                            try:
                                s3.delete_object(Bucket=bucketName, Key='public/summaries/' + fileName + ".txt")
                                print(f"Successfully deleted {fileName} from {bucketName}")
                            except Exception as e:
                                print(f"Error deleting {fileName}: {e}")
                            if value:
                                completion = openai.chat.completions.create(
                                    model="gpt-4.1",
                                    store=False,
                                    messages=[
                                        {"role": "system", "content": "Write a short summary based on the user content."},
                                        {"role": "user", "content": transcription.text}
                                    ]
                                )
                                encodedSummary = completion.choices[0].message.content.encode('utf-8')
                                s3.put_object(Bucket=bucketName, Key='public/summaries/' + fileName + ".txt", Body=encodedSummary)
                                print("Summary: " + completion.choices[0].message.content)
                        case "transcript":
                            try:
                                s3.delete_object(Bucket=bucketName, Key='public/transcriptions/' + fileName + ".txt")
                                print(f"Successfully deleted {fileName} from {bucketName}")
                            except Exception as e:
                                print(f"Error deleting {fileName}: {e}")
                            if value:
                                encodedTranscription = transcription.text.encode('utf-8')
                                s3.put_object(Bucket=bucketName, Key='public/transcriptions/' + fileName + ".txt", Body=encodedTranscription)
                                print("transcript: " + transcription.text)
                        case "action":
                            try:
                                s3.delete_object(Bucket=bucketName, Key='public/action/' + fileName + ".txt")
                                print(f"Successfully deleted {fileName} from {bucketName}")
                            except Exception as e:
                                print(f"Error deleting {fileName}: {e}")
                            if value:
                                completion = openai.chat.completions.create(
                                    model="gpt-4.1",
                                    store=False,
                                    messages=[
                                        {"role": "system", "content": "Generate actionable items from the user content."},
                                        {"role": "user", "content": transcription.text}
                                    ]
                                )
                                encodedSummary = completion.choices[0].message.content.encode('utf-8')
                                s3.put_object(Bucket=bucketName, Key='public/action/' + fileName + ".txt", Body=encodedSummary)
                                print("actionable items: " + completion.choices[0].message.content)
                        case "decisions":
                            try:
                                s3.delete_object(Bucket=bucketName, Key='public/decisions/' + fileName + ".txt")
                                print(f"Successfully deleted {fileName} from {bucketName}")
                            except Exception as e:
                                print(f"Error deleting {fileName}: {e}")
                            if value:
                                completion = openai.chat.completions.create(
                                    model="gpt-4.1",
                                    store=False,
                                    messages=[
                                        {"role": "system", "content": "Pull out any decisions made from the user content and display them neatly."},
                                        {"role": "user", "content": transcription.text}
                                    ]
                                )
                                encodedSummary = completion.choices[0].message.content.encode('utf-8')
                                s3.put_object(Bucket=bucketName, Key='public/decisions/' + fileName + ".txt", Body=encodedSummary)
                                print("decisions: " + completion.choices[0].message.content)
                        case "names":
                            try:
                                s3.delete_object(Bucket=bucketName, Key='public/names/' + fileName + ".txt")
                                print(f"Successfully deleted {fileName} from {bucketName}")
                            except Exception as e:
                                print(f"Error deleting {fileName}: {e}")
                            if value:
                                completion = openai.chat.completions.create(
                                    model="gpt-4.1",
                                    store=False,
                                    messages=[
                                        {"role": "system", "content": "Derive the names of the people speaking within the user content and display them neatly."},
                                        {"role": "user", "content": transcription.text}
                                    ]
                                )
                                encodedSummary = completion.choices[0].message.content.encode('utf-8')
                                s3.put_object(Bucket=bucketName, Key='public/names/' + fileName + ".txt", Body=encodedSummary)
                                print("names: " + completion.choices[0].message.content)
                        case "topics":
                            try:
                                s3.delete_object(Bucket=bucketName, Key='public/topics/' + fileName + ".txt")
                                print(f"Successfully deleted {fileName} from {bucketName}")
                            except Exception as e:
                                print(f"Error deleting {fileName}: {e}")
                            if value:
                                completion = openai.chat.completions.create(
                                    model="gpt-4.1",
                                    store=False,
                                    messages=[
                                        {"role": "system", "content": "Derive any topics from the user content and display them neatly."},
                                        {"role": "user", "content": transcription.text}
                                    ]
                                )
                                encodedSummary = completion.choices[0].message.content.encode('utf-8')
                                s3.put_object(Bucket=bucketName, Key='public/topics/' + fileName + ".txt", Body=encodedSummary)
                                print("topics: " + completion.choices[0].message.content)
                        case "purpose":
                            try:
                                s3.delete_object(Bucket=bucketName, Key='public/purpose/' + fileName + ".txt")
                                print(f"Successfully deleted {fileName} from {bucketName}")
                            except Exception as e:
                                print(f"Error deleting {fileName}: {e}")
                            if value:
                                completion = openai.chat.completions.create(
                                    model="gpt-4.1",
                                    store=False,
                                    messages=[
                                        {"role": "system", "content": "Derive the purpose of the user content and display it neatly."},
                                        {"role": "user", "content": transcription.text}
                                    ]
                                )
                                encodedSummary = completion.choices[0].message.content.encode('utf-8')
                                s3.put_object(Bucket=bucketName, Key='public/purpose/' + fileName + ".txt", Body=encodedSummary)
                                print("purpose: " + completion.choices[0].message.content)
                        case "next_steps":
                            try:
                                s3.delete_object(Bucket=bucketName, Key='public/next_steps/' + fileName + ".txt")
                                print(f"Successfully deleted {fileName} from {bucketName}")
                            except Exception as e:
                                print(f"Error deleting {fileName}: {e}")
                            if value:
                                completion = openai.chat.completions.create(
                                    model="gpt-4.1",
                                    store=False,
                                    messages=[
                                        {"role": "system", "content": "Derive any next steps from the user content and display them neatly."},
                                        {"role": "user", "content": transcription.text}
                                    ]
                                )
                                encodedSummary = completion.choices[0].message.content.encode('utf-8')
                                s3.put_object(Bucket=bucketName, Key='public/next_steps/' + fileName + ".txt", Body=encodedSummary)
                                print("next steps: " + completion.choices[0].message.content)
                        case "corrections":
                            try:
                                s3.delete_object(Bucket=bucketName, Key='public/corrections/' + fileName + ".txt")
                                print(f"Successfully deleted {fileName} from {bucketName}")
                            except Exception as e:
                                print(f"Error deleting {fileName}: {e}")
                            if value:
                                completion = openai.chat.completions.create(
                                    model="gpt-4.1",
                                    store=False,
                                    messages=[
                                        {"role": "system", "content": "Derive any corrections from the previous meeting from the user content and display them neatly."},
                                        {"role": "user", "content": transcription.text}
                                    ]
                                )
                                encodedSummary = completion.choices[0].message.content.encode('utf-8')
                                s3.put_object(Bucket=bucketName, Key='public/corrections/' + fileName + ".txt", Body=encodedSummary)
                                print("corrections: " + completion.choices[0].message.content)
                        case "questions":
                            try:
                                s3.delete_object(Bucket=bucketName, Key='public/questions/' + fileName + ".txt")
                                print(f"Successfully deleted {fileName} from {bucketName}")
                            except Exception as e:
                                print(f"Error deleting {fileName}: {e}")
                            if value:
                                completion = openai.chat.completions.create(
                                    model="gpt-4.1",
                                    store=False,
                                    messages=[
                                        {"role": "system", "content": "Derive any questions from the user content and display them neatly."},
                                        {"role": "user", "content": transcription.text}
                                    ]
                                )
                                encodedSummary = completion.choices[0].message.content.encode('utf-8')
                                s3.put_object(Bucket=bucketName, Key='public/questions/' + fileName + ".txt", Body=encodedSummary)
                                print("questions: " + completion.choices[0].message.content)
            else:
                tempTailorJsonPath = '/tmp/'+ fileName + '_tailor.json'
                tailorJsonPath = 'public/jsons/' + fileName + '_tailor.json'
                s3.download_file(bucketName, tailorJsonPath, tempTailorJsonPath)

                generateRegular = False

                tailorJsonFile = open(tempTailorJsonPath, 'r')
                tailorData = json.load(tailorJsonFile)

                for key, value in data.items():
                    match key:
                        case "summary":
                            try:
                                s3.delete_object(Bucket=bucketName, Key='public/summaries/' + fileName + ".txt")
                                print(f"Successfully deleted {fileName} from {bucketName}")
                            except Exception as e:
                                print(f"Error deleting {fileName}: {e}")
                            if value:
                                generatedRegular = False
                                for tailorKey, tailorValue in tailorData.items():
                                    if tailorValue == "" and not generatedRegular:
                                        completion = openai.chat.completions.create(
                                            model="gpt-4.1",
                                            store=False,
                                            messages=[
                                                {"role": "system", "content": "Write a short summary based on the user content."},
                                                {"role": "user", "content": transcription.text}
                                            ]
                                        )
                                        encodedSummary = completion.choices[0].message.content.encode('utf-8')
                                        s3.put_object(Bucket=bucketName, Key='public/summaries/' + fileName + ".txt", Body=encodedSummary)
                                        print("Summary: " + completion.choices[0].message.content)
                                        generatedRegular = True
                                    else:
                                        completion = openai.chat.completions.create(
                                            model="gpt-4.1",
                                            store=False,
                                            messages=[
                                                {"role": "system", "content": "Write a short summary based on the user content. The text that you generate will be sent to a person. Do not include any greetings, niceties, etc. Tailor the text that you generate to the person with these details: " + tailorValue},
                                                {"role": "user", "content": transcription.text}
                                            ]
                                        )
                                        encodedSummary = completion.choices[0].message.content.encode('utf-8')
                                        s3.put_object(Bucket=bucketName, Key='public/summaries/' + fileName + "_" + removeSpecialChars(tailorKey) +  ".txt", Body=encodedSummary)
                                        print("Summary for " + tailorKey + ": " + completion.choices[0].message.content)
                        case "transcript":
                            try:
                                s3.delete_object(Bucket=bucketName, Key='public/transcriptions/' + fileName + ".txt")
                                print(f"Successfully deleted {fileName} from {bucketName}")
                            except Exception as e:
                                print(f"Error deleting {fileName}: {e}")
                            if value:
                                encodedTranscription = transcription.text.encode('utf-8')
                                s3.put_object(Bucket=bucketName, Key='public/transcriptions/' + fileName + ".txt", Body=encodedTranscription)
                                print("transcript: " + transcription.text)
                        case "action":
                            try:
                                s3.delete_object(Bucket=bucketName, Key='public/action/' + fileName + ".txt")
                                print(f"Successfully deleted {fileName} from {bucketName}")
                            except Exception as e:
                                print(f"Error deleting {fileName}: {e}")
                            if value:
                                generatedRegular = False
                                for tailorKey, tailorValue in tailorData.items():
                                    if tailorValue == "" and not generatedRegular:
                                        completion = openai.chat.completions.create(
                                            model="gpt-4.1",
                                            store=False,
                                            messages=[
                                                {"role": "system", "content": "Generate actionable items from the user content."},
                                                {"role": "user", "content": transcription.text}
                                            ]
                                        )
                                        encodedSummary = completion.choices[0].message.content.encode('utf-8')
                                        s3.put_object(Bucket=bucketName, Key='public/action/' + fileName + ".txt", Body=encodedSummary)
                                        print("Actionable items: " + completion.choices[0].message.content)
                                        generatedRegular = True
                                    else:
                                        completion = openai.chat.completions.create(
                                            model="gpt-4.1",
                                            store=False,
                                            messages=[
                                                {"role": "system", "content": "Generate actionable items from the user content. The text that you generate will be sent to a person. Do not include any greetings, niceties, etc. Tailor the text that you generate to the person with these details: " + tailorValue},
                                                {"role": "user", "content": transcription.text}
                                            ]
                                        )
                                        encodedSummary = completion.choices[0].message.content.encode('utf-8')
                                        s3.put_object(Bucket=bucketName, Key='public/action/' + fileName + "_" + removeSpecialChars(tailorKey) +  ".txt", Body=encodedSummary)
                                        print("Actionable items for " + tailorKey + ": " + completion.choices[0].message.content)
                        case "decisions":
                            try:
                                s3.delete_object(Bucket=bucketName, Key='public/decisions/' + fileName + ".txt")
                                print(f"Successfully deleted {fileName} from {bucketName}")
                            except Exception as e:
                                print(f"Error deleting {fileName}: {e}")
                            if value:
                                generatedRegular = False
                                for tailorKey, tailorValue in tailorData.items():
                                    if tailorValue == "" and not generatedRegular:
                                        completion = openai.chat.completions.create(
                                            model="gpt-4.1",
                                            store=False,
                                            messages=[
                                                {"role": "system", "content": "Pull out any decisions made from the user content and display them neatly."},
                                                {"role": "user", "content": transcription.text}
                                            ]
                                        )
                                        encodedSummary = completion.choices[0].message.content.encode('utf-8')
                                        s3.put_object(Bucket=bucketName, Key='public/decisions/' + fileName + ".txt", Body=encodedSummary)
                                        print("Decisions: " + completion.choices[0].message.content)
                                        generatedRegular = True
                                    else:
                                        completion = openai.chat.completions.create(
                                            model="gpt-4.1",
                                            store=False,
                                            messages=[
                                                {"role": "system", "content": "Pull out any decisions made from the user content and display them neatly. The text that you generate will be sent to a person. Do not include any greetings, niceties, etc. Tailor the text that you generate to the person with these details: " + tailorValue},
                                                {"role": "user", "content": transcription.text}
                                            ]
                                        )
                                        encodedSummary = completion.choices[0].message.content.encode('utf-8')
                                        s3.put_object(Bucket=bucketName, Key='public/decisions/' + fileName + "_" + removeSpecialChars(tailorKey) +  ".txt", Body=encodedSummary)
                                        print("Decisions for " + tailorKey + ": " + completion.choices[0].message.content)
                        case "names":
                            try:
                                s3.delete_object(Bucket=bucketName, Key='public/names/' + fileName + ".txt")
                                print(f"Successfully deleted {fileName} from {bucketName}")
                            except Exception as e:
                                print(f"Error deleting {fileName}: {e}")
                            if value:
                                # Names in the meeting are the same regardless of recipient.
                                completion = openai.chat.completions.create(
                                    model="gpt-4.1",
                                    store=False,
                                    messages=[
                                        {"role": "system", "content": "Derive the names of the people speaking within the user content and display them neatly."},
                                        {"role": "user", "content": transcription.text}
                                    ]
                                )
                                encodedSummary = completion.choices[0].message.content.encode('utf-8')
                                s3.put_object(Bucket=bucketName, Key='public/names/' + fileName + ".txt", Body=encodedSummary)
                                print("Names: " + completion.choices[0].message.content)
                        case "topics":
                            try:
                                s3.delete_object(Bucket=bucketName, Key='public/topics/' + fileName + ".txt")
                                print(f"Successfully deleted {fileName} from {bucketName}")
                            except Exception as e:
                                print(f"Error deleting {fileName}: {e}")
                            if value:
                                generatedRegular = False
                                for tailorKey, tailorValue in tailorData.items():
                                    if tailorValue == "" and not generatedRegular:
                                        completion = openai.chat.completions.create(
                                            model="gpt-4.1",
                                            store=False,
                                            messages=[
                                                {"role": "system", "content": "Derive any topics from the user content and display them neatly."},
                                                {"role": "user", "content": transcription.text}
                                            ]
                                        )
                                        encodedSummary = completion.choices[0].message.content.encode('utf-8')
                                        s3.put_object(Bucket=bucketName, Key='public/topics/' + fileName + ".txt", Body=encodedSummary)
                                        print("Topics: " + completion.choices[0].message.content)
                                        generatedRegular = True
                                    else:
                                        completion = openai.chat.completions.create(
                                            model="gpt-4.1",
                                            store=False,
                                            messages=[
                                                {"role": "system", "content": "Derive any topics from the user content and display them neatly. The text that you generate will be sent to a person. Do not include any greetings, niceties, etc. Tailor the text that you generate to the person with these details: " + tailorValue},
                                                {"role": "user", "content": transcription.text}
                                            ]
                                        )
                                        encodedSummary = completion.choices[0].message.content.encode('utf-8')
                                        s3.put_object(Bucket=bucketName, Key='public/topics/' + fileName + "_" + removeSpecialChars(tailorKey) +  ".txt", Body=encodedSummary)
                                        print("Topics for " + tailorKey + ": " + completion.choices[0].message.content)
                        case "purpose":
                            try:
                                s3.delete_object(Bucket=bucketName, Key='public/purpose/' + fileName + ".txt")
                                print(f"Successfully deleted {fileName} from {bucketName}")
                            except Exception as e:
                                print(f"Error deleting {fileName}: {e}")
                            if value:
                                # Purpose of the meeting is the same regardless of recipient.
                                completion = openai.chat.completions.create(
                                    model="gpt-4.1",
                                    store=False,
                                    messages=[
                                        {"role": "system", "content": "Derive the purpose of the prompt the user content it neatly."},
                                        {"role": "user", "content": transcription.text}
                                    ]
                                )
                                encodedSummary = completion.choices[0].message.content.encode('utf-8')
                                s3.put_object(Bucket=bucketName, Key='public/purpose/' + fileName + ".txt", Body=encodedSummary)
                                print("purpose: " + completion.choices[0].message.content)
                        case "next_steps":
                            try:
                                s3.delete_object(Bucket=bucketName, Key='public/next_steps/' + fileName + ".txt")
                                print(f"Successfully deleted {fileName} from {bucketName}")
                            except Exception as e:
                                print(f"Error deleting {fileName}: {e}")
                            if value:
                                generatedRegular = False
                                for tailorKey, tailorValue in tailorData.items():
                                    if tailorValue == "" and not generatedRegular:
                                        completion = openai.chat.completions.create(
                                            model="gpt-4.1",
                                            store=False,
                                            messages=[
                                                {"role": "system", "content": "Derive any next steps from the user content and display them neatly."},
                                                {"role": "user", "content": transcription.text}
                                            ]
                                        )
                                        encodedSummary = completion.choices[0].message.content.encode('utf-8')
                                        s3.put_object(Bucket=bucketName, Key='public/next_steps/' + fileName + ".txt", Body=encodedSummary)
                                        print("Next Steps: " + completion.choices[0].message.content)
                                        generatedRegular = True
                                    else:
                                        completion = openai.chat.completions.create(
                                            model="gpt-4.1",
                                            store=False,
                                            messages=[
                                                {"role": "system", "content": "Derive any next steps from the user content and display them neatly. The text that you generate will be sent to a person. Do not include any greetings, niceties, etc. Tailor the text that you generate to the person with these details: " + tailorValue},
                                                {"role": "user", "content": transcription.text}
                                            ]
                                        )
                                        encodedSummary = completion.choices[0].message.content.encode('utf-8')
                                        s3.put_object(Bucket=bucketName, Key='public/next_steps/' + fileName + "_" + removeSpecialChars(tailorKey) +  ".txt", Body=encodedSummary)
                                        print("Next Steps for " + tailorKey + ": " + completion.choices[0].message.content)
                        case "corrections":
                            try:
                                s3.delete_object(Bucket=bucketName, Key='public/corrections/' + fileName + ".txt")
                                print(f"Successfully deleted {fileName} from {bucketName}")
                            except Exception as e:
                                print(f"Error deleting {fileName}: {e}")
                            if value:
                                generatedRegular = False
                                for tailorKey, tailorValue in tailorData.items():
                                    if tailorValue == "" and not generatedRegular:
                                        completion = openai.chat.completions.create(
                                            model="gpt-4.1",
                                            store=False,
                                            messages=[
                                                {"role": "system", "content": "Derive any corrections from the previous meeting from the user content and display them neatly."},
                                                {"role": "user", "content": transcription.text}
                                            ]
                                        )
                                        encodedSummary = completion.choices[0].message.content.encode('utf-8')
                                        s3.put_object(Bucket=bucketName, Key='public/corrections/' + fileName + ".txt", Body=encodedSummary)
                                        print("Corrections from previous meeting: " + completion.choices[0].message.content)
                                        generatedRegular = True
                                    else:
                                        completion = openai.chat.completions.create(
                                            model="gpt-4.1",
                                            store=False,
                                            messages=[
                                                {"role": "system", "content": "Derive any corrections from the previous meeting from the user content display them neatly. The text that you generate will be sent to a person. Do not include any greetings, niceties, etc. Tailor the text that you generate to the person with these details: " + tailorValue},
                                                {"role": "user", "content": transcription.text}
                                            ]
                                        )
                                        encodedSummary = completion.choices[0].message.content.encode('utf-8')
                                        s3.put_object(Bucket=bucketName, Key='public/corrections/' + fileName + "_" + removeSpecialChars(tailorKey) +  ".txt", Body=encodedSummary)
                                        print("Corrections from previous meeting for " + tailorKey + ": " + completion.choices[0].message.content)
                        case "questions":
                            try:
                                s3.delete_object(Bucket=bucketName, Key='public/questions/' + fileName + ".txt")
                                print(f"Successfully deleted {fileName} from {bucketName}")
                            except Exception as e:
                                print(f"Error deleting {fileName}: {e}")
                            if value:
                                generatedRegular = False
                                for tailorKey, tailorValue in tailorData.items():
                                    if tailorValue == "" and not generatedRegular:
                                        completion = openai.chat.completions.create(
                                            model="gpt-4.1",
                                            store=False,
                                            messages=[
                                                {"role": "system", "content": "Derive any questions from the user content and display them neatly."},
                                                {"role": "user", "content": transcription.text}
                                            ]
                                        )
                                        encodedSummary = completion.choices[0].message.content.encode('utf-8')
                                        s3.put_object(Bucket=bucketName, Key='public/questions/' + fileName + ".txt", Body=encodedSummary)
                                        print("Questions: " + completion.choices[0].message.content)
                                        generatedRegular = True
                                    else:
                                        completion = openai.chat.completions.create(
                                            model="gpt-4.1",
                                            store=False,
                                            messages=[
                                                {"role": "system", "content": "Derive any questions from the user content and display them neatly. The text that you generate will be sent to a person. Do not include any greetings, niceties, etc. Tailor the text that you generate to the person with these details: " + tailorValue},
                                                {"role": "user", "content": transcription.text}
                                            ]
                                        )
                                        encodedSummary = completion.choices[0].message.content.encode('utf-8')
                                        s3.put_object(Bucket=bucketName, Key='public/questions/' + fileName + "_" + removeSpecialChars(tailorKey) +  ".txt", Body=encodedSummary)
                                        print("Questions for " + tailorKey + ": " + completion.choices[0].message.content)

    
    else:
        print("Not a m4a file")
