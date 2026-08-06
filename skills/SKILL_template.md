---
# Copy this file to skills/<skill-id>/SKILL.md and fill it in.
# Every field is required unless marked optional. Delete every <...> and every
# HTML comment before you commit. Read AUTHORING_GUIDE.md first.

name: <skill-id>
# ^ kebab-case, identical to this skill's folder name. This is the *leading word*
#   the agent, your prompts, and your docs all share. e.g. scrna-seurat-preprocess,
#   scrna-label-transfer, spatial-bayesspace.

description: >
  <One sentence: the method + what it produces.> Reach for this to
  <trigger branch 1>, <trigger branch 2>, and <trigger branch 3>. For
  <adjacent task> use the <sibling-skill> skill instead.
# ^ MODEL-FACING TRIGGER. Front-load the method name. Give one trigger per
#   genuinely distinct branch — synonyms for the same branch are duplication.
#   Name the sibling skill for the adjacent task so the agent routes AWAY when
#   this isn't the fit. Triggers only — do not restate the body here.

license: <MIT | lab-internal | CC-BY-4.0>
requirements: [<r-4.3>, <seurat-5>, <bioc-3.18>]   # what the environment must provide
metadata:
  display-name: <Human Readable Name>
  source_workflow: <RepoDir_this_was_distilled_from>   # provenance: the notebook this distills
---

# <Human Readable Name> — <one-line what-it-does>

<!-- ORIENTATION. 3-5 sentences. State the method and its canonical package/
citation, the EXACT input object/format it expects, and the exact thing it emits.
A reader who stops here should know whether this is the right tool. -->

<Orientation paragraph.>

## When to use it

<!-- ROUTING. Prose, not a list. "Use this when <condition>." Then the boundary:
"For <neighbouring task> use <other-skill> — it <one-line why>." This is what
stops the agent reaching for the wrong skill. -->

## Inputs

- **Object / format:** <e.g. a merged Seurat v5 object with raw integer counts in the `RNA` assay `counts` layer; or 10x matrices under `data/<sample>/`>
- **Required upstream:** <what must have run first — a prior skill, a QC step, a file on disk>
- **Example data:** <path to the committed example or toy subset this skill runs on>

## How to run

<!-- The MINIMAL CORRECT PATH, as runnable R. Copy-pasteable. Use the current API
spelling, and pin the versions that matter. Comment the lines where a wrong
choice silently corrupts the result (e.g. "# counts BEFORE normalize"). -->

```r
suppressPackageStartupMessages(library(Seurat))
# ...
```

## Output

<!-- A reviewer traces every claim the skill makes back to a row here. Name the
concrete objects/files produced, not a prose summary. -->

| Key / object | What it holds |
|---|---|
| `<obj@meta.data$...>` | <...> |
| `<file written>` | <...> |

## Running on OSC

<!-- Only if a step is heavy enough to need the cluster. Module loads + an SBATCH
template. If the laptop/login node is fine, say so in one line and delete the
code block. -->

```bash
module load R/4.3.0
# sbatch template ...
```

## Gotchas

<!-- HARD RULE: every row is something you HIT by RUNNING the skill, with the real
error text or the real silently-wrong behaviour. An imagined gotcha is worse than
none. If you have hit nothing yet, delete this whole section rather than invent a
row — see AUTHORING_GUIDE.md, "The gotcha rule". -->

| Gotcha | What happens / fix |
|---|---|
| <exact error string OR silent-wrong behaviour> | <what triggers it → the fix> |

## Troubleshooting

| Symptom | Fix |
|---|---|
| <observable symptom> | <fix> |

---

**Next**: <the skill or step that naturally chains after this one>
