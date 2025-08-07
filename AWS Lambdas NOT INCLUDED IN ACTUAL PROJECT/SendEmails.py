import json
import boto3
from email.message import EmailMessage
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import base64
import google.oauth2.credentials as c
from googleapiclient.discovery import build

def getSpecRecipientsList(data):
    recipientsList = []
    for (key, value) in data.items():
        if value != "":
            recipientsList.append(key)
    print("recipients list: " + str(recipientsList))
    return recipientsList

def getGenRecipientsString(data, tailorData):
    if "recipients" in data:
        return data["recipients"]["content"]

    recipientsList = []
    for (key, value) in tailorData.items():
        if value == "":
            recipientsList.append(key)
    recipientsString = ""
    for index, recipient in enumerate(recipientsList):
        if index == 0:
            recipientsString = recipient
        else:
            recipientsString += ", " + recipient
    return recipientsString

def createEmailStructure(data):
    content = "Hello from McKeeAI! \n\nHere are some insights about your meeting:\n"
    for(key, value) in data.items():
        content += ("\n\n" + key.capitalize() + "\n" + value)
    content += "\n\nThank you for using McKeeAI!"
    return content

def createHTMLEmailStructure(data):
    content = "<p><strong>Hello from McKeeAI!</strong><br><br> Here are some insights about your meeting:<br><br></p>"
    for(key, value) in data.items():
        newValue = ""
        for index, char in enumerate(value):
            if index == len(value)-1:
                newValue += char
                break
            if(value[index+1].isdigit() and key != "date_time" and key != "location"):
                newValue += "<br>"
            newValue += value[index]
        content += ("<p><strong>" + key.capitalize() + "</strong></p><p>" + newValue + "</p>" if key != "date_time" and key != "next_steps" else "<p><strong>" + key.replace("_", " ").title() + "</strong></p><p>" + newValue + "</p>")
    content += "<p><br><br>Thank you for using McKeeAI!</p>"
    return content

def lambda_handler(event, context):

    try:
        request_body = event['body']
        data = json.loads(request_body)

        bucketName = 'meetingsummarizerapp3e62d7c6d4654f17bc7d042793aca958-dev'

        tokenLoc =  "/tmp/token.json"
        credentialsLoc = "/tmp/credentials.json"
        tailorLoc = data['tailorFilePath']['path']
        subject = data['subject']['content']
        s3 = boto3.client('s3')
        s3.download_file(bucketName, "public/service_account/credentials.json", credentialsLoc)
        s3.download_file(bucketName, "public/service_account/token.json", tokenLoc)
        s3.download_file(bucketName, tailorLoc, "/tmp/tailor.json")

        tailorFile = open("/tmp/tailor.json", "r")
        tailorData = json.load(tailorFile)

        creds = None
        try:
            creds = c.Credentials.from_authorized_user_file(tokenLoc, ['https://mail.google.com/'])
        except FileNotFoundError as e:
            flow = InstalledAppFlow.from_client_secrets_file(
                credentialsLoc, ['https://mail.google.com/']
            )
            creds = flow.run_local_server(port=0)
            open(tokenLoc, 'w').write(creds.to_json())

        count = 0
        for(key, value) in data.items():
            if key == "General" and getGenRecipientsString(data, tailorData) != "":
                service = build('gmail', 'v1', credentials=creds)

                message = MIMEMultipart("alternative")

                plain = MIMEText(createEmailStructure(data[key]), 'plain')
                message.attach(plain)
                html = MIMEText(createHTMLEmailStructure(data[key]), "html")
                message.attach(html)

                message["To"] = getGenRecipientsString(data, tailorData)
                message["From"] = "McKeeAI<mckeeartificialintelligence@gmail.com>"
                message["Subject"] = subject

                encodedMessage = base64.urlsafe_b64encode(message.as_bytes()).decode()

                createMessage = {"raw": encodedMessage}
                draft = service.users().messages().send(userId="me", body=createMessage).execute() # Send email!
                print("General email sent to " + getGenRecipientsString(data, tailorData))

            elif key != "tailorFilePath" and key != "subject" and key != "recipients" and key in getSpecRecipientsList(tailorData):
                print("key: " + key)
                service = build('gmail', 'v1', credentials = creds)

                message = MIMEMultipart("alternative")

                plain = MIMEText(createEmailStructure(data[key]), 'plain')
                message.attach(plain)
                html = MIMEText(createHTMLEmailStructure(data[key]), "html")
                message.attach(html)

                print("address: " + key)
                message["To"] = key
                message["From"] = "McKeeAI<mckeeartificialintelligence@gmail.com>"
                message["Subject"] = subject

                encodedMessage = base64.urlsafe_b64encode(message.as_bytes()).decode()

                createMessage = {"raw": encodedMessage}
                draft = service.users().messages().send(userId="me", body=createMessage).execute() # Send email!
                print("Tailored email sent to " + str(count))
                count += 1

        return {
            'statusCode': 200,
            'headers' : {
                'Content-Type' : 'application/json'
            },
            'body': json.dumps('success')
        }

    except Exception as e:
        return {
            'statusCode': 500,
            'headers' : {
                'Content-Type' : 'application/json'
            },
            'body': json.dumps(str(e))
        }

    # payload ={
    #     "iss": "mckeeai@meeting-summarizer-463020.iam.gserviceaccount.com",
    #     "sub": "mckeeai@meeting-summarizer-463020.iam.gserviceaccount.com",
    #     "aud": "https://gmail.googleapis.com",
    #     "iat": int(time.time()),
    #     "exp": int(time.time()) + 3600
    # }
    # additional_headers = {
    #     "kid": "928378e7166934e58179af1386a0b1a9c22276a9"
    # }
    # signed_jwt = jwt.encode(payload, private_key, headers=additional_headers, algorithm="RS256")
