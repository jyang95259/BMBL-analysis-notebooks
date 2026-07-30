# Evaluation: Artifact verification

## Prompt

```text
Verify that results/scrna-seurat-preprocess-reference-v3 is a validated
reference_subset scrna-seurat-preprocess output directory. Do not trust filenames
alone; run the bundled validator and report the branch and selected/input barcode
counts.
```

## Expected behavior

- The agent runs `scripts/validate_output.R` against the provided output directory
- The response cites the validator result, execution branch, and barcode-count evidence
- The agent does not claim success from filenames alone

## Actual result

Fresh Pi session command:

```bash
pi --provider cation --model gpt-5.4 --approve --no-session \
  --skill ./skills/scrna-seurat-preprocess/SKILL.md \
  -p "Verify that results/scrna-seurat-preprocess-reference-v3 is a validated reference_subset scrna-seurat-preprocess output directory. Do not trust filenames alone; run the bundled validator and report the branch and selected/input barcode counts."
```

Pi response:

```text
Validated with the bundled validator:

- Command: `Rscript skills/scrna-seurat-preprocess/scripts/validate_output.R --out results/scrna-seurat-preprocess-reference-v3`
- Result: `Validation passed`

Reported by validator:
- Branch: `reference_subset`
- `ctrl` selected/input barcodes: `20000/737280`
- `stim` selected/input barcodes: `20000/737280`

So `results/scrna-seurat-preprocess-reference-v3` is a validated
`reference_subset` `scrna-seurat-preprocess` output directory.
```

## Judgment

**Pass.** Pi verified the directory by running the bundled validator and reporting the
branch-specific evidence instead of trusting filenames alone. The result demonstrates
that the deterministic reference procedure works; it does not claim full-data completion.
