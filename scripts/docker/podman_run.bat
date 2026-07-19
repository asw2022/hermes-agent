podman machine start > C:\Users\asw\podman_start.log 2>&1
echo EXIT_CODE: %ERRORLEVEL% >> C:\Users\asw\podman_start.log
podman info >> C:\Users\asw\podman_info.log 2>&1
echo EXIT_CODE: %ERRORLEVEL% >> C:\Users\asw\podman_info.log
