#!/usr/bin/env Rscript

failures <- character()

record_failure <- function(message) {
  failures <<- c(failures, message)
}

fail_and_exit <- function() {
  for (message in failures) {
    message("FAIL: ", message)
  }
  quit(save = "no", status = 1L)
}

parse_args <- function(args) {
  out <- NULL
  i <- 1L
  while (i <= length(args)) {
    arg <- args[[i]]
    if (arg == "--out") {
      if (i == length(args)) {
        stop("Missing value for --out")
      }
      out <- args[[i + 1L]]
      i <- i + 2L
    } else if (arg %in% c("--help", "-h")) {
      cat("Usage: Rscript validate_output.R --out <output_dir>\n")
      quit(save = "no", status = 0L)
    } else {
      stop(paste("Unknown argument:", arg))
    }
  }
  if (is.null(out)) {
    stop("Missing required argument --out")
  }
  normalizePath(path.expand(out), winslash = "/", mustWork = TRUE)
}

args <- tryCatch(
  parse_args(commandArgs(trailingOnly = TRUE)),
  error = function(error) {
    message("ERROR: ", conditionMessage(error))
    quit(save = "no", status = 1L)
  }
)

if (!requireNamespace("Seurat", quietly = TRUE)) {
  message("ERROR: Required R package is missing: Seurat")
  quit(save = "no", status = 1L)
}
suppressWarnings(suppressPackageStartupMessages(library(Seurat)))

required_files <- c(
  "combined_qc.rds",
  "qc_summary.csv",
  "markers.csv",
  "run_manifest.txt",
  "sessionInfo.txt"
)

for (file_name in required_files) {
  full_path <- file.path(args, file_name)
  if (!file.exists(full_path)) {
    record_failure(paste("Missing required artifact", file_name))
  } else if (file.info(full_path)$size <= 0L) {
    record_failure(paste("Artifact is empty:", file_name))
  }
}

if (length(failures) > 0L) {
  fail_and_exit()
}

combined <- tryCatch(
  readRDS(file.path(args, "combined_qc.rds")),
  error = function(error) {
    record_failure(paste("combined_qc.rds could not be read:", conditionMessage(error)))
    NULL
  }
)

if (!inherits(combined, "Seurat")) {
  record_failure("combined_qc.rds is not a Seurat object")
}

if (inherits(combined, "Seurat")) {
  sample_levels <- unique(as.character(combined$orig.ident))
  expected_samples <- c("ctrl", "stim")
  if (!setequal(sample_levels, expected_samples)) {
    record_failure(
      paste(
        "Seurat object must contain the stable ctrl and stim sample identities; found:",
        paste(sort(sample_levels), collapse = ", ")
      )
    )
  }

  required_meta <- c("percent.mito", "percent.ribo", "seurat_clusters")
  missing_meta <- required_meta[!required_meta %in% colnames(combined[[]])]
  if (length(missing_meta) > 0L) {
    record_failure(paste("Missing required metadata columns:", paste(missing_meta, collapse = ", ")))
  }

  reductions <- Reductions(combined)
  if (!"pca" %in% reductions) {
    record_failure("PCA reduction is missing")
  }
  if (!"umap" %in% reductions) {
    record_failure("UMAP reduction is missing")
  }

  counts_layer <- tryCatch(
    LayerData(combined, assay = "RNA", layer = "counts"),
    error = function(error) {
      record_failure(paste("RNA counts layer is unavailable:", conditionMessage(error)))
      NULL
    }
  )
  if (!is.null(counts_layer) && (nrow(counts_layer) == 0L || ncol(counts_layer) == 0L)) {
    record_failure("RNA counts layer exists but is empty")
  }

  if ("cell_type" %in% colnames(combined[[]])) {
    record_failure("Unexpected cell_type column found; preprocessing skill must not fabricate annotations")
  }
}

markers <- tryCatch(
  read.csv(file.path(args, "markers.csv"), stringsAsFactors = FALSE),
  error = function(error) {
    record_failure(paste("markers.csv could not be read:", conditionMessage(error)))
    NULL
  }
)

expected_marker_columns <- c("gene", "cluster", "avg_log2FC", "pct.1", "pct.2", "p_val", "p_val_adj")
if (!is.null(markers)) {
  missing_marker_columns <- expected_marker_columns[!expected_marker_columns %in% colnames(markers)]
  if (length(missing_marker_columns) > 0L) {
    record_failure(
      paste(
        "markers.csv is missing expected columns:",
        paste(missing_marker_columns, collapse = ", ")
      )
    )
  }
  if (nrow(markers) == 0L) {
    record_failure("markers.csv has no rows")
  }
}

manifest_lines <- readLines(file.path(args, "run_manifest.txt"), warn = FALSE)
if (!any(grepl("^source_workflow: scRNAseq_general_workflow$", manifest_lines))) {
  record_failure("run_manifest.txt is missing the expected source workflow provenance")
}

manifest_value <- function(key) {
  matches <- manifest_lines[startsWith(manifest_lines, paste0(key, ": "))]
  if (length(matches) != 1L) {
    return(NULL)
  }
  sub(paste0("^", key, ": "), "", matches)
}

execution_branch <- manifest_value("execution_branch")
if (length(execution_branch) != 1L || !execution_branch %in% c("reference_subset", "full_data")) {
  record_failure("run_manifest.txt must declare execution_branch as reference_subset or full_data")
}

if (!identical(manifest_value("sample_labels"), "ctrl,stim")) {
  record_failure("run_manifest.txt must declare stable sample_labels: ctrl,stim")
}

qc_summary <- tryCatch(
  read.csv(file.path(args, "qc_summary.csv"), stringsAsFactors = FALSE),
  error = function(error) {
    record_failure(paste("qc_summary.csv could not be read:", conditionMessage(error)))
    NULL
  }
)
if (!is.null(qc_summary)) {
  sample_rows <- qc_summary[qc_summary$sample %in% c("ctrl", "stim"), , drop = FALSE]
  if (nrow(sample_rows) != 2L || any(sample_rows$input_barcodes < sample_rows$subset_barcodes)) {
    record_failure("qc_summary.csv must report valid input and selected barcode counts for ctrl and stim")
  }
  if (identical(execution_branch, "full_data") && nrow(sample_rows) == 2L &&
      any(sample_rows$input_barcodes != sample_rows$subset_barcodes)) {
    record_failure("full_data branch must select every barcode from each supplied matrix")
  }
}

session_lines <- readLines(file.path(args, "sessionInfo.txt"), warn = FALSE)
for (pattern in c("^Seurat: ", "^SeuratObject: ", "^Matrix: ")) {
  if (!any(grepl(pattern, session_lines))) {
    record_failure(paste("sessionInfo.txt is missing version evidence for", sub(": $", "", gsub("\\^", "", pattern))))
  }
}

if (length(failures) > 0L) {
  fail_and_exit()
}

message(
  "Validation passed for ", args,
  " (branch=", execution_branch,
  "; ctrl selected/input=", manifest_value("ctrl_selected_barcodes"), "/", manifest_value("ctrl_input_barcodes"),
  "; stim selected/input=", manifest_value("stim_selected_barcodes"), "/", manifest_value("stim_input_barcodes"), ")"
)
