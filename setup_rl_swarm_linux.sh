#!/bin/bash

set -e

# === 🐧 Gensyn RL-Swarm Linux 安装脚本 ===
# 适用于 Ubuntu 20.04 / 22.04 VPS
# 作者: Essen的节点日记

# 1. 系统依赖安装
sudo apt update && sudo apt upgrade -y
sudo apt install -y python3 python3-pip python3-venv git curl build-essential

# 2. 安装 Node.js（使用官方 LTS）
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt install -y nodejs
sudo npm install -g yarn

# 3. 克隆 Gensyn 官方仓库
git clone https://github.com/gensyn-ai/rl-swarm.git
cd rl-swarm

# 4. 创建并激活 Python 虚拟环境
python3 -m venv rl_env
source rl_env/bin/activate

# 5. 安装 Python 依赖（含 hivemind）
pip install --upgrade pip
pip install -r requirements.txt
pip install -r requirements-hivemind.txt

# 可选：安装 colorlog 等增强输出的依赖
pip install colorlog torch transformers datasets accelerate peft trl wandb hivemind bitsandbytes safetensors

# 6. 设置 Node 前端依赖（如 modal-login 页面）
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
chmod +x run_rl_swarm.sh

# 8. 提示用户下一步操作
echo -e "\n✅ 所有依赖安装完成！你现在可以运行以下命令启动节点：\n"
echo "source rl_env/bin/activate && ./run_rl_swarm.sh"
