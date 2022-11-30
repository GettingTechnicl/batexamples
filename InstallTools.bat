@echo off

:Created By
::GettingTechnicl

:Description/howto
::This script will self delete as well as delete all files copied to machine associated with this script when complete
::This script and all files associated need to be inside the same folder, and copied to the downloads folder of a client machine
::You can then run this script with success

: Change admin user per client
set adminuser=username

: Change admin password per client
set adminpassword=password

: Set Continuum installer file name within folder path
set continuum=filename.msi/exe

: Set SD installer file name within folder path
set sdchat=EIT_LMIR_Chat.msi

: Set S1 installer file name within folder path - Set token per site - Currently set to force reboot and script resumes after reboot
set s1=SentinelInstaller_windows_64bit_v22_1_4_10010.msi
set s1key=SITE_TOKEN=TOKEN /quiet /forcerestart

: Set ArcticWolf Sysmon installer path
set sysmon=sysmonassistant-1_0_1.msi
set sysvar= /quiet

: Set ArcticWolf Agent installer path
set awagent=arcticwolfagent-2022-03_52.msi
set awvar=/quiet

:below, list consecutively only apps that are supported by chocolatey "https://community.chocolatey.org/packages?q="
set chocolateyapps=

:DO NOT EDIT ANYTHING BELOW THIS LINE OR YOU RUN THE RISK OF BREAKING SCRIPT

:: BatchGotAdmin
:-------------------------------------
REM  --> Check for permissions
    IF "%PROCESSOR_ARCHITECTURE%" EQU "amd64" (
>nul 2>&1 "%SYSTEMROOT%\SysWOW64\cacls.exe" "%SYSTEMROOT%\SysWOW64\config\system"
) ELSE (
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
)

REM --> If error flag set, we do not have admin.
if '%errorlevel%' NEQ '0' (
    echo Requesting administrative privileges...
    goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    set params= %*
    echo UAC.ShellExecute "cmd.exe", "/c ""%~s0"" %params:"=""%", "", "runas", 1 >> "%temp%\getadmin.vbs"

    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
    pushd "%CD%"
    CD /D "%~dp0"
:-------------------------------------- 

call :Resume
goto %current%
goto :eof

:one
::add script to Run Key
reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Run /v %~n0 /d %~dpnx0 /f
echo two >%~dp0current.txt
echo -- Section one - Creating Admin Account - USER: %adminuser% PASSWORD: Redacted - Creating as Administrator --
net user "%adminuser%" "%adminpassword%" /add
net localgroup "Administrators" "%adminuser%" /add
WMIC USERACCOUNT WHERE "Name='%adminuser%'" SET PasswordExpires=FALSE
echo -- Completed created user -- moving on...
goto :rsymantec

:rsymantec
echo sysmon >%~dp0current.txt
echo -- Removing Symantec --
cd /D "C:\Program Files\Altiris\Altiris Agent"
aexagentutil.exe /uninstall
echo -- Completed removing symantec -- moving on...
goto :sysmon


:sysmon
echo two >%~dp0current.txt
echo -- Sysmon Installing --
cd /D "%~dp0"
Sysmon.exe -u force
Sysmon64.exe -u force
msiexec /i %sysmon% %sysvar%
:Sysmon64.exe -i -accepteula
echo -- Completed installing sysmon -- moving on...
goto :two

:two
echo three >%~dp0current.txt
echo -- Section two - Installing Sentinel One and Rebooting machine --
cd /D "%~dp0"
msiexec /i %s1% %s1key%
echo -- Completed installing Sentinel One -- rebooting...
pause
goto :four

:three
echo awagent >%~dp0current.txt
echo -- Section three - Installing Chocolatey and applications --
cd /D "%~dp0"
Powershell.exe -Command "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
Powershell.exe -Command "C:\ProgramData\chocolatey\bin\choco.exe install -y %chocolateyapps%"
echo -- Completed installing User apps -- moving on...
goto :awagent

:awagent
echo four >%~dp0current.txt
echo -- Installing AW Agent --
cd /D "%~dp0"
msiexec /i %awagent% %awvar%
echo -- AW Agent Install Finished -- moving on...
goto :four

:four
echo five >%~dp0current.txt
echo -- Section three - Installing RMM and SD Chat - Please be patient --
cd /D "%~dp0"
%continuum% /q & %sdchat%
echo -- RMM and SD deployed -- complete...
goto :five

:five
:: Remove sript from Run key
reg delete HKCU\Software\Microsoft\Windows\CurrentVersion\Run /v %~n0 /f
del %~dp0current.txt
echo Self Destructing and deleting all associated files
del /F /Q %continuum%
del /F /Q %sdchat%
del /F /Q %s1%
del /F /Q "%~dp0"
(goto) 2>nul & del "%~f0"

:resume
if exist %~dp0current.txt (
    set /p current=<%~dp0current.txt
) else (
    set current=one
)

