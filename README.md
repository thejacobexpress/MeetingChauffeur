# MeetingChauffeur
Record meetings and send helpful, AI generated, *tailored to each recipient* notes about those meetings to the stakeholders of your choice!

No need to worry if you missed a meeting or were late to one. **All of the important information you need can be sent to you via MeetingChauffeur by one of the meeting participants, in a neat email *specifically procured just for you.***

## Architecture Diagram
<img width="3966" height="2496" alt="Blank diagram(3)" src="https://github.com/user-attachments/assets/eac18c71-f783-4b7e-9d09-b32ee4e533be" />

## How Does it Work?
[See the Python code for the AWS lambda functions](AWS_Lambdas_NOT_INCLUDED_IN_ACTUAL_PROJECT)
### Sending Data to Backend
Using the MeetingChauffeur app (made using Dart and Flutter), users can record a meeting and send it (as a .m4a file) to an AWS S3 bucket (essentially simple storage inside of an AWS server). At the same time the .m4a file is sent, JSONs containing user-selected information about their generations are sent to the AWS S3 bucket, also from the app.

### Generating .txt Files (meeting notes) From Recording
When the .m4a file is uploaded to the AWS S3 bucket, an AWS lambda function is triggered. This lambda takes that .m4a file and uses the OpenAI API (specifically the Whisper-1 model) to translate that audio into text. Then, continuing to use the OpenAI API (GPT-4.1), text is generated based on the user-selected info within the JSONs sent earlier. This text is saved onto .txt files within the AWS S3 bucket.

### Sending Generated Notes to Stakeholders
The app then attempts to download the generated .txt files repeatedly (returning a StorageException each time the file cannot be found before it will be generated). Once it downloads all of them, the notes are presented to the app user to look over before sending. Once the user presses "Send", the .txt files are sent to another AWS lambda via an AWS Gateway API using a POST operation. From there, the lambda uses the Gmail API to send the generated text to the recipients.

And BOOM! It's easy to send meeting notes specificially tailored to each indiviudal stakeholder.

## Example
https://github.com/user-attachments/assets/0cbf6836-bea5-4edf-a883-15aec0edf5a8

**Here's a better look at everything in the video:**

### Transcript from Chief Marketing Officer

This is the Chief Marketing Officer of McKee Co. speaking. I think that we can all agree that the marketing department has been ran very lean recently. I believe that we can hire some new workers and really just improve the overall effectiveness of the department. I believe that the executive department would be very helpful in this matter.

### Tailored Action for Chief Executive Officer

Review current staffing levels and budget allocation for the marketing department to assess the feasibility of new hires.

Coordinate with the Chief Marketing Officer to identify urgent talent gaps and prioritize roles for recruitment.

Include marketing department resourcing needs as a discussion item in the next executive meeting focused on the new strategic plan.

Evaluate how additional marketing resources align with broader company objectives and strategic initiatives.

Provide executive guidance on integrating new hires into the existing team to maximize department performance.

### Email to Chief Executive Officer
<img width="1647" height="714" alt="image" src="https://github.com/user-attachments/assets/5d869401-ca8f-4253-b41c-0f4133d55326" />

## Generations Users can Send to Recipients
Users can choose what kind of generated notes to send their recipients. Here are the options they can choose from:

- Date and Time
- Location
- Summary
- Transcript
- Actionable Items
- Decisions Made
- Names of Meeting Participants
- Topics Discussed
- Meeting Purpose
- Next Steps
- Any Corrections to Previous Meeting
- Key Questions
<img width="250" height="542" alt="IMG_9555" src="https://github.com/user-attachments/assets/47ba6e2d-ba1a-477d-b6c5-ab39d37a0d04" />
<img width="250" height="542" alt="IMG_9556" src="https://github.com/user-attachments/assets/eec4f167-670d-4c1f-a6bc-21d03c494286" />

## How are the Generations "Tailored"?
The user can choose to tailor emails by checking the "Tailored" checkbox.

<img width="250" height="542" alt="tailored gif" src=https://github.com/user-attachments/assets/c5a042c2-7c3f-4e3b-9ddd-a42d9935183b/>

Now when the user generates meeting notes, an additional JSON is sent to the AWS S3 bucket containing info about [each chosen recipient](#choosing-recipients). Using this info, an AWS lambda requests generations "tailored" to each recipient from the OpenAI API.

### Data Used to Tailor Generations:
- **Individual info** - Information about a specific individual, inputted manually by the user.
- **Involved groups** - The specific groups/departments that an individual is involved in, inputted manually by the user.
- **Group info** - Information about a group, inputted manually by the user.
<img width="250" height="542" alt="tailored gif" src=https://github.com/user-attachments/assets/91c17569-79d3-47c8-b90d-6dc0f3963492/>
<img width="250" height="542" alt="tailored gif" src=https://github.com/user-attachments/assets/d0e8d465-105c-40e7-9889-4227b4b178e1/>
<img width="250" height="542" alt="tailored gif" src=https://github.com/user-attachments/assets/c8887c5c-5575-4c64-8f58-e902a82f208f/>

Compiling those 3 pieces of information about an individual, meeting notes are generated and sent, ensuring that the only information the recipient receives is important to them specifically.

## Recipient Organization
In MeetingChauffeur, there are two kinds of recipients: **Individuals** and **Groups**. Making use these two kinds of recipients, the user can make new individuals, make new groups that contain those individuals, and easily edit information within both.
<img width="250" height="542" alt="tailored gif" src=https://github.com/user-attachments/assets/48d309de-20e6-4210-b4fd-8a68c4d311d5/>
<img width="250" height="542" alt="tailored gif" src=https://github.com/user-attachments/assets/a663bc22-b42b-470f-b307-5f308082d619/>
<img width="250" height="542" alt="tailored gif" src=https://github.com/user-attachments/assets/20856d0c-59d5-469c-9086-a0c42e3e25ef/>

<a name="choosing-recipients"></a>
After the user has configured their **individuals** and **groups**, they can send generated notes to them.

<img width="250" height="542" alt="tailored gif" src=https://github.com/user-attachments/assets/5eb17390-6a65-4f92-9489-b87e94f3da17/>
