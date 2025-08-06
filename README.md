# MeetingChauffeur

## Architecture Diagram
<img width="3966" height="2496" alt="Blank diagram(2)" src="https://github.com/user-attachments/assets/935ca29c-ac3e-42d2-9003-2b528173b830" />

## Summary of the App
The MeetingChauffeur app records co-workers' meetings, then processes those audio files to generate helpful notes tailored to each individual recipient via the OpenAI API, and sends those notes via the Gmail API.

## How are the generations "tailored"?
The user can choose to tailor emails by checking the "Tailored" checkbox.

<img width="250" height="542" alt="tailored gif" src=https://github.com/user-attachments/assets/d6b300bf-44a4-4edb-8d95-09adc7843fe4/>

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

## Data used to tailor generations for individuals:
- Individual info
- Group info
- Which groups individuals are in
