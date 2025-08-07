# MeetingChauffeur
Record meetings and send helpful, AI generated, *tailored to each recipient* notes about those meetings to the stakeholders of your choice!

No need to worry if you missed a meeting or were late to one. All of the important information you need can be sent to you via MeetingChauffeur by one of the meeting participants, in a neat email specifically procured just for you.

## Architecture Diagram
<img width="3966" height="2496" alt="Blank diagram(3)" src="https://github.com/user-attachments/assets/eac18c71-f783-4b7e-9d09-b32ee4e533be" />

## How Does it Work?
### Sending Data to Backend
Using the MeetingChauffeur app (made using Dart and Flutter), users can record a meeting and send it (as a .m4a file) to an AWS S3 bucket (essentially simple storage inside of an AWS server). At the same time the .m4a file is sent, JSONs containing user-selected information about their generations are sent to the AWS S3 bucket, also from the app.

### Generating .txt Files (meeting notes) From Recording
When the .m4a file is uploaded to the AWS S3 bucket, an AWS lambda function is triggered. This lambda takes that .m4a file and uses the OpenAI API (specifically the Whisper-1 model) to translate that audio into text. Then, continuing to use the OpenAI API (GPT-3.5-Turbo) text is generated based on the user-selected info within the JSONs sent earlier. This text is saved onto .txt files within the AWS S3 bucket.

### Sending Generated Notes to Stakeholders
The app then attempts to download the generated .txt files repeatedly (returning a StorageException each time the file cannot be found before it will be generated). Once it downloads all of them, the notes are presented to the app user to look over before sending. Once the user presses "Send", the .txt files are sent to another AWS lambda via an AWS Gateway API using a POST operation. From there, the lambda uses the Gmail API to send the generated text to the recipients.

And BOOM! It's easy to send meeting notes specificially tailored to each indiviudal stakeholder.

## How are the Generations "Tailored"?
The user can choose to tailor emails by checking the "Tailored" checkbox.

<img width="250" height="542" alt="tailored gif" src=https://github.com/user-attachments/assets/c5a042c2-7c3f-4e3b-9ddd-a42d9935183b/>

Now when the user generates meeting notes, an additional JSON is sent to the AWS S3 bucket containing info about each chosen recipient. Using this info, an AWS lambda requests generations "tailored" to each recipient from the OpenAI API.

### Data Used to Tailor Generations:
- Individual info - Information about a specific individual, inputted manually by the user:

- Which groups the individual is apart of
- Group info

## Generations available to send recipients
- Time and date (always available)
- Location
- Summary
- Transcript
- actionable items
- decisions made
- names of meeting participants
- topics discussed
- meeting purpose
- next steps
- any corrections to previous meeting
- key questions
