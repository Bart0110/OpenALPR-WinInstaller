;NSIS Modern User Interface

; ------------------- ;
;  Include libraries  ;
; ------------------- ;

  !include "MUI2.nsh"
  !include "LogicLib.nsh"
  !include "x64.nsh"
  !include "FileFunc.nsh"
  !include ".\EnvVarUpdate.nsh"

; --------- ;
;  General  ;
; --------- ;

  ;Name and file
  !define APP_NAME "OpenALPR"

  Name "${APP_NAME}"
  OutFile "${APP_NAME}.exe"

  ;Default installation folder
  InstallDir "$LOCALAPPDATA\OpenALPR"

  ;Get installation folder from registry if available
  InstallDirRegKey HKCU "Software\OpenALPR" ""

  ;Request application privileges for Windows Vista
  RequestExecutionLevel user

  CRCCheck on
  SetCompressor /SOLID lzma

; -------------------- ;
;  Interface Settings  ;
; -------------------- ;

  !define MUI_ABORTWARNING

; ------- ;
;  Pages  ;
; ------- ;

  !insertmacro MUI_PAGE_WELCOME
  !insertmacro MUI_PAGE_COMPONENTS
  !insertmacro MUI_PAGE_DIRECTORY
  !insertmacro MUI_PAGE_INSTFILES
  !insertmacro MUI_PAGE_FINISH

  !insertmacro MUI_UNPAGE_WELCOME
  !insertmacro MUI_UNPAGE_CONFIRM
  !insertmacro MUI_UNPAGE_INSTFILES
  !insertmacro MUI_UNPAGE_FINISH

; ----------- ;
;  Languages  ;
; ----------- ;

  !insertmacro MUI_LANGUAGE "English"
  LangString noRoot ${LANG_ENGLISH} "You cannot install ${APP_NAME} in a directory that requires administrator permissions"

; -------------------- ;
;  Installer Sections  ;
; -------------------- ;

Section "x32" Sec32

  SetOutPath "$INSTDIR"
  CreateDirectory "$INSTDIR"
  CreateDirectory "$INSTDIR\openalpr_64"
  CreateDirectory "$INSTDIR\openalpr-master"


  SetOutPath "$INSTDIR\openalpr_32"
  File /r ".\files\openalpr_32\*"
  ExecWait '$INSTDIR\openalpr_32\vc_redist.x86.exe /q /norestart'

  SetOutPath "$INSTDIR\openalpr-master"
  File /r ".\files\openalpr-master\*"


  ;Store installation folder
  WriteRegStr HKCU "Software\OpenALPR" "" $INSTDIR

  ${EnvVarUpdate} $0 "PATH" "A" "HKCU" "$INSTDIR\openalpr_32"  

  ;Create uninstaller
  WriteUninstaller "$INSTDIR\Uninstall.exe"

SectionEnd

Section "x64" Sec64

  SetOutPath "$INSTDIR"
  CreateDirectory "$INSTDIR"
  CreateDirectory "$INSTDIR\openalpr_64"
  CreateDirectory "$INSTDIR\openalpr-master"


  SetOutPath "$INSTDIR\openalpr_64"
  File /r ".\files\openalpr_64\*"
  ExecWait '$INSTDIR\openalpr_64\vc_redist.x64.exe /q /norestart'

  SetOutPath "$INSTDIR\openalpr-master"
  File /r ".\files\openalpr-master\*"


  ;Store installation folder
  WriteRegStr HKCU "Software\OpenALPR" "" $INSTDIR

  ${EnvVarUpdate} $0 "PATH" "A" "HKCU" "$INSTDIR\openalpr_64"

  ;Create uninstaller
  WriteUninstaller "$INSTDIR\Uninstall.exe"

SectionEnd

Section "Python bindings" SecPython

  SetOutPath "$INSTDIR\openalpr-master\src\bindings\python\"
  ExecWait 'python setup.py install'

SectionEnd

; -------------- ;
;  Descriptions  ;
; -------------- ;

  ;Language strings
  LangString DESC_Sec32 ${LANG_ENGLISH} "This will install the 32 bit version of OpenALPR."
  LangString DESC_Sec64 ${LANG_ENGLISH} "This will install the 64 bit version of OpenALPR."
  LangString DESC_SecPython ${LANG_ENGLISH} "This will configure OpenALPR with Python."

  ;Assign language strings to sections
  !insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
    !insertmacro MUI_DESCRIPTION_TEXT ${Sec32} $(DESC_Sec32)
    !insertmacro MUI_DESCRIPTION_TEXT ${Sec64} $(DESC_Sec64)
    !insertmacro MUI_DESCRIPTION_TEXT ${SecPython} $(DESC_SecPython)
  !insertmacro MUI_FUNCTION_DESCRIPTION_END

; -------------- ;
;  32 bit check  ;
; -------------- ;

  Function .onInit
    ${If} ${RunningX64}
      !insertmacro UnselectSection ${Sec32} ; Uncheck it
    ${Else}
      !insertmacro UnselectSection ${Sec64} ; Uncheck it
      SectionSetFlags ${Sec64} ${SF_RO}
    ${EndIf}
  FunctionEnd

; --------------------- ;
;  Uninstaller Section  ;
; --------------------- ;

Section "Uninstall"

  Delete "$INSTDIR\Uninstall.exe"

  RMDir /r "$INSTDIR"

  ${un.EnvVarUpdate} $0 "PATH" "R" "HKCU" "$INSTDIR\openalpr_32"
  ${un.EnvVarUpdate} $0 "PATH" "R" "HKCU" "$INSTDIR\openalpr_64"  

  DeleteRegKey /ifempty HKCU "Software\OpenALPR"

SectionEnd


; ------------------- ;
;  Check if writable  ;
; ------------------- ;
Function IsWritable
    !define IsWritable `!insertmacro IsWritableCall`
    !macro IsWritableCall _PATH _RESULT
        Push `${_PATH}`
        Call IsWritable
        Pop ${_RESULT}
    !macroend
    Exch $R0
    Push $R1
    start:
        StrLen $R1 $R0
        StrCmp $R1 0 exit
        ${GetFileAttributes} $R0 "DIRECTORY" $R1
        StrCmp $R1 1 direxists
        ${GetParent} $R0 $R0
        Goto start
    direxists:
        ${GetFileAttributes} $R0 "DIRECTORY" $R1
        StrCmp $R1 0 ok
        StrCmp $R0 $PROGRAMFILES64 notok
        StrCmp $R0 $WINDIR notok
        ${GetFileAttributes} $R0 "READONLY" $R1
        Goto exit
    notok:
        StrCpy $R1 1
        Goto exit
    ok:
        StrCpy $R1 0
    exit:
        Exch
        Pop $R0
        Exch $R1
FunctionEnd

; ------------------- ;
;  Check install dir  ;
; ------------------- ;
Function CloseBrowseForFolderDialog
	!ifmacrodef "_P<>" ; NSIS 3+
		System::Call 'USER32::GetActiveWindow()p.r0'
		${If} $0 P<> $HwndParent
	!else
		System::Call 'USER32::GetActiveWindow()i.r0'
		${If} $0 <> $HwndParent
	!endif
		SendMessage $0 ${WM_CLOSE} 0 0
		${EndIf}
FunctionEnd

Function .onVerifyInstDir
    Push $R1
    ${IsWritable} $INSTDIR $R1
    IntCmp $R1 0 pathgood
    Pop $R1
    Call CloseBrowseForFolderDialog
    MessageBox MB_OK|MB_USERICON "$(noRoot)"
        Abort
    pathgood:
        Pop $R1
FunctionEnd