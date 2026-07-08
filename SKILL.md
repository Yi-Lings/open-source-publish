---
name: open-source-publish
description: 将 Skill/脚本/小型项目 开源到 GitHub 的标准化流程（判断→清洗→隔离→文档→提交→发布→清理）
allowed-tools: Bash(*) Read(*) Write(*) Edit(*) Glob(*) Grep(*)
---

# 开源发布 Skill

将本地内容一键发布到 GitHub 的开源标准化流程。自动判断发布类型并适配清洗/文档规则。

## 流程

```
1. 判断   —— 识别类型：Skill / 脚本 / 小型项目
2. 清洗   —— 按类型规则复制到隔离目录
3. 隔离   —— 在独立目录操作，不污染原项目
4. 文档   —— 写 README.md + LICENSE（MIT）
5. 提交   —— git init → add → commit
6. 发布   —— gh repo create --public --source=. --remote=origin --push
7. 清理   —— rm -rf <repo-dir>
```

## 类型判断

根据输入的路径/描述自动判断，优先级从高到低：

| 条件 | 类型 | 说明 |
|------|------|------|
| 路径包含 `.claude/skills/` 或用户明确提到 "skill" | **Skill** | Claude Code 技能，保留 SKILL.md + 必要附属脚本 |
| 路径是文件（`.py`/`.js`/`.ts`/`.sh`/`.ps1`/`.go`/`.rs`/`.rb` 等） | **脚本** | 单文件工具脚本 |
| 路径是目录，内含多文件源码 | **小型项目** | 有目录结构的完整小项目 |
| 用户未提供路径/仅提供描述 | **Skill** (默认) | 先按 Skill 处理，同时询问确认路径 |

判断时机：在流程第 1 步，根据用户输入路径和描述确定类型。

## 清洗规则

**通用排除（所有类型都适用）：** `.claude/`、`.env`、`.git/`、`node_modules/`、`__pycache__/`、`references/`、`responses/`、`scripts/`、`dist/`、`build/`、`.DS_Store`、Token/密码/API Key

| 类型 | 保留的文件 | 额外操作 |
|------|-----------|----------|
| **Skill** | `SKILL.md` + 必要附属脚本（`.py`/`.js`/`.sh` 等）+ `README.md` + `LICENSE` | 删除 `.claude/` `references/` `responses/` `.env` 等非必要文件，保留功能所需的脚本 |
| **脚本** | `<主脚本文件>` + `README.md` + `LICENSE` | 只保留主文件及配套数据文件（如 `requirements.txt`、`package.json`） |
| **小型项目** | 完整的源码目录结构 | 只删除通用排除列表中的内容，保留项目骨架 |

**⚠️ 注意：** 如果 `SKILL.md` 中含有硬编码的 API Key / Token 占位符，需提醒用户替换。

## README 模板

**通用章节顺序：** `功能 → 环境要求 → 安装说明 → 使用说明 → License`

### Skill 版

```markdown
# <repo-name>

一句话描述功能。

## 功能

- 要点 1
- 要点 2

## 环境要求

- Claude Code
- [可选] 其他依赖

## 安装说明

### 方式一：AI 智能体直接安装（推荐）

在 AI 助手中输入：
> 请帮我装 https://github.com/<user>/<repo> 这个 skill

### 方式二：手动安装

```bash
git clone https://github.com/<user>/<repo>.git
cp -r <repo> ~/.claude/skills/<repo>/
```

## 使用说明

在 Claude Code 中输入关键词触发。

## License

MIT
```

### 脚本版

```markdown
# <repo-name>

一句话描述脚本功能。

## 功能

- 要点

## 环境要求

- Python 3.x / Node.js x.x / Bash 等

## 安装说明

```bash
# 直接使用
git clone https://github.com/<user>/<repo>.git
cd <repo>
# 如需要依赖
pip install -r requirements.txt / npm install
```

## 使用说明

```bash
python <script>.py <参数>
# 或
./<script>.sh <参数>
```

## License

MIT
```

### 项目版

```markdown
# <repo-name>

一句话描述。

## 功能

## 环境要求

## 安装说明

```bash
git clone https://github.com/<user>/<repo>.git
cd <repo>
# 安装依赖 / 构建
```

## 使用说明

```bash
# 运行 / 使用示例
```

## License

MIT
```

## 首次发布

### 发布 Skill

```bash
REPO="my-skill"; DESC="一行描述"
mkdir -p "/c/Users/Admin/Desktop/$REPO"
cp /path/to/SKILL.md "/c/Users/Admin/Desktop/$REPO/"
# 如有必要附属脚本，一并复制
cp /path/to/companion.py "/c/Users/Admin/Desktop/$REPO/"
# 写 README.md + LICENSE

cd "/c/Users/Admin/Desktop/$REPO"
git init
git config user.email "u@users.noreply.github.com"
git config user.name "Your-GitHub-Username"
git add -A && git commit -m "init: $DESC"

gh repo create "$REPO" --public --description "$DESC" --source=. --remote=origin --push
# rm -rf "/c/Users/Admin/Desktop/$REPO"
```

### 发布脚本

```bash
REPO="my-script"; DESC="工具脚本描述"
mkdir -p "/c/Users/Admin/Desktop/$REPO"
cp /path/to/script.py "/c/Users/Admin/Desktop/$REPO/"
# 可附带 requirements.txt 等
# 写 README.md + LICENSE

cd "/c/Users/Admin/Desktop/$REPO"
git init
git config user.email "u@users.noreply.github.com"
git config user.name "Your-GitHub-Username"
git add -A && git commit -m "init: $DESC"

gh repo create "$REPO" --public --description "$DESC" --source=. --remote=origin --push
rm -rf "/c/Users/Admin/Desktop/$REPO"
```

### 发布小型项目

```bash
REPO="my-tool"; DESC="项目描述"
# 直接复制整个项目目录（排除通用排除列表）
cp -r /path/to/project "/c/Users/Admin/Desktop/$REPO"
# 手动清理通用排除项
rm -rf "/c/Users/Admin/Desktop/$REPO/.claude" "/c/Users/Admin/Desktop/$REPO/.env" ...
# 写 README.md + LICENSE

cd "/c/Users/Admin/Desktop/$REPO"
git init
git config user.email "u@users.noreply.github.com"
git config user.name "Your-GitHub-Username"
git add -A && git commit -m "init: $DESC"

gh repo create "$REPO" --public --description "$DESC" --source=. --remote=origin --push
rm -rf "/c/Users/Admin/Desktop/$REPO"
```

## 迭代同步

本地迭代后同步到已发布仓库：

```bash
gh repo clone <user>/<repo> "C:/Users/Admin/Desktop/<repo>-update"
# 更新 SKILL.md / README.md / 源码

cd "C:/Users/Admin/Desktop/<repo>-update"
git config user.email "github-actions@localhost"
git config user.name "<user>"
git add -A && git commit -m "sync: <变更摘要>"
git push

rm -rf "C:/Users/Admin/Desktop/<repo>-update"
```

**规则：** 先 `gh repo list | grep <repo>` 确认存在；commit 信息格式 `sync: <摘要>`；清理临时目录。

## 踩坑

| # | 现象 | 根因 | 解决 |
|---|------|------|------|
| 1 | `git commit` 报 Author identity unknown | git 未配置 user.name/email | `git config user.email "u@users.noreply.github.com"`（local 即可，无需 --global） |
| 2 | gh 操作后 Shell cwd 跳回原目录 | `gh` 发送 chdir 事件 | 后续命令用完整路径，不依赖 cwd |
| 3 | `gh repo create` 后 push 报 502 | GitHub 服务端瞬态错误 | 仓库已创建成功，重试 `git push -u origin master` |
| 4 | 仓库名已存在 | 同名仓库已存在 | 创建前检查：`gh repo list --json name --jq '.[].name' \| grep -x "<name>"` |
| 5 | `--source` 或 `--push` 漏了 | 参数不全 | 一步到位：`gh repo create <name> --public --desc "..." --source=. --remote=origin --push` |
| 6 | clone 后 push 报 Author unknown | 克隆的仓库无 local git config | 在仓库目录设 `git config user.email/name` |

## 自检清单

**首次发布：**
- [ ] 正确判断了发布类型（Skill/脚本/项目）？
- [ ] 按类型执行了对应的清洗规则？
- [ ] 无硬编码 API Key / 密码 / Token？
- [ ] README 协议章节顺序正确（功能 → 环境要求 → 安装说明 → 使用说明 → License）？
- [ ] Skill 类型：README 含"AI 安装" + "手动安装"两种方式，手动安装用 `cp -r` 复制整个目录？
- [ ] Skill 类型：必要附属脚本（`.py`/`.js`/`.sh` 等）已一并保留？
- [ ] 脚本/项目类型：README 含命令行使用示例？
- [ ] `git config user.email` 已设（local）？
- [ ] `gh repo create` 参数完整（`--source=. --push`）？
- [ ] 已清理临时目录？

**迭代同步：**
- [ ] `gh repo list` 确认仓库存在？
- [ ] 克隆到隔离目录，不污染本地工作区？
- [ ] 文件（SKILL.md / README.md / 源码）都已同步？
- [ ] `git config user.email/name` 在仓库内已设？
- [ ] 提交信息用 `sync: <摘要>` 格式？
- [ ] 清理临时目录？

## 触发

- "开源 / 发布到 GitHub / publish to GitHub / 帮我创建仓库"
- "发布脚本 / 开源脚本 / publish script / 发布项目 / publish project / 开源项目"
- "帮我发布 <路径>"
