#!/bin/bash
# ==============================================
# 功能    : 自动配置 Linux 系统 BBR 及网络优化参数
# 作者    : github/lillinlin
# 适用    : Debian/Ubuntu/CentOS 等 Linux 系统
# ==============================================

CONF_FILE="/etc/sysctl.d/99-bbr.conf"

echo "正在写入 BBR 优化参数到 $CONF_FILE ..."

sudo tee $CONF_FILE > /dev/null <<EOF
net.core.default_qdisc = cake
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_delack_min = 1
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_moderate_rcvbuf = 1
net.ipv4.tcp_adv_win_scale = 2
net.ipv4.tcp_frto = 2
net.core.busy_poll = 50
net.core.busy_read = 50
net.ipv4.tcp_max_syn_backlog = 65535
EOF

echo "参数写入完成，正在应用配置 ..."

sudo sysctl --system

echo "BBR 优化已启用并生效。"
