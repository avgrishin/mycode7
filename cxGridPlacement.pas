unit cxGridPlacement;

interface

uses stdctrls, windows, classes, Sysutils, Controls, comctrls, Forms, cxGridDBTableView;

type
  TAvcxGridPlacement = class(TComponent)
  private
    FActive: Boolean;
    FRestored: Boolean;
    FSaved: Boolean;
    FDestroying: Boolean;
    FcxGridDBTableView: TcxGridDBTableView;
    FTag: Integer;
    FSaveFormShow: TNotifyEvent;
    FSaveFormDestroy: TNotifyEvent;
    FSaveFormCloseQuery: TCloseQueryEvent;
    procedure SetEvents;
    procedure RestoreEvents;
    procedure FormShow(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormDestroy(Sender: TObject);
    function GetForm: TForm;
  protected
    procedure Loaded; override;
    property Form: TForm read GetForm;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure SaveGridPlacement;
    procedure RestoreGridPlacement;
  published
    property Active: Boolean read FActive write FActive default True;
    property GridDBTableView: TcxGridDBTableView read FcxGridDBTableView write FcxGridDBTableView;
    property Tag: Integer read FTag write FTag default 0;
  end;

  procedure Register;

implementation

uses FIBQuery, pFIBQuery, FIBDataset, db, cxGridCustomView, cxGrid;

procedure Register;
begin
	RegisterComponents('Data Controls', [TAvcxGridPlacement]);
end;

constructor TAvcxGridPlacement.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FActive := True;
end;

destructor TAvcxGridPlacement.Destroy;
begin
  if not (csDesigning in ComponentState) then
  begin
    RestoreEvents;
  end;
  inherited Destroy;
end;

procedure TAvcxGridPlacement.Loaded;
var
  Loading: Boolean;
begin
  Loading := csLoading in ComponentState;
  inherited Loaded;
  if not (csDesigning in ComponentState) then
  begin
    if Loading then SetEvents;
  end;
end;

function TAvcxGridPlacement.GetForm: TForm;
begin
  if Owner is TCustomForm then Result := TForm(Owner as TCustomForm)
  else Result := nil;
end;

procedure TAvcxGridPlacement.SetEvents;
begin
  if Owner is TCustomForm then
  begin
    with TForm(Form) do
    begin
      FSaveFormShow := OnShow;
      OnShow := FormShow;
      FSaveFormCloseQuery := OnCloseQuery;
      OnCloseQuery := FormCloseQuery;
      FSaveFormDestroy := OnDestroy;
      OnDestroy := FormDestroy;
    end;
  end;
end;

procedure TAvcxGridPlacement.RestoreEvents;
begin
  if (Owner <> nil) and (Owner is TCustomForm) then
    with TForm(Form) do
    begin
      OnShow := FSaveFormShow;
      OnCloseQuery := FSaveFormCloseQuery;
      OnDestroy := FSaveFormDestroy;
    end;
end;

procedure TAvcxGridPlacement.FormShow(Sender: TObject);
begin
  if Active then
    try
      RestoreGridPlacement;
    except
      Application.HandleException(Self);
    end;
  if Assigned(FSaveFormShow) then FSaveFormShow(Sender);
end;

procedure TAvcxGridPlacement.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if Assigned(FSaveFormCloseQuery) then
    FSaveFormCloseQuery(Sender, CanClose);
  if CanClose and Active and (Owner is TCustomForm) and (Form.Handle <> 0) then
    try
      SaveGridPlacement;
    except
      Application.HandleException(Self);
    end;
end;

procedure TAvcxGridPlacement.FormDestroy(Sender: TObject);
begin
  if Active and not FSaved then begin
    FDestroying := True;
    try
      SaveGridPlacement;
    except
      Application.HandleException(Self);
    end;
    FDestroying := False;
  end;
  if Assigned(FSaveFormDestroy) then FSaveFormDestroy(Sender);
end;

procedure TAvcxGridPlacement.SaveGridPlacement;
var
  FQuery: TpFIBQuery;
  Write_Str: TMemoryStream;
  Size: Integer;
  F: Array [0..4] of Integer;
begin
  if FRestored or not Active then
  begin
    Write_Str := TMemoryStream.Create;
    FQuery := TpFIBQuery.Create(Self);
    FQuery.Database := (FcxGridDBTableView.DataController.DataSource.DataSet as TFIBDataset).Database;
    FQuery.Transaction := (FcxGridDBTableView.DataController.DataSource.DataSet as TFIBDataset).UpdateTransaction;
    if not FQuery.Transaction.InTransaction then FQuery.Transaction.StartTransaction;
    try
      FQuery.SQL.Text := 'execute procedure PMTWP101BLOBSUPD(:concept, :user_id, :val)';
      FQuery.ParamByName('concept').AsInteger := 20000000+Tag*100000+1000;
      FQuery.ParamByName('user_id').AsInteger := FQuery.Database.Tag;
      FcxGridDBTableView.StoreToStream(Write_Str,[gsoUseFilter]);
      FQuery.ParamByName('VAL').LoadFromStream(Write_Str);
      FQuery.ExecProc;
      Write_Str.Clear;

      FQuery.ParamByName('concept').AsInteger := 20000000+Tag*100000+1000+1;
      Size := (FcxGridDBTableView.Control as TcxCustomGrid).Font.Size;
      Write_Str.Write(Size, sizeof(Size));
      FQuery.ParamByName('VAL').LoadFromStream(Write_Str);
      FQuery.ExecProc;
      Write_Str.Clear;

      FQuery.ParamByName('concept').AsInteger := 20000000+Tag*100000;
      F[0] := Form.Left;
      F[1] := Form.Top;
      F[2] := Form.Width;
      F[3] := Form.Height;
      Case Form.WindowState of
        wsNormal: F[4] := 0;
        wsMinimized: F[4] := 1;
        wsMaximized: F[4] := 2;
      end;

      Write_Str.Write(F[0], SizeOf(F));
      FQuery.ParamByName('VAL').LoadFromStream(Write_Str);
      FQuery.ExecProc;
      Write_Str.Clear;
      FQuery.Transaction.CommitRetaining;
      FSaved := True;
    finally
      Write_Str.Free;
    end;
  end;
end;

procedure TAvcxGridPlacement.RestoreGridPlacement;
var
  Read_Str: TMemoryStream;
  FQuery: TpFIBQuery;
  Size: Integer;
  F: array [0..4] of Integer;
begin
  FSaved := False;
  Read_Str := TMemoryStream.Create;
  FQuery := TpFIBQuery.Create(Self);
  FQuery.Database := (FcxGridDBTableView.DataController.DataSource.DataSet as TFIBDataset).Database;
  FQuery.Transaction := (FcxGridDBTableView.DataController.DataSource.DataSet as TFIBDataset).UpdateTransaction;
  if not FQuery.Transaction.InTransaction then FQuery.Transaction.StartTransaction;
  try
      FQuery.SQL.Text := 'select * from p101_blobs where concept = :concept and link = :user_id';
    FQuery.ParamByName('concept').AsInteger := 20000000+Tag*100000+1000;
    FQuery.ParamByName('user_id').AsInteger := FQuery.Database.Tag;
    FQuery.Close;
    FQuery.ExecQuery;
    if not FQuery.Eof then
    begin
      FQuery.FieldByName('VAL').SaveToStream(Read_Str);
      Read_Str.Seek(0, soFromBeginning);
      FcxGridDBTableView.RestoreFromStream(Read_Str, False, False, [gsoUseFilter]);
      Read_Str.Clear;
    end;
    FQuery.ParamByName('concept').AsInteger := 20000000+Tag*100000+1000+1;
    FQuery.Close;
    FQuery.ExecQuery;
    if not FQuery.Eof then
    begin
      FQuery.FieldByName('VAL').SaveToStream(Read_Str);
      Read_Str.Seek(0, soFromBeginning);
      Read_Str.Read(Size, sizeof(Size));
      (FcxGridDBTableView.Control as TcxCustomGrid).Font.Size := Size;
      Read_Str.Clear;
    end;
    FQuery.ParamByName('concept').AsInteger := 20000000+Tag*100000;
    FQuery.Close;
    FQuery.ExecQuery;
    if not FQuery.Eof then
    begin
      FQuery.FieldByName('VAL').SaveToStream(Read_Str);
      Read_Str.Seek(0, soFromBeginning);
      Read_Str.Read(F[0],sizeof(F));
      Form.WindowState := wsNormal;
      Form.Left := F[0];
      Form.Top := F[1];
      Form.Width := F[2];
      Form.Height := F[3];
      Case F[4] of
        0: Form.WindowState := wsNormal;
        1: Form.WindowState := wsMinimized;
        2: Form.WindowState := wsMaximized;
      end;
    end;
    FQuery.Close;
    FRestored := True;
  finally
    FQuery.Free;
    Read_Str.Free;
  end;
end;

end.
