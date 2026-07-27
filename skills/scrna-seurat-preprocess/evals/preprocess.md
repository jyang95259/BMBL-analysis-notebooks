# Evaluation: Positive execution

## Prompt

```text
Preprocess the committed control and stimulation 10x inputs with the
scrna-seurat-preprocess skill, validate the output directory, and report the
artifact paths. Use explicit paths and the bundled scripts.
```

## Expected behavior

- Pi loads `skills/scrna-seurat-preprocess/SKILL.md`
- The agent runs `scripts/run.R` with explicit `--ctrl`, `--stim`, and `--out` paths
- The agent runs `scripts/validate_output.R` against the produced output directory
- The response reports the artifact directory and does not invent annotation or DEG

## Actual result

Fresh Pi session command:

```bash
pi --provider cation --model gpt-5.4 --approve --no-session \
  --skill ./skills/scrna-seurat-preprocess/SKILL.md \
  -p "Preprocess the committed control and stimulation 10x inputs with the scrna-seurat-preprocess skill, validate the output directory, and report the artifact paths. Use explicit paths and the bundled scripts."
```

Pi response:

```text
Done.

Used the bundled scripts with explicit paths:

- Run:
  /Users/jonathanyang/Documents/BMBL-analysis-notebooks-phase2/skills/scrna-seurat-preprocess/scripts/run.R
- Validate:
  /Users/jonathanyang/Documents/BMBL-analysis-notebooks-phase2/skills/scrna-seurat-preprocess/scripts/validate_output.R

Inputs:

- Control:
  /Users/jonathanyang/Documents/BMBL-analysis-notebooks-phase2/scRNAseq_general_workflow/data/ctrl_raw_feature_bc_matrix
- Stimulation:
  /Users/jonathanyang/Documents/BMBL-analysis-notebooks-phase2/scRNAseq_general_workflow/data/stim_raw_feature_bc_matrix

Output directory:

- /Users/jonathanyang/Documents/BMBL-analysis-notebooks-phase2/results/scrna-seurat-preprocess-smoke

Validation:

- Validation passed for /Users/jonathanyang/Documents/BMBL-analysis-notebooks-phase2/results/scrna-seurat-preprocess-smoke

Artifacts:

- /Users/jonathanyang/Documents/BMBL-analysis-notebooks-phase2/results/scrna-seurat-preprocess-smoke/combined_qc.rds
- /Users/jonathanyang/Documents/BMBL-analysis-notebooks-phase2/results/scrna-seurat-preprocess-smoke/qc_summary.csv
- /Users/jonathanyang/Documents/BMBL-analysis-notebooks-phase2/results/scrna-seurat-preprocess-smoke/markers.csv
- /Users/jonathanyang/Documents/BMBL-analysis-notebooks-phase2/results/scrna-seurat-preprocess-smoke/run_manifest.txt
- /Users/jonathanyang/Documents/BMBL-analysis-notebooks-phase2/results/scrna-seurat-preprocess-smoke/sessionInfo.txt

QC summary from qc_summary.csv:

- ctrl_raw_feature_bc_matrix: 737,280 input barcodes -> 20,000 subset -> 14,957 QC-passing cells
- stim_raw_feature_bc_matrix: 737,280 input barcodes -> 20,000 subset -> 14,983 QC-passing cells
- Total: 1,474,560 input barcodes -> 40,000 subset -> 29,940 QC-passing cells

Run mode:

- Smoke test mode
- full_run: FALSE
- subset_barcodes_per_sample: 20000
```

## Judgment

**Pass.** In a fresh Pi session with the skill explicitly loaded, Pi used the bundled
runner and validator, produced a complete output directory, and reported the artifact
paths without inventing annotation or DEG.
