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

unit frmProgSettDlg;

interface

uses
  Types, Windows, SysUtils, Classes, Controls, Forms, Dialogs, StdCtrls,
  ComCtrls, Buttons, ExtCtrls, Vcl.Samples.Spin, CheckLst, Menus, Registry,
  ShellAPI, uLang;

type
  TProgSettDlg = class(TForm, ILanguageSupport)
    pcPages: TPageControl;
    btnOK: TButton;
    btnCancel: TButton;
    tabGeneral: TTabSheet;
    tabAppearance: TTabSheet;
    grpDefaultPath: TGroupBox;
    imgNewVM: TImage;
    lbDefaultPath: TLabel;
    lbPath: TLabel;
    edPath: TEdit;
    btnPath: TButton;
    btnDefPath: TButton;
    btnOpenPath: TButton;
    lbEraseProt: TLabel;
    cbEraseProt: TComboBox;
    imgInfo: TImage;
    lbOnlyNewVM: TLabel;
    grpBehavior: TGroupBox;
    cbMinimizeOnStart: TCheckBox;
    lbTrayBehavior: TLabel;
    cbTrayBehavior: TComboBox;
    lbLaunchTimeout: TLabel;
    spLaunchTimeout: TSpinEdit;
    lbMilliseconds: TLabel;
    grpAppearance: TGroupBox;
    imgDisplay: TImage;
    lbDefaultDisplay: TLabel;
    lbFullscreenSizing: TLabel;
    lbWindowSizing: TLabel;
    rbDefaultDisplay: TRadioButton;
    rbCustomDisplay: TRadioButton;
    clbCustomOptions: TCheckListBox;
    cbFullscreenSizing: TComboBox;
    cbWindowSizing: TComboBox;
    rbManualOptions: TRadioButton;
    mmManualOptions: TMemo;
    rbNoDisplayOptions: TRadioButton;
    btnManOptLoad: TButton;
    tabTools: TTabSheet;
    grpTools: TGroupBox;
    imgTools: TImage;
    lbTools: TLabel;
    lvTools: TListView;
    btnToolAdd: TButton;
    btnToolClear: TButton;
    btnToolDelete: TButton;
    btnToolModify: TButton;
    grpToolProperties: TGroupBox;
    lbToolName: TLabel;
    lbToolPath: TLabel;
    edToolName: TEdit;
    mmToolPath: TMemo;
    btnToolBrowse: TButton;
    tabEmulator: TTabSheet;
    grpDefEmulator: TGroupBox;
    imgEmulator: TImage;
    lbDefEmulator: TLabel;
    lbAffectedVMs: TLabel;
    lb86BoxPath: TLabel;
    ed86Box: TEdit;
    btnDef86Box: TButton;
    btnOpen86Box: TButton;
    btn86Box: TButton;
    grpAutoUpdate: TGroupBox;
    lbRepository: TLabel;
    cbAutoUpdate: TCheckBox;
    cbGetSource: TCheckBox;
    cbRepositories: TComboBox;
    tabSpecial: TTabSheet;
    grpExtraPaths: TGroupBox;
    lbExtraPaths: TLabel;
    imgExtraPaths: TImage;
    lbCustomTemplates: TLabel;
    edCustomTemplates: TEdit;
    btnCustomTemplates: TButton;
    btnOpenCustomTemplates: TButton;
    btnDefCustomTemplates: TButton;
    grpDebug: TGroupBox;
    lbDebug: TLabel;
    imgDebug: TImage;
    lbLogging: TLabel;
    cbLogging: TComboBox;
    cbDebugMode: TCheckBox;
    cbCrashDump: TCheckBox;
    lbGlobalLog: TLabel;
    edGlobalLog: TEdit;
    btnGlobalLog: TButton;
    btnDefGlobalLog: TButton;
    btnImport: TButton;
    pmImport: TPopupMenu;
    miImportWinBox: TMenuItem;
    miImport86Mgr: TMenuItem;
    od86Box: TOpenDialog;
    odTools: TOpenDialog;
    odLogFiles: TOpenDialog;
    lbVersion: TLabel;
    lbAppearance: TLabel;
    N1: TMenuItem;
    miDefaults: TMenuItem;
    odConfigFiles: TOpenDialog;
    lbWinBoxUpdate: TLabel;
    cbWinBoxUpdate: TComboBox;
    procedure Reload(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure cbLoggingChange(Sender: TObject);
    procedure UpdateApperance(Sender: TObject);
    procedure lvToolsSelectItem(Sender: TObject; Item: TListItem;
      Selected: Boolean);
    procedure CustomDisplayChange(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure btnImportClick(Sender: TObject);
    procedure miImportWinBoxClick(Sender: TObject);
    procedure miImport86MgrClick(Sender: TObject);
    procedure btnBrowseClick(Sender: TObject);
    procedure btnDefaultClick(Sender: TObject);
    procedure btnOpenClick(Sender: TObject);
    procedure btnToolsClick(Sender: TObject);
    procedure ed86BoxChange(Sender: TObject);
    procedure miDefaultsClick(Sender: TObject);
    procedure btnManOptLoadClick(Sender: TObject);
  private
    procedure UpdateTools(Tools: TStrings);
  public
    LangName: string;
    procedure GetTranslation(Language: TLanguage); stdcall;
    procedure Translate; stdcall;
  end;

var
  ProgSettDlg: TProgSettDlg;

implementation

uses uCommUtil, uCommText, uConfigMgr, frmMainForm, IniFiles;

resourcestring
  StrLvToolsColumn0 = '.lvTools.Column[0]';
  StrLvToolsColumn1 = '.lvTools.Column[1]';

  AskNewVMPath = '.AskNewVMPath';
  AskTemplatePath = '.AskTemplatePath';
  AskSaveChanges = '.AskSaveChanges';

  EOpenConfigLocked = '.EOpenConfigLocked';

{$R *.dfm}

procedure TProgSettDlg.btnBrowseClick(Sender: TObject);
var
  Directory: string;
begin
  case (Sender as TComponent).Tag of
    1: begin
         Directory := ExcludeTrailingPathDelimiter(edPath.Text);
         if SelectDirectory(_T(LangName + AskNewVMPath), '', Directory, Self) then
           edPath.Text := IncludeTrailingPathDelimiter(Directory);
       end;
    2: begin
         od86Box.InitialDir := ExtractFilePath(ed86Box.Text);
         od86Box.FileName := ExtractFileName(ed86Box.Text);
         if od86Box.Execute then
           ed86Box.Text := od86Box.FileName;
       end;
    3: begin
         Directory := ExcludeTrailingPathDelimiter(edCustomTemplates.Text);
         if SelectDirectory(_T(LangName + AskTemplatePath), '', Directory, Self) then
           edCustomTemplates.Text := IncludeTrailingPathDelimiter(Directory);
       end;
    4: begin
         odLogFiles.InitialDir := ExtractFilePath(edGlobalLog.Text);
         odLogFiles.FileName := ExtractFileName(edGlobalLog.Text);
         if odLogFiles.Execute then
           edGlobalLog.Text := odLogFiles.FileName;
       end;
    5: begin
         odTools.InitialDir := ExtractFilePath(mmToolPath.Text);
         odTools.FileName := ExtractFileName(mmToolPath.Text);
         if odTools.Execute then begin
           if (edToolName.Text = '') or (WideLowerCase(
               ChangeFileExt(ExtractFileName(mmToolPath.Text), ''))
                  = WideLowerCase(edToolName.Text)) then
              edToolName.Text := ChangeFileExt(ExtractFileName(odTools.FileName), '');

           mmToolPath.Text := odTools.FileName;
         end;
       end;
  end;
end;

procedure TProgSettDlg.btnDefaultClick(Sender: TObject);
begin
  case (Sender as TComponent).Tag of
    1: edPath.Text := Defaults.MachineRoot;
    2: ed86Box.Text := Defaults.EmulatorPath;
    3: edCustomTemplates.Text := Defaults.CustomTemplates;
    4: edGlobalLog.Text := Defaults.GlobalLogFile;
  end;
end;

procedure TProgSettDlg.btnImportClick(Sender: TObject);
begin
  with ClientToScreen(Point(btnImport.Left, btnImport.Top + btnImport.Height)) do
    pmImport.Popup(X, Y);
end;

procedure TProgSettDlg.btnManOptLoadClick(Sender: TObject);
var
  Config: TMemIniFile;
begin
  with WinBoxMain do
    if IsSelectedVM then
      odConfigFiles.InitialDir := Profiles[List.ItemIndex - 2].WorkingDirectory;

  if odConfigFiles.Execute then begin
    if FileExists(odConfigFiles.FileName) and
       CanLockFile(odConfigFiles.FileName, GENERIC_READ) then begin
           Config := TryLoadIni(odConfigFiles.FileName);
           try
             with Config do begin
               mmManualOptions.Clear;
               Config.DeleteKey('General', 'window_fixed_res');
               Config.ReadSectionValues('General', mmManualOptions.Lines);
               UpdateApperance(mmManualOptions);
             end;
           finally
             Config.Free;
           end;
       end
    else
      raise Exception.Create(_T(LangName + EOpenConfigLocked, [odConfigFiles.FileName]));
  end;
end;

procedure TProgSettDlg.btnOKClick(Sender: TObject);
var
  I: integer;

  procedure FixPath(const Control: TEdit; const EndDelim: boolean);
  begin
    if EndDelim then
      Control.Text := IncludeTrailingPathDelimiter(Control.Text);

    if (Control.Text = '') or (Control.Text = '\') or (Control.Text = '/') then begin
      if Assigned(Control.Parent) and Assigned(Control.Parent.Parent)
         and (Control.Parent.Parent is TTabSheet) then begin
           pcPages.ActivePage := Control.Parent.Parent as TTabSheet;
           FocusControl(Control);
         end;
      raise Exception.Create(SysErrorMessage(ERROR_INVALID_DATA));
    end;

    //Ha rossz f�jln�v van megadva az emul�tornak, akkor ind�t�sn�l
    // kell majd exceptiont feldobni -> lehet�s�g ut�lagos friss�t�sre.
    //Ezen fel�l ha itt lenne ellen�rizve, �s m�g nincs let�ltve semmi,
    // a Defaults.EmulatorPath is exceptiont dobna ezen a ponton.
  end;

begin
  FixPath(edPath, true);
  FixPath(ed86Box, false);
  FixPath(edCustomTemplates, true);
  FixPath(edGlobalLog, false);

  if Assigned(lvTools.Selected) then
    with lvTools.Selected do begin
      if ((Caption <> edToolName.Text) or
           ((SubItems.Count > 0) and (mmToolPath.Text <> SubItems[0]))) and
           (edToolName.Text <> '') and (mmToolPath.Text <> '') and
         (MessageBox(Handle, _P(LangName + AskSaveChanges),
           PChar(Application.Title), MB_YESNO or MB_ICONQUESTION) = mrYes) then
            btnToolModify.Click;
    end
  else if (edToolName.Text <> '') and (mmToolPath.Text <> '') and
          (MessageBox(Handle, _P(LangName + AskSaveChanges),
            PChar(Application.Title), MB_YESNO or MB_ICONQUESTION) = mrYes) then
              btnToolAdd.Click;

  with Config do begin
    MachineRoot := edPath.Text;
    EmulatorPath := ed86Box.Text;
    CustomTemplates := edCustomTemplates.Text;
    GlobalLogFile := edGlobalLog.Text;

    EraseProtLvl := cbEraseProt.ItemIndex;
    TrayBehavior := cbTrayBehavior.ItemIndex;
    WinBoxUpdate := cbWinBoxUpdate.ItemIndex;
    LoggingMode := cbLogging.ItemIndex;

    Repository := cbRepositories.Text;

    MinimizeOnStart := cbMinimizeOnStart.Checked;
    AutoUpdate := cbAutoUpdate.Checked;
    GetSource := cbGetSource.Checked;
    DebugMode := cbDebugMode.Checked;
    CrashDump := cbCrashDump.Checked;

    LaunchTimeout := spLaunchTimeout.Value;

    Tools.Clear;
    for I := 0 to lvTools.Items.Count - 1 do
      with lvTools.Items[I] do
        if SubItems.Count > 0 then
          Tools.AddPair(Caption, SubItems[0]);

    if rbCustomDisplay.Checked then
      DisplayMode := 1
    else if rbManualOptions.Checked then
      DisplayMode := 2
    else if rbNoDisplayOptions.Checked then
      DisplayMode := 3
    else
      DisplayMode := 0;

    case DisplayMode of
      0:    DisplayValues.Assign(Defaults.DisplayValues);
      1, 2: DisplayValues.Assign(mmManualOptions.Lines);
      3:    DisplayValues.Clear;
    end;

    Save;
  end;

  ModalResult := mrOK;
end;

procedure TProgSettDlg.btnOpenClick(Sender: TObject);
var
  Path: string;
begin
  case (Sender as TComponent).Tag of
    1: Path := ExcludeTrailingPathDelimiter(edPath.Text);
    2: Path := ExtractFileDir(ed86Box.Text);
      //Ez leveszi alapb�l a \ jelet, szemben az ExtractFilePath
      // f�ggv�nnyel (ami r�teszi, vagy csak nem veszi el?).
    3: Path := ExcludeTrailingPathDelimiter(edCustomTemplates.Text);
  end;

  SysUtils.ForceDirectories(Path); //nem a FileCtrl verzi� kell
  ShellExecute(Handle, 'open', PChar(Path), nil, nil, SW_SHOWNORMAL);
end;

procedure TProgSettDlg.btnToolsClick(Sender: TObject);

  function ValidateInput: boolean;
  begin
    Result := (edToolName.Text <> '') and (mmToolPath.Text <> '');
  end;

  function Find(const S: string): integer;
  var
    I: Integer;
  begin
    Result := -1;
    for I := 0 to lvTools.Items.Count - 1 do
      if lvTools.Items[I].Caption = S then
        exit(I);
  end;

  procedure Error;
  begin
    if edToolName.Text = '' then
      edToolName.SetFocus
    else
      mmToolPath.SetFocus;
    raise Exception.Create(SysErrorMessage(ERROR_INVALID_DATA));
  end;

begin
  case (Sender as TComponent).Tag of
    4: begin
         lvTools.Clear;
         lvTools.ItemIndex := -1;
       end;
    3: begin
         lvTools.DeleteSelected;
         lvTools.ItemIndex := -1;
       end;
    2: if Assigned(lvTools) and ValidateInput then
         with lvTools.Selected do begin
           Caption := edToolName.Text;
           SubItems.Clear;
           SubItems.Add(mmToolPath.Text);
         end
       else
         Error;

    1: if not ValidateInput then begin
         btnToolBrowse.Click;
         if ValidateInput then
           with lvTools.Items.Add do begin
             Caption := edToolName.Text;
             SubItems.Add(mmToolPath.Text);
             lvTools.ItemIndex := Index;
           end
         else
           Error;
       end
       else if Find(edToolName.Text) = -1 then
         with lvTools.Items.Add do begin
           Caption := edToolName.Text;
           SubItems.Add(mmToolPath.Text);
         end
  end;
end;

procedure TProgSettDlg.cbLoggingChange(Sender: TObject);
begin
  edGlobalLog.Enabled := cbLogging.ItemIndex = 1;
  btnGlobalLog.Enabled := edGlobalLog.Enabled;
  btnDefGlobalLog.Enabled := edGlobalLog.Enabled;
end;

procedure TProgSettDlg.CustomDisplayChange(Sender: TObject);
var
  I: integer;

  procedure WriteKey(const Name: string; const Value, Default: integer);
  begin
    if Value <> Default then
      mmManualOptions.Lines.AddPair(Name, IntToStr(Value));
  end;

begin
  if rbCustomDisplay.Checked then
    with mmManualOptions.Lines do begin
      BeginUpdate;
      Clear;

      for I := 0 to High(CheckListKeys) do
        with CheckListKeys[I] do
          WriteKey(Name, ord(clbCustomOptions.Checked[I]), Default);

      case cbWindowSizing.ItemIndex of
        1, 2: AddPair('vid_resize', IntToStr(cbWindowSizing.ItemIndex));
        3:    begin
                AddPair('vid_resize', '1');
                AddPair('scale', '0');
              end;
        4, 5: begin
                AddPair('vid_resize', '1');
                AddPair('scale', IntToStr(cbWindowSizing.ItemIndex - 2));
              end;
      end;

      WriteKey(ComboBoxKeys[2].Name,
               cbFullscreenSizing.ItemIndex,
               ComboBoxKeys[2].Default);

      EndUpdate;
    end;
end;

procedure TProgSettDlg.ed86BoxChange(Sender: TObject);
begin
  if FileExists(ed86Box.Text) then
    lbVersion.Caption := format(_T(StrVersion) ,[GetFileVer(ed86Box.Text)])
  else
    lbVersion.Caption := format(_T(StrVersion) ,[_T(StrUnknown)])
end;

procedure TProgSettDlg.FormCreate(Sender: TObject);
begin
  pcPages.ActivePageIndex := 0;
  LangName := Copy(ClassName, 2, MaxInt);

  WinBoxMain.Icons32.GetIcon(8, imgExtraPaths.Picture.Icon);
  WinBoxMain.Icons32.GetIcon(11, imgInfo.Picture.Icon);
  WinBoxMain.Icons32.GetIcon(13, imgNewVM.Picture.Icon);

  WinBoxMain.Icons32.GetIcon(30, imgDisplay.Picture.Icon);
  WinBoxMain.Icons32.GetIcon(31, imgEmulator.Picture.Icon);
  WinBoxMain.Icons32.GetIcon(32, imgTools.Picture.Icon);
  WinBoxMain.Icons32.GetIcon(33, imgDebug.Picture.Icon);

  Translate;
end;

procedure TProgSettDlg.lvToolsSelectItem(Sender: TObject; Item: TListItem;
  Selected: Boolean);
begin
  with lvTools do
    if Assigned(Selected) then begin
      edToolName.Text := Selected.Caption;
      if Selected.SubItems.Count > 0 then
        mmToolPath.Text := Selected.SubItems[0]
      else
        mmToolPath.Text := '';
    end
    else begin
      edToolName.Text := '';
      mmToolPath.Text := '';
    end;
end;

procedure TProgSettDlg.miImport86MgrClick(Sender: TObject);
begin
  with T86MgrImport.Create(true) do
    try
      edPath.Text := MachineRoot;
      ed86Box.Text := EmulatorPath;

      cbMinimizeOnStart.Checked := MinimizeOnStart;
      cbTrayBehavior.ItemIndex := TrayBehavior;
      spLaunchTimeout.Value := LaunchTimeout;

      edGlobalLog.Text := GlobalLogFile;
      cbLogging.ItemIndex := LoggingMode;
      cbLoggingChange(Self);

      mmManualOptions.Lines.Assign(DisplayValues);
      case DisplayMode of
        0: rbDefaultDisplay.Checked := true;
        1: rbCustomDisplay.Checked := true;
        2: rbManualOptions.Checked := true;
        3: rbNoDisplayOptions.Checked := true;
      end;
      UpdateApperance(Self);
    finally
      Free;
    end;
end;

procedure TProgSettDlg.miImportWinBoxClick(Sender: TObject);
begin
  with TWinBoxImport.Create(true) do
    try
      edPath.Text := MachineRoot;
      cbRepositories.Text := Repository;
      cbAutoUpdate.Checked := AutoUpdate;
      cbGetSource.Checked := GetSource;

      if FileExists(EmulatorPath) then
        ed86Box.Text := EmulatorPath;

      UpdateTools(Tools);

      mmManualOptions.Lines.Assign(DisplayValues);
      case DisplayMode of
        0: rbDefaultDisplay.Checked := true;
        1: rbCustomDisplay.Checked := true;
        2: rbManualOptions.Checked := true;
        3: rbNoDisplayOptions.Checked := true;
      end;
      UpdateApperance(Self);
    finally
      Free;
    end;
end;

procedure TProgSettDlg.UpdateApperance(Sender: TObject);
var
  I: integer;

  function ReadKey(const Name: string; const Default: integer): integer;
  var
    I: integer;
  begin
    if TryStrToInt(mmManualOptions.Lines.Values[Name], I) then
      Result := I
    else
      Result := Default
  end;

begin
  clbCustomOptions.Enabled := rbCustomDisplay.Checked;
  cbFullscreenSizing.Enabled := rbCustomDisplay.Checked;
  cbWindowSizing.Enabled := rbCustomDisplay.Checked;

  mmManualOptions.Enabled := rbManualOptions.Checked;
  btnManOptLoad.Enabled := rbManualOptions.Checked;

  if rbDefaultDisplay.Checked then
    mmManualOptions.Lines.Assign(Defaults.DisplayValues);

  //> L�sd mi�rt: uConfig.pas, 54. sor
  I := mmManualOptions.Lines.IndexOfName('window_remember');
  if I <> -1 then
    mmManualOptions.Lines.Delete(I);
  //> ---

  for I := 0 to High(CheckListKeys) do
    with CheckListKeys[I] do
      clbCustomOptions.Checked[I] := ReadKey(Name, Default) <> 0;

  case ReadKey(ComboBoxKeys[0].Name, ComboBoxKeys[0].Default) of
    1: cbWindowSizing.ItemIndex := 1;
    2: cbWindowSizing.ItemIndex := 2;
    else case ReadKey(ComboBoxKeys[1].Name, ComboBoxKeys[1].Default) of
           0: cbWindowSizing.ItemIndex := 3;
           1: cbWindowSizing.ItemIndex := 0;
           2: cbWindowSizing.ItemIndex := 4;
           3: cbWindowSizing.ItemIndex := 5;
           else
             cbWindowSizing.ItemIndex := -1;
         end;
  end;

  I := ReadKey(ComboBoxKeys[2].Name, ComboBoxKeys[2].Default);
  if (I < cbFullscreenSizing.Items.Count) and (I >= 0) then
    cbFullscreenSizing.ItemIndex := I
  else
    cbFullscreenSizing.ItemIndex := -1;
end;

procedure TProgSettDlg.UpdateTools(Tools: TStrings);
var
  I: integer;
begin
  edToolName.Text := '';
  mmToolPath.Text := '';

  lvTools.Clear;
  for I := 0 to Tools.Count - 1 do
    with lvTools.Items.Add do begin
      Caption := Tools.Names[I];
      SubItems.Add(Tools.ValueFromIndex[I]);
    end;
  lvTools.ItemIndex := -1;
end;

procedure TProgSettDlg.Reload(Sender: TObject);
begin
  miImportWinBox.Enabled := TWinBoxImport.IsExists;
  miImport86Mgr.Enabled := T86MgrImport.IsExists;
  btnImport.Enabled := miImportWinBox.Enabled or miImport86Mgr.Enabled;

  with Config do begin
    edPath.Text := MachineRoot;
    ed86Box.Text := EmulatorPath;
    edCustomTemplates.Text := CustomTemplates;
    edGlobalLog.Text := GlobalLogFile;

    cbEraseProt.ItemIndex := EraseProtLvl;
    cbTrayBehavior.ItemIndex := TrayBehavior;
    cbWinBoxUpdate.ItemIndex := WinBoxUpdate;

    cbLogging.ItemIndex := LoggingMode;
    cbLoggingChange(Self);

    cbRepositories.Text := Repository;

    cbMinimizeOnStart.Checked := MinimizeOnStart;
    cbAutoUpdate.Checked := AutoUpdate;
    cbGetSource.Checked := GetSource;
    cbDebugMode.Checked := DebugMode;
    cbCrashDump.Checked := CrashDump;

    spLaunchTimeout.Value := LaunchTimeout;

    UpdateTools(Tools);

    mmManualOptions.Lines.Assign(DisplayValues);
    case DisplayMode of
      0: rbDefaultDisplay.Checked := true;
      1: rbCustomDisplay.Checked := true;
      2: rbManualOptions.Checked := true;
      3: rbNoDisplayOptions.Checked := true;
    end;
  end;
end;

procedure TProgSettDlg.GetTranslation(Language: TLanguage);
begin
  with Language do begin
    GetTranslation(LangName, Self);
    GetTranslation(pmImport.Name, pmImport.Items);

    GetTranslation(LangName + StrLvToolsColumn0, lvTools.Column[0].Caption);
    GetTranslation(LangName + StrLvToolsColumn1, lvTools.Column[1].Caption);

    GetTranslation(OpenDlg86Box, od86Box.Filter);
    GetTranslation(OpenDlgExecutables, odTools.Filter);
    GetTranslation(OpenDlgLogFiles, odLogFiles.Filter);
  end;
end;

procedure TProgSettDlg.miDefaultsClick(Sender: TObject);
var
  Temp: TConfiguration;
begin
  Temp := Config;
  Config := Defaults;
  Reload(Self);
  Config := Temp;
end;

procedure TProgSettDlg.Translate;
begin
  with Language do begin
    Translate(LangName, Self);
    Translate(pmImport.Name, pmImport.Items);

    lvTools.Column[0].Caption := _T(LangName + StrLvToolsColumn0);
    lvTools.Column[1].Caption := _T(LangName + StrLvToolsColumn1);

    od86Box.Filter := _T(OpenDlg86Box);
    odTools.Filter := _T(OpenDlgExecutables);
    odLogFiles.Filter := _T(OpenDlgLogFiles);
    odConfigFiles.Filter := _T(OpenDlgConfig);

    Caption := ReadString(LangName, LangName, Caption);
  end;
end;

end.
