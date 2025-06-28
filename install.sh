#!/bin/bash

clear

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "BBR + FQ 一键开启脚本"
echo "作者：github/lillinlin"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "请选择操作（输入数字）："
echo "  1. 启用 BBR + FQ"
echo "  2. 查看当前内核参数"
echo "  3. 退出"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
read -rp "你的选择是: " choice

case "$choice" in
1)
    echo ""
    echo "正在应用 BBR + FQ 配置..."

    # 删除旧的配置，避免重复
    sudo sed -i '/^net.core.default_qdisc/d' /etc/sysctl.conf
    sudo sed -i '/^net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf

    # 写入新的配置
    echo 'net.core.default_qdisc=fq' | sudo tee -a /etc/sysctl.conf >/dev/null
    echo 'net.ipv4.tcp_congestion_control=bbr' | sudo tee -a /etc/sysctl.conf >/dev/null

    # 立刻让内核参数生效
    sudo sysctl -p
    
    echo ""
    echo "BBR + FQ 已成功启用！"
    echo "新的参数已写入 /etc/sysctl.conf 文件中。"
    ;;
2)
    echo ""
    echo "正在查询当前的 TCP 拥塞控制算法和默认队列算法..."
    echo "--------------------------------------------------"
    sysctl net.ipv4.tcp_congestion_control
    sysctl net.core.default_qdisc
    echo "--------------------------------------------------"
    ;;
3)
    echo ""
    echo "退出脚本。"
    exit 0
    ;;
*)
    echo ""
    echo "无效的输入，请输入 1, 2 或 3。"
    ;;
esac
