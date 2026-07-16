# Spatial Transcriptomics Analysis using Seurat

## Introduction

This tutorial provides a general pipeline for analyzing sequencing-based spatial transcriptomics data using the Seurat framework. It was adapted from resources provided by the Satija Lab ([spatial vignette](https://satijalab.org/seurat/articles/spatial_vignette.html)) and covers data normalization, dimensionality reduction and clustering, detection of spatially variable features, interactive visualization, integration with single-cell RNA-seq references via anchor-based label transfer, and analysis across multiple tissue slices. It is adapted for Seurat v5 and demonstrates how to incorporate auxiliary tools such as glmGamPoi to accelerate preprocessing.

## Pipeline Input

The pipeline requires the following inputs:

- **Spatial transcriptomics data**: A Seurat object generated from Visium data (e.g., `stxBrain` from `SeuratData`).
- **Single-cell RNA-seq reference**: A pre-annotated Seurat object (e.g., `allen_cortex.rds`) for label transfer and deconvolution.
- **(Optional) Histological image**: For spatial overlays in plots.

### Obtaining the data

The Visium example data is distributed through the `SeuratData` package:

```r
devtools::install_github('satijalab/seurat-data')
SeuratData::InstallData("stxBrain")
```

For the single-cell integration step, download the reference [here](https://www.dropbox.com/s/cuowvm4vrf65pvq/allen_cortex.rds?dl=1) and save it to a folder named `data` in your working directory.

## Pipeline Output

The output of this spatial pipeline includes:

- Violin plots and spatial feature plots for QC.
- PCA and UMAP projections of spatial domains.
- Cluster annotation and spatial visualization of cluster identity.
- Spatially variable feature identification using variogram methods.
- Subsetting and analysis of anatomical regions (e.g., cortex).
- Integration with single-cell reference via anchor-based label transfer.
- Spatial feature maps for predicted cell types.
- Analysis across multiple tissue slices (e.g., anterior and posterior sections).

## Code

Main R Markdown file:

- `ST_general_workflow_tutorial.Rmd`

## Session Info as Tested

- **R version**: 4.3.2
- **Seurat version**: ≥5.0.0
- **SeuratData version**: ≥0.2.2
- **Key packages**:
  - Seurat
  - SeuratData
  - ggplot2
  - patchwork
  - dplyr

## Notes

- Interactive plots (e.g., `SpatialDimPlot(..., interactive = TRUE)`) require running within **RStudio**.
- Ensure appropriate slot names (e.g., `"anterior1_imagerow"`) exist in `meta.data` when subsetting regions.

## Contact

Author: Magan Mcnutt

Test: Xiaojie (06/19/2025)
