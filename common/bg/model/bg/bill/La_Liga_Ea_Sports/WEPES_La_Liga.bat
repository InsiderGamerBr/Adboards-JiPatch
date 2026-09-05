@echo off
setlocal enabledelayedexpansion

title Renomeador DDS Matriz - Nova Pasta

if "%~1"=="" (
    cls
    echo ==========================================
    echo       RENOMEADOR DE ARQUIVOS DDS
    echo ==========================================
    echo.
    echo Arraste os arquivos DDS para este BAT.
    echo.
    echo Os arquivos renomeados serao salvos em
    echo uma nova pasta chamada "Output".
    echo.
    pause
    exit /b
)

cls
echo ==========================================
echo       RENOMEADOR DE ARQUIVOS DDS
echo ==========================================
echo.
echo Arquivos recebidos:
echo.

set total=0
for %%A in (%*) do (
    set /a total+=1
    set "ARQ_!total!=%%~fA"
    echo !total! - %%~nxA
)

echo.
echo Total de arquivos detectados: !total!
echo.

set /p n1="1. PRIMEIRO bloco (XX) - Numero INICIAL (ex: 02): "
set /p n2="2. PRIMEIRO bloco (XX) - Numero FINAL   (ex: 09): "
set /p n3="3. SEGUNDO  bloco (YY) - Numero INICIAL (ex: 01): "
set /p n4="4. SEGUNDO  bloco (YY) - Numero FINAL   (ex: 04): "

:: Trata entradas com zero a esquerda para evitar erro octal (08 e 09)
for /f "tokens=* delims=0" %%A in ("!n1!") do set "v1=%%A"
if "!v1!"=="" set "v1=0"
for /f "tokens=* delims=0" %%A in ("!n2!") do set "v2=%%A"
if "!v2!"=="" set "v2=0"
for /f "tokens=* delims=0" %%A in ("!n3!") do set "v3=%%A"
if "!v3!"=="" set "v3=0"
for /f "tokens=* delims=0" %%A in ("!n4!") do set "v4=%%A"
if "!v4!"=="" set "v4=0"

set /a v1=v1+0
set /a v2=v2+0
set /a v3=v3+0
set /a v4=v4+0

:: Organiza os limites da faixa XX
if !v1! LEQ !v2! (
    set /a xxIniNum=v1
    set /a xxFimNum=v2
) else (
    set /a xxIniNum=v2
    set /a xxFimNum=v1
)

:: Organiza os limites da faixa YY
if !v3! LEQ !v4! (
    set /a yyIniNum=v3
    set /a yyFimNum=v4
) else (
    set /a yyIniNum=v4
    set /a yyFimNum=v3
)

set /a qtd_xx=(xxFimNum - xxIniNum) + 1
set /a qtd_yy=(yyFimNum - yyIniNum) + 1
set /a total_combinacoes=qtd_xx * qtd_yy

echo.
echo ==========================================
echo       RESUMO DA OPERACAO
echo ==========================================
echo.
echo Faixa XX (Primeiro numero): de !xxIniNum! ate !xxFimNum!
echo Faixa YY (Segundo numero) : de !yyIniNum! ate !yyFimNum!
echo Total de combinacoes possiveis: !total_combinacoes!
echo Total de arquivos recebidos: !total!
echo.

if !total! GTR !total_combinacoes! (
    set /a excedentes=total-total_combinacoes
    echo AVISO: !excedentes! arquivos serao ignorados por falta de numeros.
    echo.
)

set /p confirma="Deseja continuar? S/N: "

if /i not "!confirma!"=="S" (
    echo.
    echo Operacao cancelada.
    pause
    exit /b
)

:: Pega o diretorio de origem do primeiro arquivo e cria a pasta Output
for %%F in ("%~1") do set "pasta_origem=%%~dpF"
set "pasta_destino=!pasta_origem!Output\"

if not exist "!pasta_destino!" mkdir "!pasta_destino!"

echo.
echo ==========================================
echo       RENOMEANDO E COPIANDO ARQUIVOS
echo ==========================================
echo Destino: !pasta_destino!
echo.

set /a sucesso=0
set /a pulados=0
set /a arq_index=1

for /l %%X in (!xxIniNum!, 1, !xxFimNum!) do (
    for /l %%Y in (!yyIniNum!, 1, !yyFimNum!) do (
        if !arq_index! LEQ !total! (
            call :PROCESSAR_ARQUIVO !arq_index! %%X %%Y
            set /a arq_index+=1
        )
    )
)

if !arq_index! LEQ !total! (
    for /l %%I in (!arq_index!, 1, !total!) do (
        call set "excedente_path=%%ARQ_%%I%%"
        echo [EXCEDENTE] !excedente_path! - Ignorado
        set /a pulados+=1
    )
)

goto FINAL

:PROCESSAR_ARQUIVO
set "idx=%1"
set "val_xx=%2"
set "val_yy=%3"

call set "caminho_completo=%%ARQ_%idx%%%"

for %%F in ("!caminho_completo!") do (
    set "nome_original=%%~nxF"
    set "extensao=%%~xF"
    set "nome_sem_ext=%%~nF"
)

:: Formata os numeros com dois digitos (02, 09, etc.)
set "fmt_xx=0!val_xx!"
set "fmt_xx=!fmt_xx:~-2!"

set "fmt_yy=0!val_yy!"
set "fmt_yy=!fmt_yy:~-2!"

:: Mantem o prefixo original (ex: La_Liga)
for /f "tokens=1,2 delims=_" %%A in ("!nome_sem_ext!") do (
    set "prefixo=%%A_%%B"
)
if "!prefixo!"=="_" set "prefixo=La_Liga"

set "novo_nome=!prefixo!_!fmt_xx!_!fmt_yy!!extensao!"
set "destino_arquivo=!pasta_destino!!novo_nome!"

copy /y "!caminho_completo!" "!destino_arquivo!" >nul 2>&1

if !errorlevel! equ 0 (
    echo [OK] !nome_original! --^> Output\!novo_nome!
    set /a sucesso+=1
) else (
    echo [FALHA] Nao foi possivel processar !nome_original!
    set /a pulados+=1
)
exit /b

:FINAL
echo.
echo ==========================================
echo       OPERACAO FINALIZADA
echo ==========================================
echo.
echo Processados com sucesso: !sucesso!
echo Ignorados ou pulados: !pulados!
echo.

if !sucesso! GTR 0 (
    echo ==========================================
    echo       EXCLUSAO DOS ORIGINAIS
    echo ==========================================
    echo.
    set /p apagar="Deseja APAGAR os arquivos ORIGINAIS recebidos? S/N: "
    if /i "!apagar!"=="S" (
        echo.
        echo Apagando arquivos originais...
        for /l %%I in (1, 1, !total!) do (
            call set "file_to_del=%%ARQ_%%I%%"
            if exist "!file_to_del!" (
                del /f /q "!file_to_del!" >nul 2>&1
                echo [DELETADO] !file_to_del!
            )
        )
        echo.
        echo Arquivos originais removidos com sucesso.
    ) else (
        echo.
        echo Arquivos originais mantidos.
    )
)

echo.
pause
exit