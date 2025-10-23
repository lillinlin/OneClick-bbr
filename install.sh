#!/bin/bash
# ==============================================
# 脚本名称: enable-bbr.sh
# 功能    : 安装/更新 sudo 并自动配置 Linux BBR
# 作者    : github/lillinlin
# 适用    : Debian/Ubuntu/CentOS 等 Linux 系统
# ==============================================

# -------------------------------
# 安装或更新 sudo
# -------------------------------
echo "检查并安装/更新 sudo ..."
if command -v apt >/dev/null 2>&1; then
    apt update -y
    apt install sudo -y
elif command -v yum >/dev/null 2>&1; then
    yum install sudo -y
else
    echo "未知包管理器，请手动安装 sudo"
fi

# -------------------------------
# 写入 BBR 配置
# -------------------------------
CONF_FILE="/etc/sysctl.d/99-bbr.conf"
echo "正在写入 BBR 优化参数到 $CONF_FILE ..."
sudo tee $CONF_FILE > /dev/null <<EOF
net.core.default_qdisc = cake
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_moderate_rcvbuf = 1
net.ipv4.tcp_adv_win_scale = 2
net.core.busy_poll = 50000
net.core.busy_read = 50000
net.ipv4.tcp_max_syn_backlog = 65535
EOF

# -------------------------------
# 应用配置（静默模式）
# -------------------------------
echo "应用 BBR 配置 ..."
sudo sysctl --system >/dev/null 2>&1

echo "BBR 优化已启用并生效。"
