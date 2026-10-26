---
name: ship
description: 端到端交付一条需求：盘问 → spec → 工单 → 测试先行 → 三轴评审 → 收尾与复盘。用 /ship 显式调用。
disable-model-invocation: true
---

# Ship

One sentence in, working code out. This skill is the **orchestrator**: it holds the path and the state, and delegates every discipline to the skill that owns it. It never re-implements grilling, TDD, or review.

Reply in the user's language. Keep the state file current: a session that dies mid-flight must be resumable from disk alone.

## Reading the invocation

This skill is user-invoked only, so it is absent from your skill catalog and the `skill` tool cannot load it — that is correct, not a fault. A subagent told to "load the ship skill" should read this file from disk instead and say so.

The message arrives as literal text, so read the argument after `/ship` as the goal:

- `/ship 我想要导出 CSV` → goal is "导出 CSV"; tier chosen automatically.
- `/ship S 修一下这个报错` → `S` / `M` / `L` as the first token forces the tier; the rest is the goal.
- `/ship resume` → list unfinished `.scratch/*/STATE.md`, continue the one the user picks.
- `/ship retro` → run [retro.md](references/retro.md) alone, no delivery.
- `/ship` with nothing after it → ask what to build, then continue.

Never assume the goal from the current conversation if the user typed something after `/ship` — the typed text wins.

## State

```
.scratch/<slug>/
├── STATE.md      # always: tier, stage, intent, baseline, next action
├── SPEC.md       # tier M and L
└── TICKETS.md    # tier L
.scratch/_lessons.md   # append-only, shared by every feature in this repo
```

`STATE.md` is not a progress board. **Record only what cannot be recomputed.** Progress, commit lists, and blast radius are derivable — `git log` holds the first two, a `grep` over the diff holds the third — so copies drift and can lie. What belongs here is intent: decisions, assumptions, deferrals, and the pre-change baseline. That is the only thing no command can reconstruct.

Templates: [STATE.md](references/STATE.md), [SPEC.md](references/SPEC.md), [TICKETS.md](references/TICKETS.md).

**First, check for an unfinished feature**: read any `.scratch/*/STATE.md` whose stage is not `done`. If one matches, resume at its recorded stage and say which.

## Stage 0 — Frame

**Preflight first.** Check `git rev-parse --show-toplevel` and the repo's test command (`package.json`, `Makefile`, `pyproject.toml`). No repo → say so and ask whether to `git init` here or work elsewhere; never create one silently. No test command → that is the first ticket, not a reason to skip tests.

Restate the goal in one sentence, pick the tier, say why in one line. The user may override; their call wins.

- **S** — one behaviour, one or two files, no interface or data-shape decision.
- **M** — several files, or any interface, schema, or module-boundary decision. Adds a spec.
- **L** — crosses modules, or will not fit one session. Adds tickets with blocking edges.

Write `STATE.md`. **Baseline before you touch anything**: run the suite once, record the pass count or the already-failing test names under `## Baseline`. This is the only thing that later tells "I broke it" from "it was already broken". Red suite → say so, get a decision.

**Done when** `STATE.md` exists with a tier, a recorded baseline, and the user has seen the restatement.

## Stage 1 — Grill (all tiers)

Load the `grilling` skill. Two changes here:

- The design tree is scoped to *this goal*. Future work is parked in `STATE.md` under "Later", not asked about.
- Completion is not "we talked". It is the artifact for your tier: a confirmed one-paragraph plan (S), or a written `SPEC.md` the user has read (M/L).

Facts are yours to find. Decisions are the user's; ask and wait.

**Done when** the user explicitly confirms. No code before this. If they say "just do it" or "做完" — or anything else that hands you the decisions — record that as the confirmation, and write down the assumptions you are taking so they can veto them later.

## Stage 2 — Spec (M, L)

Write `SPEC.md` from the confirmed conversation — do not re-interview. The sections that carry the weight: exhaustive numbered user stories (scope hides there), implementation decisions as modules and interfaces (no file paths or snippets; they go stale), testing decisions naming the seams (one is better than three), and an explicit out-of-scope list.

Present it, then ask for approval.

**Done when** the user approves, or names changes and you apply them.

## Stage 3 — Tickets (L only)

Break the spec into **tracer-bullet vertical slices**: each cuts through every layer, is demoable alone, fits one fresh context window, and declares what blocks it.

Wide mechanical refactors are the exception: sequence them **expand → migrate in batches → contract**, batches blocked by the expand, contract blocked by every batch. Never force one into a tracer bullet.

Write `TICKETS.md`, confirm granularity and edges.

**Done when** the user approves the breakdown.

## Stage 4 — Build (all tiers)

Work the **frontier**: any ticket whose blockers are done. For S and M there is one implicit ticket.

Per ticket:

1. **Find who depends on what you are about to change, and whether each of them is tested.** Grep for the call sites of every function, module, or type the ticket touches — exported names, imports, config keys, DB columns, routes. For **each** call site outside the diff, say whether a test covers it. Report the list in the conversation; do not write it into `STATE.md`, because the Regression axis recomputes it and two copies drift.

   **An untested caller is pinned before you change the shared code, not after.** If a caller has no test, write a **characterization test** first: one that asserts what it does today, run it green, then change the code. It does not judge whether that behaviour is right; it records it, so the change cannot silently rewrite it.

   Commit it **on its own, before the change** — that way `git log` proves the order, which a combined commit cannot. When the change makes it go red, that is the signal it exists for: update its expectations to the new contract, keep it, and say in the commit body that it was pinned to the old value and moved. Do not delete it — deleting reopens the edge you just closed.

   Skipping this is allowed only if the user says so; the reason goes in `STATE.md` under `## Later`.

   This step is the point of the whole path: review happens after the code exists, and a regression found there has already been written, committed, and possibly built upon.

2. Load the `tdd` skill. Agree the seam first if the spec has not settled it.
3. Red → green in vertical slices, one seam at a time.
4. Commit that ticket alone: title as subject, the decision or hypothesis in the body, and a `Verified:` trailer with the exact command and result — `Verified: npm test — 6 passed, 0 failed`. That makes `git log` the evidence chain, and it travels with the repo.
5. Update `STATE.md`: stage and the single next action. Not a checklist.

If a test cannot be written at a correct seam, stop and report it. That is an architecture finding, not permission to skip the test.

**Evidence, not assertion.** At every gate, paste the command and its real output. "Tests pass" is not evidence; `npm test → 6 passed` is. If you cannot paste it, you did not run it.

**Done when** every ticket is committed and the full suite is green.

## Stage 5 — Review

Three axes — Standards, Spec, Regression — plus the falsification step. Full instructions, including the smell baseline: [review.md](references/review.md).

Each axis as its own `subagent` so none pollutes another's context. **When you cannot delegate** — you are already a subagent at the depth limit — run them sequentially in one context and **mark the report as self-reviewed**. That is a real loss of independence, not a footnote: the same context that wrote the code is judging it, so lower your confidence and lean toward recommending the independent check at Stage 6 rather than away from it.

Report the axes **side by side**. Never merge or re-rank them: a change can pass Standards and Spec while quietly breaking a caller.

Then ask, per finding: fix now, or file it? "Fix now" returns to Stage 4.

**Done when** all three axes are reported, falsification has run or been explicitly skipped, and the user has decided on each finding.

## Stage 6 — Close

Self-audit, ask about independent verification, write the summary and PR body, then the lessons. Full instructions: [close.md](references/close.md).

**Done when** the self-audit is reported, the verification question has been asked and answered, `STATE.md` says done, the lessons are written, and every promotion proposal has an answer.

## Entering and leaving

Opt-in by construction: `disable-model-invocation: true` keeps this out of the model-facing catalog, so the only way in is the user typing `/ship`. Never start it on your own initiative, and never suggest it for a one-line edit, a question, a review, or a bug you can fix in one pass.

Other entries:

- **`/grilling`** or a plain "帮我 grill 一下" — that skill only. No `.scratch/`, no state, no gates.
- **`/ship retro`** — record a lesson without a delivery.
- **Nothing** — normal work. No process.

**Leaving**: say "停" at any gate. Set `stage: abandoned`, add one line under `## Close` saying why, stop. Keep the directory — an abandoned feature records a decision, and resuming later costs nothing. Never delete `.scratch/<slug>/` on your own initiative.

## Human gates

Every "Done when" in this path is a gate where the user decides. They are, in order: a red baseline at Stage 0 (continue or stop), the goal restatement at Stage 0, the plan or spec confirmation at Stage 1, spec approval at Stage 2, the ticket breakdown at Stage 3, the per-finding fix-or-file decision at Stage 5, and at Stage 6 the independent-verification question and each promotion proposal.

Two separate questions follow, and conflating them is a bug: **whether you may continue** (this section) and **how you record a decision you could not ask about** (next section).

### May you continue?

**Inside a subagent, M and L stop before Stage 2.** You cannot get a spec or ticket breakdown approved, and a spec nobody approved is just a document — building on it throws away the gate it exists for. Write the `SPEC.md` (or `TICKETS.md`), then stop and hand it back to the caller with the questions that need answers. S may run through on a "just do it" hand-off, because its confirmation is the user's own instruction.

A caller may explicitly override this — "run the whole thing to Stage 6" — and then the override wins, as it does everywhere. Say in your report that the spec went unapproved, so the caller knows what they are accepting.

### Recording a decision you could not ask about

Inside a subagent `ask_user_question` fails. Do not silently pick an answer, and do not drop the question:

1. Take the recommended option, and record that you took it **and why** in `STATE.md`: `## Assumptions` for a decision, `**Verify**` for the verification question, the Close section for anything left open.
2. Put the exact question, your recommendation, and the reason into your report to the caller, marked **open, needs the user**.
3. Never mark a stage done on the strength of a decision you made for the user without surfacing it.
4. If the recommended option is itself unavailable — you are at the delegation limit and cannot dispatch the verification subagent — say so, do the next best thing, and report that too. A recommendation you could not carry out is still an open question.

An unanswered question that is written down is recoverable; one that is dropped is not.

## Rules that hold across every stage

- **State lives on disk, not in the conversation.** Update it before you stop, never after.
- **A gate is a stop, not a checkpoint.** At every "Done when", say what you are about to do and wait.
- **Never commit red.** Compare against the recorded baseline, not your memory of it.
- **The user's override beats the tier.** "Skip the spec" → skip it, record the assumption.
