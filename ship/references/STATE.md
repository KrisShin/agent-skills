# <Goal in one line>

- **Slug**: `<slug>`
- **Tier**: `S | M | L` — <one line why>
- **Stage**: `frame | grill | spec | tickets | build | review | close | done | abandoned`
- **Started**: <YYYY-MM-DD>
- **Base**: `<sha the work started from>` — the diff range is `<base>..HEAD`

## Goal

<One paragraph. The user's words, sharpened. What is true after this ships that is not true now.>

## Baseline

<!-- Recorded at Stage 0, before any edit. This is the one fact no command can reconstruct afterwards: the pre-change state of the suite. Progress and commit lists are deliberately absent — git already holds them. -->

- **Command**: `<the repo's test command>`
- **Result**: <pass count, or the names of already-failing tests>
- **Recorded**: <YYYY-MM-DD HH:MM>

## Decisions

<!-- Settled decisions only, one line each, newest last. A decision that changes later gets struck through, not deleted. This is intent, and intent is not in the code. -->

- <decision> — <why, one clause>

## Assumptions

<!-- Taken when the user said "just do it" or was unavailable. Each one is a thing they can veto later. A decision you had to make without asking goes here too, marked OPEN. -->

- <assumption>
- **OPEN — needs the user**: <the decision you took on their behalf> — you would have asked: <question>; recommended <option> because <reason>.

## Next action

<!-- One line. What the next session does first. Not a checklist — the checklist is `git log`. -->

<the single next step>

## Later

<!-- In-scope-adjacent, deliberately deferred. Not "out of scope" — that lives in SPEC.md. -->

- <thing>

## Close

<!-- Filled at Stage 6, or when abandoned. -->

- **Shipped**: <one or two lines>
- **Left out**: <one line>
- **Next session needs**: <one line>
- **Verify**: <yes/no> — <reason>. If this could not be asked, write `OPEN — needs the user` here with the exact question and your recommendation.
