#!/bin/bash
# ==============================================
# 脚本名称: enable-bbr.sh
# 功能    : 安装 sudo + BBR + CAKE 网络优化
# 作者    : github/lillinlin
# 适用    : Debian / Ubuntu
# ==============================================

echo "开始网络优化脚本..."

# -------------------------------
# 安装基础工具
# -------------------------------

echo "检查并安装必要组件..."

if command -v apt >/dev/null 2>&1; then
    apt update -y
    apt install -y sudo iproute2
elif command -v yum >/dev/null 2>&1; then
    yum install -y sudo iproute
else
    echo "未知包管理器，请手动安装 sudo 和 iproute2"
fi

# -------------------------------
# 修复 hostname 解析问题
# -------------------------------

HOSTNAME_NOW=$(hostname)

if ! grep -q "$HOSTNAME_NOW" /etc/hosts; then
    echo "修复 /etc/hosts hostname 解析..."
    echo "127.0.1.1 $HOSTNAME_NOW" >> /etc/hosts
fi

# -------------------------------
# 写入 BBR 配置
# -------------------------------

CONF_FILE="/etc/sysctl.d/99-bbr.conf"

echo "写入 BBR 优化参数到 $CONF_FILE ..."

sudo tee $CONF_FILE > /dev/null <<EOF
net.core.default_qdisc = cake
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_adv_win_scale = 1
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_moderate_rcvbuf = 1
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_pacing_ss_ratio = 300
net.ipv4.tcp_pacing_ca_ratio = 150
net.core.busy_poll = 50
net.core.busy_read = 50
net.core.netdev_max_backlog = 65535
EOF

echo "应用 sysctl 配置..."
sudo sysctl --system >/dev/null 2>&1

# -------------------------------
# 自动检测真实网卡
# -------------------------------

echo "检测真实网卡..."

IFACE=$(ip -o link show | awk -F': ' '{print $2}' | grep -Ev 'lo|docker|veth|warp|wg|tun|br-' | head -n1)

if [ -z "$IFACE" ]; then
    echo "未检测到有效网卡，退出"
    exit 1
fi

echo "检测到网卡: $IFACE"

# -------------------------------
# 立即应用 CAKE
# -------------------------------

echo "应用 CAKE 队列调度..."

tc qdisc replace dev $IFACE root cake unlimited besteffort triple-isolate ack-filter-aggressive split-gso rtt 1ms memlimit 64mb

# -------------------------------
# 创建 systemd 服务
# -------------------------------

echo "创建 systemd 开机服务..."

SERVICE_FILE="/etc/systemd/system/cake-qdisc.service"

sudo tee $SERVICE_FILE > /dev/null <<'EOF'
[Unit]
Description=Apply CAKE qdisc automatically
After=network-online.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'IFACE=$(ip -o link show | awk -F": " "{print \$2}" | grep -Ev "lo|docker|veth|warp|wg|tun|br-" | head -n1); tc qdisc replace dev $IFACE root cake unlimited besteffort triple-isolate ack-filter-aggressive split-gso rtt 1ms memlimit 64mb'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# -------------------------------
# 启用开机启动
# -------------------------------

echo "启用 systemd 服务..."

sudo systemctl daemon-reload
sudo systemctl enable cake-qdisc

echo ""
echo "=============================================="
echo "BBR + CAKE 网络优化已启用"
echo "检测到网卡: $IFACE"
echo "CAKE 已设置为开机自动加载"
echo "=============================================="
