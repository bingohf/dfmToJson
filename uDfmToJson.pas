unit uDfmToJson;

interface
uses
  System.SysUtils, System.Variants, System.Classes, Vcl.StdCtrls;



procedure ObjectTextToJson(const Input: TStream; sb:TStringBuilder);
implementation

procedure ObjectTextToJson(const Input: TStream; sb:TStringBuilder);
var
  Parser: TParser;
  FFmtSettings: TFormatSettings;
  TokenStr: String;

  function ConvertOrderModifier: Integer;
  begin
    Result := -1;
    if Parser.Token = '[' then
    begin
      Parser.NextToken;
      Parser.CheckToken(toInteger);
      Result := Parser.TokenInt;
      Parser.NextToken;
      Parser.CheckToken(']');
      Parser.NextToken;
    end;
  end;

  procedure ConvertHeader(IsInherited, IsInline: Boolean);
  var
    ClassName, ObjectName: string;
    Flags: TFilerFlags;
    Position: Integer;
  begin
    Parser.CheckToken(toSymbol);
    ClassName := Parser.TokenString;
    ObjectName := '';
    if Parser.NextToken = ':' then
    begin
      Parser.NextToken;
      Parser.CheckToken(toSymbol);
      ObjectName := ClassName;
      ClassName := Parser.TokenString;
      Parser.NextToken;
    end;
    Flags := [];
    Position := ConvertOrderModifier;
    if IsInherited then
      Include(Flags, ffInherited);
    if IsInline then
      Include(Flags, ffInline);
    if Position >= 0 then
      Include(Flags, ffChildPos);
    //Writer.WritePrefix(Flags, Position);
   // Writer.WriteUTF8Str('{');
    sb.append('{');
    sb.append('''className'':' + quotedStr(ClassName));
    sb.append(', ''name'':' + quotedStr(ObjectName));
  end;

  procedure ConvertProperty; forward;

  procedure ConvertValue;
  var
    Order: Integer;
    f1:Boolean;
    lastInt:integer;
    function CombineString: String;
    begin
      Result := Parser.TokenWideString;
      while Parser.NextToken = '+' do
      begin
        Parser.NextToken;
        if not (Parser.Token in [System.Classes.toString, toWString]) then
          Parser.CheckToken(System.Classes.toString);
        Result := Result + Parser.TokenWideString;
      end;
    end;

  begin
    if Parser.Token in [System.Classes.toString, toWString] then
      //Writer.WriteString(CombineString)
      sb.Append(QuotedStr(CombineString))
    else
    begin
      case Parser.Token of
        toSymbol:
          //Writer.WriteIdent(Parser.TokenComponentIdent);
          sb.Append(QuotedStr(Parser.TokenComponentIdent));
        toInteger:
          //Writer.WriteInteger(Parser.TokenInt);
          sb.Append(Parser.TokenInt);
        toFloat:
          begin
            case Parser.FloatType of
              's', 'S': sb.Append(VarTostr(Parser.TokenFloat));
              'c', 'C': sb.Append(VarToStr(Parser.TokenFloat / 10000));
              'd', 'D': sb.Append(VarToStr(Parser.TokenFloat));
            else
              sb.Append(VarToStr(Parser.TokenFloat));
            end;
          end;
        '[':
          begin
            Parser.NextToken;
            sb.Append('[');
            //Writer.WriteValue(vaSet);
            f1 := false;
            if Parser.Token <> ']' then
              while True do
              begin
                TokenStr := Parser.TokenString;
                case Parser.Token of
                  toInteger: begin end;
                   System.Classes.toString,toWString: TokenStr := AnsiString('#' + IntToStr(Ord(TokenStr[1])));
                else
                  Parser.CheckToken(toSymbol);
                end;
                //Writer.WriteUTF8Str(TokenStr);
                if f1 then
                  sb.Append(',');
                sb.Append(quotedStr(TokenStr));

                f1 := true;
                if Parser.NextToken = ']' then Break;
                Parser.CheckToken(',');
                Parser.NextToken;
              end;
            sb.Append(']');
          end;
        '(':
          begin
            Parser.NextToken;
            f1 := false;
            while Parser.Token <> ')' do begin
              if f1  then
              begin
                 sb.Remove(sb.Length -1 , 1);
                 sb.Append('\n');
              end;
              lastInt := sb.Length;

               ConvertValue;
               if f1 then
               begin
                  sb.Remove(lastInt, 1);
               end;

               f1 := true;
            end;
          end;
        '{':
          ;
          //Writer.WriteBinary(Parser.HexToBinary);
        '<':
          begin
            Parser.NextToken;
            //Writer.WriteValue(vaCollection);
            sb.Append('[');
            f1 := false;
            while Parser.Token <> '>' do
            begin
              Parser.CheckTokenSymbol('item');
              Parser.NextToken;
              Order := ConvertOrderModifier;
              //if Order <> -1 then Writer.WriteInteger(Order);
              if f1  then
                 sb.Append(',');
              sb.Append('{ ''item'':''item''');
              while not Parser.TokenSymbolIs('end') do
              begin
                ConvertProperty;
              end;
              sb.Append('}');
              Parser.NextToken;
              f1 := true;
            end;
            sb.Append(']');
          end;
      else
        Parser.Error('Invalid property value');
      end;
      Parser.NextToken;
    end;
  end;

  procedure ConvertProperty;
  var
    PropName: string;
  begin
    Parser.CheckToken(toSymbol);
    PropName := Parser.TokenString;
    Parser.NextToken;
    while Parser.Token = '.' do
    begin
      Parser.NextToken;
      Parser.CheckToken(toSymbol);
      PropName := PropName + '.' + Parser.TokenString;
      Parser.NextToken;
    end;
    sb.append(',' + quotedStr(PropName) + ':');
    Parser.CheckToken('=');
    Parser.NextToken;
    ConvertValue;
  end;

  procedure ConvertObject;
  var
    InheritedObject: Boolean;
    InlineObject: Boolean;
    f:Boolean;
  begin
    InheritedObject := False;
    InlineObject := False;
    if Parser.TokenSymbolIs('INHERITED') then
      InheritedObject := True
    else if Parser.TokenSymbolIs('INLINE') then
      InlineObject := True
    else
      Parser.CheckTokenSymbol('OBJECT');
    Parser.NextToken;
    ConvertHeader(InheritedObject, InlineObject);
    while not Parser.TokenSymbolIs('END') and
      not Parser.TokenSymbolIs('OBJECT') and
      not Parser.TokenSymbolIs('INHERITED') and
      not Parser.TokenSymbolIs('INLINE') do
      ConvertProperty;
    f := false;

    while not Parser.TokenSymbolIs('END') do begin
      if not F then
        sb.Append(',childrens:[');
       if f then
         sb.Append(',');
       ConvertObject;
       f := true;
    end;
    if f then
      sb.Append(']');
    Parser.NextToken;
    sb.Append('}')
  end;
begin
  { Initialize a new TFormatSettings block }
  FFmtSettings := FormatSettings;
  FFmtSettings.DecimalSeparator := '.';

  { Create the parser instance }
  Parser := TParser.Create(Input, FFmtSettings);
  try
    ConvertObject;
  finally
    Parser.Free;
  end;
end;




end.
