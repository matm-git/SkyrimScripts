# Konfiguration
$suffixes = @("SPR", "SUM", "AUT", "WIN")
#$suffixes = @("SPR")
[bool]$overwrite = $true
$toolPath = ".\PBRNifpatcher.exe"
$outputDir = "pbr_output\meshes"

# PBRNifpatcher Batch Script - Funktionale Version
# Führt PBRNifpatcher.exe mehrmals aus und erstellt Kopien mit verschiedenen Suffixen

# Funktion: PBRNifpatcher.exe ausführen
function Start-PBRNifpatcher {
    param(
        [string]$ToolPath 
    )
    
    Write-Host "Führe PBRNifpatcher.exe aus..."
    
    try {
        # Automatische Eingabe: Sendet Enter-Taste an das Tool
        "" | & $ToolPath
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "PBRNifpatcher.exe hat einen Fehler zurückgegeben (Exit Code: $LASTEXITCODE)"
            return $false
        }
        return $true
    }
    catch {
        Write-Error "Fehler beim Ausführen von PBRNifpatcher.exe: $_"
        return $false
    }
}

# Funktion: NIF-Dateien kopieren mit Suffix
function Copy-NifFilesWithSuffix {
    param(
        [string]$OutputDir,
        [string]$Suffix,
        [string]$Suffixes,
        [bool]$overwrite = $false
    )
    
    Write-Host "Suche rekursiv nach .nif Dateien in $OutputDir..."
    
    # Prüfe ob Output-Verzeichnis existiert
    if (-not (Test-Path $OutputDir)) {
        Write-Warning "Verzeichnis $OutputDir existiert nicht"
        return @()
    }
    
    # Rekursive Suche nach .nif Dateien
    $nifFiles = Get-ChildItem -Path $OutputDir -Filter "*.nif" -File -Recurse |
    Where-Object { $_.Name -notmatch $Suffixes }
    
    if ($nifFiles.Count -eq 0) {
        Write-Warning "Keine .nif Dateien in $OutputDir (rekursiv) gefunden"
        return @()
    }
    
    Write-Host "Gefunden: $($nifFiles.Count) .nif Dateien (rekursiv)"
    $copiedFiles = @()
    
    foreach ($file in $nifFiles) {
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
        $newFileName = "${baseName}${Suffix}.nif"
        $newFilePath = Join-Path $file.Directory $newFileName
        
        # Kopie nur erstellen wenn sie noch nicht existiert
        if (-not (Test-Path $newFilePath) -or $overwrite) {
            try {
                Copy-Item $file.FullName $newFilePath 
                $relativePath = $file.FullName.Replace("$OutputDir\", "")
                Write-Host "  Erstellt: $relativePath -> ${baseName}${Suffix}.nif" -ForegroundColor Green
                $copiedFiles += $newFileName
            }
            catch {
                Write-Warning "  Fehler beim Kopieren von $($file.Name) zu $newFileName : $_"
            }
        }
        else {
            $relativePath = $file.FullName.Replace("$OutputDir\", "")
            Write-Host "  Übersprungen (existiert bereits): $relativePath -> ${baseName}${Suffix}.nif" -ForegroundColor Cyan
        }
    }
    
    return $nifFiles
}

# Funktion: Ursprüngliche NIF-Dateien löschen
function Remove-OriginalNifFiles {
    param(
        [System.IO.FileInfo[]]$FilesToDelete
    )
    
    if ($FilesToDelete.Count -eq 0) {
        Write-Host "Keine Dateien zum Löschen vorhanden"
        return
    }
    
    Write-Host "Lösche ursprüngliche .nif Dateien..."
    
    foreach ($file in $FilesToDelete) {
        try {
            Remove-Item $file.FullName -Force
            #Write-Host "  Gelöscht: $($file.Name)" -ForegroundColor Red
        }
        catch {
            Write-Warning "  Fehler beim Löschen von $($file.Name): $_"
        }
    }
}




# Funktion: Eingabeparameter validieren
function Test-Prerequisites {
    param(
        [string]$ToolPath
    )
    
    if (-not (Test-Path $ToolPath)) {
        Write-Error "PBRNifpatcher.exe wurde nicht gefunden: $ToolPath"
        return $false
    }
    
    return $true
}

function Create-Json {
    param(
        [string]$Suffix,
        [bool]$overwrite = $false
    )    
    # Set folder path
    # Initialize list for JSON output
    $jsonList = @()
    $currentPath = Get-Location
    $outputFilePath = "$currentPath\PBRNifPatcher\CreateSeasonalVariants.json"

    # Check if the folder exists
    if (-Not (Test-Path -Path "$currentPath\PBRNifPatcher\")) {
        # Create the folder
        New-Item -ItemType Directory -Path "$currentPath\PBRNifPatcher" | Out-Null
    } 


    # Find all files with the name pattern *_n.dds
    #Get-ChildItem -Path $folderPath -Filter "*_n.dds" | ForEach-Object {
    Get-ChildItem -Filter "*_n.dds" -Recurse | ForEach-Object {       
        $relativePath = $_.FullName.Replace($currentPath, "").TrimStart("\")
        #Write-Host "Found texture $relativePath as base"
        $texturePath = $relativePath 
        $texturePath = $texturePath -replace '_n.dds$' -replace '^textures\\', '' -replace '^pbr\\', '' -replace '\\', '\'
        $slot1 = $relativePath -replace '_n.dds$'  
        $slot1 = $slot1 + $Suffix + ".dds"
        # Create JSON object and add it to the list
        $jsonList += @{
            texture = $texturePath
            subsurface = $false
            slot1 = $slot1
        }
        

        # Copy diffuse texture to a seasonal variant
        $source = $relativePath -replace '_n.dds$' -replace '\\', '\'
        $source = $source + '.dds'
        $destination = $slot1 -replace '\\', '\'
        if (!(Test-Path $destination) -or $overwrite)    {
            Write-Host "Copying $source to $destination"
            Copy-Item -Path $source  -Destination $destination
        } else {
            Write-Host "Skipping $source to $destination as it already exists"
        }
    }


    # Output entire list to a JSON file
    #$jsonList | ConvertTo-Json -Compress | Out-File -FilePath "PBR.json" -Encoding UTF8


    # Create the file and write the first entry
    $_firstEntry = $jsonList[0] | ConvertTo-Json -Compress
    Set-Content -LiteralPath "$outputFilePath" -Value "[ `n"


    if (($jsonList.Count) -lt 1) {
        Write-Host "Found " + ($jsonList.Count) + " matching _n textures, hence cannot produce a valid JSON file. Aborting."
        return $false
    }
    
    # For the remaining entries, use line break and then append
    for ($i = 0; $i -lt $jsonList.Count; $i++) {
        Add-Content -LiteralPath $outputFilePath -Value ($jsonList[$i] | ConvertTo-Json -Compress) 
        if ($i -lt $jsonList.Count -1 ) { Add-Content -LiteralPath $outputFilePath -Value "," }
        #Add-Content -LiteralPath $outputFilePath -Value "`n"  # Line break

    }
    Add-Content -LiteralPath "$outputFilePath" -Value "] "
    Write-Host "Created json $outputFilePath"
    # Output to console for verification
    $jsonList | ConvertTo-Json -Compress
    
}

# =============================================================================
# HAUPT-SCRIPT
# =============================================================================


Write-Host "Starte Batch-Verarbeitung mit PBRNifpatcher. " -ForegroundColor Green
Write-Host "Überschreibe bestehende Outputs: $overwrite"

# Hauptschleife durch alle Suffixe
$successfulSuffixes = @()
foreach ($suffix in $suffixes) {   
    Write-Host "`nVerarbeite Suffix: $Suffix" -ForegroundColor Yellow
    
    # Schritt 0: JSON generieren
    $jsonSuccess = Create-Json -Suffix $Suffix -overwrite $overwrite
    if (-not $jsonSuccess) {
        Write-Warning "Überspringe Suffix $Suffix aufgrund von Problemen bei der JSON-Erstellung"
        return $false
    }    

    # Schritt 1: PFRNifpatcher ausführen
    $toolSuccess = Start-PBRNifpatcher -ToolPath $ToolPath
    if (-not $toolSuccess) {
        Write-Warning "Überspringe Suffix $Suffix aufgrund von Fehlern bei Ausführung von PBRNifpatcher"
        return $false
    }
    
    # Schritt 2: NIF-Dateien kopieren
    $originalFiles = Copy-NifFilesWithSuffix -OutputDir $OutputDir -Suffix $Suffix -overwrite $overwrite -Suffixes ($suffixes -join "|")
    
    # Schritt 3: Ursprüngliche Dateien löschen
    Remove-OriginalNifFiles -FilesToDelete $originalFiles
    
    Write-Host "Verarbeitung für Suffix '$Suffix' abgeschlossen." -ForegroundColor Green
    $successfulSuffixes += $Suffix


}

# Abschließende Zusammenfassung
Write-Host "Verarbeitete Suffixe: $($successfulSuffixes -join ', ')"
