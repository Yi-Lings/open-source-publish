# open-source-publish

将 Claude Code Skill 一键发布到 GitHub 的标准化流程工具。自动完成：清洗 → 隔离 → 文档 → 提交 → 发布 → 清理。

## 功能

- **清洗**：只复制需要开源的文件（SKILL.md）到隔离目录，自动排除 `.claude/`、`.env`、Token 等敏感内容
- **隔离**：在独立的临时目录操作，不污染原项目
- **文档**：自动生成标准化的 README.md 和 MIT LICENSE
- **提交**：`git init` → `add` → `commit` 一键完成
- **发布**：通过 `gh repo create` 创建公开仓库并 push
- **清理**：发布完成后自动删除临时目录

## 环境要求

- [Claude Code](https://claude.ai/code) (AI 智能体环境)
- [Git](https://git-scm.com/) (≥ 2.0)
- [GitHub CLI](https://cli.github.com/) (`gh`，已登录账号)

## 安装说明

### 方式一：AI 智能体直接安装（推荐）

在 Claude Code 中输入：

> 请帮我装 https://github.com/Yi-Lings/open-source-publish 这个 skill

### 方式二：手动安装

```bash
git clone https://github.com/Yi-Lings/open-source-publish.git
cp open-source-publish/SKILL.md ~/.claude/skills/open-source-publish/
```

## 使用说明

### 首次发布新 Skill

在 Claude Code 中输入 `帮我开源 <skill-name> 这个 skill`，或包含以下关键词：
- "开源 / 发布到 GitHub / publish to GitHub / 帮我创建仓库"

Skill 会自动执行：
1. 将目标 Skill 的 SKILL.md 复制到桌面隔离目录
2. 生成 README.md（功能 → 环境要求 → 安装说明 → 使用说明 → License）
3. 生成 MIT LICENSE
4. `git init` → `git add` → `git commit`
5. `gh repo create --public --push`
6. 删除临时目录

### 迭代同步（Skill 更新后重新同步）

```bash
gh repo clone Yi-Lings/open-source-publish "/c/Users/Admin/Desktop/open-source-publish-update"
# 更新 SKILL.md 和 README.md（手动）

cd "/c/Users/Admin/Desktop/open-source-publish-update"
git config user.email "u@users.noreply.github.com"
git config user.name "Yi-Lings"
git add -A && git commit -m "sync: <变更摘要>"
git push

rm -rf "/c/Users/Admin/Desktop/open-source-publish-update"
```

## License

MIT
