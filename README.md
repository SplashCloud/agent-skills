# Agent Skills

用于 Codex、Claude Code、omp 等 coding agent 的可迁移 skills。`original-skills/` 只保存平台无关的核心内容；`install.sh` 负责生成目标 agent 需要的 `SKILL.md` 并安装到项目或全局目录。

## 当前 skill

### 工作流

- `tldr`：让回答优先给结论，保持简洁、聚焦、可执行。
- `repo-explorer`：修改前分析目录、入口、调用关系和项目约定。
- `implementation-plan`：把需求拆成文件、接口、调用方、测试和验证步骤。
- `code-review`：检查正确性、边界、安全、兼容性和维护成本。
- `test-engineer`：设计覆盖行为、边界、错误路径和状态转换的测试。
- `debugger`：通过复现和证据定位根因，并验证修复。

### 质量与安全

- `security-review`：检查认证、授权、注入、敏感数据和供应链风险。
- `error-handling`：设计错误分类、传播、重试、超时和用户可见契约。
- `refactor-safely`：迁移定义、调用方、测试和兼容路径，避免隐性破坏。
- `dependency-audit`：评估依赖的必要性、维护状态、许可证和供应链风险。
- `performance-review`：基于基线和 profiling 进行性能分析与验证。
- `concurrency-review`：检查竞态、死锁、取消、泄漏、背压和幂等性。

### 文档与协作

- `documentation`：同步 README、API、配置、示例和迁移文档。
- `changelog`：记录用户可见的新增、修复、变更和破坏性变化。
- `commit`：根据实际变更生成提交信息，执行 `git commit` 并直接推送到远端。
- `pr-description`：整理背景、方案、影响、验证、风险和回滚信息。
- `release-checklist`：检查构建、迁移、观测、发布顺序和回滚。
- `decision-record`：记录技术决策的背景、选项、取舍和后果。

### 约束型

- `scope-control`：限制修改范围，避免擅自扩展任务。
- `evidence-first`：区分事实和推断，并要求具体验证证据。
- `minimal-diff`：保持变更小而完整，避免无关重排和重构。

每个 skill 的平台无关内容位于 `original-skills/<name>/`，包含：

- `description.txt`：显示在 coding agent skill 列表中的简洁简介
- `instructions.md`：核心行为规则
- `README.md` 或 `examples.md`：使用说明和示例

安装器会把 `description.txt` 写入生成的 `SKILL.md` front matter，因此不同 skill 会显示各自的用途，而不是通用占位简介。

## 一键安装

在仓库根目录运行。省略 `--skill` 时会安装全部 skill；目标位置已经存在的 skill 默认直接跳过。

```bash
# 安装全部 skill 到当前项目，供 Codex 使用
./install.sh --agent codex --scope project

# 安装全部 skill 到全局 Claude Code 环境
./install.sh --agent claude --scope global

# 只安装一个 skill
./install.sh --skill code-review --agent codex --scope project

# 也可以逐个安装多个 skill
./install.sh --skill tldr --agent omp --scope project
./install.sh --skill evidence-first --agent omp --scope project

# 安装 commit skill；它会在生成信息后执行 git commit 和 git push
./install.sh --skill commit --agent codex --scope project
```

默认安装路径：

| Agent | project | global |
| --- | --- | --- |
| Codex | `<project>/.agents/skills/<name>/SKILL.md` | `${CODEX_HOME:-~/.codex}/skills/<name>/SKILL.md` |
| Claude Code | `<project>/.claude/skills/<name>/SKILL.md` | `${CLAUDE_CONFIG_DIR:-~/.claude}/skills/<name>/SKILL.md` |
| omp | `<project>/.agents/skills/<name>/SKILL.md` | `~/.agents/skills/<name>/SKILL.md` |

`project` 默认使用当前目录，也可以指定：

```bash
./install.sh --skill repo-explorer --agent codex --scope project --project-dir /path/to/project
```

安装器默认跳过已经存在的 skill，并在最后输出安装/跳过数量。核心内容更新后，如果需要刷新已安装版本，显式使用 `--force`：

```bash
# 刷新全部 skill
./install.sh --agent codex --scope global --force

# 只刷新一个 skill
./install.sh --skill tldr --agent claude --scope global --force
```

`commit` skill 会检查实际 diff，生成提交信息，执行 `git commit`，然后执行 `git push origin <当前分支名>` 显式推送到 `origin`。它会先通过 `git branch --show-current` 获取当前分支，不依赖 upstream 配置。遇到检查、commit 或 push 错误时，会保留关键错误输出并说明失败阶段、原因和解决方案；不会使用 `git push --force` 或绕过 hooks。

原来的 `commit-message` skill 已更名为 `commit`。已有旧目录不会被自动删除，需要手动移除旧安装后重新安装：

```bash
rm -rf <skill-root>/commit-message
./install.sh --skill commit --agent codex --scope project --force
```

## 设计约束

- `original-skills/` 不包含 Codex、Claude Code、omp 的平台元数据或路径约定；`description.txt` 是 skill 自身的功能简介。
- 安装器在安装时读取 `description.txt`，生成带有对应简介的 agent-specific `SKILL.md`。
- Codex 项目 skill 使用 `.agents/skills`；全局路径遵循 `CODEX_HOME`。
- omp 项目 skill 使用 `.agents/skills`；全局路径为 `~/.agents/skills`。
- Claude Code 项目和全局 skill 分别使用 `.claude/skills` 与 `CLAUDE_CONFIG_DIR`（未设置时为 `~/.claude`）。
