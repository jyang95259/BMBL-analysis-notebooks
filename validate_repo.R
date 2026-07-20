#!/usr/bin/env Rscript

# BMBL Analysis Notebooks - Repository Validation Script
# Run this locally before pushing to catch issues early
#
# Usage: Rscript validate_repo.R

library(utils)

cat("========================================\n")
cat("BMBL Repository Validation\n")
cat("========================================\n\n")

errors <- 0
warnings <- 0

# Color codes (if terminal supports it)
red <- "\033[31m"
green <- "\033[32m"
yellow <- "\033[33m"
reset <- "\033[0m"

# Helper functions
check_pass <- function(msg) {
  cat(green, "✓", reset, msg, "\n")
}

check_fail <- function(msg) {
  cat(red, "✗", reset, msg, "\n")
  errors <<- errors + 1
}

check_warn <- function(msg) {
  cat(yellow, "⚠", reset, msg, "\n")
  warnings <<- warnings + 1
}

read_text_file <- function(path) {
  if (!file.exists(path)) {
    return("")
  }
  paste(readLines(path, warn = FALSE), collapse = "\n")
}

extract_front_matter <- function(text) {
  match <- regexec("(?s)^---\n(.*?)\n---(?:\n|$)", text, perl = TRUE)
  captures <- regmatches(text, match)[[1]]
  if (length(captures) < 2) {
    return(NULL)
  }
  captures[2]
}

workflow_pages <- function() {
  c(
    "rnaseq-workflow.qmd",
    sort(list.files("site/workflows", pattern = "\\.qmd$", full.names = TRUE))
  )
}

required_site_headings <- c(
  "## What it does",
  "## When to use it",
  "## Prerequisites",
  "## Steps",
  "## Gotchas / notes"
)

extract_markdown_image_paths <- function(text) {
  matches <- gregexpr("!\\[[^]]*\\]\\(([^)]+)\\)", text, perl = TRUE)
  raw <- regmatches(text, matches)[[1]]
  if (length(raw) == 0) {
    return(character())
  }
  paths <- sub("^!\\[[^]]*\\]\\(([^)]+)\\)$", "\\1", raw, perl = TRUE)
  trimws(sub("\\s+\"[^\"]*\"$", "", paths, perl = TRUE))
}

# 1. Check required root files
cat("1. Checking required root files...\n")
required_files <- c(
  "AGENTS.md",
  "CLAUDE.md", 
  "CONTRIBUTING.md",
  "README.md",
  "RATIONALE.md"
)

for (file in required_files) {
  if (file.exists(file)) {
    check_pass(paste(file, "exists"))
  } else {
    check_fail(paste(file, "is missing"))
  }
}
cat("\n")

# 2. Check workflow directories
cat("2. Checking workflow directories...\n")
all_dirs <- list.dirs(".", recursive = FALSE)
exclude_dirs <- c(".git", ".github", "_common", "_figure_code",
                  "_Archived", "_Introduction_OSC", "dependencies",
                  "_generated", "docs", "scripts", "site", "skills")

workflow_dirs <- all_dirs[!basename(all_dirs) %in% exclude_dirs & 
                           !grepl("^\\.", basename(all_dirs))]

for (dir in workflow_dirs) {
  dir_name <- basename(dir)
  cat("  Checking:", dir_name, "\n")
  
  # Check for README
  if (file.exists(file.path(dir, "README.md"))) {
    check_pass(paste("  README.md exists"))
  } else {
    check_warn(paste("  README.md missing"))
  }
  
  # Check for install packages script if R files exist
  r_files <- list.files(dir, pattern = "\\.(rmd|r|R)$", ignore.case = TRUE)
  if (length(r_files) > 0) {
    if (file.exists(file.path(dir, "0_install_packages.R"))) {
      check_pass(paste("  0_install_packages.R exists"))
    } else {
      check_warn(paste("  0_install_packages.R missing (R code detected)"))
    }
  }
}
cat("\n")

# 3a. Check generated website files and site catalog alignment
cat("3a. Checking generated website files...\n")
if (!nzchar(Sys.which("python3"))) {
  check_warn("python3 not found - skipping generated-site catalog sync check")
} else {
  site_check <- tryCatch(
    system2(
      "python3",
      c("scripts/build_site_catalog.py", "--check"),
      stdout = TRUE,
      stderr = TRUE
    ),
    error = function(e) structure(
      paste("Could not run build_site_catalog.py:", conditionMessage(e)),
      status = 1L
    )
  )

  if (is.null(attr(site_check, "status"))) {
    check_pass("Generated site files and catalog are in sync")
  } else {
    check_fail(paste(site_check, collapse = "\n"))
  }
}
cat("\n")

# 3. Check R file syntax
cat("3. Checking R file syntax...\n")
r_files <- list.files(".", pattern = "\\.[rR]$", recursive = TRUE, full.names = TRUE)
r_files <- r_files[!grepl("\\.git", r_files)]

for (file in r_files) {
  tryCatch({
    parse(file)
    check_pass(paste(file))
  }, error = function(e) {
    check_fail(paste(file, "-", conditionMessage(e)))
  })
}
cat("\n")

# 4. Check YAML syntax
cat("4. Checking YAML files...\n")
yaml_files <- c("environment.yml", "dependencies/index.yml")

for (file in yaml_files) {
  if (file.exists(file)) {
    # Try to read with yaml package if available
    if (requireNamespace("yaml", quietly = TRUE)) {
      tryCatch({
        yaml::yaml.load_file(file)
        check_pass(paste(file, "is valid YAML"))
      }, error = function(e) {
        check_fail(paste(file, "has YAML errors:", conditionMessage(e)))
      })
    } else {
      check_warn(paste("Cannot validate", file, "- install 'yaml' package"))
    }
  } else {
    check_warn(paste(file, "not found"))
  }
}
cat("\n")

# 5. Check site workflow pages
cat("5. Checking site workflow pages...\n")
for (page in workflow_pages()) {
  if (!file.exists(page)) {
    check_fail(paste(page, "is referenced but does not exist"))
    next
  }
  text <- read_text_file(page)
  front_matter <- extract_front_matter(text)

  if (is.null(front_matter)) {
    check_fail(paste(page, "is missing YAML front matter"))
    next
  }

  # Anchor to a top-level `workflow:` key with indented children, so a stray
  # top-level `id:`/`repo_path:` (or the word "workflow:" in prose) cannot pass.
  if (grepl("(?m)^workflow:[ \\t]*$", front_matter, perl = TRUE)) {
    check_pass(paste(page, "has workflow metadata"))
  } else {
    check_fail(paste(page, "is missing workflow metadata block"))
  }

  if (grepl("(?m)^[ \\t]+id:\\s*\"?[A-Za-z0-9_-]+\"?", front_matter, perl = TRUE)) {
    check_pass(paste(page, "has workflow.id"))
  } else {
    check_fail(paste(page, "is missing workflow.id"))
  }

  if (grepl("(?m)^[ \\t]+repo_path:\\s*\"?[^\n\"]+\"?", front_matter, perl = TRUE)) {
    check_pass(paste(page, "has workflow.repo_path"))
  } else {
    check_fail(paste(page, "is missing workflow.repo_path"))
  }

  for (heading in required_site_headings) {
    # Anchor to a whole line so a deeper level (`### Prerequisites`) or a
    # reworded heading (`## What it does differently`) does not falsely pass.
    heading_pattern <- paste0("(?m)^", heading, "[ \\t]*$")
    if (grepl(heading_pattern, text, perl = TRUE)) {
      check_pass(paste(page, "contains", heading))
    } else {
      check_fail(paste(page, "is missing", heading))
    }
  }

  if (grepl("View source on GitHub", text, fixed = TRUE)) {
    check_pass(paste(page, "contains View source link"))
  } else {
    check_fail(paste(page, "is missing View source on GitHub link"))
  }
}
cat("\n")

# 6. Check local image assets referenced by site pages
cat("6. Checking local image assets used by site pages...\n")
for (page in c("index.qmd", workflow_pages())) {
  text <- read_text_file(page)
  image_paths <- extract_markdown_image_paths(text)
  local_paths <- image_paths[!grepl("^(https?:)?//", image_paths)]

  if (length(local_paths) == 0) {
    check_pass(paste(page, "has no local image references to validate"))
    next
  }

  for (img in local_paths) {
    resolved <- file.path(dirname(page), img)
    if (file.exists(resolved)) {
      check_pass(paste(page, "references existing image", img))
    } else {
      check_fail(paste(page, "references missing image", img))
    }
  }
}
cat("\n")

# 7. Check root README live-site link placement
cat("7. Checking root README live-site link...\n")
readme_top <- readLines("README.md", warn = FALSE, n = 20)
if (any(grepl("https://osu-bmbl.github.io/BMBL-analysis-notebooks/", readme_top, fixed = TRUE))) {
  check_pass("README.md includes the live-site link near the top")
} else {
  check_fail("README.md is missing the live-site link near the top")
}
cat("\n")

# 8. Check for AI context files (Phase 5)
cat("8. Checking AI context files (Phase 5)...\n")
major_workflows <- c(
  "scRNAseq_general_workflow",
  "scRNAseq_trajectory_Slingshot",
  "scATACseq_general_workflow",
  "RNAseq_nfcore_workflow",
  "ST_general_workflow"
)

for (workflow in major_workflows) {
  ai_context_file <- file.path(workflow, ".ai_context.md")
  if (file.exists(ai_context_file)) {
    check_pass(paste(workflow, "has .ai_context.md"))
  } else {
    check_warn(paste(workflow, "missing .ai_context.md"))
  }
}

# Check for common recipes file
if (file.exists("_common/ai_recipes.md")) {
  check_pass("_common/ai_recipes.md exists")
} else {
  check_warn("_common/ai_recipes.md missing")
}
cat("\n")

# Summary
cat("========================================\n")
cat("Validation Summary\n")
cat("========================================\n")

if (errors == 0 && warnings == 0) {
  cat(green, "✓ All checks passed!\n", reset)
  quit(status = 0)
} else {
  if (errors > 0) {
    cat(red, sprintf("✗ %d error(s) found\n", errors), reset)
  }
  if (warnings > 0) {
    cat(yellow, sprintf("⚠ %d warning(s) found\n", warnings), reset)
  }
  if (errors == 0) {
    cat("Repository is valid but has warnings.\n")
    quit(status = 0)
  } else {
    cat("\nPlease fix the errors before pushing.\n")
    quit(status = 1)
  }
}
