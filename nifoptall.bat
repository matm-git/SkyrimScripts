@echo off
setlocal enabledelayedexpansion
cls

set "replaceMode=0"
if /i "%1"=="replace" set "replaceMode=1"

echo Start the script with 'replace' option to overwrite old nifs
echo.
echo Searching for .nif files to optimise...
set count=0
for %%f in (*.nif) do (
    set filename=%%f
    
    if not "!filename:~-8!"==".opt.nif" (
        if not "!filename:~-8!"==".rev.nif" (
            if not "!filename:~-11!"==".sseopt.nif" (
                echo Processing: %%f
                set sseoptoutput=%%~nf.sseopt.nif
                copy "!filename!" "!sseoptoutput!"
                "SSE NIF Optimizer.exe" "%%sseoptoutput"
                if !errorlevel! equ 0 (
                    echo SSE NIF Optimizer erfolgreich angewendet: "!sseoptoutput!"
                    nifopt !sseoptoutput!
                    if !errorlevel! equ 0 (
                        set "nifoptoutput=!sseoptoutput:.nif=.opt.nif!"  
                        if exist "!nifoptoutput!" (
                            echo NifOpt succesfully applied: !nifoptoutput!
                            move /Y "!nifoptoutput!" "!filename!"
                            del "!sseoptoutput!"
                        ) else (
                            set "nifoptoutput=!sseoptoutput:.nif=.rev.nif!" 
                            if exist "!nifoptoutput!" (
                                echo NifOpt reverted to LE, removed the result: !nifoptoutput!
                                del "!nifoptoutput!"    
                                move /Y "!sseoptoutput!" "!filename!"
                            )
                        )
                        set /a count+=1
                    ) else (
                        echo Fehler beim Verarbeiten von: %%sseoptoutput
                    )
                )       
            )         
        )
    ) else (
        echo Skipping already optimised file: %%f
    )
    echo.
)

echo.
echo Completed! %count% files processed.
