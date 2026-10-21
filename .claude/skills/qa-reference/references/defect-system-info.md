---
id: ref-defect-system-info
---
# Defect System Info Reference

> **Read on demand** | Moved out of `/qa-defect` | Part of the `qa-reference` skill

Read this when collecting runtime and dependency versions for a defect report's `SystemInfo` and `FoundIn`. The stack-neutral commands (`git`, `uname`) stay in `/qa-defect`; this file holds the commands per stack, so another stack can be added beside Node.

---

## Node

If the project is Node:

```bash
# Runtime & tooling versions
node --version
npm --version
npx next --version 2>/dev/null || true

# Key dependency versions from package.json
python3 -c "
import json
d = json.load(open('package.json'))
deps = {**d.get('dependencies', {}), **d.get('devDependencies', {})}
keys = ['next', 'react', 'eslint', 'prettier', 'husky', 'lint-staged',
        '@commitlint/cli', 'typescript', 'playwright', 'vitest']
for k in keys:
    if k in deps: print(k, '=', deps[k])
"
```
