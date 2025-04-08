
# 🧠 Gensyn RL-Swarm Linux 安装脚本

本脚本用于自动部署 [Gensyn 官方 rl-swarm 项目](https://github.com/gensyn-ai/rl-swarm)，简化在 Ubuntu VPS 上的安装流程。

这是一个适用于 **Ubuntu 20.04 / 22.04** 版本的 Linux 自动部署脚本，用于快速安装并运行 [Gensyn](https://github.com/gensyn-ai/rl-swarm) 的 `rl-swarm` 项目。

---

## 🚀 一键安装（推荐 ✅）

打开终端，复制粘贴以下命令，自动完成全部依赖安装和环境配置：

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/essenwo/gensyn-rl-swarm-linux-setup/main/setup_rl_swarm_linux.sh)"

⏱️ 安装过程会根据你的网络和设备环境耗时 5-15 分钟不等。

⸻

📦 脚本功能
	•	安装系统依赖（Python、pip、Node.js、Yarn、git 等）
	•	创建 Python 虚拟环境并安装依赖
	•	安装 Node 前端依赖（如 modal-login 页面）
	•	自动克隆 Gensyn 官方仓库
	•	设置适用于 Linux 的运行环境
	•	支持 CPU-only 环境，自动调整 PyTorch 配置
	•	启动 RL Swarm 节点任务执行

⸻

✅ 支持平台
	•	Ubuntu 20.04 / 22.04
（其他 Linux 发行版可以参考相应的依赖管理方式）
	•	CPU-only 环境（适用于无 GPU 的 VPS）

⸻

🧑‍💻 作者

@essenwo

如果这个项目帮到了你，欢迎点个 ⭐️ 或 提交 PR！
