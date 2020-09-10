unit PmDBGrid;

interface

uses
  SysUtils, Classes, Controls, Grids, DBGrids;

type
  TPmDBGrid = class(TDBGrid)
  private
    { Private declarations }
  protected
    function HighlightCell(DataCol, DataRow: Integer; const Value: string;
      AState: TGridDrawState): Boolean; override;
    procedure Initialize;
  public
    { Public declarations }
  published
    { Published declarations }
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Data Controls', [TPmDBGrid]);
end;

function TPmDBGrid.HighlightCell(DataCol, DataRow: Integer; const Value: string;
      AState: TGridDrawState): Boolean;
begin
    Result := (gdSelected in AState)
      and ((dgAlwaysShowSelection in Options) or Focused)
      and ((UpdateLock = 0) {or (dgRowSelect in Options)});
//  Result := inherited HighlightCell(DataCol, DataRow, Value, AState) or ((gdSelected in AState) and (UpdateLock = 0));
end;

procedure TPmDBGrid.Initialize;
begin
  inherited Options := [goRowSelect];
end;

end.
