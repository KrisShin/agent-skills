# <Feature name> — tickets

One ticket per section, numbered in dependency order. A ticket is a **tracer bullet**: it cuts a narrow but complete path through every layer, is demoable on its own, and fits one fresh context window.

## 01 — <ticket title>

**What it delivers**: <the end-to-end behaviour this makes work, from the user's perspective. Not a layer-by-layer list.>

**Blocked by**: None (can start immediately)

**Seam**: <the public boundary this ticket's tests live at>

- [ ] <acceptance criterion>
- [ ] <acceptance criterion>

## 02 — <ticket title>

**What it delivers**: <...>

**Blocked by**: 01

**Seam**: <...>

- [ ] <acceptance criterion>

<!-- Wide refactor? Do not force it into a tracer bullet. Write it as expand → migrate batches → contract, with each batch blocked by the expand and the contract blocked by every batch. -->
