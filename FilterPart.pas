unit FilterPart;

interface

uses stdctrls, windows, classes, Sysutils, Controls, comctrls, Forms, extctrls, db, dbgrids, buttons, graphics, Placemnt, DBGridEh;

type
{
	TAvGrid = class(TDBGrid)
	private
  	FIniLink: TIniLink;
		FLabel: TLabel;
		FEdit: TEdit;
		FButton: TBitBtn;
		FPanel: TPanel;
		FShift: TShiftState;
		FStatusBar: TStatusBar;
    function GetStorage: TFormPlacement;
    procedure SetStorage(Value: TFormPlacement);
    procedure IniSave(Sender: TObject);
    procedure IniLoad(Sender: TObject);
    procedure InternalSaveLayout(IniFile: TObject; const Section: string);
    procedure InternalRestoreLayout(IniFile: TObject; const Section: string);
    procedure SaveColumnsLayout(IniFile: TObject; const Section: string);
    procedure RestoreColumnsLayout(IniFile: TObject; const Section: string);
		procedure OnFButtonClick(Sender: TObject);
		procedure OnFPanelExit(Sender: TObject);
		procedure SetStatusBar(Value: TStatusBar);
	protected
		procedure TitleClick(Column: TColumn); override;
		procedure KeyUp(var Key: Word; Shift: TShiftState); override;
		procedure MouseUp(Button: TMouseButton; Shift: TShiftState;
			X, Y: Integer); override;
		procedure SetParent(AParent: TWinControl); override;
	public
		constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
	published
		property StatusBar: TStatusBar read FStatusBar write SetStatusBar;
    property IniStorage: TFormPlacement read GetStorage write SetStorage;
	end;
}
  TAvEhGridOption = (aegFilter);
  TAvEhGridOptions = set of TAvEhGridOption;

	TAvEhGrid = class(TDBGridEh)
	private
  	FOptionsAv: TAvEhGridOptions;
  	FIniLink: TIniLink;
		FLabel: TLabel;
		FEdit: TEdit;
		FButton: TBitBtn;
		FPanel: TPanel;
		FShift: TShiftState;
		FStatusBar: TStatusBar;
    function GetStorage: TFormPlacement;
    procedure SetStorage(Value: TFormPlacement);
    procedure IniSave(Sender: TObject);
    procedure IniLoad(Sender: TObject);
    procedure InternalSaveLayout(IniFile: TObject; const Section: string);
    procedure InternalRestoreLayout(IniFile: TObject; const Section: string);
    procedure SaveColumnsLayout(IniFile: TObject; const Section: string);
    procedure RestoreColumnsLayout(IniFile: TObject; const Section: string);
		procedure OnFButtonClick(Sender: TObject);
		procedure OnFPanelKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
		procedure OnFPanelExit(Sender: TObject);
		procedure SetStatusBar(Value: TStatusBar);
    procedure SetOptionsAv(const Value: TAvEhGridOptions);
	protected
		procedure TitleClick(Column: TColumnEh); override;
		procedure KeyUp(var Key: Word; Shift: TShiftState); override;
		procedure MouseUp(Button: TMouseButton; Shift: TShiftState;
			X, Y: Integer); override;
		procedure SetParent(AParent: TWinControl); override;
	public
		constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    //procedure DefaultApplySorting; override;
	published
		property StatusBar: TStatusBar read FStatusBar write SetStatusBar;
    property IniStorage: TFormPlacement read GetStorage write SetStorage;
    property OptionsAv: TAvEhGridOptions read FOptionsAv write SetOptionsAv default [];
	end;

procedure Register;

function FilterPart1(s:string; FType:TFieldType; c: string):string;

implementation

uses ADOdb, VCLUtils, DbConsts, Dialogs, DbUtils, AppUtils, RxStrUtils;

procedure Register;
begin
//	RegisterComponents('Data Controls', [TAvGrid]);
	RegisterComponents('Data Controls', [TAvEhGrid]);
end;

function FilterPart1(s:string; FType:TFieldType; c: string):string;
var
	sgn: string;
begin
	if s = '' then exit;
	case s[1] of
		'>':
		begin
			Delete(s,1,1);
			if (s<>'')and(s[1]='=') then
			begin
				sgn:='>=';
				Delete(s,1,1);
			end
			else
				sgn:='>';
		end;
		'<':
		begin
			Delete(s,1,1);
			if (s<>'')and(s[1] in ['=','>']) then
			begin
				sgn := '<'+s[1];
				Delete(s,1,1);
			end
			else
				sgn := '<';
		end;
		'=':
		begin
			sgn:='=';
			Delete(s,1,1);
		end;
		else
		begin
			if FType in [ftString,ftWideString] then
				sgn := ' LIKE '
			else
				sgn := '=';
		end;
	end;
	if s <> '' then
	begin
		if (s[1] <> '''') and (FType in [ftString,ftWideString,ftDate, ftTime, ftDateTime]) then
		begin
			if (sgn = ' LIKE ') and (Pos(c, s) = 0) then
				s:=c+s+c;
			s := ''''+s+'''';
		end;
		Result := sgn+s;
	end
	else
		Result := '';
end;
{
constructor TAvGrid.Create(AOwner: TComponent);
begin
	inherited;
	FPanel := TPanel.Create(Self);
	FPanel.Visible := False;
	FPanel.Height := 33;
	FPanel.Width := 0;
	FPanel.OnExit := OnFPanelExit;
	FLabel := TLabel.Create(Self);
	FLabel.Parent := FPanel;
	FLabel.Top := 10;
	FLabel.Left := 8;
	FEdit := TEdit.Create(Self);
	FEdit.Parent := FPanel;
	FEdit.Top := 8;
	FEdit.Width := 129;
	FButton := TBitBtn.Create(Self);
	FButton.Parent := FPanel;
	FButton.OnClick := OnFButtonClick;
	FButton.Top := 8;
	FButton.Width := 22;
	FButton.Height := 22;
	FButton.Glyph.Handle := LoadBitmap(hInstance, 'FILTER');
  FIniLink := TIniLink.Create;
  FIniLink.OnSave := IniSave;
  FIniLink.OnLoad := IniLoad;
end;

destructor TAvGrid.Destroy;
begin
	FIniLink.Free;
	inherited Destroy;
end;

procedure TAvGrid.OnFPanelExit(Sender: TObject);
begin
	FPanel.Visible := False;
	SetFocus;
end;

procedure TAvGrid.SetParent(AParent: TWinControl);
begin
	inherited;
	if Assigned(AParent) then
		FPanel.Parent := AParent;
end;

procedure TAvGrid.MouseUp(Button: TMouseButton; Shift: TShiftState;
	X, Y: Integer);
begin
	FShift := Shift;
	if (dgMultiSelect in Options) and Assigned(FStatusBar) and (FStatusBar.Panels.Count > 2) then
		FStatusBar.Panels[0].Text := 'Выделено '+IntToStr(SelectedRows.Count)+' строк';
	inherited;
end;

procedure TAvGrid.KeyUp(var Key: Word; Shift: TShiftState);
begin
	if (dgMultiSelect in Options) and Assigned(FStatusBar) and (FStatusBar.Panels.Count > 2) then
		FStatusBar.Panels[0].Text := 'Выделено '+IntToStr(SelectedRows.Count)+' строк';
	inherited;
end;

procedure TAvGrid.OnFButtonClick(Sender: TObject);
var
	s: string;
	sAnd: string;
	DataSet: TCustomADODataSet;
begin
	DataSet := DataSource.DataSet as TCustomADODataSet;
	try
		s := FilterPart1(FEdit.Text, SelectedField.DataType, '*');
		if s <> '' then
		begin
			sAnd := '';
			if DataSet.Filter <> '' then
				sAnd := ' and ';
			try
				DataSet.Filter := DataSet.Filter+sAnd+SelectedField.FieldName+s;
				DataSet.Filtered := DataSet.Filter <> '';
				if Assigned(FStatusBar) and (FStatusBar.Panels.Count > 2) then
					FStatusBar.Panels[2].Text := DataSet.Filter;
			except
				on EDatabaseError do Application.MessageBox('Неверное выражение фильтра', PChar(Caption),MB_ICONERROR+MB_OK);
			end;
		end;
	finally
		FPanel.Visible := False;
		SetFocus;
	end;
end;

procedure TAvGrid.TitleClick(Column: TColumn);
var
	mc: TColumn;
	rect: TRect;
	ds: TCustomADODataSet;
	i: Integer;
	z: string;
begin
	inherited;
	if not Assigned(DataSource) or  not Assigned(DataSource.DataSet) then Exit;
	if not (ssCtrl in FShift) then
	begin
		ds := DataSource.DataSet as TCustomADODataSet;
		if ssShift in FShift then
		begin
			if not (fsBold in Column.Title.Font.Style) then
			begin
				z := '';
				if ds.Sort <> '' then z := ',';
				ds.Sort := ds.Sort+z+Column.Field.FieldName;
				Column.Title.Font.Style := Column.Title.Font.Style+[fsBold];
				if Assigned(FStatusBar) and (FStatusBar.Panels.Count > 1) then
					FStatusBar.Panels[1].Text := FStatusBar.Panels[1].Text+','+Column.Title.Caption;
			end
		end
		else
		begin
    	if Column.Field <> nil then
      begin
				ds.Sort := Column.Field.FieldName;
				for i := 0 to Columns.Count-1 do
					Columns[i].Title.Font.Style := Columns.Items[i].Title.Font.Style-[fsBold];
				Column.Title.Font.Style := Column.Title.Font.Style+[fsBold];
				if Assigned(FStatusBar) and (FStatusBar.Panels.Count > 1) then
					FStatusBar.Panels[1].Text := 'Сорт.: '+Column.Title.Caption;
      end;
		end;
	end
	else
	begin
		if (Column.Field.DataType = ftString) or (Column.Field.DataType = ftFloat)
			or (Column.Field.DataType = ftCurrency) then
		begin
			FLabel.Caption := Column.Title.Caption;
			rect := CalcTitleRect(Column,0,mc);
			FEdit.Left := FLabel.Left+FLabel.Width+10;
			FButton.Left := FEdit.Left+FEdit.Width+2;
			FPanel.Width := FButton.Left+FButton.Width+5;
			FPanel.Left := rect.Left;
			if FPanel.Left+FPanel.Width > Width then
				FPanel.Left := Width-FPanel.Width;
			if FPanel.Left < 0 then
				FPanel.Left := 0;
			FPanel.Top := 1+Top;
			FPanel.Visible := True;
			FPanel.BringToFront;
			FEdit.Text := Column.Field.AsString;
			SelectedField := Column.Field;
			FEdit.SetFocus;
		end;
	end;
end;

procedure TAvGrid.SetStatusBar(Value: TStatusBar);
begin
	FStatusBar := Value;
end;

procedure TAvGrid.IniSave(Sender: TObject);
var
  Section: string;
begin
  if (Name <> '') and (FIniLink.IniObject <> nil) then begin
    if StoreColumns then
      Section := FIniLink.RootSection + GetDefaultSection(Self)
    else
    if (FIniLink.RootSection <> '') and (DataSource <> nil) and
      (DataSource.DataSet <> nil) then
      Section := FIniLink.RootSection + DataSetSectionName(DataSource.DataSet)
    else Section := '';
    InternalSaveLayout(FIniLink.IniObject, Section);
  end;
end;

procedure TAvGrid.InternalSaveLayout(IniFile: TObject;
  const Section: string);
begin
  if (DataSource <> nil) and (DataSource.DataSet <> nil) then
    if StoreColumns then SaveColumnsLayout(IniFile, Section) else
    InternalSaveFields(DataSource.DataSet, IniFile, Section);
end;

procedure TAvGrid.IniLoad(Sender: TObject);
var
  Section: string;
begin
  if (Name <> '') and (FIniLink.IniObject <> nil) then begin
    if StoreColumns then
      Section := FIniLink.RootSection + GetDefaultSection(Self) else
    if (FIniLink.RootSection <> '') and (DataSource <> nil) and
      (DataSource.DataSet <> nil) then
      Section := FIniLink.RootSection + DataSetSectionName(DataSource.DataSet)
    else Section := '';
    InternalRestoreLayout(FIniLink.IniObject, Section);
  end;
end;

procedure TAvGrid.InternalRestoreLayout(IniFile: TObject;
  const Section: string);
begin
  if (DataSource <> nil) and (DataSource.DataSet <> nil) then begin
    HandleNeeded;
    BeginLayout;
    try
      if StoreColumns then RestoreColumnsLayout(IniFile, Section) else
      InternalRestoreFields(DataSource.DataSet, IniFile, Section, False);
    finally
      EndLayout;
    end;
  end;
end;

procedure TAvGrid.SaveColumnsLayout(IniFile: TObject;
  const Section: string);
var
  I: Integer;
  S: string;
begin
  if Section <> '' then S := Section
  else S := GetDefaultSection(Self);
  IniEraseSection(IniFile, S);
  with Columns do begin
    for I := 0 to Count - 1 do begin
      IniWriteString(IniFile, S, Format('%s.%s', [Name, Items[I].FieldName]),
        Format('%d,%d', [Items[I].Index, Items[I].Width]));
    end;
  end;
end;

procedure TAvGrid.RestoreColumnsLayout(IniFile: TObject;
  const Section: string);
type
  TColumnInfo = record
    Column: TColumn;
    EndIndex: Integer;
  end;
  PColumnArray = ^TColumnArray;
  TColumnArray = array[0..0] of TColumnInfo;
const
  Delims = [' ',','];
var
  I, J: Integer;
  SectionName, S: string;
  ColumnArray: PColumnArray;
begin
  if Section <> '' then SectionName := Section
  else SectionName := GetDefaultSection(Self);
  with Columns do begin
    ColumnArray := AllocMemo(Count * SizeOf(TColumnInfo));
    try
      for I := 0 to Count - 1 do begin
        S := IniReadString(IniFile, SectionName,
          Format('%s.%s', [Name, Items[I].FieldName]), '');
        ColumnArray^[I].Column := Items[I];
        ColumnArray^[I].EndIndex := Items[I].Index;
        if S <> '' then begin
          ColumnArray^[I].EndIndex := StrToIntDef(ExtractWord(1, S, Delims),
            ColumnArray^[I].EndIndex);
          Items[I].Width := StrToIntDef(ExtractWord(2, S, Delims),
            Items[I].Width);
        end;
      end;
      for I := 0 to Count - 1 do begin
        for J := 0 to Count - 1 do begin
          if ColumnArray^[J].EndIndex = I then begin
            ColumnArray^[J].Column.Index := ColumnArray^[J].EndIndex;
            Break;
          end;
        end;
      end;
    finally
      FreeMemo(Pointer(ColumnArray));
    end;
  end;
end;

function TAvGrid.GetStorage: TFormPlacement;
begin
  Result := FIniLink.Storage;
end;

procedure TAvGrid.SetStorage(Value: TFormPlacement);
begin
  FIniLink.Storage := Value;
end;
}
constructor TAvEhGrid.Create(AOwner: TComponent);
begin
	inherited;
	FPanel := TPanel.Create(Self);
	FPanel.Visible := False;
	FPanel.Height := 33;
	FPanel.Width := 0;
	FPanel.OnExit := OnFPanelExit;
	FLabel := TLabel.Create(Self);
	FLabel.Parent := FPanel;
	FLabel.Top := 10;
	FLabel.Left := 8;
	FEdit := TEdit.Create(Self);
	FEdit.Parent := FPanel;
	FEdit.Top := 8;
	FEdit.Width := 129;
	FButton := TBitBtn.Create(Self);
	FButton.Parent := FPanel;
	FButton.OnClick := OnFButtonClick;
	FButton.Top := 8;
	FButton.Width := 22;
	FButton.Height := 22;
	FButton.Glyph.Handle := LoadBitmap(hInstance, 'FILTER');
  FIniLink := TIniLink.Create;
  FIniLink.OnSave := IniSave;
  FIniLink.OnLoad := IniLoad;
  OptionsEh := [dghFixed3D, dghHighlightFocus, dghClearSelection, dghAutoSortMarking, dghMultiSortMarking, dghEnterAsTab, dghIncSearch, dghPreferIncSearch, dghRowHighlight, dghDblClickOptimizeColWidth];
  AllowedOperations := [];
  AllowedSelections := [gstRecordBookmarks,gstAll];
  RowHeight := 17;
  TitleHeight := 15;
  TitleLines := 0;
end;

destructor TAvEhGrid.Destroy;
begin
	FIniLink.Free;
	inherited Destroy;
end;

procedure TAvEhGrid.OnFPanelExit(Sender: TObject);
begin
	FPanel.Visible := False;
  FEdit.OnKeyDown := nil;
	SetFocus;
end;

procedure TAvEhGrid.SetParent(AParent: TWinControl);
begin
	inherited;
	if Assigned(AParent) then
		FPanel.Parent := AParent;
end;

procedure TAvEhGrid.MouseUp(Button: TMouseButton; Shift: TShiftState;
	X, Y: Integer);
begin
	FShift := Shift;
	if (dgMultiSelect in Options) and Assigned(FStatusBar) and (FStatusBar.Panels.Count > 2) then
		FStatusBar.Panels[0].Text := 'Выделено '+IntToStr(SelectedRows.Count)+' строк';
	inherited;
end;

procedure TAvEhGrid.KeyUp(var Key: Word; Shift: TShiftState);
begin
	if (dgMultiSelect in Options) and Assigned(FStatusBar) and (FStatusBar.Panels.Count > 2) then
		FStatusBar.Panels[0].Text := 'Выделено '+IntToStr(SelectedRows.Count)+' строк';
	inherited;
end;

procedure TAvEhGrid.OnFPanelKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = 13 then
  begin
    Key := 0;
    OnFButtonClick(Sender);
  end;
end;

procedure TAvEhGrid.OnFButtonClick(Sender: TObject);
var
	s: string;
	sAnd: string;
	DataSet: TDataSet; //TCustomADODataSet;
begin
	DataSet := DataSource.DataSet; // as TCustomADODataSet;
	try
    if (DataSource.DataSet is TCustomADODataSet) then
  		s := FilterPart1(FEdit.Text, SelectedField.DataType, '%')
    else
      s := FilterPart1(FEdit.Text, SelectedField.DataType, '*');
		if s <> '' then
		begin
			sAnd := '';
			if DataSet.Filter <> '' then
				sAnd := ' and ';
			try
				DataSet.Filter := DataSet.Filter+sAnd+SelectedField.FieldName+s;
				DataSet.Filtered := DataSet.Filter <> '';
				if Assigned(FStatusBar) and (FStatusBar.Panels.Count > 2) then
					FStatusBar.Panels[2].Text := DataSet.Filter;
			except
				on EDatabaseError do Application.MessageBox('Неверное выражение фильтра', PChar(Caption),MB_ICONERROR+MB_OK);
			end;
		end;
	finally
		FPanel.Visible := False;
    FEdit.OnKeyDown := nil;
		SetFocus;
	end;
end;

procedure TAvEhGrid.TitleClick(Column: TColumnEh);
var
	rect: TRect;
begin
	inherited;
  if not (aegFilter in FOptionsAv) then Exit;
	if not Assigned(DataSource) or  not Assigned(DataSource.DataSet) then Exit;
	if ssCtrl in FShift then
	begin
		if (Column.Field.DataType = ftSmallint)
      or (Column.Field.DataType = ftInteger)
      or (Column.Field.DataType = ftString)
      or (Column.Field.DataType = ftWideString)
      or (Column.Field.DataType = ftFloat)
			or (Column.Field.DataType = ftCurrency) then
		begin
			FLabel.Caption := Column.Title.Caption;
			rect := CellRect(Column.Index+1,0);
			FEdit.Left := FLabel.Left+FLabel.Width+10;
			FButton.Left := FEdit.Left+FEdit.Width+2;
			FPanel.Width := FButton.Left+FButton.Width+5;
			FPanel.Left := rect.Left;
			if FPanel.Left+FPanel.Width > Width then
				FPanel.Left := Width-FPanel.Width;
			if FPanel.Left < 0 then
				FPanel.Left := 0;
			FPanel.Top := 1+Top;
			FPanel.Visible := True;
			FPanel.BringToFront;
			FEdit.Text := Column.Field.AsString;
			SelectedField := Column.Field;
      FEdit.OnKeyDown := OnFPanelKeyDown;
			FEdit.SetFocus;
		end;
	end;
end;

procedure TAvEhGrid.SetStatusBar(Value: TStatusBar);
begin
	FStatusBar := Value;
end;

procedure TAvEhGrid.IniSave(Sender: TObject);
var
  Section: string;
begin
  if (Name <> '') and (FIniLink.IniObject <> nil) then begin
    if StoreColumns then
      Section := FIniLink.RootSection + GetDefaultSection(Self)
    else
    if (FIniLink.RootSection <> '') and (DataSource <> nil) and
      (DataSource.DataSet <> nil) then
      Section := FIniLink.RootSection + DataSetSectionName(DataSource.DataSet)
    else Section := '';
    InternalSaveLayout(FIniLink.IniObject, Section);
  end;
end;

procedure TAvEhGrid.InternalSaveLayout(IniFile: TObject;
  const Section: string);
begin
  if (DataSource <> nil) and (DataSource.DataSet <> nil) then
    if StoreColumns then SaveColumnsLayout(IniFile, Section) else
    InternalSaveFields(DataSource.DataSet, IniFile, Section);
end;

procedure TAvEhGrid.IniLoad(Sender: TObject);
var
  Section: string;
begin
  if (Name <> '') and (FIniLink.IniObject <> nil) then begin
    if StoreColumns then
      Section := FIniLink.RootSection + GetDefaultSection(Self) else
    if (FIniLink.RootSection <> '') and (DataSource <> nil) and
      (DataSource.DataSet <> nil) then
      Section := FIniLink.RootSection + DataSetSectionName(DataSource.DataSet)
    else Section := '';
    InternalRestoreLayout(FIniLink.IniObject, Section);
  end;
end;

procedure TAvEhGrid.InternalRestoreLayout(IniFile: TObject;
  const Section: string);
begin
  if (DataSource <> nil) and (DataSource.DataSet <> nil) then begin
    HandleNeeded;
    BeginLayout;
    try
      if StoreColumns then RestoreColumnsLayout(IniFile, Section) else
      InternalRestoreFields(DataSource.DataSet, IniFile, Section, False);
    finally
      EndLayout;
    end;
  end;
end;

procedure TAvEhGrid.SaveColumnsLayout(IniFile: TObject;
  const Section: string);
var
  I: Integer;
  S: string;
begin
  if Section <> '' then S := Section
  else S := GetDefaultSection(Self);
  IniEraseSection(IniFile, S);
  with Columns do begin
    for I := 0 to Count - 1 do begin
      IniWriteString(IniFile, S, Format('%s.%s', [Name, Items[I].FieldName]),
        Format('%d,%d', [Items[I].Index, Items[I].Width]));
    end;
  end;
end;

procedure TAvEhGrid.RestoreColumnsLayout(IniFile: TObject;
  const Section: string);
type
  TColumnInfo = record
    Column: TColumnEh;
    EndIndex: Integer;
  end;
  PColumnArray = ^TColumnArray;
  TColumnArray = array[0..0] of TColumnInfo;
const
  Delims = [' ',','];
var
  I, J: Integer;
  SectionName, S: string;
  ColumnArray: PColumnArray;
begin
  if Section <> '' then SectionName := Section
  else SectionName := GetDefaultSection(Self);
  with Columns do begin
    ColumnArray := AllocMemo(Count * SizeOf(TColumnInfo));
    try
      for I := 0 to Count - 1 do begin
        S := IniReadString(IniFile, SectionName,
          Format('%s.%s', [Name, Items[I].FieldName]), '');
        ColumnArray^[I].Column := Items[I];
        ColumnArray^[I].EndIndex := Items[I].Index;
        if S <> '' then begin
          ColumnArray^[I].EndIndex := StrToIntDef(ExtractWord(1, S, Delims),
            ColumnArray^[I].EndIndex);
          Items[I].Width := StrToIntDef(ExtractWord(2, S, Delims),
            Items[I].Width);
        end;
      end;
      for I := 0 to Count - 1 do begin
        for J := 0 to Count - 1 do begin
          if ColumnArray^[J].EndIndex = I then begin
            ColumnArray^[J].Column.Index := ColumnArray^[J].EndIndex;
            Break;
          end;
        end;
      end;
    finally
      FreeMemo(Pointer(ColumnArray));
    end;
  end;
end;

function TAvEhGrid.GetStorage: TFormPlacement;
begin
  Result := FIniLink.Storage;
end;

procedure TAvEhGrid.SetStorage(Value: TFormPlacement);
begin
  FIniLink.Storage := Value;
end;

procedure TAvEhGrid.SetOptionsAv(const Value: TAvEhGridOptions);
begin
  if (OptionsAv = Value) then Exit;
  FOptionsAv := Value;
  LayoutChanged;
end;
{
procedure TAvEhGrid.DefaultApplySorting;
var
	i: Integer;
	s: String;
  bm: TBookmark;
begin
	if not (DataSource.DataSet is TCustomADODataSet) then Exit;
	s := '';
	for i := 0 to SortMarkedColumns.Count-1 do
  begin
		if SortMarkedColumns[i].Title.SortMarker = smUpEh then
			s := s + SortMarkedColumns[i].FieldName + ' DESC , '
		else
			s := s + SortMarkedColumns[i].FieldName + ', ';
  end;
	if s <> '' then s := Copy(s,1,Length(s)-2);
  bm := DataSource.DataSet.GetBookmark;
	(DataSource.DataSet as TCustomADODataSet).Sort := s;
  DataSource.DataSet.GotoBookmark(bm);
  DataSource.DataSet.FreeBookmark(bm);
end;
}
end.
