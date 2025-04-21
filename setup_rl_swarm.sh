#!/bin/bash

# === 1. 基础变量 ===
RL_PROJECT_DIR=~/rl-swarm-project
RL_DIR=$RL_PROJECT_DIR/rl-swarm
VENV_PATH=$RL_DIR/rl_env310

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
python3.10 -m venv rl_env310
source $VENV_PATH/bin/activate

# === 6. 安装 Python 依赖 ===
pip install --upgrade pip
pip install -r requirements.txt
pip install -r requirements-hivemind.txt

# === 6.1 安装 hivemind 模块 ===
pip install hivemind

# 修复 protobuf 版本
pip uninstall -y protobuf
pip install protobuf==5.27.5

# === 7. 修复类型注解（自动替换）===
sed -i '1i\
from typing import Any, Callable, Sequence, Union\
from dataclasses import dataclass, field\
from collections import defaultdict\
import torch\
' $RL_DIR/hivemind_exp/hivemind_utils.py

sed -i 's/rewards: list = field(default_factory=list)/rewards: Sequence[Union[float, int]] = field(default_factory=list)/' $RL_DIR/hivemind_exp/hivemind_utils.py

# === 8. 修改超时时间 ===
sed -i 's/startup_timeout=30/startup_timeout=120/' $RL_DIR/hivemind_exp/runner/gensyn/testnet_grpo_runner.py

# === 9. 优化训练配置 ===
CONFIG_FILE=$RL_DIR/hivemind_exp/configs/mac/grpo-qwen-2.5-0.5b-deepseek-r1.yaml
cat <<EOF > $CONFIG_FILE
# Training arguments
max_steps: 3
per_device_train_batch_size: 1
gradient_accumulation_steps: 2
max_grad_norm: 0.5
gradient_checkpointing: true
gradient_checkpointing_kwargs:
  use_reentrant: false
max_completion_length: 512
EOF

# === 10. 生成运行脚本 ===
cat <<EOF > $RL_DIR/run_rl_swarm.sh
#!/bin/bash
export PYTORCH_MPS_HIGH_WATERMARK_RATIO=0.0
export PYTORCH_ENABLE_MPS_FALLBACK=1
export PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512
export CUDA_LAUNCH_BLOCKING=1

python3.10 -m hivemind_exp.runner.gensyn.testnet_grpo_runner
EOF

chmod +x $RL_DIR/run_rl_swarm.sh

# === 11. 启动 screen 会话并限制内存为 18GB ===
echo "🚀 启动 RL Swarm（内存限制为 18GB）..."
screen -dmS swarm bash -c "ulimit -v 18874368; cd $RL_DIR && source $VENV_PATH/bin/activate && ./run_rl_swarm.sh"

# === 12. 提示完成 ===
echo "✅ RL Swarm 已部署并在 screen 会话中运行。"
echo "👉 输入以下命令进入 screen 查看运行情况："
echo "     screen -r swarm"
