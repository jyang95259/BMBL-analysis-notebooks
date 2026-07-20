---
# STATUS: skeleton — Phase 2 starting point, NOT a finished skill.
# The How-to-run below is distilled from scRNAseq_general_workflow's notebooks,
# but Output / Gotchas / OSC are marked TODO because they can only be filled by
# ACTUALLY RUNNING this on the example data. That run is the work. See
# ../AUTHORING_GUIDE.md §4 (the gotcha rule) and §8 (definition of done).

name: scrna-seurat-general
description: >
  Baseline Seurat v5 scRNA-seq pipeline — raw 10x matrices through QC, clustering,
  marker-based cell-type annotation, and per-cell-type differential expression.
  Reach for this to preprocess 10x gene-expression data, cluster and annotate cells,
  or run a two-condition DEG comparison from the lab's default settings. For batch
  integration across many samples use scrna-scvi-integration; for label transfer from
  a reference use scrna-label-transfer instead.
license: lab-internal
requirements: [r-4.3, seurat-5, bioc-3.18]
metadata:
  display-name: scRNA-seq General Workflow (Seurat)
  source_workflow: scRNAseq_general_workflow
---

# scRNA-seq General Workflow (Seurat) — QC → cluster → annotate → DEG

The lab's baseline Seurat v5 pipeline for two-condition single-cell RNA-seq. It reads
raw 10x matrices, applies dataset-specific QC thresholds, clusters, annotates cell
types from markers, and runs cell-type-specific differential expression. Input is one
or more 10x `raw_feature_bc_matrix` directories; output is an annotated Seurat object
plus per-cell-type DEG tables. Use it as the default starting point when you have
standard 10x gene-expression matrices and want the lab's committed QC/clustering/
annotation conventions rather than a bespoke pipeline.

## When to use it

Use this when you have standard 10x gene-expression matrices and want a general-purpose
preprocessing-through-DEG path with the lab's default thresholds. For integrating many
batches into one corrected latent space use `scrna-scvi-integration`; for transferring
annotations from an existing reference onto a query use `scrna-label-transfer`; for CNV
inference use `scrna-infercnv`. This skill assumes a small number of samples compared
directly, not a large atlas.

## Inputs

- **Object / format:** one or more 10x `raw_feature_bc_matrix/` directories (barcodes,
  features, matrix). Raw integer counts — not filtered, not normalized.
- **Required upstream:** none; this is the entry point. `_common/functions.R` must be
  sourceable for shared helpers.
- **Example data:** `scRNAseq_general_workflow/data/ctrl_raw_feature_bc_matrix/` and
  `.../stim_raw_feature_bc_matrix/` (committed control + stimulation matrices).

## How to run

<!-- Distilled from 1_preprocess.rmd / 2_annotate_cell_type.rmd / 3_deg.rmd.
Verify each call against the current notebook + Seurat 5 before you rely on it. -->

```r
suppressPackageStartupMessages({
  library(Seurat)      # v5
  library(purrr)
})

# 1. Load raw 10x matrices and merge (counts stay raw)
data_dirs <- c("data/ctrl_raw_feature_bc_matrix", "data/stim_raw_feature_bc_matrix")
data_list <- lapply(data_dirs, function(d) {
  tmp <- Read10X(d, unique.features = TRUE, strip.suffix = FALSE)
  CreateSeuratObject(tmp, assay = "RNA", min.cells = 3, min.features = 200,
                     project = basename(d))
})
combined <- purrr::reduce(data_list, function(x, y) merge(x, y, merge.data = TRUE))
combined <- PercentageFeatureSet(combined, "^MT-", col.name = "percent.mito")
combined <- PercentageFeatureSet(combined, "^RP[SL]", col.name = "percent.ribo")

# 2. QC filter — thresholds are dataset-specific; inspect before committing them
combined_qc <- subset(
  combined,
  subset = percent.mito < 5 & percent.ribo < 50 & nFeature_RNA > 200
)

# 3. Normalize → HVG → scale → PCA → cluster → UMAP
combined_qc <- NormalizeData(combined_qc)
combined_qc <- FindVariableFeatures(combined_qc, nfeatures = 2000)
combined_qc <- ScaleData(combined_qc)
combined_qc <- RunPCA(combined_qc, npcs = 30)
combined_qc <- FindNeighbors(combined_qc, dims = 1:30)
combined_qc <- FindClusters(combined_qc, resolution = 0.5)
combined_qc <- RunUMAP(combined_qc, dims = 1:30)

# 4. Markers + manual annotation (annotation is a human decision from these markers)
combined_qc <- JoinLayers(combined_qc)   # Seurat v5: needed before marker/DE calls
markers <- FindAllMarkers(combined_qc, only.pos = TRUE, min.pct = 0.25)
# ... assign combined_qc$cell_type from markers ...

# 5. Per-cell-type DEG between conditions
# ... see 3_deg.rmd ...
```

## Output

<!-- TODO(run): fill from an actual run. Name the real objects/columns/files. -->

| Key / object | What it holds |
|---|---|
| `combined_qc$seurat_clusters` | cluster id per cell |
| `combined_qc$cell_type` | assigned cell-type label per cell |
| `markers` | per-cluster positive markers |
| `<deg output files>` | TODO — per-cell-type DEG tables (name them after a run) |

## Running on OSC

<!-- TODO(run): only if the example is too heavy for a laptop. Add module loads +
SBATCH if so; otherwise state "runs locally" and delete this section. -->

```bash
module load R/4.3.0
# sbatch template — TODO
```

## Gotchas

<!-- EMPTY BY DESIGN until the first real run. Fill each row with the exact error
text or silently-wrong behaviour you hit — never an invented one. See guide §4.
Likely candidates to confirm by running: Seurat v5 split-layer state before
FindAllMarkers (JoinLayers), the "^RP[SL]" vs "^RP[SL]" ribo regex, merge() layer
names on v5. Confirm or delete — do not ship them as guesses. -->

| Gotcha | What happens / fix |
|---|---|
| _filled after first real run_ | |

## Troubleshooting

| Symptom | Fix |
|---|---|
| _filled after first real run_ | |

---

**Next**: annotate downstream with `scrna-module` (module enrichment) or hand the
DEG tables to `enrichment-pathway`.
