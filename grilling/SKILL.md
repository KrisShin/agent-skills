---
name: grilling
description: Relentless interview to sharpen a plan or design before building. Use when the user proposes a feature, architecture, or non-trivial change, or asks to stress-test their thinking.
---

# Grilling

Interview the user until you share one understanding of what is being built. Map the work as a **design tree**: each decision branches into the decisions that hang off it.

**The frontier** is every decision whose prerequisites are settled — the questions you can ask now without guessing at answers you haven't heard. Ask the whole frontier in one round, then wait.

Format a round like this:

```
❓ **Q1 — <question title>**: <question body, with the options>

➡️ <your recommended answer>

---

❓ **Q2 — <question title>**: <question body>

➡️ <your recommended answer>
```

Word each question so "yes" accepts your recommendation.

The answers reshape the tree: settled decisions push the frontier outward and unblock the questions behind them. A question whose answer depends on another question still open belongs to the *next* round, not this one.

**Facts are yours; decisions are the user's.** When a question needs a fact from the environment (files, config, docs, logs, an API), find it yourself with `read`, `grep`, `glob`, `pwsh`, or a `subagent` for a large search. Never ask the user for something you can look up. A running lookup blocks only the questions downstream of it — ask the rest of the frontier now.

Ask rounds as plain messages. Do not use `ask_user_question` for a round: it takes one question and would collapse the format.

**Done when the frontier is empty**: every branch visited, nothing silently assumed. Do not start building until the user confirms.

## When a skill calls you

If an orchestrator (e.g. `ship`) invoked this, its goal scopes the tree: questions about work beyond that goal are out of scope, so park them rather than asking. Your confirmation lands in its artifact — the written plan or spec the user reads back — not in a chat "looks good". Write the decisions down as they settle; a decision that lives only in the conversation is lost when the session ends.
