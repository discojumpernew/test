#ifndef MyAppVersion
#define MyAppVersion "1.1.0"
#endif

[Setup]
AppId={{8F3C2A61-7B4D-4A2E-9C1F-5E7A9B3D6C42}
AppName=IPS4MCO Car Wash Terminal
AppVersion={#MyAppVersion}
AppVerName=IPS4MCO Car Wash Terminal {#MyAppVersion}
AppPublisher=voda
DefaultDirName={sd}\IPS4MCO
DirExistsWarning=no
DisableProgramGroupPage=yes
AllowNoIcons=yes
UninstallDisplayName=IPS4MCO Car Wash Terminal
UninstallDisplayIcon={app}\IPS4MCO.exe
OutputDir=..\installer-out
OutputBaseFilename=IPS4MCO-Setup-{#MyAppVersion}
SetupIconFile=..\icon.ico
WizardStyle=modern
WizardImageFile=wizard.bmp
WizardSmallImageFile=wizard-small.bmp
Compression=lzma2/max
SolidCompression=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0
PrivilegesRequired=admin
CloseApplications=yes
RestartApplications=no
ChangesEnvironment=no

[Languages]
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"

[Tasks]
Name: "desktopicon"; Description: "Ярлык на рабочем столе"; GroupDescription: "Ярлыки:"
Name: "autostart"; Description: "Автозапуск терминала при входе в Windows (рекомендуется для киоска)"; GroupDescription: "Запуск:"; Flags: checkedonce

[Dirs]
; Папка установки доступна на запись обычному пользователю:
; приложение пишет config/id.json, логи и файлы OTA-обновлений рядом с exe
Name: "{app}"; Permissions: users-modify

[Files]
; Основные файлы приложения (всё кроме config)
Source: "..\dist\*"; DestDir: "{app}"; Excludes: "config,config\*"; Flags: ignoreversion recursesubdirs createallsubdirs

; Конфиги: перезаписываем только если файла ещё нет,
; чтобы не затереть настройки (COM-порт, цены, креды БД)
Source: "..\dist\config\*"; DestDir: "{app}\config"; Flags: ignoreversion onlyifdoesntexist uninsneveruninstall recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\IPS4MCO"; Filename: "{app}\IPS4MCO.exe"; WorkingDir: "{app}"
Name: "{autodesktop}\IPS4MCO"; Filename: "{app}\IPS4MCO.exe"; WorkingDir: "{app}"; Tasks: desktopicon
Name: "{userstartup}\IPS4MCO Terminal"; Filename: "{app}\IPS4MCO.exe"; WorkingDir: "{app}"; Tasks: autostart

[Run]
Filename: "{app}\IPS4MCO.exe"; Description: "Запустить IPS4MCO"; WorkingDir: "{app}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
; Чистим артефакты работы приложения; config с ID-кодом поста сохраняется
Type: filesandordirs; Name: "{app}\update"
Type: filesandordirs; Name: "{app}\log"
Type: files; Name: "{app}\IPS4MCO.exe.bak"
Type: files; Name: "{app}\apply_update.bat"

[Code]
// Киоск-приложение открывается поверх всех окон — убеждаемся, что оно закрыто
function PrepareToInstall(var NeedsRestart: Boolean): String;
var
  ResultCode: Integer;
begin
  Result := '';
  Exec('taskkill.exe', '/IM IPS4MCO.exe /F /T', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Sleep(500);
end;
