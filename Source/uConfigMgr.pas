(*

    WinBox for 86Box - An alternative manager for 86Box VMs

    Copyright (C) 2020-2021, Laci b�'

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.

*)

unit uConfigMgr;

interface

uses Windows, Classes, SysUtils, IOUtils, Graphics, Registry;

type
  TConfiguration = class
  public
    MachineRoot: string;
    EraseProtLvl: integer;

    TrayBehavior,
    WinBoxUpdate: integer;
    MinimizeOnStart: boolean;
    LaunchTimeout: integer;

    EmulatorPath,
    Repository: string;
    AutoUpdate,
    GetSource: boolean;

    DisplayMode: integer;
    DisplayValues: TStrings;

    Tools: TStrings;

    CustomTemplates: string;

    LoggingMode: integer;
    GlobalLogFile: string;
    DebugMode, CrashDump: boolean;

    DiskImages: string;

    constructor Create(const AutoLoad: boolean);

    procedure Default;
    procedure Reload; virtual;
    procedure ReloadTools;
    procedure Save;

    destructor Destroy; override;
  end;

var
  Defaults, Config: TConfiguration;

  Templates: string;

type
  TCheckListKey = record
    Name: string;
    Default: integer;
  end;

const
  CheckListKeys: array [0..9] of TCheckListKey =
    (//(Name: 'window_remember';     Default: 0),
     //   Cause a deadlock since makes 86Box continously write to the INI file.
     //   WinBox can handle it, since it reads the INI when the monitor notifies
     //     a change, but ultimately slows down the VM.
     //   Can be re-enabled if this behaviour will be changed in the future,
     //     such as 86Box only write these values at e.g. closing.

     (Name: 'force_43';               Default: 0),
     (Name: 'enable_overscan';        Default: 0),
     (Name: 'dpi_scale';              Default: 1),
     (Name: 'video_filter_method';    Default: 1),
     (Name: 'vid_cga_contrast';       Default: 0),
     (Name: 'update_icons';           Default: 1),
     (Name: 'hide_status_bar';        Default: 0),
     (Name: 'video_fullscreen_first'; Default: 1),
     (Name: 'confirm_exit';           Default: 1),
     (Name: 'enable_discord';         Default: 0));

  ComboBoxKeys: array [0..2] of TCheckListKey =
    ((Name: 'vid_resize';             Default: 0),
     (Name: 'scale';                  Default: 1),
     (Name: 'video_fullscreen_scale'; Default: 0));

type
  TWinBoxImport = class(TConfiguration)
    procedure Reload; override;
    class function IsExists: boolean;
  end;

  T86MgrImport = class(TConfiguration)
    procedure Reload; override;
    class function IsExists: boolean;
  end;

implementation

uses uCommUtil;

resourcestring
  PfTemplatesPath  = 'Templates\';

  DefMachineRoot   = 'WinBox for 86Box\Virtual Machines\';
  DefEmulatorPath  = 'WinBox for 86Box\Emulator Files\86Box.exe';
  DefTemplatesPath = 'WinBox for 86Box\Custom Templates\';
  DefGlobalLogFile = 'WinBox for 86Box\86Box.log';
  DefNameDefFile   = 'WinBox for 86Box\namedefs.ini';

  DefOtherImages   = 'Other Disk Images\';

  DefJenkinsRepo   = 'https://ci.86box.net/job/86Box';
  DefRomsRepo      = 'https://github.com/86Box/roms';
  DefSourceRepo    = 'https://github.com/86Box/86Box';

  DefDisplayValues = 'video_fullscreen_scale=1'#13#10 +
                     'dpi_scale=0'#13#10 +
                     'vid_resize=2';

  RegConfigKey       = 'Software\Laci b�''\WinBox for 86Box\Configuration';

  KeyMachineRoot     = 'MachineRoot';
  KeyEraseProtLvl    = 'EraseProtLvl';
  KeyTrayBehavior    = 'TrayBehavior';
  KeyWinBoxUpdate    = 'WinBoxUpdate';
  KeyMinimizeOnStart = 'MinimizeOnStart';
  KeyLaunchTimeout   = 'LaunchTimeout';
  KeyEmulatorPath    = 'EmulatorPath';
  KeyRepository      = 'Repository';
  KeyAutoUpdate      = 'AutoUpdate';
  KeyGetSource       = 'GetSource';
  KeyDisplayMode     = 'DisplayMode';
  KeyDisplayValues   = 'DisplayValues';
  KeyTools           = 'Tools';
  KeyCustomTemplates = 'CustomTemplates';
  KeyLoggingMode     = 'LoggingMode';
  KeyGlobalLogFile   = 'GlobalLogFile';
  KeyDebugMode       = 'DebugMode';
  KeyCrashDump       = 'CrashDump';

  ImportWinBoxRoot   = 'Software\Laci b�''\WinBox';
  Import86MgrRoot    = 'Software\86Box';

{ TConfiguration }

constructor TConfiguration.Create(const AutoLoad: boolean);
begin
  Tools := TStringList.Create;
  DisplayValues := TStringList.Create;

  if AutoLoad then
    Reload
  else
    Default;
end;

destructor TConfiguration.Destroy;
begin
  DisplayValues.Free;
  Tools.Free;
  inherited;
end;

procedure TConfiguration.Reload;
begin
  Default;

  with TRegistry.Create(KEY_READ) do
    try
      if OpenKeyReadOnly(RegConfigKey) then
        try
          MachineRoot     := IncludeTrailingPathDelimiter(ReadStringDef(KeyMachineRoot, MachineRoot));
          DiskImages      := MachineRoot + DefOtherImages;

          EraseProtLvl    := ReadIntegerDef(KeyEraseProtLvl, EraseProtLvl);

          TrayBehavior    := ReadIntegerDef(KeyTrayBehavior, TrayBehavior);
          WinBoxUpdate    := ReadIntegerDef(KeyWinBoxUpdate, WinBoxUpdate);
          MinimizeOnStart := ReadBoolDef(KeyMinimizeOnStart, MinimizeOnStart);
          LaunchTimeout   := ReadIntegerDef(KeyLaunchTimeout, LaunchTimeout);

          EmulatorPath    := ReadStringDef(KeyEmulatorPath, EmulatorPath);
          Repository      := ReadStringDef(KeyRepository, Repository);
          AutoUpdate      := ReadBoolDef(KeyAutoUpdate, AutoUpdate);
          GetSource       := ReadBoolDef(KeyGetSource, GetSource);

          DisplayMode     := ReadIntegerDef(KeyDisplayMode, DisplayMode);
          case DisplayMode of
            0:    DisplayValues.Assign(Defaults.DisplayValues);
            1, 2: if ValueExists(KeyDisplayValues) then begin
                    DisplayValues.Clear;
                    ReadStringMulti(KeyDisplayValues, DisplayValues);
                  end;
            3:    DisplayValues.Clear;
          end;

          if ValueExists(KeyTools) then begin
            Tools.Clear;
            ReadStringMulti(KeyTools, Tools);
          end;

          CustomTemplates := ReadStringDef(KeyCustomTemplates, CustomTemplates);

          LoggingMode := ReadIntegerDef(KeyLoggingMode, LoggingMode);
          GlobalLogFile := ReadStringDef(KeyGlobalLogFile, GlobalLogFile);
          DebugMode := ReadBoolDef(KeyDebugMode, DebugMode);
          CrashDump := ReadBoolDef(KeyCrashDump, CrashDump);
       finally
          CloseKey;
        end;
    finally
      Free;
    end;
end;

procedure TConfiguration.ReloadTools;
begin
  with TRegistry.Create(KEY_READ) do
    try
      if OpenKeyReadOnly(RegConfigKey) then begin
        Tools.Clear;
        if ValueExists(KeyTools) then
          ReadStringMulti(KeyTools, Tools);
      end;
    finally
      Free;
    end;
end;

procedure TConfiguration.Save;
begin
  with TRegistry.Create(KEY_ALL_ACCESS) do
    try
      if OpenKey(RegConfigKey, true) then
        try
          WriteStringChk(KeyMachineRoot, MachineRoot, Defaults.MachineRoot);
          WriteIntegerChk(KeyEraseProtLvl, EraseProtLvl, Defaults.EraseProtLvl);

          WriteIntegerChk(KeyTrayBehavior, TrayBehavior, Defaults.TrayBehavior);
          WriteIntegerChk(KeyWinBoxUpdate, WinBoxUpdate, Defaults.WinBoxUpdate);

          WriteBoolChk(KeyMinimizeOnStart, MinimizeOnStart, Defaults.MinimizeOnStart);
          WriteIntegerChk(KeyLaunchTimeout, LaunchTimeout, Defaults.LaunchTimeout);

          WriteStringChk(KeyEmulatorPath, EmulatorPath, Defaults.EmulatorPath);
          WriteStringChk(KeyRepository, Repository, Defaults.Repository);
          WriteBoolChk(KeyAutoUpdate, AutoUpdate, Defaults.AutoUpdate);
          WriteBoolChk(KeyGetSource, GetSource, Defaults.GetSource);

          WriteIntegerChk(KeyDisplayMode, DisplayMode, Defaults.DisplayMode);
          DeleteValue(KeyDisplayValues);
          if DisplayMode in [1, 2] then
            WriteStringMulti(KeyDisplayValues, DisplayValues);

          DeleteValue(KeyTools);
          if Tools.Count <> 0 then
            WriteStringMulti(KeyTools, Tools);

          WriteStringChk(KeyCustomTemplates, CustomTemplates, Defaults.CustomTemplates);

          WriteIntegerChk(KeyLoggingMode, LoggingMode, Defaults.LoggingMode);
          WriteStringChk(KeyGlobalLogFile, GlobalLogFile, Defaults.GlobalLogFile);
          WriteBoolChk(KeyDebugMode, DebugMode, Defaults.DebugMode);
          WriteBoolChk(KeyCrashDump, CrashDump, Defaults.CrashDump);
        finally
          CloseKey;
        end;
    finally
      Free;
    end;
end;

procedure TConfiguration.Default;
var
  Documents: string;
begin
  Documents := IncludeTrailingPathDelimiter(TPath.GetDocumentsPath);

  MachineRoot := Documents + DefMachineRoot;
  DiskImages := MachineRoot + DefOtherImages;
  EraseProtLvl := 1;

  TrayBehavior := 0;
  WinBoxUpdate := 3;

  MinimizeOnStart := false;
  LaunchTimeout := 5000;

  EmulatorPath := Documents + DefEmulatorPath;
  Repository := DefJenkinsRepo;
  AutoUpdate := true;
  GetSource := false;

  DisplayMode := 0;
  DisplayValues.Text := DefDisplayValues;

  Tools.Clear;

  CustomTemplates := Documents + DefTemplatesPath;

  LoggingMode := 0;
  GlobalLogFile := Documents + DefGlobalLogFile;
  DebugMode := false;
  CrashDump := false;
end;

{ TWinBoxImport }

class function TWinBoxImport.IsExists: boolean;
begin
  Result := false;
  with TRegistry.Create(KEY_READ) do
    try
      if OpenKeyReadOnly(ImportWinBoxRoot) then begin
        Result := true;
        CloseKey;
      end;
    finally
      Free;
    end;
end;

procedure TWinBoxImport.Reload;
var
  Key: HKEY;
begin
  Default;

  with TRegIniFile.Create(ImportWinBoxRoot, KEY_READ) do
    try
      Tools.Clear;
      ReadSectionValues('Configuration.Tools', Tools);

      MachineRoot := IncludeTrailingPathDelimiter(ReadString('Configuration', 'RootDirectory', MachineRoot));
      DiskImages := MachineRoot + DefOtherImages;

      EmulatorPath := IncludeTrailingPathDelimiter(
        GetEnvironmentVariable('APPDATA')) + 'Laci b�''\WinBox\86Box\86Box.exe';

      Repository := ReadString('Configuration.86Box', 'Repository', Repository);
      AutoUpdate := ReadInteger('Configuration.86Box', 'AutoUpdate', ord(AutoUpdate)) <> 0;
      GetSource := ReadInteger('Configuration.86Box', 'DownloadSource', ord(GetSource)) <> 0;

      case ReadInteger('Configuration.86Box', 'AutoAppearance', 1) of
        0: DisplayMode := 3;
        2: DisplayMode := 1;
        3: DisplayMode := 2;
        else
          DisplayMode := 0;
      end;

      DisplayValues.Clear;
      if RegOpenKey(CurrentKey, 'Configuration.86Box', Key) = ERROR_SUCCESS then begin
        RegReadMulti(Key, 'ApperanceValues', DisplayValues);
        RegCloseKey(Key);
      end;
    finally
      Free;
    end;
end;

{ T86MgrImport }

class function T86MgrImport.IsExists: boolean;
begin
  Result := false;
  with TRegistry.Create(KEY_READ) do
    try
      if OpenKeyReadOnly(Import86MgrRoot) then begin
        Result := true;
        CloseKey;
      end;
    finally
      Free;
    end;
end;

procedure T86MgrImport.Reload;
begin
  Default;

  with TRegistry.Create(KEY_READ) do
    try
      if OpenKeyReadOnly(Import86MgrRoot) then
        try
          MachineRoot := IncludeTrailingPathDelimiter(ReadStringDef('CFGdir', MachineRoot));
          DiskImages := MachineRoot + DefOtherImages;

          if ReadBoolDef('CloseToTray', TrayBehavior = 2) then
            TrayBehavior := 2
          else if ReadBoolDef('MinimizeToTray', TrayBehavior = 1) then
            TrayBehavior := 1
          else
            TrayBehavior := 0;

          LaunchTimeout := ReadIntegerDef('LaunchTimeout', LaunchTimeout);
          EmulatorPath := ReadStringDef('EXEdir', EmulatorPath) + '86Box.exe';
          if not FileExists(EmulatorPath) then
            EmulatorPath := Defaults.EmulatorPath;

          if ReadBoolDef('EnableLogging', LoggingMode = 1) then begin
            LoggingMode := 1;
            GlobalLogFile := ReadStringDef('LogPath', GlobalLogFile);
          end;

          DisplayMode := 3;
          MinimizeOnStart := ReadBoolDef('MinimizeOnVMStart', MinimizeOnStart);
          AutoUpdate := false;
        finally
          CloseKey;
        end;
    finally
      Free;
    end;
end;

initialization
  Defaults := TConfiguration.Create(false);
  Config   := TConfiguration.Create(true);

  Templates := ExtractFilePath(paramstr(0));
  Templates := Templates + PfTemplatesPath;

finalization
  Config.Free;
  Defaults.Free;

end.
