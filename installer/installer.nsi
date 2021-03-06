﻿;
;	Copyright (C) 2013 - 2015 Hong Jen Yee (PCMan) <pcman.tw@gmail.com>
;
;	This library is free software; you can redistribute it and/or
;	modify it under the terms of the GNU Library General Public
;	License as published by the Free Software Foundation; either
;	version 2 of the License, or (at your option) any later version.
;
;	This library is distributed in the hope that it will be useful,
;	but WITHOUT ANY WARRANTY; without even the implied warranty of
;	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;	Library General Public License for more details.
;
;	You should have received a copy of the GNU Library General Public
;	License along with this library; if not, write to the
;	Free Software Foundation, Inc., 51 Franklin St, Fifth Floor,
;	Boston, MA  02110-1301, USA.
;

!include "MUI2.nsh" ; modern UI
!include "x64.nsh" ; NSIS plugin used to detect 64 bit Windows
!include "Winver.nsh" ; Windows version detection
!include "LogicLib.nsh" ; for ${If}, ${Switch} commands

Unicode true ; turn on Unicode (This requires NSIS 3.0)
SetCompressor /SOLID lzma ; use LZMA for best compression ratio
SetCompressorDictSize 16 ; larger dictionary size for better compression ratio
AllowSkipFiles off ; cannot skip a file

; icons of the generated installer and uninstaller
!define MUI_ICON "${NSISDIR}\Contrib\Graphics\Icons\orange-install.ico"
!define MUI_UNICON "${NSISDIR}\Contrib\Graphics\Icons\orange-uninstall.ico"
!define PRODUCT_VERSION "git"

!define PRODUCT_UNINST_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\PIME"
!define HOMEPAGE_URL "https://github.com/EasyIME/"

Name "PIME 輸入法"
BrandingText "PIME 輸入法"

OutFile "PIME-${PRODUCT_VERSION}-setup.exe" ; The generated installer file name

; We install everything to C:\Program Files (x86)
InstallDir "$PROGRAMFILES32\PIME"

;Request application privileges (need administrator to install)
RequestExecutionLevel admin
!define MUI_ABORTWARNING

;Pages
; license page
!insertmacro MUI_PAGE_LICENSE "..\COPYING.txt"

; !insertmacro MUI_PAGE_COMPONENTS

; installation progress page
!insertmacro MUI_PAGE_INSTFILES

; finish page
!define MUI_FINISHPAGE_LINK_LOCATION "${HOMEPAGE_URL}"
!define MUI_FINISHPAGE_LINK "PIME 專案網頁 ${MUI_FINISHPAGE_LINK_LOCATION}"
!insertmacro MUI_PAGE_FINISH

; uninstallation pages
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
;--------------------------------

!insertmacro MUI_LANGUAGE "TradChinese" ; traditional Chinese

; Uninstall old versions
Function uninstallOldVersion
	ClearErrors
	;  run uninstaller
	ReadRegStr $R0 HKLM "${PRODUCT_UNINST_KEY}" "UninstallString"
	${If} $R0 != ""
		ClearErrors
		MessageBox MB_OKCANCEL|MB_ICONQUESTION "偵測到已安裝舊版，是否要移除舊版後繼續安裝新版？" IDOK +2
			Abort ; this is skipped if the user select OK

		CopyFiles "$INSTDIR\Uninstall.exe" "$TEMP"
		ExecWait '"$TEMP\Uninstall.exe" _?=$INSTDIR'
		Delete "$TEMP\Uninstall.exe"
	${EndIf}

	;ClearErrors
	; Ensure that old files are all deleted
	;${If} ${RunningX64}
	;	${If} ${FileExists} "$INSTDIR\x64\PIMETextService.dll"
	;		Call onInstError
	;	${EndIf}			
	;${EndIf}
	;${If} ${FileExists} "$INSTDIR\x86\PIMETextService.dll"
	;	Call onInstError
	;${EndIf}			
	;${If} ${FileExists} "$INSTDIR\Dictionary\*.dat"
	;	Call onInstError
	;${EndIf}
FunctionEnd

; Called during installer initialization
Function .onInit
	; Currently, we're not able to support Windows xp since it has an incomplete TSF.
	${IfNot} ${AtLeastWinVista}
		MessageBox MB_ICONSTOP|MB_OK "抱歉，本程式目前只能支援 Windows Vista 以上版本"
		Quit
	${EndIf}

	${If} ${RunningX64} 
		SetRegView 64 ; disable registry redirection and use 64 bit Windows registry directly
	${EndIf}

	; check if old version is installed and uninstall it first
	Call uninstallOldVersion
FunctionEnd

; called to show an error message when errors happen
Function .onInstFailed
	MessageBox MB_ICONSTOP|MB_OK "安裝發生錯誤，無法完成。$\n$\n可能有檔案正在使用中，暫時無法刪除或覆寫$\n$\n建議重新開機後，再次執行安裝程式。"
FunctionEnd

; called to show an error message when errors happen
;Function onInstError
;	MessageBox MB_ICONSTOP|MB_OK "安裝發生錯誤，舊版可能有檔案正在使用中，暫時無法覆寫$\n$\n請重開機後，再次執行安裝程式。"
;	Abort
;FunctionEnd

;Installer Sections
Section "PIME 輸入法" SecMain

	; TODO: may be we can automatically rebuild the dlls here.
	; http://stackoverflow.com/questions/24580/how-do-you-automate-a-visual-studio-build
	; For example, we can build the Visual Studio solution with the following command line.
	; C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\devenv.com "..\build\PIME.sln" /build Release

	SetOverwrite on ; overwrite existing files
	SetOutPath "$INSTDIR"
	; FIXME: install python and pywin32 automatically as needed
	; Download and install python 3.4.3
	; nsisdl::download https://www.python.org/ftp/python/3.4.3/python-3.4.3.msi $0
	; ExecWait '"msiexec" /i "$0"'

	; Download and install pywin32
	; nsisdl::download http://downloads.sourceforge.net/project/pywin32/pywin32/Build%20219/pywin32-219.win32-py3.4.exe?r=http%3A%2F%2Fsourceforge.net%2Fprojects%2Fpywin32%2Ffiles%2Fpywin32%2FBuild%2520219%2F&ts=1439740165 $0
	; ExecWait "$0"

	; Install the python server and input method modules
	File /r /x "__pycache__" "..\server"

    ; Install the launcher and monitor of the server
	File "..\build\PIMELauncher\Release\PIMELauncher.exe"

    ; Install the text service dlls
	${If} ${RunningX64} ; This is a 64-bit Windows system
		SetOutPath "$INSTDIR\x64"
		File "..\build64\pime\Release\PIMETextService.dll" ; put 64-bit PIMETextService.dll in x64 folder
		; Register COM objects (NSIS RegDLL command is broken and cannot be used)
		ExecWait '"$SYSDIR\regsvr32.exe" /s "$INSTDIR\x64\PIMETextService.dll"'
	${EndIf}
	SetOutPath "$INSTDIR\x86"
	File "..\build\pime\Release\PIMETextService.dll" ; put 32-bit PIMETextService.dll in x86 folder
	; Register COM objects (NSIS RegDLL command is broken and cannot be used)
	ExecWait '"$SYSDIR\regsvr32.exe" /s "$INSTDIR\x86\PIMETextService.dll"'

	; Launch the python server on startup
    ; TODO: write the PIMELauncher program
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Run" "PIMELauncher" "$INSTDIR\PIMELauncher.exe"

	;Store installation folder in the registry
	WriteRegStr HKLM "Software\PIME" "" $INSTDIR
	;Write an entry to Add & Remove applications
	WriteRegStr HKLM "${PRODUCT_UNINST_KEY}" "DisplayName" "PIME 輸入法"
	WriteRegStr HKLM "${PRODUCT_UNINST_KEY}" "UninstallString" "$\"$INSTDIR\uninstall.exe$\""
	WriteRegStr HKLM "${PRODUCT_UNINST_KEY}" "Publisher" "PIME 開發團隊"
	; WriteRegStr HKLM "${PRODUCT_UNINST_KEY}" "DisplayIcon" "$INSTDIR\x86\PIMETextService.dll"
	WriteRegStr HKLM "${PRODUCT_UNINST_KEY}" "DisplayVersion" "${PRODUCT_VERSION}"
	WriteRegStr HKLM "${PRODUCT_UNINST_KEY}" "URLInfoAbout" "${HOMEPAGE_URL}"
	WriteUninstaller "$INSTDIR\Uninstall.exe" ;Create uninstaller
SectionEnd

;Language strings
LangString DESC_SecMain ${LANG_ENGLISH} "A test section." ; What's this??

;Assign language strings to sections
!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
!insertmacro MUI_DESCRIPTION_TEXT ${SecMain} $(DESC_SecMain)
!insertmacro MUI_FUNCTION_DESCRIPTION_END

;Uninstaller Section
Section "Uninstall"

	; Unregister COM objects (NSIS UnRegDLL command is broken and cannot be used)
	ExecWait '"$SYSDIR\regsvr32.exe" /u /s "$INSTDIR\x86\PIMETextService.dll"'
	${If} ${RunningX64} 
		SetRegView 64 ; disable registry redirection and use 64 bit Windows registry directly
		ExecWait '"$SYSDIR\regsvr32.exe" /u /s "$INSTDIR\x64\PIMETextService.dll"'
		RMDir /r "$INSTDIR\x64"
	${EndIf}

	RMDir /r "$INSTDIR\x86"
	RMDir /r "$INSTDIR\server"
	Delete "$INSTDIR\PIMELauncher.exe"

	DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\PIME"
	DeleteRegValue HKLM "Software\Microsoft\Windows\CurrentVersion\Run" "PIMELauncher"
	DeleteRegKey /ifempty HKLM "Software\PIME"

	Delete "$INSTDIR\Uninstall.exe"
	RMDir "$INSTDIR"

SectionEnd

