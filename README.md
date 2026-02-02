# Reproducible Analytical Pipelines – Final Project Documentation 

**Course:** Reproducible Analytical Pipelines<a href="https://rap4mads.eu/" target="_blank" rel="noopener noreferrer nofollow"></a>  
**Repository**: https://github.com/BDelfanian/irisrap  
**Student:** Behrouz Delfanian  
**Date:** January 2026  
**Location:** Luxembourg

## Course Material Update Suggestion

### `nix-env` Deprecation

The course instructions in section **1.2.5.2 Actually installing Nix** recommend:

```bash
nix-env -iA cachix -f https://cachix.org/api/v1/install
```

As of late 2025 / early 2026, `nix-env` is deprecated for profile management and triggers this warning:

```
error: profile '...' is incompatible with 'nix-env'; please use 'nix profile' instead
```

The equivalent modern command is:

```bash
nix profile install nixpkgs#cachix
```

## Reproducibility Instructions

```bash
git clone https://github.com/BDelfanian/irisrap.git
cd irisrap
direnv allow
# Then open in Positron
```

## Project Goal & Context

The objective is to perform a simple analytical task (analysis of the built-in `iris` dataset) while demonstrating **all main pillars** of reproducible analytical pipelines:

- Reproducible environments (Nix + {rix})
- Reproducible history (Git from day 1)
- Reproducible logic (pure functions + unit testing)
- Packaging (minimal R package `irisrap`)
- Data products (Quarto report using the package)

The project deliberately focuses on **R-only** workflow (no Python) to keep it simple.

Environment: Windows + WSL (Ubuntu) + Positron + Nix + Git + Quarto

## Step 1 – Project Setup & Folder Structure

**Goal**: Create a clean, Git-versioned project structure.

```bash
# In WSL terminal
mkdir ~/irisrap
cd ~/irisrap

# Create folders
mkdir -p R tests/testthat quarto
```

Initialize Git, create a remote repository on GitHub and a `.gitignore` file (exclude Nix store, temp files, Quarto outputs).

## Step 2 – Reproducible Nix Environment with {rix}
**Goal**: Define a declarative R environment with all required packages.  

- Create `gen-env.R` in project root.  

```bash
library(rix)

rix(
  date = "2026-01-14",
  r_pkgs = c(
    "tidyverse",       # dplyr, ggplot2, tidyr, etc.
    "testthat",        # unit testing
    "devtools",        # package development
    "languageserver",  # Positron/VS Code integration
    "quarto"           # rendering
  ),
  project_path = ".",
  overwrite = TRUE,
  print = TRUE
)
```

- Generate `default.nix`

```bash
nix-shell -p R rPackages.rix --run "R -e 'source(\"gen-env.R\")'"
```

- Create `.envrc` file

```bash
use nix
mkdir &TMP
```

- Activate environment with direnv:

```bash
direnv allow
```

Now, every time you open a terminal in the project folder, it should automatically load the Nix shell (you'll see a message like "direnv: loading ...").


>Note: Everytime you update `gen-env.R` file, run the following in WSL terminal:  
`nix-shell -p R rPackages.rix --run "R -e 'source(\"gen-env.R\")'"`


Open Positron on Windows, install `direnv` extension, open the project folder and confirm the message to restart the environment.

## Step 3 – Pure Functions (Functional Programming)
**Goal**: Write pure, testable, composable functions.  
Create `R/clean_and_summarize.R`:

```r
# Pure functions for iris analysis

#' Clean and filter iris data
#' ...
clean_iris <- function(...) { ... }

#' Summarize measurements by species
#' ...
summarize_by_species <- function(...) { ... }

#' Plot boxplots faceted by measurement
#' ...
plot_iris_boxplots <- function(...) { ... }
```

## Step 4 – Unit Testing
**Goal**: Prove functions behave correctly.  
Create `tests/testthat/test-clean-summarize.R`:

```r
library(testthat)
library(irisrap)   # after packaging

test_data <- iris

test_that("clean_iris filters species correctly", {
  cleaned_setosa <- clean_iris(test_data, species = "setosa")
  expect_equal(as.character(unique(cleaned_setosa$Species)), "setosa")
  expect_equal(nrow(cleaned_setosa), 50)
})

test_that("summarize_by_species produces correct structure", {
  cleaned <- clean_iris(test_data)
  summary <- summarize_by_species(cleaned)
  expect_s3_class(summary, "tbl_df")
  expect_equal(ncol(summary), 10)
  expect_equal(as.character(unique(summary$Species)), levels(test_data$Species))
})
```

Run tests (after packaging):

```bash
R -e "devtools::test()"
```

## Step 5 – Convert Project to R Package

To make the functions reusable, documented, and testable in a standard way, we convert the project into a minimal R package named `irisrap`.

Key lessons learned:
- Package names must follow CRAN rules (letters, numbers, dots; start with letter; no underscores).
- Nix-managed R libraries are read-only (`/nix/store/...`), so `devtools::install()` and `R CMD INSTALL` fail unless we direct installation to a writable user library.
- Non-interactive R sessions (e.g., `R -e`, Quarto rendering) may not automatically inherit shell variables like `R_LIBS_USER` — explicit prepending or startup configuration is often needed.

### 5.1 Choose a valid package name and prepare folder

Avoid underscores or invalid characters in the folder name.

### 5.2 Initialize minimal package structure
Create `DESCRIPTION`, `NAMESPACE`, and `R/` folder manually (since `usethis::create_package('.')` fails in existing Git repo due to nesting detection).

### 5.3 Add roxygen2 documentation
Add full roxygen comments to `R/clean_and_summarize.R` (with `@export`, `@param`, `@return`, `@examples`, and `@importFrom` for tidyverse NSE).

### 5.4 Generate documentation and namespace

```bash
R -e "devtools::document()"
```

This creates/updates `NAMESPACE` and `man/` folder with `.Rd` help files.

### 5.5 Run package checks and tests

```bash
# Check (should pass with 0 errors; notes are acceptable)
R -e "devtools::check()"

# Run tests (should show all tests passing)
R -e "devtools::test()"
```

### 5.6 Install package locally (Nix-specific workaround)
**Problem**: Nix R libraries are read-only (`/nix/store/...`), so normal install commands fail:

```bash
# These fail:
R -e "devtools::install()"
R CMD INSTALL .
```

**Solution**: Install to a writable user library:

```bash
# Create user library if not exists
mkdir -p ~/R/library
chmod -R u+w ~/R/library

# Set environment variable
export R_LIBS_USER="$HOME/R/library"

# Verify
echo $R_LIBS_USER   # should show /home/delfanian_b/R/library

# Install package to user library
R CMD INSTALL --library="$HOME/R/library" .
```

**Verification** (in same shell):

```bash
R -e ".libPaths(c(Sys.getenv('R_LIBS_USER'), .libPaths())); library(irisrap); print('Loaded OK')"
```

### 5.7 Render the data product (Quarto report) using the package
The Quarto report needs to load `irisrap`. Because non-interactive R may not inherit `R_LIBS_USER`, add an explicit prepend in a setup chunk:  

```qmd
---
title: "Iris Dataset Analysis – Reproducible Report"
author: "Behrouz Delfanian"
date: today
format: html
execute:
  echo: true
  warning: false
---

```{r setup}
# Prepend user library path so irisrap is found
.libPaths(c(Sys.getenv("R_LIBS_USER"), .libPaths()))

library(irisrap)
library(tidyverse)
```

Then, render:

```bash
quarto render quarto/iris-analysis-report.qmd
```

## Step 6 - Orchestration / Pipeline with {targets}
**Goal**: Automate the entire analysis so that:

- Dependencies are tracked (change a function → only affected targets re-run)

- Results are cached

- Report renders only when needed

- Everything is reproducible

**Tool**: {targets} — the course's primary pipeline tool for R.

### 6.1 Install {targets}

Add to `gen-env.R`:

```r
r_pkgs = c(
  ... existing packages ...,
  "targets",
  "tarchetypes",       # helpers for Quarto rendering
  "visNetwork"         # for tar_visnetwork()
)
```

Re-generate environment:

```bash
nix-shell -p R rPackages.rix --run "R -e 'source(\"gen-env.R\")'"
```

Reload direnv:

```bash
direnv reload
```

### 6.2 Create `_targets.R` (pipeline definition)
Create `_targets.R` in project root.

### 6.3 Run the pipeline

```bash
# Build everything
R -e "targets::tar_make()"

# View dependency graph
R -e "targets::tar_visnetwork()"

# Clean (if you want to re-run)
R -e "targets::tar_destroy(destroy = 'all')"
```

> Important: Make user library available in targets pipeline  
> targets runs in clean R sessions, so prepend the user library in `_targets.R`:

>```r
>.libPaths(c(Sys.getenv("R_LIBS_USER"), .libPaths()))
>```
>This ensures `library(irisrap)` succeeds during pipeline execution.

## Step 7 – Containerization with Docker
**Goal**: Package the entire project (Nix env + `irisrap` + pipeline + report) into a Docker image for full portability.

- Create a Dockerfile that:
  - Starts from a base Ubuntu image
  - Installs Nix
  - Sets up the reproducible environment via `default.nix`
  - Installs the local `irisrap` package
  - Runs the {targets} pipeline
  - Renders the Quarto report

- Build and test the image locally
- Document how to reproduce everything inside Docker

### 7.1 Create Dockerfile in project root
Create a file called `Dockerfile` in `~/irisrap`.

### 7.2 Create `.dockerignore` (exclude unnecessary files)
Create `.dockerignore` in root.

This keeps the image small and clean.

### 7.3 Build the Docker image
In terminal (project root):

```bash
# Build image (named irisrap)
docker build -t irisrap .
```

>Important notes on Docker build
>**First build time & size**:
>- The initial `docker build` took ~25 minutes and used >15 GB of disk space.
>- This is expected: Nix downloads and caches all dependencies (R, tidyverse, quarto, >targets, compilers, etc.) with exact reproducibility.
>- Subsequent builds are much faster (~1–3 minutes) because Docker caches layers.

### 7.4 Test the container
Run the pipeline + report inside Docker:

```bash
docker run --rm -v $(pwd)/quarto:/app/quarto irisrap
```

