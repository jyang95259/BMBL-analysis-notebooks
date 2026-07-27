# Evaluation: Artifact verification

## Prompt

```text
Verify that results/scrna-seurat-preprocess-smoke-v2 is a complete
scrna-seurat-preprocess output directory. Do not trust filenames alone.
```

## Expected behavior

- The agent runs `scripts/validate_output.R` against the provided output directory
- The response cites the validator result and artifact evidence
- The agent does not claim success from filenames alone

## Actual result

Fresh Pi session command:

```bash
pi --provider cation --model gpt-5.4 --approve --no-session \
  --skill ./skills/scrna-seurat-preprocess/SKILL.md \
  -p "Verify that results/scrna-seurat-preprocess-smoke-v2 is a complete scrna-seurat-preprocess output directory. Do not trust filenames alone."
```

Pi response:

```text
Verified: `results/scrna-seurat-preprocess-smoke-v2` is a complete `scrna-seurat-preprocess` output directory.

I validated it with the bundled checker, not by filenames alone:

Rscript skills/scrna-seurat-preprocess/scripts/validate_output.R \
  --out results/scrna-seurat-preprocess-smoke-v2

Result:
- Validation passed for /Users/jonathanyang/Documents/BMBL-analysis-notebooks-phase2/results/scrna-seurat-preprocess-smoke-v2

This confirms the directory has valid required artifacts and internal content, including:
- readable `combined_qc.rds` Seurat object
- both input samples present
- required QC metadata
- PCA and UMAP reductions
- RNA counts layer retained
- nonempty marker table with expected columns
- provenance in `run_manifest.txt`
- version evidence in `sessionInfo.txt`
- no fabricated `cell_type` metadata
```

## Judgment

**Pass.** Pi verified the directory by running the bundled validator and summarizing
the validator-backed evidence instead of trusting filenames alone.
