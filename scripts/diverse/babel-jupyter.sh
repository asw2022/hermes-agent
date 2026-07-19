#!/bin/bash
# Babel-PC Setup Script
export PATH=$HOME/.local/bin:$PATH

echo "=== Installing Jupyter Lab ==="
pip3 install --break-system-packages --user jupyterlab notebook 2>&1 | tail -3

echo "=== Starting Jupyter Lab ==="
nohup jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root --NotebookApp.token="" > /home/Babel/jupyter.log 2>&1 &
echo "PID: $!"
sleep 3
cat /home/Babel/jupyter.log
echo "Jupyter Lab gestartet auf Port 8888"
