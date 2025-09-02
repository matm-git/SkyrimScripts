unit UserScript;

var
  targetFile, inputFile: IInterface;
  outFile: TextFile;

function Initialize: integer;
var
  i, j, recCount: Integer;
  srcRec, newRec, edidElem, targetRecord: IInterface;
  edid, suffix, newEdid: string;
  suffixes: array[0..3] of string;
  modelElem: IInterface;
  oldModelPath, newModelPath: string;  
begin
  Result := 0;

  // Zielplugin festlegen
  targetFile := FileByName('PBR Flora Overhaul Seasons.esp');
  if not Assigned(targetFile) then begin
    AddMessage('Zieldatei "PBR Flora Overhaul Seasons.esp" nicht geladen!');
    Result := 1;
    Exit;
  end;

  // Inputplugin festlegen 
  inputFile := FileByName('Records for Seasons conversion.esp');
  if not Assigned(inputFile) then begin
    AddMessage('Eingabedatei "Records for Seasons conversion.esp" nicht geladen!');
    Result := 1;
    Exit;
  end;


  // Suffixe definieren
  suffixes[0] := 'SPR';
  suffixes[1] := 'SUM';
  suffixes[2] := 'AUT';
  suffixes[3] := 'WIN';

  // Alle Records aus Input.esp durchgehen
  for i := 0 to Pred(RecordCount(inputFile)) do begin
    srcRec := RecordByIndex(inputFile, i);
    if not Assigned(srcRec) then Continue;

    edid := GetElementEditValues(srcRec, 'EDID');
    if edid = '' then
      edid := 'NoEditorID_' + IntToHex(FixedFormID(srcRec), 8);

     // Vier Kopien erzeugen, per Index statt "for..in"
    for j := Low(suffixes) to High(suffixes) do begin
      AddRequiredElementMasters(GetFile(srcRec), targetFile, false);
      newRec := wbCopyElementToFile(srcRec, targetFile, True, True);


      if not Assigned(newRec) then Continue;    
      newEdid := edid + suffixes[j];
      SetElementEditValues(newRec, 'EDID', newEdid);
      AddMessage(';' + edid + '|' + newEdid);

      // Modelpfad anpassen
      //modelElem := ElementBySignature(newRec, 'MODL');
      modelElem := ElementByPath(newRec, 'Model\MODL'); // Standardpfad
      if Assigned(modelElem) then begin
        oldModelPath := GetEditValue(modelElem);
        if oldModelPath <> '' then begin
          // Neuen Pfad erstellen - Suffix vor der Dateiendung einfügen
          if Pos('.nif', LowerCase(oldModelPath)) > 0 then begin
            newModelPath := StringReplace(oldModelPath, '.nif', suffixes[j] + '.nif', [rfIgnoreCase]);
          end else begin
            // Falls keine .nif Endung, Suffix am Ende anhängen
            newModelPath := oldModelPath + suffixes[j];
          end;
          
          SetEditValue(modelElem, newModelPath);
          //AddMessage('  Model: ' + oldModelPath + ' -> ' + newModelPath);
        end;
      end;


      // EDID setzen â€" nur wenn der Record-Typ EDID unterstÃ¼tzt
      edidElem := ElementByPath(newRec, 'EDID');
      if not Assigned(edidElem) then
        edidElem := Add(newRec, 'EDID', True);
      if Assigned(edidElem) then
        SetEditValue(edidElem, newEdid);

   
      AddMessage('0x' + Copy(IntToHex(FixedFormID(srcRec), 8),4,5) + '~Skyrim.esm|' +
                       '0x' + Copy(IntToHex(FixedFormID(newRec), 8),4,5) + 
                       '~PBR Flora Overhaul Seasons.esp');  
 
    end;
  end;


end;

end.