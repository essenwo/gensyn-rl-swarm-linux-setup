#!/bin/bash

# === 1. 基础变量 ===
RL_PROJECT_DIR=~/rl-swarm-project
RL_DIR=$RL_PROJECT_DIR/rl-swarm
VENV_PATH=$RL_DIR/rl_env310
SCREEN_NAME="rl_swarm_session"  # 修改了screen会话名称

# === 2. 创建干净目录 ===
mkdir -p $RL_PROJECT_DIR
cd $RL_PROJECT_DIR

# === 3. 安装依赖工具（需 sudo）===
sudo apt update
sudo apt install -y curl git python3.10 python3.10-venv screen  # 确保安装 screen

# === 4. 克隆仓库 ===
git clone https://github.com/gensyn-ai/rl-swarm.git
cd $RL_DIR

# === 5. 创建虚拟环境并激活 ===
python3.10 -m venv $VENV_PATH
source $VENV_PATH/bin/activate

# === 6. 安装 Python 依赖 ===
pip install --upgrade pip
pip install -r requirements.txt || { echo "安装失败：requirements.txt"; exit 1; }
pip install -r requirements-hivemind.txt || { echo "安装失败：requirements-hivemind.txt"; exit 1; }

# === 6.1 安装 hivemind 模块 ===
pip install hivemind || { echo "安装失败：hivemind"; exit 1; }

# 修复 protobuf 版本
pip uninstall -y protobuf
pip install protobuf==5.27.5 || { echo "安装失败：protobuf"; exit 1; }

# === 7. 修复类型注解（自动替换）===
sed -i '1i\
from typing import Any, Callable, Sequence, Union\
from dataclasses import dataclass, field\
from collections import defaultdict\
import torch\
' $RL_DIR/hivemind_exp/hivemind_utils.py

sed -i 's/rewards: list = field(default_factory=list)/rewards: Sequence[Union[float, int]] = field(default_factory=list)/' $RL_DIR/hivemind_exp/hivemind_utils.py

# === 8. 修改超时时间 ===
sed -i 's/startup
