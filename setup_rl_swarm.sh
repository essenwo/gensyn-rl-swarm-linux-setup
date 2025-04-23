#!/bin/bash

set -e
set -o pipefail

echo "🚀 开始一键部署 RL-Swarm 环境..."

# ----------- 架构检测（可选）-----------
ARCH=$(uname -m)
if [[ "$ARCH" != "x86_64" && "$ARCH" != "aarch64" ]]; then
  echo "❌ 不支持的架构：$ARCH，退出。"
  exit 1
fi

# ----------- 检查并更新 /etc/hosts ----------- 
echo "🔧 检查 /etc/hosts 配置..."
if ! grep -q "raw.githubusercontent.com" /etc/hosts; then
  echo "📝 写入 GitHub 加速 Hosts 条目..."
  sudo tee -a /etc/hosts > /dev/null <<EOL
199.232.68.133 raw.githubusercontent.com
199.232.68.133 user-images.githubusercontent.com
199.232.68.133 avatars2.githubusercontent.com
199.232.68.133 avatars1.githubusercontent.com
EOL
else
  echo "✅ Hosts 已配置，跳过。"
fi

# ----------- 安装依赖 ----------- 
echo "📦 安装依赖项：curl、git、python3.12、pip、nodejs、yarn、screen..."
sudo apt update
sudo apt install -y curl git screen nodejs yarn python3.12 python3.12-venv python3-pip

# ----------- 设置默认 Python3.12 ----------- 
echo "🐍 设置 Python3.12 为默认版本..."
echo 'alias python=python3.12' >> ~/.bashrc
echo 'alias python3=python3.12' >> ~/.bashrc
echo 'alias pip=pip3' >> ~/.bashrc
source ~/.bashrc

# ----------- 检查 Python 版本 ----------- 
PY_VERSION=$(python3 --version | grep "3.12" || true)
if [[ -z "$PY_VERSION" ]]; then
  echo "⚠️ Python 版本未正确指向 3.12，再次加载配置..."
  source ~/.bashrc
fi
echo "✅ 当前 Python 版本：$(python3 --version)"

# ----------- 克隆仓库 ----------- 
if [[ -d "rl-swarm" ]]; then
  echo "⚠️ 当前目录已存在 rl-swarm 文件夹。"
  read -p "是否覆盖已有目录？(y/n): " confirm
  if [[ "$confirm" == [yY] ]]; then
    echo "🗑️ 删除旧目录..."
    rm -rf rl-swarm
  else
    echo "❌ 用户取消操作，退出。"
    exit 1
  fi
fi

echo "📥 克隆 rl-swarm 仓库..."
git clone https://github.com/zunxbt/rl-swarm.git

# ----------- 修改配置文件 ----------- 
echo "📝 修改 YAML 配置..."
sed -i 's/max_steps: 20/max_steps: 5/' rl-swarm/hivemind_exp/configs/mac/grpo-qwen-2.5-0.5b-deepseek-r1.yaml
sed -i 's/gradient_accumulation_steps: 8/gradient_accumulation_steps: 1/' rl-swarm/hivemind_exp/configs/mac/grpo-qwen-2.5-0.5b-deepseek-r1.yaml
sed -i 's/max_completion_length: 1024/max_completion_length: 512/' rl-swarm/hivemind_exp/configs/mac/grpo-qwen-2.5-0.5b-deepseek-r1.yaml

echo "📝 修改 Python 启动参数..."
sed -i 's/startup_timeout=30/startup_timeout=120/' rl-swarm/hivemind_exp/runner/gensyn/testnet_grpo_runner.py

# ----------- 清理端口占用 ----------- 
echo "🧹 清理端口占用..."
pid=$(lsof -ti:3000) && [ -n "$pid" ] && kill -9 $pid && echo "✅ 杀掉 3000 端口进程：$pid" || echo "✅ 3000 端口未占用"

# ----------- 启动 screen 会话 ----------- 
echo "🖥️ 启动并进入 screen 会话 gensyn..."

sleep 2
screen -S gensyn bash -c '
  cd rl-swarm || exit 1

  echo "🐍 创建 Python 虚拟环境..."
  python3.12 -m venv .venv
  source .venv/bin/activate

  echo "🔧 设置 PyTorch MPS 环境变量（Linux 可省略或注释）..."
  export PYTORCH_MPS_HIGH_WATERMARK_RATIO=0.0
  export PYTORCH_ENABLE_MPS_FALLBACK=1

  echo "🚀 启动 RL-Swarm..."
  chmod +x run_rl_swarm.sh
  ./run_rl_swarm.sh
'

