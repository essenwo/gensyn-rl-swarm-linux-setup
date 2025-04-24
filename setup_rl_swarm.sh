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

# 添加 Python 3.12 的 PPA 源并安装
sudo apt update
sudo apt install -y software-properties-common
sudo add-apt-repository -y ppa:deadsnakes/ppa
sudo apt update
sudo apt install -y python3.12 python3.12-venv || {
  echo "❌ 安装 Python3.12 失败，退出。"
  exit 1
}

# 修复无法安装 python3.12-distutils 的情况
echo "🔧 使用 ensurepip 安装 pip 和 setuptools（代替 distutils）..."
python3.12 -m ensurepip --upgrade
python3.12 -m pip install --upgrade pip setuptools

# 安装其他基础工具
sudo apt install -y curl git screen wget

# ----------- 安装 Ngrok ----------- 
echo "📦 安装 Ngrok..."
wget https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz
tar -xvzf ngrok-v3-stable-linux-amd64.tgz
sudo mv ngrok /usr/local/bin/
rm ngrok-v3-stable-linux-amd64.tgz

# 安装 Node.js（使用 NodeSource 源）
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# 安装 Yarn（通过官方 APT 源）
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt update && sudo apt install -y yarn

# 如果你更喜欢通过 npm 安装 Yarn，可取消注释以下行（不推荐）：
# npm install -g yarn

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
echo -e "\n⚠️ 重要提示 ⚠️"
echo "当运行到 [ ] Waiting for you to complete the login process... 这一步时:"
echo "1. 请按 Ctrl+A+D 退出当前 screen 会话"
echo "2. 然后输入命令: screen -S ngrok"
echo "3. 在新的 screen 会话中执行: ngrok http 3000"
echo "4. 复制生成的 ngrok 域名链接，在浏览器中打开并完成邮箱登录验证"
echo "5. 验证完成后，按 Ctrl+A+D 退出 ngrok screen"
echo "6. 输入命令: screen -r gensyn 回到原先的会话继续运行"
echo -e "\n按任意键继续..."
read -n 1

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

echo "⚠️ 登录验证步骤说明 ⚠️"
echo "如果您看到此消息，说明您已退出了 gensyn 会话。请按以下步骤完成登录验证："
echo "1. 输入命令: screen -S ngrok"
echo "2. 在新的 screen 会话中执行: ngrok http 3000"
echo "3. 复制生成的 ngrok 域名链接，在浏览器中打开并完成邮箱登录验证"
echo "4. 验证完成后，按 Ctrl+A+D 退出 ngrok screen"
echo "5. 输入命令: screen -r gensyn 回到原先的会话继续运行"
