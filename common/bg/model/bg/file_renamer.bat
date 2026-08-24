@echo off
setlocal enabledelayedexpansion

set /p letra="Letra: "
set /p inicio="Numero inicial: "
set /p fim="Numero final: "

set cont=%inicio%
for %%f in (*.*) do (
    if not "%%f"=="%~nx0" (
        if !cont! leq %fim% (
            set num=00!cont!
            set num=!num:~-2!
            set ext=%%~xf
            ren "%%f" "%letra%_!num!!ext!"
            echo %%f --^> %letra%_!num!!ext!
            set /a cont+=1
        )
    )
)

echo Pronto!
pause