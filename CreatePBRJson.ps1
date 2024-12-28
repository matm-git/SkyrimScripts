# Set folder path
# Initialize list for JSON output
$jsonList = @()
$currentPath = Get-Location
$outputFilePath = "$currentPath\PBRNifPatcher\PBR.json"
Write-Host $outputFilePath

# Check if the folder exists
if (-Not (Test-Path -Path "$currentPath\PBRNifPatcher\")) {
    # Create the folder
    New-Item -ItemType Directory -Path "$currentPath\PBRNifPatcher" | Out-Null
} 


# Find all files with the name pattern *_n.dds
#Get-ChildItem -Path $folderPath -Filter "*_n.dds" | ForEach-Object {
Get-ChildItem -Filter "*_n.dds" -Recurse | ForEach-Object {
    # Extract original file name without _n.dds
    $fileName = $_.BaseName -replace '_n$',''
    
    $relativePath = $_.FullName.Replace($currentPath, "").TrimStart("\")
    Write-Host $relativePath
    $texturePath = $relativePath -replace '_n.dds$' -replace '^pbr\\', '' -replace '\\', '\'

    # Create JSON object and add it to the list
    $jsonList += @{
        texture = $texturePath
        emissive = $false
        parallax = $true
        subsurface_foliage = $false
        subsurface = $false
        specular_level = 0.04
        subsurface_color = @(1, 1, 1)
        roughness_scale = 1.0
        subsurface_opacity = 1
        displacement_scale = 1.0
    }
}

# Check if the file exists and delete if necessary
if (Test-Path $outputFilePath) {
    Remove-Item $outputFilePath
}


# Output entire list to a JSON file
#$jsonList | ConvertTo-Json -Compress | Out-File -FilePath "PBR.json" -Encoding UTF8


# Create the file and write the first entry
$_firstEntry = $jsonList[0] | ConvertTo-Json -Compress
Set-Content -LiteralPath "$outputFilePath" -Value "[ `n"


# For the remaining entries, use line break and then append
for ($i = 0; $i -lt $jsonList.Count; $i++) {
    Add-Content -LiteralPath $outputFilePath -Value ($jsonList[$i] | ConvertTo-Json -Compress) 
    if ($i -lt $jsonList.Count -1 ) { Add-Content -LiteralPath $outputFilePath -Value "," }
    #Add-Content -LiteralPath $outputFilePath -Value "`n"  # Line break

}
Add-Content -LiteralPath "$outputFilePath" -Value "] "
Write-Host $outputFilePath
# Output to console for verification
$jsonList | ConvertTo-Json -Compress
