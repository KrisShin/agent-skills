# Close — self-audit, verification, summary

## 1. Self-audit

Run these yourself and report the real output. Do not claim a result you did not see.

| Check | How |
| --- | --- |
| Every claimed ticket has a commit | `git log <base>..HEAD --oneline` — count against the tickets you said were done |
| The suite is actually green now | run it, paste the output |
| The diff is the size you think it is | `git diff --stat <base>..HEAD` |
| **Every commit was green when it landed** | read each commit's `Verified:` trailer (`git log <base>..HEAD --format='%h %s%n%b'`) and check the count never dropped below the baseline. The current suite being green does not prove the intermediate commits were |
| Uncommitted work left behind | `git status --short` |

## 2. Ask about independent verification

Then **ask** — do not run it unasked, and do not silently skip asking:

> 自检结果如上。要不要派一个独立的 subagent 复核？它会自己读 diff、自己跑测试，不看我上面的推理，结论直接给你。我建议 [要/不要]，因为 [理由]。

Recommend **yes** when: the diff touches shared code, the ticket count is high, or any self-audit check came back ambiguous.

Recommend **no** when: the diff is small and well covered, and the falsification check already proved the tests bite. A second reader costs tokens and rarely finds what the three axes missed.

If yes, dispatch a `subagent` with **the diff range and the test command only** — not your summary, not your reasoning — and tell it to report findings directly to the user. Fold its findings in without re-ranking them against your own.

If you cannot ask a human (you are inside a subagent), follow [Human gates](../SKILL.md#human-gates).

## 3. Summary

Append a `## Close` section to `STATE.md`: what shipped, what was deliberately left out, what the next session needs to know. A handful of lines; point at the commits and the spec instead of restating them.

## 4. PR body

If the repo takes PRs — the summary as the smallest visual that makes the change clear, before/after evidence that it works, and a merge-danger call: one-way or two-way door, plus blast radius.

**"Takes PRs" means** `git remote -v` shows a remote, and that remote is a forge (GitHub/GitLab/etc.) rather than a bare path. No remote, or a local-only repo → skip this section and say so.

## 5. Lessons and promotions

See [retro.md](retro.md). Then set `stage: done` in `STATE.md`.
