---
name: open-source-publish
description: 将 Skill/脚本/小型项目 开源到 GitHub 的标准化流程（判断→清洗→隔离→文档→提交→发布→清理）
allowed-tools: Bash(*) Read(*) Write(*) Edit(*) Glob(*) Grep(*)
---

# 开源发布 Skill

将本地内容一键发布到 GitHub 的标准化流程。自动判断发布类型并适配清洗/文档规则。

## 流程

```
1. 判断 → 2. 清洗 → 3. 隔离 → 4. 文档(README+LICENSE) → 5. 提交(git init→add→commit) → 6. 发布(gh repo create --public --push) → 7. 清理(rm -rf <repo-dir>)
```

## 类型判断

| 条件 | 类型 |
|------|------|
| 路径含 `.claude/skills/` 或提及 "skill" | **Skill** |
| 路径是 `.py`/`.js`/`.ts`/`.sh`/`.ps1`/`.go`/`.rs`/`.rb` 单文件 | **脚本** |
| 路径是目录内含多文件 | **小型项目** |
| 仅描述无路径 | **Skill**（默认），询问确认 |

## 清洗规则

**通用排除：** `.claude/` `.env` `.git/` `node_modules/` `__pycache__/` `references/` `responses/` `scripts/` `dist/` `build/` `.DS_Store` Token/密码/API Key

| 类型 | 保留 | 排除 |
|------|------|------|
| **Skill** | `SKILL.md` + 必要附属脚本(`.py`/`.js`/`.sh`) + `README.md` + `LICENSE` | 通用排除 + 无关文件 |
| **脚本** | `<主脚本>` + `README.md` + `LICENSE`（可附带 `requirements.txt`/`package.json`） | 同上 |
| **小型项目** | 完整源码目录结构 | 通用排除 |

**⚠️** 检查 SKILL.md 无硬编码 API Key/Token。

## README 模板

章节顺序统一：`功能 → 环境要求 → 安装说明 → 使用说明 → License`

### Skill

```markdown
# <repo>

一句话描述功能。

## 功能
- 要点

## 环境要求
- Claude Code
- [可选] 其他依赖

## 安装说明
### 方式一：AI 智能体直接安装（推荐）
在 AI 助手中输入：
> 请帮我装 https://github.com/<user>/<repo> 这个 skill

### 方式二：手动安装

    git clone https://github.com/<user>/<repo>.git
    cp -r <repo> ~/.claude/skills/<repo>/

## 使用说明
在 Claude Code 中输入关键词触发。

## License
MIT
```

### 脚本

```markdown
# <repo>

一句话描述脚本功能。

## 功能
- 要点

## 环境要求
- Python 3.x / Node.js x.x / Bash 等

## 安装说明

    git clone https://github.com/<user>/<repo>.git
    cd <repo>
    pip install -r requirements.txt  # 或 npm install

## 使用说明

    python <script>.py <参数>
    ./<script>.sh <参数>

## License
MIT
```

### 项目

```markdown
# <repo>

一句话描述。

## 功能

## 环境要求

## 安装说明

    git clone https://github.com/<user>/<repo>.git
    cd <repo>
    # 安装依赖 / 构建

## 使用说明

    # 运行 / 使用示例

## License
MIT
```

## 首次发布（通用）

```bash
REPO="my-thing"; DESC="一行描述"
TYPE="skill"  # skill / script / project
mkdir -p "/c/Users/Admin/Desktop/$REPO"

# Skill  → cp SKILL.md [+ companion scripts]
# 脚本  → cp script.py [+ requirements.txt]
# 项目  → cp -r /path/to/project/* . && 清理通用排除项

cd "/c/Users/Admin/Desktop/$REPO"
# 写 README.md + LICENSE

git init && git config user.email "u@users.noreply.github.com" && git config user.name "Your-GitHub-Username"
git add -A && git commit -m "init: $DESC"
gh repo create "$REPO" --public --description "$DESC" --source=. --remote=origin --push
rm -rf "/c/Users/Admin/Desktop/$REPO"
```

## 迭代同步

```bash
gh repo clone <user>/<repo> "C:/Users/Admin/Desktop/<repo>-update"
# 更新文件
cd "C:/Users/Admin/Desktop/<repo>-update"
git config user.email "github-actions@localhost" && git config user.name "<user>"
git add -A && git commit -m "sync: <摘要>" && git push
rm -rf "C:/Users/Admin/Desktop/<repo>-update"
```

先 `gh repo list | grep <repo>` 确认存在。

## 踩坑

| # | 现象 | 解决 |
|---|------|------|
| 1 | `git commit` 报 Author identity unknown | `git config user.email/name`（local，无需 --global） |
| 2 | gh 操作后 Shell cwd 跳回原目录 | 后续命令用完整路径 |
| 3 | push 报 502 | 仓库已创建，重试 `git push -u origin master` |
| 4 | 仓库名已存在 | 先 `gh repo list --json name \| grep -x "<name>"` 检查 |
| 5 | `--source` 或 `--push` 漏了 | 一步到位：`gh repo create <name> --public --desc "..." --source=. --remote=origin --push` |
| 6 | clone 后 push 报 Author unknown | 在仓库目录设 `git config user.email/name` |

## 自检清单

**首次发布：** 类型判断正确？清洗规则匹配？无 API Key/Token？README 章节顺序正确？Skill 附带脚本已保留？`git config` 已设？`gh repo create` 含 `--source=. --push`？临时目录已清理？

**迭代同步：** repo 存在？克隆到隔离目录？文件已同步？`git config` 已设？commit 信息 `sync:` 格式？临时目录已清理？

## 触发

- "开源 / 发布到 GitHub / publish to GitHub / 帮我创建仓库 / 帮我发布 <路径>"
- "发布(开源)脚本/项目 / publish script/project"
