;NSIS Modern User Interface

; ------------------- ;
;  Include libraries  ;
; ------------------- ;
!include "MUI2.nsh"
!include "LogicLib.nsh"
!include "x64.nsh"
!include "FileFunc.nsh"
!include "Sections.nsh"
!include ".\EnvVarUpdate.nsh"

; --------- ;
;  General  ;
; --------- ;
;Name and file
!define APP_NAME "OpenALPR"
!define APP_VERSION "0.0.1"
!define COMPANY_NAME "OpenALPR WinInstaller"
!define APP_URL "https://github.com/Bart0110/OpenALPR-WinInstaller"

!define UNINSTALL_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}"

Name "${APP_NAME}"
Caption "${APP_NAME} ${APP_VERSION}"
BrandingText "${APP_NAME} ${APP_VERSION}"
VIAddVersionKey "ProductName" "${APP_NAME}"
VIAddVersionKey "ProductVersion" "${APP_VERSION}"
VIAddVersionKey "FileDescription" "${APP_NAME} ${APP_VERSION} Installer"
VIAddVersionKey "FileVersion" "${APP_VERSION}"
VIAddVersionKey "CompanyName" "${COMPANY_NAME}"
VIAddVersionKey "LegalCopyright" "${APP_URL}"
VIProductVersion "${APP_VERSION}.0"
OutFile ".\build\${APP_NAME}.exe"

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
Section
    
    RMDir /r "$INSTDIR"

SectionEnd

; ---------------- ;
;  32 bit version  ;
; ---------------- ;
Section "OpenALPR x32" Sec32

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

SectionEnd

; ---------------- ;
;  64 bit version  ;
; ---------------- ;
Section "OpenALPR x64" Sec64

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

SectionEnd

; ----------------- ;
;  Python bindings  ;
; ----------------- ;
Section "Python bindings" SecPython

    SetOutPath "$INSTDIR\openalpr-master\src\bindings\python\"
    ExecWait 'python setup.py install'

SectionEnd

; ---------------------- ;
;  Register uninstaller  ;
; ---------------------- ;
Section

    ;Create uninstaller
    WriteUninstaller "$INSTDIR\Uninstall.exe"

    ;Add/remove programs uninstall entry
    ${GetSize} "$INSTDIR" "/S=0K" $0 $1 $2
    IntFmt $0 "0x%08X" $0
    WriteRegDWORD HKCU "${UNINSTALL_KEY}" "EstimatedSize" "$0"
    WriteRegStr HKCU "${UNINSTALL_KEY}" "DisplayName" "${APP_NAME}"
    WriteRegStr HKCU "${UNINSTALL_KEY}" "DisplayVersion" "${APP_VERSION}"
    ;WriteRegStr HKCU "${UNINSTALL_KEY}" "DisplayIcon" "$INSTDIR\${MUI_ICON_LOCAL_PATH}"
    WriteRegStr HKCU "${UNINSTALL_KEY}" "Publisher" "${COMPANY_NAME}"
    WriteRegStr HKCU "${UNINSTALL_KEY}" "UninstallString" "$INSTDIR\Uninstall.exe"
    WriteRegStr HKCU "${UNINSTALL_KEY}" "InstallString" "$INSTDIR"
    WriteRegStr HKCU "${UNINSTALL_KEY}" "URLInfoAbout" "${APP_URL}"
    WriteRegStr HKCU "${UNINSTALL_KEY}" "HelpLink" "${APP_URL}"

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
    nsExec::ExecToStack 'python -c "import struct;print( 8 * struct.calcsize(\"P\"))"'
    Pop $0
    ${If} $0 = 0
        Pop $0
    ${EndIf}

    ${If} $0 = 32
        StrCpy $9 ${Sec32} ; Radiobutton group 9 - Select x32
        !insertmacro UnselectSection ${Sec64} ; Uncheck it
        SectionSetFlags ${Sec64} ${SF_RO}
    ${EndIf}

    ReadRegStr $1 HKCU "${UNINSTALL_KEY}" "InstallString"
    StrCmp $1 "" done
    StrCpy $INSTDIR $1
    done:

    ${If} ${RunningX64}        
        ${If} $0 <> 32
            StrCpy $9 ${Sec64} ; Radiobutton group 9 - Select x64
            !insertmacro UnselectSection ${Sec32} ; Uncheck it
        ${EndIf}
    ${Else}
        StrCpy $9 ${Sec32} ; Radiobutton group 9 - Select x32
        !insertmacro UnselectSection ${Sec64} ; Uncheck it
        SectionSetFlags ${Sec64} ${SF_RO}
    ${EndIf}
FunctionEnd

; ----------------------------- ;
;  Radio buttons 32 and 64 bit  ;
; ----------------------------- ;
Function .onSelChange

  !insertmacro StartRadioButtons $9
    !insertmacro RadioButton ${Sec32}
    !insertmacro RadioButton ${Sec64}
  !insertmacro EndRadioButtons

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