@echo off
set OUTFILE=C:\Users\asw\netmon_raw.txt
del "%OUTFILE%" 2>nul

echo === DATE >> "%OUTFILE%"
date /t >> "%OUTFILE%"
time /t >> "%OUTFILE%"
echo. >> "%OUTFILE%"

echo === IPCONFIG >> "%OUTFILE%"
ipconfig /all >> "%OUTFILE%" 2>&1
echo. >> "%OUTFILE%"

echo === ARP >> "%OUTFILE%"
arp -a >> "%OUTFILE%" 2>&1
echo. >> "%OUTFILE%"

echo === NETSTAT ESTABLISHED >> "%OUTFILE%"
netstat -an -p TCP | find "ESTABLISHED" >> "%OUTFILE%" 2>&1
echo. >> "%OUTFILE%"

echo === NETSTAT LISTENING >> "%OUTFILE%"
netstat -an -p TCP | find "LISTENING" >> "%OUTFILE%" 2>&1
echo. >> "%OUTFILE%"

echo === ROUTE >> "%OUTFILE%"
route print >> "%OUTFILE%" 2>&1
echo. >> "%OUTFILE%"

echo === PING ROUTER >> "%OUTFILE%"
ping -n 3 192.168.0.1 >> "%OUTFILE%" 2>&1
echo. >> "%OUTFILE%"

echo === PING DNS >> "%OUTFILE%"
ping -n 3 8.8.8.8 >> "%OUTFILE%" 2>&1
echo. >> "%OUTFILE%"

echo DONE
