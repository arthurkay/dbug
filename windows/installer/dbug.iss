[Setup]
AppId={{B5E3C8A2-4F7D-4E9A-A1C3-8D6F2E5B7C9D}
AppName=dbug
AppVersion=0.1.6
AppPublisher=com.dbug
AppPublisherURL=https://github.com/arthurkay/dbug
AppSupportURL=https://github.com/arthurkay/dbug/issues
AppUpdatesURL=https://github.com/arthurkay/dbug/releases
DefaultDirName={autopf}\dbug
DefaultGroupName=dbug
AllowNoIcons=yes
OutputDir=..\..\build
OutputBaseFilename=dbug-windows-x64-setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
SetupIconFile=..\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\dbug.exe
VersionInfoVersion=0.1.6.0
VersionInfoCompany=com.dbug
VersionInfoDescription=dbug - Local API Testing Tool
VersionInfoProductName=dbug
VersionInfoProductVersion=0.1.6

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "quicklaunchicon"; Description: "{cm:CreateQuickLaunchIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked; OnlyBelowVersion: 6.1

[Files]
Source: "..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\dbug"; Filename: "{app}\dbug.exe"
Name: "{group}\{cm:UninstallProgram,dbug}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\dbug"; Filename: "{app}\dbug.exe"; Tasks: desktopicon
Name: "{userappdata}\Microsoft\Internet Explorer\Quick Launch\dbug"; Filename: "{app}\dbug.exe"; Tasks: quicklaunchicon

[Run]
Filename: "{app}\dbug.exe"; Description: "{cm:LaunchProgram,dbug}"; Flags: nowait postinstall skipifsilent
