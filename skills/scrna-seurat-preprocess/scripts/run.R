#!/usr/bin/env Rscript

suppressWarnings(suppressPackageStartupMessages({
  library(Seurat)
  library(Matrix)
}))

fail <- function(message, status = 1L) {
  message("ERROR: ", message)
  quit(save = "no", status = status)
}

parse_args <- function(args) {
  parsed <- list(
    ctrl = NULL,
    stim = NULL,
    out = NULL,
    subset_barcodes_per_sample = 20000L,
    seed = 42L,
    full_run = FALSE
  )
  i <- 1L
  while (i <= length(args)) {
    arg <- args[[i]]
    if (arg %in% c("--ctrl", "--stim", "--out", "--subset-barcodes-per-sample", "--seed")) {
      if (i == length(args)) {
        fail(paste("Missing value for", arg))
      }
      value <- args[[i + 1L]]
      if (arg == "--ctrl") {
        parsed$ctrl <- value
      } else if (arg == "--stim") {
        parsed$stim <- value
      } else if (arg == "--out") {
        parsed$out <- value
      } else if (arg == "--subset-barcodes-per-sample") {
        parsed$subset_barcodes_per_sample <- suppressWarnings(as.integer(value))
        if (is.na(parsed$subset_barcodes_per_sample) || parsed$subset_barcodes_per_sample < 1L) {
          fail("--subset-barcodes-per-sample must be a positive integer")
        }
      } else if (arg == "--seed") {
        parsed$seed <- suppressWarnings(as.integer(value))
        if (is.na(parsed$seed)) {
          fail("--seed must be an integer")
        }
      }
      i <- i + 2L
    } else if (arg == "--full-run") {
      parsed$full_run <- TRUE
      i <- i + 1L
    } else if (arg %in% c("--help", "-h")) {
      cat(
        paste(
          "Usage:",
          "Rscript skills/scrna-seurat-preprocess/scripts/run.R",
          "--ctrl <path>",
          "--stim <path>",
          "--out <path>",
          "[--subset-barcodes-per-sample <int>]",
          "[--seed <int>]",
          "[--full-run]",
          sep = " "
        ),
        "\n"
      )
      quit(save = "no", status = 0L)
    } else {
      fail(paste("Unknown argument:", arg))
    }
  }
  missing_required <- vapply(parsed[c("ctrl", "stim", "out")], is.null, logical(1))
  if (any(missing_required)) {
    fail(
      paste(
        "Missing required arguments:",
        paste(names(missing_required)[missing_required], collapse = ", ")
      )
    )
  }
  parsed
}

normalize_input_dir <- function(path) {
  expanded <- path.expand(path)
  if (!dir.exists(expanded)) {
    fail(paste("Input directory does not exist:", path))
  }
  required_files <- c("barcodes.tsv.gz", "features.tsv.gz", "matrix.mtx.gz")
  missing <- required_files[!file.exists(file.path(expanded, required_files))]
  if (length(missing) > 0L) {
    fail(
      paste(
        "Input directory is missing required 10x files:",
        paste(missing, collapse = ", "),
        "in",
        expanded
      )
    )
  }
  normalizePath(expanded, winslash = "/", mustWork = TRUE)
}

normalize_output_dir <- function(path) {
  expanded <- path.expand(path)
  parent <- dirname(expanded)
  if (!dir.exists(parent)) {
    dir.create(parent, recursive = TRUE, showWarnings = FALSE)
  }
  if (!dir.exists(parent)) {
    fail(paste("Parent directory for output does not exist and could not be created:", parent))
  }
  if (!dir.exists(expanded)) {
    dir.create(expanded, recursive = TRUE, showWarnings = FALSE)
  }
  if (!dir.exists(expanded)) {
    fail(paste("Output directory could not be created:", expanded))
  }
  normalizePath(expanded, winslash = "/", mustWork = TRUE)
}

select_matrix_columns <- function(matrix, subset_barcodes_per_sample, full_run) {
  if (full_run || ncol(matrix) <= subset_barcodes_per_sample) {
    list(
      matrix = matrix,
      selected_barcodes = colnames(matrix),
      subset_strategy = "full"
    )
  } else {
    counts <- Matrix::colSums(matrix)
    order_index <- order(counts, colnames(matrix), decreasing = TRUE)
    keep <- order_index[seq_len(subset_barcodes_per_sample)]
    keep <- keep[order(colnames(matrix)[keep])]
    list(
      matrix = matrix[, keep, drop = FALSE],
      selected_barcodes = colnames(matrix)[keep],
      subset_strategy = sprintf("top_%d_barcodes_by_total_counts", subset_barcodes_per_sample)
    )
  }
}

calc_percent_ribo <- function(object) {
  ribo_genes <- rownames(object)[grep("^RP[SL][[:digit:]]", rownames(object))]
  if (length(ribo_genes) == 0L) {
    rep(0, ncol(object))
  } else {
    ribo_counts <- Matrix::colSums(LayerData(object[ribo_genes, ], assay = "RNA", layer = "counts"))
    total_counts <- Matrix::colSums(LayerData(object, assay = "RNA", layer = "counts"))
    as.numeric(ribo_counts / total_counts * 100)
  }
}

ensure_package_versions <- function() {
  needed <- c("Seurat", "SeuratObject", "Matrix")
  missing <- needed[!vapply(needed, requireNamespace, quietly = TRUE, FUN.VALUE = logical(1))]
  if (length(missing) > 0L) {
    fail(paste("Required R packages are missing:", paste(missing, collapse = ", ")))
  }
}

args <- parse_args(commandArgs(trailingOnly = TRUE))
ensure_package_versions()

ctrl_dir <- normalize_input_dir(args$ctrl)
stim_dir <- normalize_input_dir(args$stim)
out_dir <- normalize_output_dir(args$out)

set.seed(args$seed)

sample_specs <- list(
  ctrl = list(path = ctrl_dir, label = basename(ctrl_dir)),
  stim = list(path = stim_dir, label = basename(stim_dir))
)

sample_objects <- list()
sample_summaries <- vector("list", length(sample_specs))
names(sample_summaries) <- names(sample_specs)

for (sample_name in names(sample_specs)) {
  spec <- sample_specs[[sample_name]]
  raw_matrix <- tryCatch(
    Read10X(spec$path, unique.features = TRUE, strip.suffix = FALSE),
    error = function(error) fail(paste("Failed to read 10x matrix from", spec$path, "-", conditionMessage(error)))
  )
  if (!inherits(raw_matrix, "dgCMatrix")) {
    fail(paste("Expected a gene-expression sparse matrix from", spec$path))
  }

  selected <- select_matrix_columns(
    matrix = raw_matrix,
    subset_barcodes_per_sample = args$subset_barcodes_per_sample,
    full_run = args$full_run
  )

  object <- CreateSeuratObject(
    selected$matrix,
    assay = "RNA",
    min.cells = 3,
    min.features = 200,
    project = spec$label
  )

  object$percent.ribo <- calc_percent_ribo(object)
  object <- PercentageFeatureSet(object, "^MT-", col.name = "percent.mito")

  sample_objects[[sample_name]] <- object
  sample_summaries[[sample_name]] <- data.frame(
    sample = spec$label,
    input_barcodes = ncol(raw_matrix),
    subset_barcodes = ncol(selected$matrix),
    create_seurat_cells = ncol(object),
    subset_strategy = selected$subset_strategy,
    stringsAsFactors = FALSE
  )
}

combined <- merge(
  x = sample_objects[[1L]],
  y = sample_objects[-1L],
  add.cell.ids = vapply(sample_specs, function(spec) spec$label, character(1)),
  merge.data = TRUE
)

# These thresholds are copied from the committed workflow's example dataset. They are
# example-dataset defaults for this skill's smoke test, not universal biology rules.
qc_thresholds <- list(
  percent_mito_max = 5,
  percent_ribo_max = 50,
  nFeature_RNA_min = 200,
  nFeature_RNA_max = 1500,
  nCount_RNA_max = 6000
)

combined_qc <- subset(
  combined,
  subset =
    percent.mito < qc_thresholds$percent_mito_max &
    percent.ribo < qc_thresholds$percent_ribo_max &
    nFeature_RNA > qc_thresholds$nFeature_RNA_min &
    nFeature_RNA < qc_thresholds$nFeature_RNA_max &
    nCount_RNA < qc_thresholds$nCount_RNA_max
)

DefaultAssay(combined_qc) <- "RNA"
combined_qc <- NormalizeData(combined_qc, verbose = FALSE)
combined_qc <- FindVariableFeatures(combined_qc, nfeatures = 2000, verbose = FALSE)
combined_qc <- ScaleData(combined_qc, verbose = FALSE)
combined_qc <- RunPCA(combined_qc, npcs = 30, verbose = FALSE, seed.use = args$seed)
combined_qc <- FindNeighbors(combined_qc, dims = 1:30, verbose = FALSE)
combined_qc <- FindClusters(combined_qc, resolution = 0.8, verbose = FALSE, random.seed = args$seed)
combined_qc <- RunUMAP(combined_qc, dims = 1:30, verbose = FALSE, seed.use = args$seed)

# Seurat v5 marker finding needs joined layers after preprocessing and before
# FindAllMarkers(), or marker output can fail or be incomplete.
combined_qc <- JoinLayers(combined_qc)
markers <- FindAllMarkers(combined_qc, only.pos = TRUE, min.pct = 0.25, verbose = FALSE)
markers$gene <- rownames(markers)
markers <- markers[, c("gene", setdiff(colnames(markers), "gene")), drop = FALSE]

post_qc_counts <- as.data.frame(table(combined_qc$orig.ident), stringsAsFactors = FALSE)
names(post_qc_counts) <- c("sample", "qc_cells")

qc_summary <- do.call(rbind, sample_summaries)
qc_summary <- merge(qc_summary, post_qc_counts, by = "sample", all.x = TRUE, sort = FALSE)
qc_summary$qc_cells[is.na(qc_summary$qc_cells)] <- 0L
total_row <- data.frame(
  sample = "Total",
  input_barcodes = sum(qc_summary$input_barcodes),
  subset_barcodes = sum(qc_summary$subset_barcodes),
  create_seurat_cells = sum(qc_summary$create_seurat_cells),
  subset_strategy = if (args$full_run) "full" else sprintf("top_%d_barcodes_per_sample", args$subset_barcodes_per_sample),
  qc_cells = ncol(combined_qc),
  stringsAsFactors = FALSE
)
qc_summary <- rbind(qc_summary, total_row)

saveRDS(combined_qc, file.path(out_dir, "combined_qc.rds"))
write.csv(qc_summary, file.path(out_dir, "qc_summary.csv"), row.names = FALSE)
write.csv(markers, file.path(out_dir, "markers.csv"), row.names = FALSE)

manifest_lines <- c(
  paste("skill_name:", "scrna-seurat-preprocess"),
  paste("source_workflow:", "scRNAseq_general_workflow"),
  paste("source_commit_validated:", "692d8f8"),
  paste("ctrl_dir:", ctrl_dir),
  paste("stim_dir:", stim_dir),
  paste("out_dir:", out_dir),
  paste("full_run:", args$full_run),
  paste("subset_barcodes_per_sample:", if (args$full_run) "disabled" else args$subset_barcodes_per_sample),
  paste("subset_policy:", if (args$full_run) "full_input" else "top_barcodes_by_total_counts_per_sample"),
  paste("seed:", args$seed),
  paste("qc_percent_mito_max:", qc_thresholds$percent_mito_max),
  paste("qc_percent_ribo_max:", qc_thresholds$percent_ribo_max),
  paste("qc_nFeature_RNA_min:", qc_thresholds$nFeature_RNA_min),
  paste("qc_nFeature_RNA_max:", qc_thresholds$nFeature_RNA_max),
  paste("qc_nCount_RNA_max:", qc_thresholds$nCount_RNA_max),
  paste(
    "qc_threshold_rationale:",
    "Copied from the committed example workflow for this dataset; these are smoke-test defaults, not universal thresholds."
  ),
  paste("artifacts:", paste(c("combined_qc.rds", "qc_summary.csv", "markers.csv", "run_manifest.txt", "sessionInfo.txt"), collapse = ", "))
)
writeLines(manifest_lines, con = file.path(out_dir, "run_manifest.txt"))

session_output <- c(
  sprintf("R.version: %s", R.version.string),
  sprintf("Seurat: %s", as.character(packageVersion("Seurat"))),
  sprintf("SeuratObject: %s", as.character(packageVersion("SeuratObject"))),
  sprintf("Matrix: %s", as.character(packageVersion("Matrix"))),
  "",
  capture.output(sessionInfo())
)
writeLines(session_output, con = file.path(out_dir, "sessionInfo.txt"))

message("Wrote artifacts to ", out_dir)
