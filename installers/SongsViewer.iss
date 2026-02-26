; Inno Setup Script for Songs Viewer
; Generated for Songs Viewer Flutter Windows application

#define MyAppName "Songs Viewer"
#define MyAppVersion "1.1.25"
#define MyAppPublisher "jelazi"
#define MyAppURL "https://github.com/jelazi"
#define MyAppExeName "songs_viewer.exe"
#define MySourceDir "..\build\windows\x64\runner\Release"
#define MyIconFile "..\windows\runner\resources\app_icon.ico"

[Setup]
; NOTE: The value of AppId uniquely identifies this application.
; (To generate a new GUID, click Tools | Generate GUID inside the IDE.)
AppId={{B7F2A3E1-5C4D-4E8F-9A1B-2D3E4F5A6B7C}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\SongsViewer
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
; Uncomment the following line to run in non administrative install mode (install for current user only.)
;PrivilegesRequired=lowest
OutputDir=C:\Users\jelazi\Workspace\Setups
OutputBaseFilename=SongsViewerSetup_{#MyAppVersion}
SetupIconFile={#MyIconFile}
UninstallDisplayIcon={app}\{#MyAppExeName}
Compression=lzma
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "czech"; MessagesFile: "compiler:Languages\Czech.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#MySourceDir}\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#MySourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Code]
procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  AppDataDir: String;
begin
  if CurUninstallStep = usUninstall then begin
    if MsgBox('Chcete odinstalovat všechna uživatelská data?', mbConfirmation,
        MB_YESNO) = IDYES
    then begin
      AppDataDir := ExpandConstant('{localappdata}\SongsViewer');
      if DirExists(AppDataDir) then
        DelTree(AppDataDir, True, True, True);
    end;
  end;
end;
