# TxtClient_GPT
A simple selfcontained windows common controls gui frontend for chatGPT

Now supports chatgpt_3.5_turbo and davinci003 models.

Major cost is chat history is not working properly and not documented, i have attempted to reverse engineer the payload unsucesdfully so far.

to do, add ability to launch test script received from chatGPT filelessly through a named pipe.

<img width="344" alt="Clipboarder 2023 07 31-004" src="https://github.com/wolfman616/TxtClient_GPT/assets/62726599/860bc1b5-8dc1-4b12-befc-6a986a09682c"> <img src="https://i.imgur.com/n6BMwLa.gif">

<img width="322" alt="Clipboarder 2023 07 31-007" src="https://github.com/wolfman616/TxtClient_GPT/assets/62726599/ac0b948d-0ab4-4473-81c0-81d0c2dcdb5e">

![image](https://github.com/wolfman616/TxtClient_GPT/assets/62726599/6f1543f7-b9f4-4aaa-a483-f9293d53f986)

![image](https://github.com/wolfman616/TxtClient_GPT/assets/62726599/94f353c7-7a87-44dc-ba31-c5c40c9ddcbc)

![image](https://github.com/wolfman616/TxtClient_GPT/assets/62726599/49460a66-2958-4ae7-b59c-41a7487daad0)

![image](https://github.com/wolfman616/TxtClient_GPT/assets/62726599/f3c6dfd7-d886-4906-8ef6-fd5a7668f8fe)

should now accept long string of code etc correctly,

maxtokens is adjusted to half the string length before subtracting from maxtokens as i was getting some errors.
