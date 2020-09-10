unit Tabenter;

interface

uses

SysUtils, WinTypes, WinProcs, Messages, Classes,
Graphics, Controls, Forms, Dialogs, Buttons, StdCtrls, dbgrids;

type
	TkEnterAsTab = class(TSpeedButton)
private
	FEnterAsTab : boolean;
protected
	procedure CMDialogKey(var Message: TCMDialogKey);
	message CM_DIALOGKEY;
	procedure Paint; override;
public
	constructor Create( AOwner : TComponent );override;
published
	property EnterAsTab : boolean read FEnterAsTab write FEnterAsTab default True;
end;

procedure Register;

implementation

constructor TkEnterAsTab.Create( AOwner : TComponent );
begin
	inherited Create(AOwner);
	FEnterAsTab := True;
	if not (csDesigning in ComponentState) then begin
		Enabled := False;
		Visible := False;
	end
	else
		Caption := 'ET';
end;

procedure TkEnterAsTab.CMDialogKey(var Message: TCMDialogKey);
begin
	if GetParentForm(Self).ActiveControl is TButton then
		inherited
	else if (Message.CharCode = VK_RETURN) and (EnterAsTab) then
  begin
  	if not (GetParentForm(Self).ActiveControl is TDBGrid) then
    begin
			GetParentForm(Self).Perform(CM_DialogKey, VK_TAB, 0);
			//GetParentForm(Self).Perform(WM_NEXTDLGCTL, 0, 0);
			Message.Result := 1;
    end
    else
    begin
    	with TDBGrid(GetParentForm(Self).ActiveControl) do
      begin
      	if selectedindex < (fieldcount -1) then
        	selectedindex := selectedindex +1
        else
        	selectedindex := 0;
      end
    end
	end
	else
		inherited;
end;

procedure TkEnterAsTab.Paint;
begin
	if (csDesigning in ComponentState) then begin
		Width := 27;
		Height := 27;
	end;
	inherited Paint;
end;

procedure Register;
begin
	RegisterComponents('Samples', [TkEnterAsTab]);
end;

end.


