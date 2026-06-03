---
description: Create a conventional commit
---
Create a git commit with a conventional commit message.

Rules:
- Format: `<type>: <description>`
- Types: feat, fix, docs, refactor, test, chore, style, perf
- Write in English
- Be detailed and descriptive
- Use bullet points for clarity and structure
- First line is a general summary, followed by bullet points for detailed changes

1. Run `git status` and `git diff` to see staged and unstaged changes
2. Run `git log --oneline -5` to see recent commit style
3. Stage relevant files
4. Create the commit with a properly formatted conventional commit message
5. Run `git status` to verify success
