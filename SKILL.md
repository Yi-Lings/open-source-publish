---
name: open-source-publish
description: 将 Skill 开源到 GitHub 的标准化流程（清洗→隔离→文档→提交→发布→清理）
allowed-tools: Bash(*) Read(*) Write(*) Edit(*) Glob(*) Grep(*)
---

# 开源发布 Skill

## 流程

```
1. 清洗   —— 只复制要开源的文件到隔离目录
2. 隔离   —— 在独立目录操作，不污染原项目
3. 文档   —— 写 README.md
4. 提交   —— git init → add → commit
5. 发布   —— gh repo create --public --source=. --remote=origin --push
6. 清理   —— rm -rf <repo-dir>
```

## 规则

**只保留 3 个文件：** `SKILL.md` + `README.md` + `LICENSE`（MIT）
**绝不带：** `.claude/`、`references/`、`responses/`、`scripts/`、`.env`、Token/密码

**README 章节顺序：** `功能 → 环境要求 → 安装说明 → 使用说明 → License`

**安装说明两种方式：**
```
### 方式一：AI 智能体直接安装（推荐）
在 AI 助手中输入：> 请帮我装 https://github.com/<用户>/<仓库> 这个 skill

### 方式二：手动安装
git clone https://github.com/<用户>/<仓库>.git
cp <仓库>/SKILL.md /path/to/.claude/skills/<仓库>/
```

## 首次发布

```bash
REPO="my-skill"; DESC="一行描述"
mkdir -p "/c/Users/Admin/Desktop/$REPO"
cp /path/to/SKILL.md "/c/Users/Admin/Desktop/$REPO/"
# 写 README.md + LICENSE

cd "/c/Users/Admin/Desktop/$REPO"
git init
git config user.email "u@users.noreply.github.com"
git config user.name "Your-GitHub-Username"
git add -A && git commit -m "init: $DESC"

gh repo create "$REPO" --public --description "$DESC" --source=. --remote=origin --push
# rm -rf "/c/Users/Admin/Desktop/$REPO"
```

## 迭代同步

本地 skill 迭代后同步到已发布仓库：

```bash
gh repo clone <user>/<repo> "C:/Users/Admin/Desktop/<repo>-update"
# 更新 SKILL.md 和 README.md

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
- [ ] 只复制了 SKILL.md（无 `.claude/`、`.env`、Token）？
- [ ] 无硬编码 API Key / 密码？
- [ ] README 含"AI 安装" + "手动安装"两种方式？
- [ ] `git config user.email` 已设（local）？
- [ ] `gh repo create` 参数完整（`--source=. --push`）？

**迭代同步：**
- [ ] `gh repo list` 确认仓库存在？
- [ ] 克隆到隔离目录，不污染本地工作区？
- [ ] SKILL.md 和 README.md 都已同步？
- [ ] `git config user.email/name` 在仓库内已设？
- [ ] 提交信息用 `sync: <摘要>` 格式？
- [ ] 清理临时目录？

## 触发

- "开源 / 发布到 GitHub / publish to GitHub / 帮我创建仓库"
