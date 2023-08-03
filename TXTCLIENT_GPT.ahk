#NoEnv ; (MW:2023) (MW:2023) TxtClient_GPT ; I use 144dpi this may be the only DPI working as intended/ This is untested.
#NoTrayicon
ListLines,Off
SetBatchLines,-1
SetWinDelay,-1
#Persistent
#Singleinstance,Force
Setworkingdir,% (splitpath(A_AhkPath)).dir
DetectHiddenWindows,On
DetectHiddenText,	On
SetTitleMatchMode,2
SetTitleMatchMode,Slow
coordMode,ToolTip,Screen
coordmode,Mouse,	Screen

InitialQuestion:= A_args[1]?  A_args[1] : "" ; "Marius is " ; test*

loop,parse,% "VarZ,Menus,Hookinit,Optionz,Dimz,RegRead,OnMessages,Main,StatusBarInit,ShowMainGui",`,
	 gosub,% a_loopfield
return,

Optionz:
Opt_DebugPayload:= False
MattTheme:= False ;set to false if you are not Matt

, Opt_Appear_TransitionN	:= " slide vpos "
, Opt_Appear_TransitionS	:= " slide vneg "
, Opt_Appear_TransitionDurMs:= 200
, Opt_Hide_TransitionN		:= " Slide VNeg "
, Opt_Hide_TransitionS		:= " Slide Vpos "
, Opt_Hide_TransitionDurMs	:= 150
 
, Opt_GuiBlur				:= False ; works with AeroGlass
, Opt_GuiTrans			:= False ; works with AeroGlass
, Opt_SpawnOnMouse	:= True
, Opt_MultiLang			:= False
, Opt_SeeResultJson	:= False

; Gpt options in json payload ;
, Opt_Tokens:= False
, Opt_MaxTokens:= 3999
, Opt_Temperature:= 0.001 ; 0-Strict / 1-Creative ;
return,

Dimz:
opt_guicolor:= 070011
, opt_gui_fontcol:= "c7488D8"
, Const_OtherGuiMargin:= MattTheme? 10 : 18 ; other system metrics for window frame dimension approximation
, Opt_GuiQuestionLines:= "r2"
, Opt_GuiTabMarginSz	:= 18
, opt_GuiTabTopMargin := 20
, Opt_Gui_Main_W			:= 450
, Opt_Gui_Question_W	:= Opt_Gui_Main_W -100
, Opt_Gui_Main_H			:= 320
, Opt_GUI_Answer_W		:= Opt_Gui_Main_W - Const_OtherGuiMargin -Opt_GuiTabMarginSz -24
, Opt_GUI_Answer_H		:= 80 ; Opt_Gui_Main_h - opt_GuiTabTopMargin*4
, Opt_Guitab_W				:= Opt_Gui_Main_W -( 2*opt_GuiTabMarginSz ) -Const_OtherGuiMargin
return,

^+v::	; paste multiline test
string:=","
if(instr(clipboard,chr(10))) {
	Loop,Parse,clipboard,`n
		string.= a_loopfield ",`n"
		, count++
	GuiControl,,% InputQuestionhwnd,% string
	GuiControl,Choose,r1,ahk_id   %InputQuestionhwnd%
} return,

OnMessages:
onexit,exit
onmessage(0x201,"WM_LBUTTDOWNUP")
;onmessage(0x202,"WM_LBUTTDOWNUP")
OnMessage(0x6,"onActiv8")
OnMessage(0x404,"AHK_NOTIFYICON")
return,

ShowMainGui:
mousegetpos,x_,y_
( x_> (a_screenwidth -Opt_Gui_Main_W-80))? x_ -= Opt_Gui_Main_W-120 : ( x_<64 ? x_:= 120)

( y_> (a_screenheight -Opt_Gui_Main_h-80))? x_-= Opt_Gui_Main_W-120 : ( y_<64 ? y_:= 120)

winmove(hGuiA,x_ -(Opt_Gui_Main_W/2),y_ -(Opt_Gui_Main_H/5))

Gui,Show,% (Opt_SpawnOnMouse? ("x" . x_ -(Opt_Gui_Main_W/2) . " y" . y_ -(Opt_Gui_Main_H/5)):())  " w" . Opt_Gui_Main_W . " h" . Opt_Gui_Main_H . " NA HIDE",% a_scriptname " - GuiHWND: " hGuiA

settimer,Trans_Enact_OrNot,-10

if(!api_key)
	gosub,DataEntryWindow
	;msgbox,% "please enter api key in the settings tab."
Gui,PleaseWait:Show,Na Hide

(wingetpos(hguia).y > (a_screenwidth/2))? Opt_Appear_Transition:= Opt_Appear_TransitionS : Opt_Appear_Transition:= Opt_Appear_TransitionN
(Opt_GuiBlur? dBlur(hguia))
WinAnimate(hGuiA,"activate " Opt_Appear_Transition,Opt_Appear_TransitionDurMs)
winset,style,+0x40000,ahk_id %hGuiA%

settimer,Trans_Enact_OrNot,-1000

GuiControl,hide,AnswerEdit ;GuiControl,hide,ToggleListView ;GuiControl,Move,Answer, % "w" Opt_Gui_Main_H

if(Opt_MultiLang)
	GuiControl,,Answer,% "ChatGPT Response translated with Google Translate:" ;GuiControl,Move,AnswerEdit2, % "y+140 h" 500 ;GuiControl, hide, AnswerEdit2
GuiControl,hide,TextTranslate ; https://ahkde.github.io/docs/v1/lib/GuiControl.htm
EM_SETCUEBANNER(InputQuestionhwnd, a_space "to ChatGPT3.5")
if(InitialQuestion) {
	GuiControl,Text,%InputQuestionhwnd%,% InitialQuestion
	gosub,ButtonClick
} GuiControl,Focus,% InputQuestionhwnd
Return,

onActiv8(wparam="",lparam="",msg="",hwnd="") {
	local static smicon:= b64_2_hicon(icoB64["smicon64"])
	, lgicon:= b64_2_hicon(icoB64["lgicon64"])
	,large:=1, small:=0, m:= 0x80
	SendMessage,m,small,smicon,,ahk_id %hWnd% ;WM_SETICON,ICON_SMALL
	SendMessage,m,large,lgicon,,ahk_id %hWnd% ;WM_SETICON,ICON_LARGE
	Return,ErrorLevel
}

WM_LBUTTDOWNUP(wparam,lparam,umsg,hwnd) {
	static xs, ys, closedeye
	(!closedeye? closedeye:=b64_2_hicon(icoB64["EyeClose48"]))
	global SbarhWnd,answer,AnswerEdithwnd,copiedthis
	if(hwnd=AnswerEdithwnd)||(hwnd=AnswerEdithwnd2)
		return,

	xCs:= lParam &0xffff, yCs:= lParam>>16

	coordmode,Mouse,Screen
	ControlGetText,copiedthis , , ahk_id %SbarhWnd%
	mousegetpos,,,hwndmouse,ctrlhwndmouse,2
	switch,ctrlhwndmouse {
		case,hGuiA,tabcontrolhwnd: PostMessage,0xA1,2 ; WM_NCLBUTTONDOWN - Same as dragging window by its tittlebar.
		case,SbarhWnd: if(xcs<55) {
				gui,Submit,NoHide
				ss:= wingetpos(SbarhWnd)
				tooltip,% "Hiding double click tray to show...",ss.x-100,ss.y-35.1
				SendMessage,0x40F,0,% closedeye,,ahk_id %SbarhWnd%
				settimer,SBIconReset,-480
				settimer,ttStop,-1180
				settimer,HideMainGui,-1600
				return,
			} PostMessage,0xA1,2 
		case,AnswerEdithwnd2,AnswerEdithwnd: msgbox,%	"sdaads " clipboard:= answer
		default:PostMessage,0xA1,2
	} return,
;	switch,umsg {
;		case,513 : mousegetpos,xs,ys
;			sleep 200, mousegetpos,xn,yn
;			if(xn!=xs||yn!=Ys) {
;				PostMessage,0xA1,2 ; WM_NCLBUTTONDOWN
;				return,1
;			}	else,return,
;		case,514 : mousegetpos,xf,yf
;			return,
;	} 	;tooltip % wparam "`n " lparam "`n"  umsg
}

Main:

(MattTheme? Aero_StartUp())

menu,tray,icon,% "HICON: " b64_2_HICON(icoB64["tray24"])	;24x24 @144 dpi (SM_CXSMICON,SM_CYSMICON)
menu,tray,icon

	; api_key := "thisApikey"  ; https://platform.openai.com/account/api-keys ; optionally Your OpenAI API-key.
	; The endpoint URL for the GPT-3 API.


Gui,PleaseWait: -dpiscale +LastFound +AlwaysOnTop +Disabled -resize -Caption +ToolWindow  +hwndhGUIPleaseWait +0x40000
Gui,PleaseWait: Color,%opt_guicolor%
Gui,PleaseWait: Add,Text,xm vTextA w120 Center,% "Please wait..."
Gui,PleaseWait: Add,Text,xs vTextB w99 Center,% "Loading..."
Gui,PleaseWait: Show,% "x300 y" (A_ScreenHeight/2),% hGUIPleaseWait

Gui,New,-dpiscale +hwndhGuiA +MaxSize%Opt_Gui_Main_W%x%Opt_Gui_Main_H% +MinSize%Opt_Gui_Main_W%x%Opt_Gui_Main_H% +ToolWindow -caption +AlwaysOnTop +LastFound -0x40000 -DPIScale,% hGuiA ;+e0x80000
gui,color,% opt_guicolor,% opt_guicolor
if(Opt_fontlarge)
	Gui,Font,s12

HeaderTitles:= "Main"

(Opt_MultiLang? HeaderTitles.= "|TranslateJson")

(opt_seejson? HeaderTitles.= "|ResultJson")

HeaderTitles.= "|Settings"

Gui,Add,Tab3 ,% "c" opt_guicolor " hwndtabcontrolhwnd x" opt_GuiTabMarginSz " y" opt_GuiTabTopMargin " w" Opt_Guitab_W " h" Opt_Gui_Main_H-38,% HeaderTitles

Gui,Tab,% "Main" ;Gui,Add,Text,,Question to ChatGPT:
if(opt_richtext_question) {
	hModuleME := DllCall("kernel32.dll\LoadLibrary", Str,"msftedit.dll", Ptr)
	vPos := (!vShowBuiltIn1 && !vShowBuiltIn2) ? "y30" : "" ;make room for toolbar if needed
	Gui,Add,Custom,% vPos " ClassRICHEDIT50W vInputQuestion hwndInputQuestionhwnd x" opt_GuiTabMarginSz + 4 " y41 h28 w" Opt_Gui_Question_W "c" opt_guicolor
	ControlSetText,RICHEDIT50W1,% "RICH 1",% "ahk_id " hGui
}	else {
	Gui,Add,Edit,% " vInputQuestion hwndInputQuestionhwnd x20 y" opt_GuiTabTopMargin +31 " h32 w" Opt_Gui_Question_W " " Opt_GuiQuestionLines " " opt_gui_fontcol
	GuiControl, Choose, r4,ahk_id   %InputQuestion%
	Gui,Font,c7488D8

;	GuiControl,% InputQuestionhwnd, , , , , 0xFFFFFF
	ControlSetText,% InputQuestionhwnd, , , , , 0xFFFFFF
}

SetExplorerTheme(tabcontrolhwnd)
winset,style,-0x2000,ahk_id %tabcontrolhwnd%
if(Opt_fontlarge)
	Gui,Font,s12 %opt_gui_fontcol%
Gui,Font,% opt_gui_fontcol

if(Opt_MultiLang) {
	Gui,Add,Text,Section,% "Source Language:"
	Gui,Add,Radio,ys Group gRadioGroupSelection Checked1 vMyRadioA,% "German"
	Gui,Add,Radio,ys gRadioGroupSelection vMyRadioB,% "English"
	Gui,Add,Radio,ys gRadioGroupSelection vMyRadioC,% "Mix"
} Gui,Add,CheckBox,ys gToggleListView checked vToggleListView,% "ListView History"

Gui,Tab,% "Settings"
if(Opt_fontlarge)
	Gui,Font,s12
Gui,Add,Text,x38 y63 Section,% "API Key:"
if(Opt_Tokens) {
	Gui,Add,Text,ys x+110,% "total_tokens:"
	Gui,Add,Edit,ys w220 vTextApiKey,% "Counter"
} if(Opt_fontlarge)
	Gui,Font,s11
Gui,Add,Edit,% opt_gui_fontcol " x112 y60 vApi_key w" Opt_Gui_Main_W-165 " h25 center Password",% api_key
if(Opt_fontlarge)
	Gui,Font,s12
Gui,Tab,% "Main"
Gui,Add,Button,% "gButtonClick x" 19 + Opt_Gui_Question_W " y50 w49 h50 default Section",% "Ask"

if(Opt_MultiLang)
	Gui,Add,Button,ys gTranslateBeforeAsk w200 h30,% "Translate before Ask"

Gui,Add,Button,ys gReloadApp +hwndreloadbutthwnd w68 h30, % "Reload"
guicontrol,hide,% reloadbutthwnd
Gui,Add,Text,x24 y80 vAnswer +hwndAnswerHeadingHwnd,% "Answer..."
guicontrol,Hide,% AnswerHeadingHwnd

if(opt_richtext_answer) {
	hModuleME := DllCall("kernel32.dll\LoadLibrary", Str,"msftedit.dll", Ptr)
	vPos := (!vShowBuiltIn1 && !vShowBuiltIn2) ? "y30" : "" ;make room for toolbar if needed
	Gui,Add,Custom,% vPos " ClassRICHEDIT50W  vAnswerEdit hwndAnswerEdithwnd x20 y80 r10 w%Opt_GUI_Answer_W%" Opt_GUI_Answer_W " h" Opt_GUI_Answer_H
	ControlSetText,RICHEDIT50W1,% "RICH 1", % "ahk_id " hGui
}	else,Gui,Add,Edit,% "vAnswerEdit +hwndanswerEdithwnd x20 y96 r9 w" Opt_GUI_Answer_W " " Opt_GuiQuestionLines " h" Opt_GUI_Answer_H " c" opt_guicolor

;Gui,Add,Edit,vAnswerEdit +hwndAnswerEdithwnd x20 y80 r10 w%Opt_GUI_Answer_W%

Gui,Add,Text,vTextTranslate,% "Translate"
Gui,Add,Edit,% "vAnswerEdit2 +hwndAnswerEdithwnd2 x20 y" opt_GuiTabTopMargin +79 " r8 w" Opt_GUI_Answer_W " h" Opt_GUI_Answer_H " " opt_gui_fontcol

if(opt_seejson) {
	Gui,Tab,% "TranslateJson"
	Gui,Add,Text,,Json
	Gui,Add,Edit,vJsonEdit r30 w%Opt_GUI_Answer_W%,
}

if(Opt_SeeResultJson) {
	Gui,Tab,% "ResultJson"
	Gui,Add,Text,,Result
	Gui,Add,Edit,vResultEdit x100 r30 w%Opt_GUI_Answer_W% ;Gui,Show,% "x100 y" (A_ScreenHeight/10), % a_scriptname " - GuiHWND: " hGuiA
} return,

Trans_Enact_OrNot:
; (Opt_GuiTrans? VarSetCapacity(rect0,16,0xff) , DllCall("dwmapi\DwmExtendFrameIntoClientArea","uint",hGuiA,"uint",&rect0))
if(Opt_GuiTrans) {
 VarSetCapacity(rect0,16,0xff)
 DllCall("dwmapi\DwmExtendFrameIntoClientArea","uint",hGuiA,"uint",&rect0)
} return,

;~+4::
DataEntryWindow:
gui_W:=300, gui_H:=138
WS_POPUP := 0x80000000, WS_CHILD := 0x40000000

Gui,1:+LastFound +hWndhGui1 +Owner +AlwaysOnTop +hwndghwnd +0x40000 -0x400000
Gui,1:Color,181535
;Gui, 1: Add, Picture, w300 h165 x0 y0 AltSubmit BackgroundTrans, %A_ScriptDir%\Ressources\grey.png
Gui,1:Font,s11 bold,Segoe UI
Parent_ID := WinExist()
Gui,2:Font,s11 bold,Segoe UI ;Gui, 2:margin,1,1
Gui,2:-Caption +hWndhGui2 +%WS_CHILD% -%WS_POPUP%
gui,2:Color,000000,000000
Gui,2:Font,s11 bold, Segoe UI
Gui,2:Add,Edit,x15 y+50 r1 w270 Limit51 +hwndAPIEntryEdithWnd Password vPassword
gui,1:Add,Picture,X0 Y0 BackgroundTrans,% a_scriptdir "\glass.png"
Gui,2:Add,Button, y+15 x205 w80 h30 gapiSubmitKey Default,Submit
Gui,2:+LastFound
Child_ID := WinExist()
DllCall("SetParent","uint",Child_ID,"uint",Parent_ID)
Gui,2:Add,Text,vtext1 %opt_gui_fontcol% w270 x17 y17 AltSubmit,% "Please enter API Key:"
OnMessage(0x6,"col")
Gui,1:Show,x-300 y-200 w%gui_W% h%gui_H%,% "no_glass" ;Gui, 1: Add, Text, vtext2 w270 x15 y15 AltSubmit, Please enter the Password:

Gui,2: Show, x0 y0 w300 h135,no_glass
Gui,1: hide

dBlur(ghwnd)

win_move(ghwnd,A_screenwidth*.5-gui_W,A_screenheight*.5-gui_H,"","","")
Win_Animate(ghwnd,"hneg slide",200)
winactivate,ahk_id %ghwnd%
GuiControl,Focus,% APIEntryEdithWnd
return,

apiSubmitKey:
Gui,2:Submit,NoHide
Gui,1:Submit,NoHide
;try,api_key:= Password
result:= strlen(Password)=51? "Good" : "Bad"
Gui,2:Destroy
Gui,1:Destroy
if(result="Bad") {
	msgbox,262145,error,% "api-key length missmatch (51 chars), try again.",60
	ifmsgbox,ok
		gosub,DataEntryWindow
}return,


col() {
	static go:= !false
	go:= winactive(ghwnd)? true : false
	(go? (col:=181535,col2:="c220040", col3:="c99aafe") :  (col:= 050513, col2:= "c200570", col3:="c6688aff"))
	Gui, 1: Color,%col%
	Gui, 1: Font,%col2%
	Gui, 2: Font,%col3%
	guicontrol,Font,text1
	guicontrol,Font,text2
}

;-=====================================================================================================================================


StatusBarInit:
init:= 0, inc:= Opt_Gui_Main_W -38
(init=0? Eye48_hIcon:= b64_2_hicon(icoB64["Eye48"]))
Gui,Add,StatusBar,% "+hWndSbarhWnd +e0x2000000 "
SB_SetParts(inc,100)
SendMessage,0x40F,0,% Eye48_hIcon,,ahk_id %SbarhWnd%
return,

EM_SETCUEBANNER(HWND, Text) {	;EM_SETCUEBANNER-0x1501: msdn.microsoft.com/en-us/library/bb761639(v=vs.85).aspx
	Return,DllCall("SendMessage","Ptr",HWND,"UInt",0x1501,"Ptr",True,"WStr",Text,"Ptr")
}

RadioGroupSelection:
return,

ToggleListView:
return,

HideMainGui:
(wingetpos(hguia).y > (a_screenwidth/2))? Opt_Hide_Transition:= Opt_Hide_TransitionS :Opt_Hide_Transition:= Opt_Hide_TransitionN
(isWindowVisible(hGuiA)? WinAnimate(hGuiA,"hide " . Opt_Hide_Transition,Opt_Hide_TransitionDurMs))
return,

TranslateBeforeAsk:
Gui,Submit,NoHide
GuiControl,,InputQuestion,% InputQuestionOLD
return,

ButtonClick:
Gui,Submit,NoHide
GuiControl,% AnswerHeadingHwnd,show
Gui,PleaseWait:Show,% "x300 y" (A_ScreenHeight/2), % AttemptNo
AttemptNo:= 1

api_url:= "https://api.openai.com/v1/engines/text-davinci-003/completions"
	; Set up whttpr session.
try,{
	whttpr:= ComObjCreate("WinHttp.WinHttpRequest.5.1")
	whttpr.Open("POST", api_url)
	whttpr.SetRequestHeader("Content-Type","application/json")
	whttpr.SetRequestHeader("Authorization","Bearer " api_key)
	; Prepare JSON payload.
	jsonY =
}

jsonY:= thisJson(InputQuestion)
if(Opt_DebugPayload)
	msgbox,% jsonY ; for debug purposes

; Send the request and get the response
whttpr.Send(jsonY)
result := whttpr.ResponseText
test := result
;msgbox,, % "A_LineNumber. " A_LineNumber " - isObject", % isObject(result) ;msgbox,, % "A_LineNumber. " A_LineNumber " - result", % result

If test contains error
{
	AttemptNo++
	GuiControl,,AnswerEdit2,% "error"
	fileappend,% error "`n",% a_scriptdir "\chatGPT UI - mini - error A.txt"
	msgbox,,% "A_LineNumber. " A_LineNumber " - error A", % test,62
	;exitapp
	sleep,1000
;	GuiControl,PleaseWait:,TextB,% AttemptNo
	;GoTo,ButtonClick
}

If test =
{
	AttemptNo++
	GuiControl,,AnswerEdit2, error
	fileappend,% error "`n", % a_scriptdir "\chatGPT UI - mini - error B.txt"
	msgbox,,% "A_LineNumber. " A_LineNumber " - error B", % test,5
	;sleep,1000
	;GuiControl, PleaseWait:, TextB, % AttemptNo
	;GoTo, ButtonClick
}

Array:= [] ;Array := JSON.Load(result)
Array:= JsonToAHK(result) ;msgbox,, % "A_LineNumber. " A_LineNumber " - isObject", % isObject[Array)

i:= 1

While(i< 100) { ; ToolTip,% i ;
	setTimer,ttStop,-3000
	Answer:= Array["choices"][i]["text"]
	If(Answer!="")
		Break,
	i++
}

Result:= RegExReplace(Result,"^[\s\r\n]+|[\s\r\n]+$","")  ; remove leading and trailing whitespaces
Answer:= RegExReplace(Answer,"^[\s\r\n]+|[\s\r\n]+$","")  ; remove leading and trailing whitespaces
;Answer := RegExReplace(Answer, "(?:\r\n|\r|\n)", " ")       ; replaces line breaks with space
Answer:= StrReplace(Answer,"Ã",	"ß")
Answer:= StrReplace(Answer,"Ü",			"Ä")
Answer:= StrReplace(Answer,"Ã¤",		"ä")
Answer:= StrReplace(Answer,"Ü",	"Ö")
Answer:= StrReplace(Answer,"Ã¶",		"ö")
Answer:= StrReplace(Answer,"Ã",			"Ü")
Answer:= StrReplace(Answer,"Ã¼",		"ü")
Answer:= StrReplace(Answer,"Ü¼",		"ü")
Answer:= StrReplace(Answer,"â",			"-")
Answer:= StrReplace(Answer,"Â°",			"°") ; 100°C 100 Degrees
; GemeinschaftsgefÜ¼hl. allmÃ¤chtige, Â° =
; https://www.autohotkey.com/boards/viewtopic.php?style=19&p=384889#p384889
	         arr := {"Ã¤": "ä"
			,"Ã¼"	: "ü"
			,"ï¿½": "ü"
			,"Ã¶"	: "ö"
			,"ÃŸ"	: "ß"
			,"Ãœ"	: "Ü"
			,"Â„"	: "„"
			,"Â“"	: "“"}
	for,key,val in arr
		StrReplace(Answer, key, val)

GuiControl,,AnswerEdit,% Answer? Answer : Result

; GuiControl,-Redraw,PleaseWait

GuiControl,, AnswerEdit2,% Answer

try,thisBeautifyJson:= BeautifyJson(Result)
GuiControl,,ResultEdit,% thisBeautifyJson

;GuiControl,, ResultEdit, % Result%

; Gui, PleaseWait: Destroy
Gui,PleaseWait:show,Hide
result =
thisAPI_completion_tokens := Array["usage", "completion_tokens"]
thisAPI_prompt_tokens     := Array["usage", "prompt_tokens"]
thisAPI_total_tokens      := Array["usage", "total_tokens"]
thisAPI_created		  := Array["created"] ; "`t"

   time := 1970
   ,time += thisAPI_created, s
   , diff -= A_NowUTC, h
   , time += diff, h
   FormatTime,TimeStamp,%time%,dd.MM.yyyy HH-mm-ss tt  ; 24.März.2018 05-20-37

   GuiControl,,TextApiKey,% "[ " thisAPI_total_tokens " ]   " TimeStamp

   thisLV_ADD:= InputQuestion "`t"
 		. Answer "`t"
 		. Answer2 "`t"
		  fileappend, % thisLV_ADD "`n", % a_scriptdir "\chatGPT UI - mini - history.txt"
      this_ADD := InputQuestion "`t"
 		. Answer "`t"
 		. Answer2 "`t"
 		. Array["choices", 1, "finish_reason"] "`t"
 		. Array["choices", 1, "index"] "`t"
 		. Array["choices", 1, "logprobs"] "`t"
 		. Array["choices", 1, "text"] "`t"
 		. Array["created"] "`t"
 		. Array["id"] "`t"
 		. Array["model"] "`t"
 		. Array["object"] "`t"
 		. Array["usage", "completion_tokens"] "`t"
 		. Array["usage", "prompt_tokens"] "`t"
 		. Array["usage", "total_tokens"] "`n"
      fileappend,% thisLV_ADD "`n",% a_scriptdir "\chatGPT UI - mini - history-FULL.txt"
      this_LV_Line:= InputQuestion "`t"
    . Answer "`t"
 		. Answer2 "`n"
		fileappend,% this_LV_Line "`n", % a_scriptdir "\chatGPT UI - mini - this_LV_Line.txt"
return,

ReloadApp:
Gui,Submit,NoHide
menu,tray,noicon
reload,
return

ttStop:
toolTip,
return

GuiClose:
ExitApp,

GuiEscape:
settimer,HideMainGui,-10
return,

; json = {"ItemN": 625, "Digital": ["", "", {"key": "value"}], "LocalDel": "Check"}
; ahkObj := JsonToAHK(json) ;MsgBox, % ahkObj["Digital", 3, "key"]

JsonToAHK(json, rec:= False) {
	static doc:= ComObjCreate("htmlfile")
				, __:= doc.write("<meta http-equiv=""X-UA-Compatible"" content=""IE=9"">")
				, JS:= doc.parentWindow
	if(!rec)
		obj:= %A_ThisFunc%(JS.eval("(" . json . ")"), True)
	else,if(!IsObject(json))
		obj:= json
	else,if JS.Object.prototype.toString.call(json) == "[object Array]" {
		obj := []
		Loop % json.length
				obj.Push( %A_ThisFunc%(json[A_Index - 1], True) )
	} else {
		obj:= {}
		keys:= JS.Object.keys(json)
		Loop,% keys.length {
				k:= keys[A_Index -1]
				obj[k]:= %A_ThisFunc%(json[k], True)
		}
	}	Return,obj
}
 
thisJson(ByRef Search_Input:= "Hello") { ; Build the JSON payload
	(instr(Search_Input,"\")? Search_Input:= strreplace(Search_Input,"\","\\"))  ;backslash escape char in JSON
	(instr(Search_Input,"/")? Search_Input:= strreplace(Search_Input,"/","//"))  ;fwdslash escape char in JSON
	(instr(Search_Input,chr(9))? Search_Input:= strreplace(Search_Input,chr(9)," "))  ;fwdslash escape char in JSON

	Search_Input:= RegExReplace(Search_Input,"`n","\n") ; newline chars
	Search_Input:= RegExReplace(Search_Input,"`" chr(34),"\" chr(34)) ;doublequote mark
	Search_Input:= RegExReplace(Search_Input, chr(126),"\" chr(126)) ;tilde
	MaxTokens:= round((Opt_MaxTokens/2)-(len:= strlen(Search_Input)))
	if(Opt_DebugPayload)
		msgbox % Search_Input
	jsonY:= "
(LTrim
{
 ""prompt"": " chr(34) Search_Input chr(34) ",
 ""max_tokens"": " MaxTokens ",
 ""temperature"": " Opt_Temperature "
}
)"
	Return,byref jsonY
}While(i< 100) { ; ToolTip,% i ;
	setTimer,ttStop,-3000
	Answer:= Array["choices"][i]["text"]
	If(Answer!="")
		Break,
	i++
} 

BeautifyJson(json, indent := "    ") {
	static Doc, JS
	if(!Doc) {
		Doc:= ComObjCreate("htmlfile")
		Doc.write("<meta http-equiv=""X-UA-Compatible"" content=""IE=9"">")
		JS:= Doc.parentWindow
	} Return JS.eval("JSON.stringify(" . json . ",'','" . indent . "')")
}

;################################################################################################################

;MsgBox, % GoogleTranslate("今日の天気はとても良いです")
;MsgBox, % GoogleTranslate("Hello, World!", "en", "ru")

GoogleTranslate(str,from:= "auto", to:= "de") {
   static JS:= CreateScriptObj(), _:= JS.( GetJScript() ):= JS.("delete ActiveXObject; delete GetObject;")

   json:= SendRequest(JS,str,to,from,proxy:= "")
		oJSON:= JS.("(" . json . ")")

	ATickCount:= A_TickCount
	try,thisBeautifyJson:= BeautifyJson(json)
	GuiControl,,JsonEdit,% thisBeautifyJson

	;try fileappend,% thisBeautifyJson,% a_ScriptDir "\" ATickCount "-Google Translate json_History ChatGTP.json.txt"
	;try run,% a_ScriptDir "\" ATickCount "-Google Translate json_History ChatGTP.json.txt"

	if(!IsObject(oJSON[1])) {
		Loop,% oJSON[0].length
			trans .= oJSON[0][A_Index -1][0]
	} else {
		MainTransText:= oJSON[0][0][0]
		Loop,% oJSON[1].length {
			trans .= "`n+"
			obj:= oJSON[1][A_Index-1][1]
			Loop,% obj.length {
				txt:= obj[A_Index - 1]
				trans .= (MainTransText = txt ? "" : "`n" txt)
			}
		}
	}

	if(!IsObject(oJSON[1]))
		MainTransText:= trans:= Trim(trans, ",+`n ")
	else,trans:= MainTransText . "`n+`n" . Trim(trans, ",+`n ")
	from:= oJSON[2]
	Return,trans:= Trim(trans, ",+`n ")
}

SendRequest(JS,str,tl,sl,proxy) {
	static http
	ComObjError(False)
	if(!http) {
			http:= ComObjCreate("WinHttp.WinHttpRequest.5.1")
			( proxy && http.SetProxy(2, proxy) )
			http.open("GET", "https://translate.google.com", True)
			http.SetRequestHeader("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:47.0) Gecko/20100101 Firefox/47.0")
			http.send()
			http.WaitForResponse(-1)
	}	http.open("POST", "https://translate.googleapis.com/translate_a/single?client=gtx"
								; or "https://clients5.google.com/translate_a/t?client=dict-chrome-ex"
			. "&sl=" . sl . "&tl=" . tl . "&hl=" . tl
			. "&dt=at&dt=bd&dt=ex&dt=ld&dt=md&dt=qca&dt=rw&dt=rm&dt=ss&dt=t&ie=UTF-8&oe=UTF-8&otf=0&ssel=0&tsel=0&pc=1&kc=1"
			. "&tk=" . JS.("tk").(str), True)

	http.SetRequestHeader("Content-Type", "application/x-www-form-urlencoded;charset=utf-8")
	http.SetRequestHeader("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:47.0) Gecko/20100101 Firefox/47.0")
	http.send("q=" . URIEncode(str))
	http.WaitForResponse(-1)
	Return,http.responsetext
}

URIEncode(str,encoding:= "UTF-8") {
	VarSetCapacity(var,StrPut(str,encoding))
	StrPut(str,&var,encoding)

	while(code:= NumGet(Var, A_Index - 1, "UChar"))  {
		bool:= (code > 0x7F || code < 0x30 || code = 0x3D)
		UrlStr.=bool? "%" . Format("{:02X}", code) : Chr(code)
	} Return,UrlStr
}

GetJScript() {
		script =
		(
			var TKK = ((function() {
				var a = 561666268;
				var b = 1526272306;
				return 406398 + '.' + (a + b);
			})());

			function b(a, b) {
				for (var d = 0; d < b.length - 2; d += 3) {
						var c = b.charAt(d + 2),
								c = "a" <= c ? c.charCodeAt(0) - 87 : Number(c),
								c = "+" == b.charAt(d + 1) ? a >>> c : a << c;
						a = "+" == b.charAt(d) ? a + c & 4294967295 : a ^ c
				}
				return a
			}

			function tk(a) {
					for (var e = TKK.split("."), h = Number(e[0]) || 0, g = [], d = 0, f = 0; f < a.length; f++) {
							var c = a.charCodeAt(f);
							128 > c ? g[d++] = c : (2048 > c ? g[d++] = c >> 6 | 192 : (55296 == (c & 64512) && f + 1 < a.length && 56320 == (a.charCodeAt(f + 1) & 64512) ?
							(c = 65536 + ((c & 1023) << 10) + (a.charCodeAt(++f) & 1023), g[d++] = c >> 18 | 240,
							g[d++] = c >> 12 & 63 | 128) : g[d++] = c >> 12 | 224, g[d++] = c >> 6 & 63 | 128), g[d++] = c & 63 | 128)
					}
					a = h;
					for (d = 0; d < g.length; d++) a += g[d], a = b(a, "+-a^+6");
					a = b(a, "+-3^+b+-f");
					a ^= Number(e[1]) || 0;
					0 > a && (a = (a & 2147483647) + 2147483648);
					a `%= 1E6;
					return a.toString() + "." + (a ^ h)
			}
		)
		Return,script
}

CreateScriptObj() {
	static doc, JS, _JS
	if(!doc) {
			doc:= ComObjCreate("htmlfile")
			doc.write("<meta http-equiv='X-UA-Compatible' content='IE=9'>")
			JS:= doc.parentWindow
			if(doc.documentMode < 9)
				JS.execScript()
			_JS:= ObjBindMethod(JS, "eval")
	} Return,_JS
}

WinAnimate(Hwnd,Type="",Time=100) {
	static AW_ACTIVATE=0x20000,  AW_BLEND=0x80000, AW_CENTER=0x10, AW_HIDE=0x10000
	,	AW_HNEG=0x2,AW_HPOS=0x1, AW_SLIDE=0x40000, AW_VNEG=0x8, AW_VPOS=0x4
	loop,parse,Type,%A_Tab%%A_Space%,%A_Tab%%A_Space%
		ifEqual,A_LoopField,,Continue,
		else,(!hFlags? (hFlags:= 0, hFlags|=AW_%A_LoopField%):hFlags|=AW_%A_LoopField%)
	ifEqual,hFlags,% "",return,"Err: Some of the types are invalid"
	return,dllcall("AnimateWindow","uint",Hwnd,"uint",Time,"uint",hFlags)
}

onMsgbox(HookCr,eventcr,hWnd,idObject,idChild,dwEventThread) {
	winget,pid,pid,ahk_id %hwnd%
	if(pid!=r_pid)
		return,	;if its our mbox change icon
	onActiv8(wparam="",lparam="",msg="",hwnd)
}

Hookinit:
HookMb:= dllcall("SetWinEventHook","Uint",0x0010,"Uint",0x0010,"Ptr",0,"Ptr"
, ProcMb_:= RegisterCallback("onMsgbox",""),"Uint",0,"Uint",0,"Uint",0x0000) ;WINEVENT_OUTOFCONTEXT:= 0x0000
, hOOkz:= "HookMb,ProcMb_"
return,

Time4mat(time="",pattern="") {
	FormatTime,out,% (time=""? A_now : time),% (pattern=""? "H:m:s" : pattern)
	return,out
}

SetExplorerTheme(hWnd) {
	return,DllCall("UxTheme.dll\SetWindowTheme","Ptr",hWnd,"Str","explorer","Ptr",0)
}

RegRead:
RegRead,api_key,% RegBase,api_key
return,

RegWrite:
if(api_key)
	RegWrite,REG_SZ,% RegBase,api_key,% api_key
return,

exit:
menu,tray,noicon
gosub,RegWrite
gosub,unhook
ExitApp,

reload() {
	reload,
	exitapp,
}

unHook:
if(FileExist(TEMP_FILE))
	FileDelete,%TEMP_FILE%
else,sleep,300

loop,Parse,% hOOkz,`,
{	dllcall("UnhookWinEvent","Ptr",a_loopfield)
	sleep,20
	dllcall("GlobalFree",    "Ptr",a_loopfield,"Ptr")
	(%a_loopfield%) := ""
} return,

dBlur(hWnd) {
	static WCA_ACCENT_POLICY := 19
	, ACCENT_DISABLED := 0  ;AccentState
	, ACCENT_ENABLE_GRADIENT := 1
	, ACCENT_ENABLE_TRANSPARENTGRADIENT := 2
	, ACCENT_ENABLE_BLURBEHIND := 3
	, ACCENT_INVALID_STATE := 4

	, accentStructSize := VarSetCapacity(AccentPolicy, 4*4, 0)
	NumPut(ACCENT_ENABLE_BLURBEHIND, AccentPolicy, 0, "UInt")

	padding:= A_PtrSize=8? 4 : 0
	VarSetCapacity(WindowCompositionAttributeData, 4 + padding + A_PtrSize + 4 + padding)
	NumPut(WCA_ACCENT_POLICY, WindowCompositionAttributeData, 0, "UInt")
	NumPut(&AccentPolicy, WindowCompositionAttributeData, 4 + padding, "Ptr")
	NumPut(accentStructSize, WindowCompositionAttributeData, 4 + padding + A_PtrSize, "UInt")
	return,DllCall("SetWindowCompositionAttribute","Ptr",hWnd,"Ptr",&WindowCompositionAttributeData)
}

Aero_StartUp(){
	global
		MODULEID3:=DllCall("LoadLibrary", "str", "dwmapi")
		MODULEID2:=DllCall("LoadLibrary", "str", "uxtheme") ;zwar noch nicht gebraucht aber egal
		MODULEID:=MODULEID3 . "|" . MODULEID2
		Return,MODULEID

}

WinMove(hWnd="",X="",Y="",W="",H="",byref flags="") {
	static local dts:=0
	,uint:="uint", int:="int"
	,msg_:="SetWindowPos"
	listlines,off
	((dts=0)? (dts:= ((Flags="")
	? (optM2dAutoActiv8? 0x4:0x015):dts:=flags)))
	return,DllCall(msg_,uint,hWnd,uint,0,int,x,int,y,int,w,int,h,uint,dts)
}


B64_2_hicon(B64in,NewHandle:= False) {
	Static hBitmap:= 0
	(NewHandle? hBitmap:= 0)
	If(hBitmap)
		Return,hBitmap
	VarSetCapacity(B64,3864 <<!!A_IsUnicode)
	If(!DllCall("Crypt32.dll\CryptStringToBinary","Ptr",&B64in,"UInt",0,"UInt", 0x01,"Ptr",0,"UIntP",DecLen,"Ptr",0,"Ptr",0))
		Return,False
	VarSetCapacity(Dec,DecLen,0)
	If(!DllCall("Crypt32.dll\CryptStringToBinary","Ptr",&B64in,"UInt",0,"UInt",0x01,"Ptr",&Dec,"UIntP",DecLen,"Ptr",0,"Ptr",0))
		Return,False
	hData:= DllCall("Kernel32.dll\GlobalAlloc","UInt",2,"UPtr",DecLen,"UPtr")
	, pData:= DllCall("Kernel32.dll\GlobalLock","Ptr",hData,"UPtr")
	, DllCall("Kernel32.dll\RtlMoveMemory","Ptr",pData,"Ptr",&Dec,"UPtr",DecLen)
	, DllCall("Kernel32.dll\GlobalUnlock","Ptr",hData)
	, DllCall("Ole32.dll\CreateStreamOnHGlobal","Ptr",hData,"Int",True,"PtrP",pStream)
	, hGdip:= DllCall("Kernel32.dll\LoadLibrary","Str","Gdiplus.dll","UPtr")
	, VarSetCapacity(SI,16,0), NumPut(1,SI,0,"UChar")
	, DllCall("Gdiplus.dll\GdiplusStartup","PtrP",pToken,"Ptr",&SI,"Ptr",0)
	, DllCall("Gdiplus.dll\GdipCreateBitmapFromStream","Ptr",pStream,"PtrP",pBitmap)
	, DllCall("gdiplus\GdipCreateHICONFromBitmap","UPtr",pBitmap,"UPtr*",hIcon)
	, DllCall("Gdiplus.dll\GdipDisposeImage","Ptr",pBitmap)
	, DllCall("Gdiplus.dll\GdiplusShutdown","Ptr",pToken)
	, DllCall("Kernel32.dll\FreeLibrary","Ptr",hGdip)
	, DllCall(NumGet(NumGet(pStream +0,0,"UPtr") +(A_PtrSize *2),0,"UPtr"),"Ptr",pStream)
	return,byref hIcon
}
WinGetPos(byref WinTitle="") { ;,WinText="",ExcludeTitle="",ExcludeText="") {
	listlines,off
	(!detecthiddenwindows? (detecthiddenwindows,"on",timer("detecthiddenwindows",-300)))
	(!detecthiddentext? (detecthiddentext,"on",timer("detecthiddentext",-300)))
	WinGetPos, wX, wY, wWidth, wHeight,ahk_id %WinTitle% ;,% WinText,% ExcludeTitle,% ExcludeText
	return,	_:= ({	"X" : wx
				,	"Y" : wY
				,	"W" : wWidth
				,	"H" : wHeight })
}

detecthiddenwindows:
detecthiddentext:
(%a_thislabel%),off
return,

IsWindowVisible(hWnd) {
	listlines,off
	return,dllcall("IsWindowVisible","Ptr",hWnd)
}

SBIconReset:
global icoB64, SbarhWnd, eyeo
SendMessage,0x40F,0,% Eye48_hIcon,,ahk_id %SbarhWnd%
if(!eyeo?eyeo:=b64_2_hicon(icoB64["Eye48"]))
	SendMessage,0x40F,0,% eyeo,,ahk_id %SbarhWnd%
return,

MenuTray:
mousegetpos,,,hwnd,CN
if(instr(CN,"ToolbarWindow")) {
	send,{RButton Up}
	menu,Tray,Show
} return,

Menus:
menu,Tray,NoStandard
menu,Tray,Add,%	 splitpath(A_scriptFullPath).fn,% "do_nothing"
menu,Tray,disable,% splitpath(A_scriptFullPath).fn
menu,Tray,Add ,% "Open",%			"MenHandlr"
menu,Tray,Icon,% "Open",% 		"HICON: " b64_2_hicon(icoB64["data24"])
menu,Tray,Add ,% "Open Containing",% "MenHandlr"
menu,Tray,Icon,% "Open Containing",% "HICON: " b64_2_hicon(icoB64["runfolder24"]) ;	"C:\Icon\24\explorer24.ico"
if(!A_IsCompiled) {
	menu,Tray,Add ,% "Edit",%			"MenHandlr"
	menu,Tray,Icon,% "Edit",% 		"HICON: " b64_2_hicon(icoB64["edit24"]) ;	"C:\Icon\24\explorer24.ico"
}
menu,Tray,Add ,% "Reload",%		"MenHandlr"
menu,Tray,Icon,% "Reload",% 	"HICON: " b64_2_hicon(icoB64["reload24"]) ;	"C:\Icon\24\eaa.bmp"
menu,Tray,Add,%	 "Suspend",%	"MenHandlr"
menu,Tray,Icon,% "Suspend",% 	"HICON: " b64_2_hicon(icoB64["suspended24"]) ;	"C:\Icon\24\head_fk_a_24_c1.ico"
menu,Tray,Add,%	 "Pause",%		"MenHandlr"
menu,Tray,Icon,% "Pause",% 		"HICON: " b64_2_hicon(icoB64["sitting24"]) ; 		"C:\Icon\24\head_fk_a_24_c2b.ico"
menu,Tray,Add ,% "Exit",%			"MenHandlr"
menu,Tray,Icon,% "Exit",% 		"HICON: " b64_2_hicon(icoB64["exit_2_24"])

a_scriptStartTime:= Time4mat(a_now,"H:m - d\M")
menu,Tray,Tip,% splitpath(A_scriptFullPath).fn "`nRunning, Started @`n" a_scriptStartTime
do_nothing:
return,

MenHandlr(isTarget="") {
	listlines,off
	switch,(isTarget=""? a_thismenuitem : isTarget) {
		case,"Open Containing": TT("Opening "   a_scriptdir "...")
			return,OpenContaining(A_scriptFullPath)
		case,"edit","Open","SUSPEND","pAUSE":
			PostMessage,0x0111,(%a_thismenuitem%),,,% A_ScriptName " - AutoHotkey"
		case,"RELOAD": reload()
		case,"EXIT": exitapp
		case,"suspend": menu,Tray,rename,%	 "Suspend",%	"Resume"
		case,"Resume": menu,Tray,rename,%	 "Resume",%	"Suspend"
		default: isLabel(a_thismenuitem)? timer(a_thismenuitem,-10) : ()
	}	return,1
}

AHK_NOTIFYICON(byref wParam="", byref lParam="") {
	listlines,off
	switch,lParam {
		case,0x0203: if(IsWindowVisible(hGuiA))
				settimer,HideMainGui,-20
			else,settimer,ShowMainGui,-20
			return,
		;	PostMessage,0x0111,%open%,,,% A_ScriptName " - AutoHotkey"
		;	sleep(80),tt("Loading...","tray",1) ; WM_LBdoubleclick
		case,0x0204: settimer,MenuTray,-30 ;WM_RBUTTONdn RBD Will initiate the menu RBU will select item
			return,1
		case,0x0205: send,{enter}
		return,1
	}	return,
}

Varz:
global r_pid, tabcontrolhwnd, MattTheme, password, copiedthis, api_key, AnswerEdithwnd, InputQuestion, InputQuestionhwnd, Opt_GUI_Answer_W, RegBase, Opt_Gui_Main_W, xs, ys, smicon64, lgicon64, APIEntryEdithWnd, Opt_MultiLang, Opt_Tokens, Opt_SpawnOnMouse, opt_GuiTabMarginSz, Opt_MaxTokens, Opt_Appear_Transition, Opt_Appear_TransitionDurMs, Opt_Gui_Question_W, Opt_GuiQuestionLines, Opt_Hide_Transition, opt_GuiTabTopMargin, Opt_Hide_TransitionDurMs, Opt_Guitab_W, EDIT:= 65304, open:= 65407, Suspend:= 65305, PAUSE:= 65306, exit:= 6530, SbarhWnd, Opt_Temperature, Opt_GuiTrans, hGuiA, MattTheme, Opt_Hide_TransitionS, Opt_Hide_TransitionN, Opt_Appear_TransitionS, opt_gui_fontcol, Opt_Appear_TransitionN, Opt_GUI_Answer_H, AnswerEdithwnd2, AnswerEdithwnd, gui_W, gui_H

, r_pid:= DllCall("GetCurrentProcessId"), hOOkz

, icoB64:= []

RegBase:= "HKEY_CURRENT_USER\SOFTWARE\_ch@_GP-Tizzle"

gosub,b64icons_

return,

B64icons_:
icoB64["smicon64"]:="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"

icoB64["lgicon64"]:="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"

icoB64["exit_2_24"]:="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"

icoB64["running24"]:="AAABAAEAGBgAAAEAIACICQAAFgAAACgAAAAYAAAAMAAAAAEAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wBkEwsN////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8AZBMLBWQTCxhkEwtNZBMLY2QTCz7///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8AZBMLCshVYpSkOnP1yk91m2QTC3f///8A////AP///wD///8A////AP///wD///8A////AP///wBkEws+ZBMLQGQTC01kEws4ZBMLG////wD///8A////AP///wD///8AZBMLEKRyMf+5nhT/r1tV/2QTC23///8A////AP///wD///8A////AP///wD///8AZBMLJlkQEjO6LFXnuCpO/qclSP9cEjH9ZBMLQf///wD///8A////AP///wD///8AeDoK4daoCv/OrhT/kEI89WQTCz3///8A////AP///wD///8A////AP///wBXEy+veh018qZAQ//XcVr/5ZZG//F2YP+PKTv/cxpB52QTCzb///8A////AP///wD///8Auo0a/eisKf+abR//cBg9oWQTCxL///8A////AP///wD///8A////AHARL0fTVk///7ZO///cPf//w0j/+MI////cWf/rgFP/cBcy/4QhTb9kEwtF////AP///wCkdCvK6rI6/9iTQf9+QC/9YhINOWQTCxP///8A////AP///wD///8A////AGIQHDny2zb8+Osq/+LZJf/FoBztXEIT4+jRR///1Vr/02pN/24dQP9nERpvXBExVLBFVrXdqTv//51h/750Rf9UDie/ZBMLI////wD///8A////AP///wD///8A////AP///wBkEwtNOxwKZ////wD///8A////AJBAG8bt3Eb//9VS/8eKQP9wHC//mS0//9SlN//htDn/2YpJ/5AKQd5VEQ1L////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wCXiBnx//pF//nJOP/trTz/57gp/+S/E//UkkX/2VBs/2MML8NkEwsl////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wBCNApngxg8doMYPHmJbAyT8PUi//zcJf/1zw3/2aYi/+FbcP/TVWz/pjxA7mQTC0P///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wBfSgreZR8b6WUuNv9GNwrH4t8R///5B//83wb/5b8H/8xTY/+4Nlb/ZBMLRWQTCyX///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AEolCk/K2BL7+c4s/38aQv7///8Aybss+//1Ff/83Qf/88EJ/9JlT/+uPUr+RREhnVINKfNQECrvfBxEFP///wD///8A////AP///wD///8A////AP///wD///8A////AEo7Coju+y7r/8tX/4UZPf+VJmIUz4pF/v/rFf/93Ar/+s0H/+yhRP/enj7/0H1H/9JPVf+JCz//PAoeEP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wDe3jX//7xr/7EnVf+WHUj9z58x///kBv//4QP//9gO//3ZBP/93yX/8ckp//S8P/+3PU3/cxo/x////wD///8A////AP///wD///8A////AP///wD///8A////AP///wDp0hj+/9pc//+RZf//rVz//8xT///0K///8Qj//94W//XcIP+7kw3+jWoZ///QTv/Vgk7/TA0m9v///wD///8A////AP///wD///8A////AP///wD///8A////AP///wDBsBvy8vhU///pVf//2U3/5tE4/8miJP+lhQv1TSkRaTwFG03Zw38HfWELIOa7KNzpp0T/XQ8r/////wD///8A////AP///wD///8A////AP///wD///8A////AP///wB4Xwp8qH0r3oRiDvOGRBDh/fz2AP/tYoDx0hf/86VK/8pfTP46AhJV79d1DMCWEf/quiz/jlIu/////wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A/+xvEPrcA/D83ib//7Rp//9Adv+4UEP/wplWAJFyCuC5kBD/h2Ia6P///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A/+xuEPncAvH93jP//8Fp//9ve//IZEv9uGFAAPngGABGPAkf6+fiAP39/QD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP/sbkb94T33+tBO/uu7RN0l3gUEx2ZKAMzJxQBKPwkAUEgrAN7e3gD7+/sA////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///gDjyFQqyrJKTcyzSiztzpcA5vfkAPz8/ADb29sAgICAAEZGRgDKysoA+/v7AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP79+wD8+/gA/v7+AP///wD+/v4A8PDwAMrKygBKSkoA8vLyAP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////APv7+wDy8vIA/v7+AP///wD//98A//8HAP//BwD8HwcA8B8HAOAPBwDABgcAwAAPAOcAHwD/gB8A/AA/APwAPwD4QA8A+AAPAPwADwD8AA8A/AAPAPwgDwD/wI8A/8DfAP/g/wD/8f8A////AP///wA"

icoB64["CmdPrompt24"]:="iVBORw0KGgoAAAANSUhEUgAAABgAAAAUCAYAAACXtf2DAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAAFiUAABYlAUlSJPAAAAPQSURBVEhLrZXbT5tlHMfft/TwUiqlh7fHjZb1gFHjYVsjxa5AkVEKYRCatggENl2GUdpSpmZh0qFeiG7eGO+9mgtqvPXeu114GJsYM/0HjAmHsqwb+PX3PC/daDGmJl588vu9z/P8vt/n2ArL48DSK8ClqX0miel9Knklsv7978sTQJFB9Syv6FTalzMKQuEaMPMtMPInMFwnbGzmNjC/DMxeBybWqvMFyt+5DLx1lQyyn1DBH8Ap7KETu3XTC2Dqs12M/gqcrsnPfQoU3iVo8twg+Tt4QTeZ1EuMxg8STJDVHsyHibPfATlmsEDLuDS5i9ciP+B85Pv/xOxLP+ICcSjvvIXFiT0wbW7Q412BJJihE1oIE88VLFWwvmrY+MOwWqb5yCDm+RANQhMEQUSD2AyDNgCDLgiNKFNbAyEcQAW1YIRedPxDnwLTYpo1BgaoRTM6/IvI5jaJDYSfKqJR7aEiFUQSE0UNdCoXwr5FXBj8CbL5ed5Xl4FeJcP99CDyJDyyUeZkCxvwdUygyejBEUsEzuN9cDq6ufmZzfuQuwbIVFeHQdsKrMEIUnfu4eJcGf6+V+HrO4eFN3Ywc3MbgdA4svF1yrcQ6JhGbqGE+M4DuBNTkCQviar/3aDH9xHs4QQS22Ve7JJ7YdD4EQ28h+zAOry20+jyXiGTnxH0ZGhl20jc28Pk55sIHS9CUrfWGBhqVuD7GPbIEPpLtC0Xt+GyxqBVWeEhYTZ7Y0s7NwmEMnDLXTifuoWBnTKZ/IW5/AbspggJs7MQORrRdNjAGR6ifb+PXKGEAM3S7xhDdug3nKVt8ZMwm/3MzU24TsThdnXjuemrZPJQWbG1Bw7pRThNUdilEJpURxGruqbHVuC0hDE7uoalmYfIF3Y4V6YfIJ+4C4/8MqLeInLxOzhijaBB1QJ77AwStOL8PJ1Rawpzw3cxn92i+Avc5lNc87EBuTWKLhw19HCTEbohjNfH1tHWPEBLNqORZmXTvEBX2Ug3RwvbyV6kb5e4sO9kBum1Eoa3yjw6n+2vMaD9Yo9HFCTYLCcgR/ohR+Nw2ML84R08QAURWr0F8jNRuCyd0De3whbqg9yd4MZPSK01W8QNDFSoPCiVKCkIGmpjr5UdYC1snHZ/jJpyHaHnbRr6uag65OSTX8Go9aNZ5yXaYNQdewT7VmB9CrxP8qGFUKIfJilIMaD0kdZY+6piwP4UlrLA+6PAByP/D0yr+CbwNjNIBm8gE/wGKd8XxHVk/F/ymKTvtG+Vx5TvBs/HA2ycEtm4Ckkar9Q/1kj7V5Fu/xp/A8gK/ztkcEmcAAAAAElFTkSuQmCC"

icoB64["sitting24"]:="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"

icoB64["suspended24"]:="iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAAFiUAABYlAUlSJPAAAAS8SURBVEhL7dJ5TJN3GAfwF9oRnEw51DgMGccKQfHYRJiAHAVpS0/a0vZFNyLuUJbNRMd0sEy3sTnHkuHUETY8AFFLKxTBCsglTAWVS6CgFgq0Wi5LD67R49lP02xZtj+W/eUffJNPfk/e931+z3thi1nMYl6g4ESxq73EXsLCHO3l/w8BSyH4pJ9w4l3uc8VXSIrwJSWtuKekGfeQ1IqWiIuRd/hLC88LAyVydE6M/GRv/W9BA5wRF9ytpEi0pbSTJ3/wY+KI/ha3abBEFH65ReBdrGCyLj2JlffoImvbbiZxZR34emmRvf2fwbFiZ2RtMnbW2X7oeXBncbNgd7WaOaIfYXfrphNaNQvxlYoZakPfRKxKYxZMzwNbbTJT7qvVolT5NXvb34MeT8jP64wU7q6W416XZEKnolOU1FNviDxLSpO2lNyhNal17CG9mVOutVIlHSBgy4D5QG0VqWchtXQBdrRZgD5ksIUptOfwiFKZfdu/ggZkJ1YN/8xuGdewB0x6dovqdmxDdxEnrWqEu+/6FL1zfIHbpbOyLgzYok/VQHh2ObCnZ+C9GxYQrpIAr0oDPI3RJkqv7cbf+rcBIWWViXVqDT/nnolXMWCM75gYoyv005RB/Ry9f8rMaJ2yCaV6YBy9CxFZlbCtrh1i1SZgV44BP70BqJ1TwHxo0Avfr+3BWeXyrwxAtG/9/O7F+LrL97jH79ShV6ISBkkVMcfby6knlFryyfZp+umueQG5BjhfdkHcd/WwOVMMrxXUgP91JXAONUHI3QmIHPwdtneO2jj9Y72MsflsAfdqfTJJKv1zAC+vPYdT2JUdI7u5PsnlfCNvy8X+xIBzYyzffAM3WmLmHesAWkEnUI7VAi9eCty3KyDk+1vg1zoLK5UWiH40DzHN3YZ1PZOzvqoF48vKBRNZPXskOaLsAkat6Q9NqOgdoJf3Gtl92odxbUpZyN0HEr8axXBYWbeBUq0ys1onYPsvvwE/RAwiLykkHmoA2hkFhNbpYU2P0bahe3KIl3RFE18xB4z7NghRWSHqsVUhCiutwCJOVxeEHs6fD96ZZYzOrddFlPWoo+T9k+FVKhOjZdLCaJy0MBsfW8LJOWaW+69mbsoVYDZprPE3H5k3tihtr/5QbIuj5Q7TffMf79jzEPbnmeHdWxZbfJepmRN0ph4L2LRj1Ee4V+vrQJnxc+eM+EWlTfnS9k8HUjMN5AMybUJGoyY2snBk27LPZ6lbc+diavqt0Q19psBPvx19fRVdFeDGn3FZTboWREwe3brsoD6JJDby8wZHQwtvZAV77O3DfAiUCT/HhHGSI/MJoiY5sHQBjhxTIFHwdDNxz9Mw4sFxstPXj4JdP9L5Hy3URFR22AI/y1F6etNaNhJSnqx3TO5Cn/Is5kAsCFwiGt6wLFX75uoPeqNXftHmRYy6jW0i7CpHF+xDdi2Poaa5xyWg2mmnA7Y65RUs6GMMc8vAHJwzg90+HCIIDrS778oY8uDvuUj2+qZ0uSuJhvrCkHXIBoSHHEbOI/nICQQLQPwRb2QN6Ui2D1pXYthST7SuRbYhvHDiJxfRmkZekdXO8Dh5FdXPzq9BXBAC8uzfR31YOLIb2YthWPAffGZQQc/Y47gAAAAASUVORK5CYII"

icoB64["reload24"]:="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"

icoB64["edit24"]:="iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAAFiUAABYlAUlSJPAAAASlSURBVEhL5ZR7TNNXFMd/7YDCeAlCKXUITJAyKkMLCExaGCEr0PHS0fEodVJgUM2QMEYWDM4HkmjGGCrLHo5o7JwjG2G4gCGbcxtWmZ0wRKDUShGK9N0fIvR1dy+PTc2yTf3PneST3y/3nPs999fe88X+F0G4HwdmJIHCycIcYhko98SBRO0gDhDHlG0nVh9JlzaK1yqACzMe5Z8oVsSdIB7MTdw1u18Z/h6J780aO06KeBHVPHasiDtDfDK9W5kH0uQyJF6ZNHBJSB0MRUWPGw+IQ+i1DJkUiQtf/UH6mmdb4nIe1T1SoA1EiD3EBUIhkrDwyudutSFxwRvHlP7ZvBIqO9Eb5kgQ1ATVI/612cqpHSGrMIKdf0ZecUJDfWczEs/hX56NqRDpuK3T/cUfKT7fcXS4PFXUERIo4Lkv73F0YdDsMQqViNHXE4KSEwiHP2jC8HENTC3FXz+JD5nObm4sbui/+TMSrzo0uRDGPnwvrWLKLGiZBWU9GqvwrEFXPqq+xpP2N6Z9cYpd2NyRsE88t//Y0GzGiUF887B6xmvGoHdW4zj6usVAN4UCiYwUFgvenBgdQuLZ+3ULG1ObLAGRB0xRnNs2Tj0OSi7qQdkwRDsDhFq5aZdKcbuoTT9S3G3B68TmwXbZ/N6b2rssFW7w1+FGdOjFWA0Jd6UF52Z3d36NxBNrRs2hzBaLCznO6uTJsa0JO25lVWgB++IEKFHJoPgY2KmbAjvlBiBs0NjSv7FY8nusRpHiXuuI3ph1B8dDtUZ81ZI8hgUE2qVyNvBePyi4NXmH3aC0UH2yrX7kDLOPb7nVL+Kg9aWydgPvU721QKIGZWo5bICaTIPSH9VgR60GJJ+x2thdNtNJ5dxXQwZNvsKg36gy4uhCwHtI4kdvjW+oQSfn/TRtTspsm9/MqDalc1otCfkfgpTPBqz8Dq2l6IIG8CUqkCm7DthDEpAkkQD2aQnIKZ0ESSdNgNNls3win/8ONuCPG3SRUwY9uuYYlubxcR4SL6deB1t2986n8ER3eb8oTAWXVKDwshrwZDrAvaoG3CtKsOXcMGB09wJG2w3ArRoHgiSFLYcls8SctYCiHuvC0ZGFHimO504YdBGTBv3SFyyLTyQH15138g3Xrkvbo4x755o5vrpfE1t+RRkt/HWcxR/Co7h9utDt3YrA0kNT8bm/6wvjZHMZUeLp0JAi/OVuk6VabMZPSefP3NDNZk0ZtLRJvdZjsUGqR8u2bLKoKcCLc45gb3/B9YVEETVj11UHL1of0cl3zNNl0zTZLc5Mdo01EZ/1+Y3o6vWtvTutl+RO73rGiSJyCw7sLDjfN1Avnh1rlxnrpBpNjEKn8ZNrNWhgMSzZ/f04pve+POeA2HqCnfN7BBKp1o7iWwPH7whMV0IKIPmQLEje8nMrJBdSCnnXkx7WHBwTfTqCxXorNS+Xvv3tKrc9X4r+nAP0ZwQRSR4b4DMcgsxsHWQ95HmIP2QtxO8hAiA0CNoXAgmCoHlC9v6AfaBBc4Oge4tA72hI0PoKi5bwEGgd1SGQPyEf+1tvQovILlAB4n4j+y8gwX80vJWCR+WpDwz7A2yFDq30trstAAAAAElFTkSuQmCC"

icoB64["runfolder24"]:="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"

icoB64["data24"]:="iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAAFiUAABYlAUlSJPAAAAGISURBVEhL7ZU/S8NAGIdPKjg4+RncFbSD3VzqICqi6OCfJuJmdZGqu6vuFQzooA5OdvADKHQK/QCCqFf9Hmd+h+9x9zaXNJktPKR538vvyd01jViIpVrsSrXxLNXWk1T7kVTNi3ROmy5nRz+q3pOascq4IJK6pjIyKsTyi1SN6etSQJAmcQS4awxOGoUhwUnLlXgFkxM1FUR9w/zblxPI6wgPa3eqdfDpSLwCHmqf03cuCKq3Kpz7kxwPSkT4MJwgrUaCoHqjJTjnM/EKcMwTHF5+GwFJMBOISCLw8+MCHHkYYdca98meaIFLpoDCeVhabem1ryWYCUJtjAAPTNk9IIQQDpjFymM8KKAAgss41OeC3dnILyhDpsDeg7IUFvAlyOsVEtDFaQJfr5CASBP4ev+C3F6mAK9IPAs7U+3MkKxermDvPNYCgIs5FObrcQFyjGAtedlvtmMDlguD6O6GIVdgQxJMk9ieuXKwewT9VdNKGIH94TKw3vnQrHbeNVTj4zgIr/ek+gV1Jm8TdticOwAAAABJRU5ErkJggg"

icoB64["EyeClose48"]:="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"

icoB64["Eye48"]:="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"

icoB64["tray24"]:="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"

return,