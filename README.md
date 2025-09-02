# CreatePBRJson
CreatePBRJson.ps1: A simple powershell script to generate a basic PBR json for PBRNifPatcher or ParallaxGen
 Run it from the main folder of your mod and it creates the folder and a basic json

# nifoptall
nifoptall.bat: A simple batch script that runs SSE NIF Optimizer.exe and nifopt on all meshes in a folder.
 Requires both tools to be on the Windows path environment variable. Use 'nifoptall replace' to replace unoptimise versions instead of creating new files.

# Create seasonal variations
Create seasonal variations.pas: xEdit Script that duplicates FormIds from an input plugin and creates 4 seasonal copies (SPR,SUM,AUT,WIN) in a targetFileName\
 Needs to be placed in folder xedit\Edit Scripts\
It requires to set inputFileName (default 'Input records for Seasons conversion.esp') in the script itself and that plugin must be loaded in xEdit. All FormIds of this plugin will be read.\
It requires to set targetFileName (default 'PBR Flora Overhaul Seasons.esp') in the script itself and that plugin must be loaded in xEdit. This will be used to write the output FormIds.
