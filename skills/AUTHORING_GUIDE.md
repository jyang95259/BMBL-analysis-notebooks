# Authoring a BMBL Skill

How to turn a lab workflow into a skill an agent can *run*, not just a tutorial a
human can *read*. Read this once before you fill in `SKILL_template.md`.

> This guide distils Anthropic's `writing-great-skills` principles into the BMBL
> (R / Seurat / OSC) setting. Where it says "predictability", "leading word",
> "gotcha", "progressive disclosure" — those are the load-bearing ideas; the rest
> is scaffolding.

---

## 1. What a skill is, and why it is not the Quarto page

The Quarto workflow pages you built are written for a **human** reading a tutorial.
A skill is written for an **agent loading a procedure at runtime**. Same knowledge,
different reader — and the different reader changes almost every line.

The root virtue of a skill is **predictability**: the skill makes the agent take
the *same process* every run. Not the same output — the same *way of working*. Every
rule below is a lever on that one goal. When you are unsure whether a sentence
belongs, ask: *does this make the agent's process more repeatable?* If not, cut it.

| | Quarto page | Skill |
|---|---|---|
| Reader | human | agent |
| "When to use" | prose paragraph | a **routing trigger** that names sibling skills |
| Code | illustrative | runnable, version-pinned, the minimal correct path |
| Gotchas | narrative notes | a table of errors you **actually hit**, each with a fix |
| Output | often implicit | a table a reviewer can **trace** claims back to |

## 2. Distil — don't reformat

A skill is a **distillation** of a workflow, not a re-typeset copy. You are pulling
out the one correct path and the traps around it, and dropping everything a human
tutorial carries for context. If your skill reads like the Quarto page with the
headings renamed, you have reformatted, not distilled — and you have added nothing.

The test at the end of every skill: **would an agent that had never seen the
notebook run this correctly on the first try, and know when *not* to?** That is the
bar. Nothing else counts as done.

## 3. Section by section

Fill the sections in `SKILL_template.md` in this spirit:

### `description` — the trigger, not the identity

This one line is what the agent reads to decide whether to load the skill. It does
two jobs: say what the skill *is*, and list the **branches** that should trigger it.

- **Front-load the method name.** `scANVI label transfer …`, not `A skill that …`.
  The first words do the routing work.
- **One trigger per distinct branch.** "integrate batches … correct batch effects"
  is one branch written twice — collapse it. Keep only genuinely different uses.
- **Name the sibling for the adjacent task.** `For spatial deconvolution use
  spatial-spotlight instead.` This is what makes the agent route *away* when your
  skill is the wrong fit — it is as important as making it trigger correctly.
- **Don't restate the body.** Identity that's already in the opening paragraph is
  wasted here; the description pays a cost on every single turn.

### Orientation paragraph — the 5-second decision

Method + canonical package + *exact* input format + *exact* output. A reader who
stops after this paragraph should already know if this is their tool. Name the
package and citation so the agent grounds on the real method, not a plausible one.

### `When to use it` — the boundary

Prose. Say when to use it, then say what to use *instead* for the neighbouring task.
The lab's value is in the branches Claude Science lacks (label transfer, inferCNV,
BayesSpace, CellChat …) — so the boundary between your skills is where the value is.

### `Inputs` — leave nothing to guess

The single biggest cause of a skill silently producing garbage is a wrong-shaped
input. State the exact object and layer: *"a merged Seurat v5 object with raw
integer counts in the `RNA` assay `counts` layer"* — not *"your Seurat object"*.

### `How to run` — the minimal correct path

Runnable R, copy-pasteable, current API spelling. Not the whole notebook — the
shortest path that produces the result correctly. Comment the lines where a wrong
choice corrupts the result silently (`# JoinLayers BEFORE FindMarkers on Seurat v5`).
Pin the versions that actually matter; skip the ones that don't.

### `Output` — what a reviewer traces

Name the concrete objects and files the skill produces, in a table. This is the
target a reviewer (human or agent) **traces** each claim back to — "the skill says
it annotated cell types; which object holds them?" A prose summary can't be traced;
a table row can.

### `Running on OSC` — only when it earns it

Most single-sample steps run on a laptop. Add the SBATCH block only for steps heavy
enough to need Ascend/Pitzer, and say in one line when local is fine. Use the module
loads from the project `CLAUDE.md` (`module load R/4.3.0`, etc.).

### `Gotchas` and `Troubleshooting` — see the next section

## 4. The gotcha rule (the one that matters most)

**Every gotcha must be one you hit by running the skill — with the real error text
or the real silently-wrong behaviour.**

This is the difference between a skill that saves the next person an afternoon and a
skill that reads plausibly and helps no one. A gotcha table earns its place only
because someone ran the code and got bitten: the exact `Error in ...` string, the
version where the API changed, the parameter whose default quietly produces wrong
numbers. You cannot write these from memory or from reading the notebook — you get
them by **running the skill on the example data and recording what broke.**

If you have not run it yet, the honest state is an *empty* Gotchas section with a
`<!-- filled after first real run -->` marker — never an invented row. An imagined
gotcha is worse than none: it teaches the agent a trap that isn't there and hides
that the real traps are still unknown.

This rule is why converting a skill is real work and not reformatting. Budget for it.

## 5. Keep it lean

Three habits from day one, or the skill rots:

- **Leading words over restatement.** Pick the compact term the field already uses
  (`counts`, `latent space`, `label transfer`, `pseudobulk`) and repeat *the word*,
  never the sentence. A repeated token sharpens the agent's attention for free; a
  repeated *sentence* is duplication that costs tokens and drifts out of sync.
- **No no-ops.** Delete any line the agent would already follow by default. "Be
  careful with your data" changes nothing. "scVI needs raw integer counts, not
  log-normalized" changes everything. Keep only the second kind.
- **Say the positive.** "Stash counts in `layers$counts` before `NormalizeData`"
  steers; "don't feed normalized data to scVI" drags the wrong behaviour into view
  and half-reads as an instruction to do it. State the target, not the ban.

## 6. Progressive disclosure — when to split a file out

Keep `SKILL.md` legible. When a block is long *and only some runs need it* — a deep
parameter reference, a long alternative path, a big troubleshooting appendix — push
it into `references/<name>.md` and point at it from `SKILL.md` with one line naming
*when* to read it. Inline what every run needs; disclose what only some runs reach.
Reusable R helpers go in a `functions.R` beside `SKILL.md` (the analog of the
Claude Science `kernel.py` sidecar), sourced from `How to run`.

Don't over-split: a 120-line skill that every run reads top to bottom wants to stay
one file.

## 7. Provenance

Every skill carries `metadata.source_workflow` pointing at the notebook directory it
distils. That is the trail back to the evidence — when the skill and the notebook
disagree later, that link is how anyone knows which came first and what to re-check.

## 8. Definition of done — self-check before you open the PR

A skill is done when **all** of these hold. This is the completion bar; a "yes" to
each, not a vibe.

- [ ] `name` matches the folder; `description` front-loads the method, has one
      trigger per branch, and names the sibling skill for the adjacent task.
- [ ] Orientation paragraph states method, exact input format, exact output.
- [ ] `Inputs` names the exact object/layer and the example data path.
- [ ] `How to run` executed end-to-end on the example (or toy) data **and produced
      the documented Output** — not "should work".
- [ ] Every `Gotchas` row was actually hit while running it (or the section is
      honestly empty with a marker). No invented rows.
- [ ] `Output` table names concrete objects/files a reviewer can trace to.
- [ ] `metadata.source_workflow` points at the source notebook.
- [ ] You reread it once and cut every line that didn't change the agent's process.
