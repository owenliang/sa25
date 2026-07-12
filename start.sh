#!/bin/bash
# 石器时代服务端启动脚本
# Usage: ./start.sh [saac|gmsv|both|stop|status]

ROOT=/root/stone-age

start_saac() {
    pkill -9 -f saacjt.exe 2>/dev/null
    sleep 1
    cd "$ROOT/saac"
    # 使用 setsid + nohup 真正脱离会话, 避免被父进程的退出波及
    setsid nohup ./saacjt.exe > /tmp/saac_run.log 2>&1 < /dev/null &
    echo "saac started (PID=$!)"
}

start_gmsv() {
    pkill -9 -f gmsvjt.exe 2>/dev/null
    sleep 1
    cd "$ROOT/gmsv"
    setsid nohup ./gmsvjt.exe > /tmp/gmsv_run.log 2>&1 < /dev/null &
    echo "gmsv started (PID=$!)"
}

case "${1:-both}" in
    saac)  start_saac ;;
    gmsv)  start_gmsv ;;
    both)  start_saac; sleep 3; start_gmsv ;;
    stop)  pkill -9 -f saacjt.exe; pkill -9 -f gmsvjt.exe; echo "stopped" ;;
    status)
        echo "saac: $(pgrep -f saacjt.exe >/dev/null && echo RUNNING || echo STOPPED)"
        echo "gmsv: $(pgrep -f gmsvjt.exe >/dev/null && echo RUNNING || echo STOPPED)"
        ss -ltn 2>/dev/null | grep -E "9300|9065"
        ;;
    *) echo "Usage: $0 [saac|gmsv|both|stop|status]"; exit 1 ;;
esac
