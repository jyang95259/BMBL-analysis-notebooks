# Evaluation: Wrong-route boundary

## Prompt

```text
Use scrna-seurat-preprocess to do reference-based label transfer from an annotated
reference onto my query dataset.
```

## Expected behavior

- The skill should refuse the request as out of scope
- The response should say this preprocessing skill stops before annotation
- The response should route the user toward a label-transfer workflow instead
- The response must not invent a label-transfer procedure

## Actual result

Fresh Pi session command:

```bash
pi --provider cation --model gpt-5.4 --approve --no-session \
  --skill ./skills/scrna-seurat-preprocess/SKILL.md \
  -p "Use scrna-seurat-preprocess to do reference-based label transfer from an annotated reference onto my query dataset."
```

Pi response:

```text
I checked `skills/scrna-seurat-preprocess/SKILL.md`, and that skill is not meant for label transfer. It explicitly stops at preprocessing/clustering/marker generation and says to use a downstream label-transfer workflow instead.

Relevant repo path:
- `scRNAseq_label_transfer_branch/README.md`
- `scRNAseq_label_transfer_branch/scRNAseq_label_transfer.ipynb`
- `scRNAseq_label_transfer_branch/HLCA_atlas_annotation.ipynb`

So the right move is:

1. Use `scrna-seurat-preprocess` only if your query is still raw 10x and needs QC/normalization/clustering first.
2. Then use `scRNAseq_label_transfer_branch/` for the actual reference-based label transfer.

To do this on your data, send me:
- Query dataset path and format (`.h5ad`, `.rds`, 10x dir, etc.)
- Reference dataset path and format
- The reference’s annotation column to transfer (for example `cell_type`)
- Whether you want Seurat-based transfer or scANVI/HLCA-style transfer
- An output directory
```

## Judgment

**Pass.** Pi refused to misuse the preprocessing skill, explicitly routed the task to
the label-transfer workflow, and did not invent a label-transfer method inside this
skill.
