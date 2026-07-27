---
name: scrna-seurat-preprocess
description: >
  Seurat v5 preprocessing for raw 10x scRNA-seq matrices through QC, normalization,
  PCA, clustering, UMAP, and cluster marker artifacts. Reach for this to preprocess
  raw 10x gene-expression matrices, generate cluster-level marker evidence, or verify
  that a preprocessing output directory is complete with the bundled validator. For
  manual cell-type annotation, reference label transfer, batch integration, or
  per-cell-type DEG use a downstream annotation or label-transfer workflow instead.
license: lab-internal
requirements: [r-4.3, seurat-5, seuratobject-5]
metadata:
  display-name: scRNA-seq Seurat Preprocess
  source_workflow: scRNAseq_general_workflow
  source_commit_validated: 692d8f8
---

# scRNA-seq Seurat Preprocess

This skill packages the deterministic first half of the lab's general Seurat workflow:
raw 10x matrices through QC, normalization, PCA, clustering, UMAP, and marker
artifacts. It expects raw integer 10x `raw_feature_bc_matrix/` directories for a
control and stimulation sample, and it runs the bundled
`scripts/run.R` entrypoint instead of reconstructing notebook code by hand. The
output is a QC-filtered Seurat object, a QC summary table, a cluster marker table, a
run manifest, and exact session/version evidence.

## When to use it

Use this when you need the lab's baseline Seurat preprocessing on raw 10x
gene-expression matrices and want artifact-backed evidence that preprocessing
completed correctly. Stop here once you have clusters, UMAP, and marker evidence.
For manual cluster-to-cell-type interpretation, use the downstream annotation
notebook; for reference-based label transfer, use a label-transfer workflow; for
batch correction or integration across many samples, use an integration workflow
instead. This skill must not fabricate `cell_type` labels or run per-cell-type DEG.

## Inputs

- **Object / format:** two raw integer 10x directories, each containing `barcodes.tsv.gz`,
  `features.tsv.gz`, and `matrix.mtx.gz`
- **Required upstream:** none; this is the entry point for the preprocessing half of
  the Seurat workflow
- **Example data:** `scRNAseq_general_workflow/data/ctrl_raw_feature_bc_matrix/` and
  `scRNAseq_general_workflow/data/stim_raw_feature_bc_matrix/`

## How to run

Run the bundled script with explicit paths. The default smoke-test mode uses the top
`20000` barcodes per sample by total counts so Pi can exercise the committed raw 10x
directories deterministically without processing every barcode. Use `--full-run` when
you intentionally want the complete raw matrices.

```bash
Rscript skills/scrna-seurat-preprocess/scripts/run.R \
  --ctrl scRNAseq_general_workflow/data/ctrl_raw_feature_bc_matrix \
  --stim scRNAseq_general_workflow/data/stim_raw_feature_bc_matrix \
  --out results/scrna-seurat-preprocess-smoke
```

Validate the output directory instead of trusting filenames alone:

```bash
Rscript skills/scrna-seurat-preprocess/scripts/validate_output.R \
  --out results/scrna-seurat-preprocess-smoke
```

## Output

| Key / object | What it holds |
|---|---|
| `combined_qc.rds` | QC-filtered Seurat object with both samples, RNA counts retained, PCA, UMAP, and `seurat_clusters` |
| `qc_summary.csv` | Per-sample and total barcode/cell counts before and after QC |
| `markers.csv` | Per-cluster positive marker table from `FindAllMarkers()` after `JoinLayers()` |
| `run_manifest.txt` | Input paths, subset/full-run mode, QC thresholds, seed, and artifact inventory |
| `sessionInfo.txt` | Exact R, Seurat, SeuratObject, and related package versions used for the run |

Completion is proven only when `validate_output.R` exits `0` and confirms that all
required artifacts exist, both samples are present, QC metadata exists, PCA and UMAP
reductions exist, raw counts remain available, marker columns are intact, and no
`cell_type` metadata was fabricated.

## Gotchas

| Gotcha | What happens / fix |
|---|---|
| `Warning: Some cell names are duplicated across objects provided. Renaming to enforce unique cell names.` | Observed during a real run when the committed control and stimulation 10x inputs reused barcode names across samples. The bundled `run.R` now prevents ambiguous Seurat auto-renaming by merging with explicit `add.cell.ids` derived from each sample directory name. |

---

**Next**: review marker evidence manually in
`scRNAseq_general_workflow/2_annotate_cell_type.rmd` before any cell-type annotation
or per-cell-type DEG.
