#!/bin/bash

set -e

# === 🐧 Gensyn RL-Swarm Linux 安装脚本 ===
# 适用于 Ubuntu 20.04 / 22.04 VPS
# 作者: Essen的节点日记

echo "开始安装 Gensyn RL-Swarm..."

# 1. 系统依赖安装
echo "正在更新系统并安装基础依赖..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y python3 python3-pip python3-venv git curl build-essential

# 2. 安装 Node.js（使用官方 LTS）
echo "正在安装 Node.js..."
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt install -y nodejs
sudo npm install -g yarn

# 3. 克隆 Gensyn 官方仓库
echo "正在克隆 Gensyn 仓库..."
if [ -d "rl-swarm" ]; then
  echo "rl-swarm 目录已存在，跳过克隆步骤"
else
  git clone https://github.com/gensyn-ai/rl-swarm.git
fi
cd rl-swarm

# 4. 创建并激活 Python 虚拟环境
echo "正在设置 Python 环境..."
python3 -m venv rl_env
source rl_env/bin/activate

# 5. 安装 Python 依赖（含 hivemind）
echo "正在安装 Python 依赖..."
pip install --upgrade pip
pip install -r requirements.txt
pip install -r requirements-hivemind.txt

# 可选：安装 colorlog 等增强输出的依赖
echo "正在安装额外的 Python 包..."
pip install colorlog torch transformers datasets accelerate peft trl wandb hivemind bitsandbytes safetensors

# 6. 设置 Node 前端依赖（如 modal-login 页面）
echo "正在安装前端依赖..."
cd modal-login

# 避免 npm 权限问题（动态判断当前用户名）
NPM_USER=$(whoami)
sudo chown -R $NPM_USER:$(id -gn $NPM_USER) ~/.npm || true

# 安装依赖
yarn add viem@2.25.0
yarn add @account-kit/react@latest
yarn add next@latest
yarn install
cd ..

# 7. 启动脚本授权 & 运行
echo "设置启动脚本权限..."
chmod +x run_rl_swarm.sh

# 8. 提示用户下一步操作
echo -e "\n✅ 所有依赖安装完成！你现在可以运行以下命令启动节点：\n"
echo "cd $(pwd) && source rl_env/bin/activate && ./run_rl_swarm.sh"
