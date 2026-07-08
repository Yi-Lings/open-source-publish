# open-source-publish

将 Claude Code Skill / 脚本 / 小型项目一键发布到 GitHub 的标准化流程工具。自动判断类型并适配清洗规则与 README 模板。

## 功能

- **类型自判**：根据路径和文件特征自动判断 Skill / 脚本 / 小型项目
- **清洗**：按类型规则复制到隔离目录，自动排除 `.claude/`、`.env`、Token 等敏感内容
- **隔离**：在独立的临时目录操作，不污染原项目
- **文档**：按类型生成对应模板的 README.md 和 MIT LICENSE
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

### 发布 Skill

在 Claude Code 中输入 `帮我开源 <skill-name> 这个 skill`：
1. 自动识别为 **Skill** 类型
2. 只复制 SKILL.md 到隔离目录
3. 生成 README.md + LICENSE
4. `git init` → `add` → `commit`
5. `gh repo create --public --push`
6. 清理临时目录

### 发布脚本（.py / .js / .sh 等）

在 Claude Code 中输入 `帮我发布这个脚本` 或 `发布 <path/to/script.py>`：
1. 自动识别为 **脚本** 类型
2. 复制主脚本 + README.md + LICENSE
3. README 适配命令行参数说明和使用示例

### 发布小型项目

在 Claude Code 中输入 `帮我开源这个项目` 或 `发布 <path/to/project/>`：
1. 自动识别为 **项目** 类型
2. 保留完整源码目录结构
3. 自动排除构建产物和敏感文件

### 迭代同步（更新后重新同步）

```bash
gh repo clone Yi-Lings/open-source-publish "/c/Users/Admin/Desktop/open-source-publish-update"
# 更新文件

cd "/c/Users/Admin/Desktop/open-source-publish-update"
git config user.email "u@users.noreply.github.com"
git config user.name "Yi-Lings"
git add -A && git commit -m "sync: <变更摘要>"
git push

rm -rf "/c/Users/Admin/Desktop/open-source-publish-update"
```

## License

MIT
