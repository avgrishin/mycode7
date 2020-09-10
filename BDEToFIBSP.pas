unit BDEToFIBSP;

interface

uses
  SysUtils, Classes;

type
  TBDEToFIBSP = class(TComponent)
  private
    FMappings: TStrings;
    procedure SetMappings(Value: TStrings);
  protected
    { Protected declarations }
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    { Public declarations }
  published
    property Mappings: TStrings read FMappings write SetMappings;
  end;

procedure Register;

implementation

constructor TBDEToFIBSP.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FMappings := TStringList.Create;
end;

destructor TBDEToFIBSP.Destroy;
begin
  FMappings.Free;
  inherited Destroy;
end;

procedure TBDEToFIBSP.SetMappings(Value: TStrings);
begin
  FMappings.Assign(Value);
end;

procedure Register;
begin
  RegisterComponents('Samples', [TBDEToFIBSP]);
end;

end.
