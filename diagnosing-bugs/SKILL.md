---
name: diagnosing-bugs
description: Disciplined diagnosis loop for hard bugs and performance regressions, gated on a feedback loop that goes red on the bug. Use when the user says diagnose or debug this, or reports something broken, throwing, failing, or slow.
---

# Diagnosing bugs

Skip a phase only when you can say why.

**When a workflow skill (`ship`) hands you a failing test mid-build**, you are in Phase 2 already: the failing test is the loop. Do not build a second one. Minimise, then continue from Phase 3. Report back the hypothesis you land on, because the orchestrator needs it for the commit message.

**Redact every secret** in anything you show: write `<REDACTED>`. Keep credentials in the environment rather than in the command you print, and quote only the lines of an artifact that carry the signal. If the redacted output is too little to diagnose, say so and ask.

## Phase 1 — Build a feedback loop

This is the skill; everything else is mechanical. A **tight** loop that goes red on *this* bug means you will find the cause. Without one, staring at code will not save you. Be aggressive; refuse to give up early.

Ways in, roughly in order:

1. A failing test at whatever seam reaches the bug.
2. A curl / HTTP script against a running dev server.
3. A CLI call on fixture input, diffing stdout against a known-good snapshot.
4. A headless browser script asserting on DOM, console, or network.
5. Replaying a captured trace (saved request, payload, event log) through the code path.
6. A throwaway harness: one call that exercises the bug with minimal deps.
7. A property / fuzz loop, when the bug is "sometimes wrong".
8. A bisection harness you can drive with `git bisect run`.
9. A differential loop: the same input through old and new, diff the outputs.

**Tighten it.** Faster (cache setup, narrow the test), sharper (assert the exact symptom, not "didn't crash"), more deterministic (pin time, seed RNG, isolate the filesystem, freeze the network). A 30-second flaky loop is barely better than none; a 2-second deterministic one is a superpower.

**Flaky bugs**: aim for a higher reproduction rate, not a clean repro. Loop it 100×, parallelise, stress it. A 50% flake is debuggable; 1% is not.

Long-running loops go in the background (`run_in_background`) so you keep working; collect them with `job_output`.

**Done when** you can name one command you have already run and shown (redacted), and it is:

- [ ] **Red-capable**: drives the bug's code path and asserts the user's exact symptom.
- [ ] **Deterministic**: same verdict every run.
- [ ] **Fast**: seconds, not minutes.
- [ ] **Agent-runnable**: no human needed mid-loop.

If you catch yourself reading code to form a theory before that command exists, stop. No red command, no Phase 2.

## Phase 2 — Reproduce and minimise

Run the loop. Confirm it shows the failure the **user** reported, not a nearby one: wrong bug, wrong fix.

Then shrink it to the smallest scenario that still goes red. Cut inputs, callers, config, data, and steps one at a time, re-running after each cut. Done when every remaining element is load-bearing: removing any one turns it green. The minimal repro shrinks the hypothesis space and becomes the regression test.

## Phase 3 — Hypothesise

Write **3–5 ranked hypotheses** before testing any of them. A single hypothesis anchors on the first plausible idea.

Each must be falsifiable: "If X is the cause, changing Y makes the bug disappear / changing Z makes it worse." No prediction means it is a vibe; sharpen or discard it.

Show the ranked list to the user before testing; they often re-rank it instantly. Do not block on it.

## Phase 4 — Instrument

Every probe maps to a prediction from Phase 3. Change one variable at a time.

Prefer a debugger or REPL over logs; then targeted logs at the boundaries that distinguish hypotheses. Never "log everything and grep".

**Tag every debug log** with a unique prefix such as `[DEBUG-a4f2]`; cleanup then becomes one grep.

**Performance regressions**: logs are usually wrong here. Establish a baseline measurement first (timing harness, profiler, query plan), then bisect from it.

## Phase 5 — Fix and lock it down

Write the regression test before the fix, but only at a **correct seam**: one that exercises the bug pattern as it occurs at the call site. A test too shallow to reproduce the trigger gives false confidence.

If no correct seam exists, that is itself the finding: report that the architecture prevents locking this bug down.

Then watch it fail, apply the fix, watch it pass, and re-run the Phase 1 loop against the original un-minimised scenario.

## Phase 6 — Clean up

- [ ] The original repro no longer reproduces
- [ ] The regression test passes, or the missing seam is documented
- [ ] Every `[DEBUG-...]` prefix greps to nothing
- [ ] Throwaway harnesses deleted
- [ ] The commit or PR message names the hypothesis that turned out right
