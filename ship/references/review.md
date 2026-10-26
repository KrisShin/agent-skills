# Review — three axes

Run each axis as its own `subagent` so none pollutes another's context. Inside a subagent that cannot delegate deeper, run them sequentially but still record them separately, and say that isolation was not available.

## Standards

Does the diff follow this repo's documented conventions?

Read the repo's own sources first: `AGENTS.md`, `CONTRIBUTING.md`, `CODING_STANDARDS.md`, and whatever the lint config enforces. A documented repo standard always overrides the baseline below; skip anything tooling already enforces.

Then the smell baseline, which applies even when a repo documents nothing. Each reads *what it is* → *how to fix*:

- **Mysterious Name** — a name that doesn't reveal what it does or holds. → rename; if no honest name comes, the design is murky.
- **Duplicated Code** — the same logic shape in more than one hunk or file. → extract the shape, call it from both.
- **Feature Envy** — a method reaching into another object's data more than its own. → move it onto the data it envies.
- **Data Clumps** — the same few fields travelling together. → bundle them into one type.
- **Primitive Obsession** — a primitive standing in for a domain concept. → give the concept a small type.
- **Repeated Switches** — the same `switch`/`if`-cascade on the same type, recurring. → polymorphism, or one shared map.
- **Shotgun Surgery** — one logical change forcing scattered edits. → gather what changes together.
- **Divergent Change** — one module edited for several unrelated reasons. → split by reason.
- **Speculative Generality** — abstraction for needs the spec doesn't have. → delete it; inline back.
- **Message Chains** — long `a.b().c().d()` navigation. → hide the walk behind one method.
- **Middle Man** — a class or function that mostly delegates. → cut it, call the target direct.
- **Refused Bequest** — a subclass ignoring most of what it inherits. → composition instead.

Every baseline hit is a **judgement call** ("possible Feature Envy"), never a hard violation. Only a documented repo standard can be a hard violation.

## Spec

Does the diff implement the spec, no more and no less?

Report: requirements the spec asked for that are missing or partial; behaviour in the diff that wasn't asked for (scope creep); requirements that look implemented but are wrong. Quote the source line for each finding — the spec's, or for tier S (which has no `SPEC.md`) the `## Goal` line in `STATE.md`.

## Regression

What existing behaviour could this diff change, and what is the evidence that it does not?

Compute the blast radius **now**, from the diff itself — `git diff <base>..HEAD`, plus a grep for each changed symbol's call sites. Do not trust a note from earlier; two copies drift.

For every symbol with call sites outside the diff:

1. Name each caller.
2. Say whether it is covered by a test that ran green.
3. Check the unstated contracts: error modes, return shapes, ordering, nullability, defaults, and side effects a caller might rely on.

Then re-run the full suite and compare against the **recorded baseline** in `STATE.md`. Any test that was green before and is red now is a blocker, no discussion.

An untested caller is an **unprotected edge**. Stage 4 should already have pinned it with a characterization test. If it did not, that is a finding: say which caller, why it was missed, and pin it now before the change ships. "Recorded but unpinned" is only acceptable when the user explicitly chose that, and the reason is in `## Later`.

## Falsify the tests

Pick the most important new test, break the production code it asserts on, and confirm that test goes red. Restore, confirm green. Run this for every new test that carries real behaviour — the decision tree below applies per mutation.

A test that cannot fail is decoration; this is the only cheap proof it tests anything. **Judge the mutation first, then the test** — a bad mutation produces a confident wrong answer.

**Is the mutation valid?** It must still parse, still run, and actually change behaviour on at least one input. A syntax error, a broken escape, or a semantically equivalent rewrite proves nothing — redo it.

**Prove equivalence, never assert it.** Before calling a rewrite equivalent, run both versions over the input domain that matters (integers, fractions, `NaN`, `±Infinity`, `0`, `-0`, boundaries) and diff the outputs. `n !== Math.trunc(n)` looks equivalent to `!Number.isInteger(n)` and is not: `Math.trunc(Infinity) === Infinity`, so `Infinity` slips through. A guessed equivalence silently discards a real gap.

**Old tests going red is not a defect.** If the mutated line was already covered, the old tests catch it too — that is evidence the mutation is valid. Only the *new* test's verdict decides whether the new test bites.

Then read the result, per mutation:

- **New test red** → it bites. Done, restore the code.
- **New test green, old tests red** → the mutation is valid and observable, but the new test does not cover the behaviour you mutated. That is a **coverage gap, not an invalid mutation**: write the test that covers it, or record the behaviour as out of scope. Do not "redo the mutation".
- **Nothing red anywhere** → the mutation was unobservable on every existing input. Before calling the test weak, prove the line is reachable and observable at all (a one-line probe). Then decide what the line is for:
  - it carries behaviour a requirement needs → write the test that pins it, re-run the mutation;
  - no requirement needs it → it is Speculative Generality: **delete the line rather than pinning it**, and say which you chose.
  - it is neither (a diagnostic message's wording, for instance) → leave it, and record why it is deliberately unpinned.

Skip only when the diff adds no tests, and say so.

## Reporting

Report all three **side by side**. Do not merge, rank, or average them: a change can pass Standards and Spec while quietly breaking a caller, and that is exactly the failure a merged report hides.

End with one line per axis: finding count, and the worst issue within that axis. Do not pick a winner across axes.

Then ask, per finding: fix now, or file it?

- **Fix now** → return to Stage 4 for that item.
- **File it** → write one line under `## Later` in `STATE.md`: what it is, and why it is not being fixed in this pass. Not a ticket, not a TODO comment — `Later` is the one place deferred work is allowed to live, and it survives the session.

If you cannot ask a human (you are inside a subagent), follow [Human gates](../SKILL.md#human-gates).
