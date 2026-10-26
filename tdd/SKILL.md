---
name: tdd
description: Test-driven development with a red-green-refactor loop over agreed seams. Use when building a feature or fixing a bug test-first, when the user mentions red-green-refactor, or when a change needs tests.
---

# TDD

The loop is red → green. This skill is what makes that loop produce tests worth keeping.

## Seams

A **seam** is the public boundary you test at: the interface where you observe behavior without reaching inside. Tests live at seams, never against internals.

**Agree the seams before writing any test.** Write down the seam under test and confirm it with the user; no test at an unconfirmed seam. You cannot test everything, so agreeing seams first puts the testing effort on critical paths instead of every edge case.

## What a good test is

A test reads like a specification: "user can check out with a valid cart" survives a rewrite of the internals. Code may change entirely; the test should not.

## Anti-patterns

- **Implementation-coupled**: mocking internal collaborators, testing private methods, or asserting through a side channel (reading the database instead of the interface). The tell: the test breaks on a refactor while the behavior is unchanged.
- **Tautological**: the assertion recomputes the expected value the way the code does (`expect(add(a, b)).toBe(a + b)`, a snapshot derived by hand the same way, a constant asserted against itself). Expected values come from an independent source of truth: a known-good literal, a worked example, the spec.
- **Horizontal slicing**: all tests first, then all implementation. Those tests encode imagined behavior: the shape of things rather than what a user does. Work in **vertical slices**: one test → one implementation → repeat. Each test is a **tracer bullet** that responds to what the last cycle taught you.

## The loop

- **Red before green.** Write the failing test, then only enough code to pass it. No speculative features.
- **One slice at a time**: one seam, one test, one minimal implementation.
- **Refactoring is not part of the loop.** It belongs to review, after the suite is green.

Run the single test file each cycle and the full suite once at the end. If the suite was already red before your first edit, say so instead of fixing unrelated tests silently.

## When a skill calls you

An orchestrator (e.g. `ship`) may hand you one ticket at a time and expect the work committed when the ticket is green. Finish the whole ticket — every acceptance criterion — before committing, and keep the commit to that ticket alone. Do not reach into the next ticket because the code is "right there": each ticket is sized to be reviewed and reverted on its own.

If the ticket cannot get a test at a correct seam, stop and report that as an architecture finding. That is the one outcome that legitimately ends a ticket without a green test.
