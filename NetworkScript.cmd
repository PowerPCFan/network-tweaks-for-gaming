@echo off
title NETWORK OPTIMIZATIONS FOR GAMING
cls
chcp 65001 > nul

net session >nul 2>&1
if %errorLevel% == 0 (
    goto mainscript
) else (
    echo Failure: Current permissions inadequate. Please run the file again as administrator.
	echo Press any key to exit
    pause > nul
    Exit
)

:mainscript
echo ███╗   ██╗███████╗████████╗██╗    ██╗ ██████╗ ██████╗ ██╗  ██╗
echo ████╗  ██║██╔════╝╚══██╔══╝██║    ██║██╔═══██╗██╔══██╗██║ ██╔╝
echo ██╔██╗ ██║█████╗     ██║   ██║ █╗ ██║██║   ██║██████╔╝█████╔╝ 
echo ██║╚██╗██║██╔══╝     ██║   ██║███╗██║██║   ██║██╔══██╗██╔═██╗ 
echo ██║ ╚████║███████╗   ██║   ╚███╔███╔╝╚██████╔╝██║  ██║██║  ██╗
echo ╚═╝  ╚═══╝╚══════╝   ╚═╝    ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝
echo  ██████╗ ██████╗ ████████╗██╗███╗   ███╗██╗███████╗ █████╗ ████████╗██╗ ██████╗ ███╗   ██╗███████╗
echo ██╔═══██╗██╔══██╗╚══██╔══╝██║████╗ ████║██║╚══███╔╝██╔══██╗╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
echo ██║   ██║██████╔╝   ██║   ██║██╔████╔██║██║  ███╔╝ ███████║   ██║   ██║██║   ██║██╔██╗ ██║███████╗
echo ██║   ██║██╔═══╝    ██║   ██║██║╚██╔╝██║██║ ███╔╝  ██╔══██║   ██║   ██║██║   ██║██║╚██╗██║╚════██║
echo ╚██████╔╝██║        ██║   ██║██║ ╚═╝ ██║██║███████╗██║  ██║   ██║   ██║╚██████╔╝██║ ╚████║███████║
echo  ╚═════╝ ╚═╝        ╚═╝   ╚═╝╚═╝     ╚═╝╚═╝╚══════╝╚═╝  ╚═╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝
echo ███████╗ ██████╗ ██████╗      ██████╗  █████╗ ███╗   ███╗██╗███╗   ██╗ ██████╗ 
echo ██╔════╝██╔═══██╗██╔══██╗    ██╔════╝ ██╔══██╗████╗ ████║██║████╗  ██║██╔════╝ 
echo █████╗  ██║   ██║██████╔╝    ██║  ███╗███████║██╔████╔██║██║██╔██╗ ██║██║  ███╗
echo ██╔══╝  ██║   ██║██╔══██╗    ██║   ██║██╔══██║██║╚██╔╝██║██║██║╚██╗██║██║   ██║
echo ██║     ╚██████╔╝██║  ██║    ╚██████╔╝██║  ██║██║ ╚═╝ ██║██║██║ ╚████║╚██████╔╝
echo ╚═╝      ╚═════╝ ╚═╝  ╚═╝     ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝

echo Press any key to start. This shouldn't take too long. 
pause > nul

:: Enable Direct Cache Access (DCA) to allow network adapters to directly access the CPU cache.
netsh int tcp set global dca=enabled > nul

:: Disable NetBIOS over TCP/IP for network adapter with index 8.
wmic nicconfig where index=8 call SetTcpipNetbios 2 > nul

:: Disable Teredo tunneling protocol for IPv6 over IPv4.
netsh int teredo set state disabled > nul

:: Disable TCP Window Scaling heuristics to force a fixed TCP window size.
netsh int tcp set heuristics Disabled > nul

:: Disable task offloading, forcing the CPU to handle network tasks.
netsh int ip set global taskoffload=Disabled > nul

:: Ensure task offloading is enabled in the registry (contrary to the netsh setting above).
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" /v "DisableTaskOffload" /t REG_DWORD /d "0" /f > nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v "DisablegTaskOffload" /t REG_DWORD /d "0" /f > nul

:: Disable network throttling by setting it to the maximum value.
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "NetworkThrottlingIndex" /t REG_DWORD /d "4294967295" /f > nul

:: Loop through all network adapters and apply Message-Signaled Interrupt (MSI) support and device priority.
for /f %%i in ('wmic path win32_NetworkAdapter get PNPDeviceID') do (
    :: Set device priority for interrupt management.
    reg add "HKLM\System\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\Affinity Policy" /v "DevicePriority" /f > nul
    :: Enable MSI (Message-Signaled Interrupts) for more efficient hardware interrupt handling.
    reg add "HKLM\System\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties" /v "MSISupported" /t REG_DWORD /d "1" /f > nul
)

:: Loop through network adapter GUIDs to adjust various TCP/IP parameters.
for /f %%q in ('wmic path win32_networkadapter get GUID ^| findstr "{"') do (
    :: Set interface metric (priority) for the adapter to 55.
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\%%q" /v InterfaceMetric /t REG_DWORD /d "55" /f > nul
    :: Disable Nagle's algorithm to reduce latency.
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\%%q" /v TCPNoDelay /t REG_DWORD /d "1" /f > nul
    :: Increase the frequency of TCP acknowledgments to improve latency.
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\%%q" /v TcpAckFrequency /t REG_DWORD /d "1" /f > nul
    :: Disable delayed acknowledgments for even lower latency.
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\%%q" /v TcpDelAckTicks /t REG_DWORD /d "0" /f > nul
)

:: Adjust service provider priorities (these are default values on modern systems).
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" /v "LocalPriority" /t REG_DWORD /d "4" /f > nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" /v "HostsPriority" /t REG_DWORD /d "5" /f > nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" /v "DnsPriority" /t REG_DWORD /d "6" /f > nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" /v "NetbtPriority" /t REG_DWORD /d "7" /f > nul


:: More random network tweaks
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v "MaxUserPort" /t REG_DWORD /d "65534" /f > nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v "TCPTimedWaitDelay" /t REG_DWORD /d "30" /f > nul
for /f %%q in ('wmic path win32_networkadapter get GUID ^| findstr "{"') do reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\%%q" /v "TCPNoDelay" /t REG_DWORD /d "1" /f > nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v "MaxCacheTtl" /t REG_DWORD /d "1" /f > nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v "MaxNegativeCacheTtl" /t REG_DWORD /d "0" /f > nul
netsh int tcp set global autotuninglevel=disabled > nul

echo Network tweaks applied successfully. Press any key to exit.
pause > nul
exit
