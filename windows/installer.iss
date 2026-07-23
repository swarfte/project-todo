#define MyAppName GetStringParam("MyAppName", "My Flutter App")
#define MyAppExeName GetStringParam("MyAppExeName", "my_app.exe")
#define MyAppVersion GetStringParam("MyAppVersion", "1.0.0")
#define BuildDir GetStringParam("BuildDir", "build\windows\x64\runner\Release")
#define OutputDir GetStringParam("OutputDir", "dist")

[Setup]
AppId={{B43F6267-C230-4B22-9905-9A988F32E784}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}

OutputDir={#OutputDir}
OutputBaseFilename={#MyAppName}-Windows-Setup

Compression=lzma2
SolidCompression=yes
WizardStyle=modern

ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

PrivilegesRequired=admin
UninstallDisplayIcon={app}\{#MyAppExeName}

[Files]
Source: "{#BuildDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "建立桌面捷徑"; GroupDescription: "其他選項："

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "啟動 {#MyAppName}"; Flags: nowait postinstall skipifsilent