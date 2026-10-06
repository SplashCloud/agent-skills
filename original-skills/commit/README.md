# commit

根据实际 diff 生成准确的提交信息，完成 `git commit` 后执行 `git push origin <当前分支名>`，显式推送当前分支到 `origin`。

## 成功示例

```text
Commit: feat(auth): reject expired refresh tokens
Push: origin/main updated
```

## 错误示例

```text
阶段: push
错误: The current branch has no upstream branch.
原因: 当前分支没有配置远端跟踪分支。
解决: git push origin <当前分支>
```

push 失败时不要再次创建 commit；先保留已成功的本地 commit，并根据错误处理认证、网络、upstream、分支保护或冲突问题。
