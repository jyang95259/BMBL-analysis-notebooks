# BMBL Skills

Agent-executable versions of the lab's analysis workflows. Where the Quarto site
(`site/workflows/`) documents a workflow for a **human to read**, a skill packages
the same knowledge for an **agent to run** — the minimal correct path, the exact
inputs, and the real traps — following the format Anthropic's Claude Science uses
for its scientific skills.

## Layout

```text
skills/
├── README.md               # this file
├── AUTHORING_GUIDE.md      # read this before writing a skill
├── SKILL_template.md       # copy this to start a new skill
└── <skill-id>/
    ├── SKILL.md            # the skill itself
    ├── references/         # optional: disclosed reference (deep params, appendices)
    └── functions.R         # optional: reusable R helpers sourced by SKILL.md
```

## Start a new skill

1. Read [`AUTHORING_GUIDE.md`](AUTHORING_GUIDE.md).
2. `cp SKILL_template.md <skill-id>/SKILL.md` and fill it in.
3. Run it on the workflow's example (or a toy subset) — the run is what produces a
   real `Output` table and real `Gotchas`.
4. Check it against the "Definition of done" list at the end of the guide, then PR.

## Why this exists

Claude Science ships general scientific skills; it does **not** have the lab's
specialised workflows — label transfer, inferCNV, the HPV / iPSC / stomach branches,
CellChat, BayesSpace, Giotto, SPOTlight, cellular neighbourhood. Distilling those
into skills turns the lab's institutional knowledge into a runnable, reviewable
skill pack. Each skill records `metadata.source_workflow` — the notebook it distils
— so the trail back to the original analysis is never lost.
