# dfmToJson
A pascal tool for Convering Delphi Dfm to Json.


Example:
```
unit Unit2;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TForm2 = class(TForm)
    Memo1: TMemo;
    Memo2: TMemo;
    DfmToJson: TButton;
    procedure DfmToJsonClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;

implementation

{$R *.dfm}

uses uDfmToJson;

procedure TForm2.DfmToJsonClick(Sender: TObject);
var
  MemStream:TMemoryStream;
  dfmText:String;
  sb:TStringBuilder;
  i:integer;
begin
  try
    MemStream := TMemoryStream.Create;
    dfmText := memo1.Text;
    for I := 1 to Length(dfmText) do
      MemStream.Write(dfmText[I] , 1);
    memStream.Position := 0;
    sb := TStringBuilder.Create;
    ObjectTextToJson(memStream, sb);
    memo2.Text := sb.ToString;
  finally
    memStream.Free;
    sb.Free;

  end;

end;

end.
```