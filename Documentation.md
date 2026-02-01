# Reproducible Analytical Pipelines
....

## Overall Context and Goals
The core idea is to build reproducible analytical pipelines (RAPs) that produce data products (e.g., reports, apps, or analyses) in a way that's automated, versioned, testable, and shareable.

- RAPs emphasize automation over manual work: code that runs consistently, minimizes errors, and scales.

- It is recommended to employ plain-text scripts, functional programming, and build tools instead of Jupyter notebooks as they introduce "state" (non-reproducible execution order).

- **Why Reproducibility?**: Non-reproducible work leads to "it works on my machine" issues, wasted time, and unscientific results.  
The pillars of reproducibility are:

    - Reproducible environments (Nix): Use Nix (via {rix}) for declarative environments.

    - Reproducible history (Git).

    - Reproducible logic (functional programming and unit testing).

    - Orchestration (pipelines, Docker, CI/CD).

## Steps on Windows

### Step 1: Define the project and set up your workspace
Goal: Plan the analysis and prepare your local setup.

- Ensure WSL is enabled: Open PowerShell as admin, run `wsl --install`
- Install Nix in WSL
- Install Git
- Set up Git globally
- Install VS Code/Positron
- Create project folder in WSL

### Step 2: Set up the reproducible Nix environment with {rix}
Goal: Create a `default.nix` file that defines a reproducible environment containing:

- R
- tidyverse (for data manipulation and ggplot2)
- testthat (for unit testing in R)
- languageserver (for better Positron/VS Code integration)
- Python + pandas, seaborn, matplotlib (for polyglot part)
- quarto (CLI) so we can render documents from the shell

#### 2.1 Create the environment generator script
In your project folder, create a file called `gen-env.R`.

#### 2.2 Run the script inside a temporary Nix shell with {rix}
In your WSL terminal (inside the project folder):

```bash
# Start a temporary shell that has R + {rix}
nix-shell -p R rPackages.rix

# Inside the shell → start R
R
```

Then inside R:

```r
source("gen-env.R")
```

Everytime you update `gen-env.R` file, run the following in WSL terminal:  
`nix-shell -p R rPackages.rix --run "R -e 'source(\"gen-env.R\")'"`

#### 2.3 Activate the environment for development
Create a file called `.envrc` in the project root:

```bash
# .envrc
use nix
mkdir $TMP
```

Then allow it (only needed once):

```bash
direnv allow
```

Now every time you open a terminal in this folder, it should automatically load the Nix shell (you'll see a message like "direnv: loading ...").

Open Positron on Windows, install `direnv` extension, open the project folder and confirm the message to restart the environment.

### Step 3: Writing Pure Functions
- Pure functions (same input → same output, no side effects, no globals)
- Replace loops with map/filter/reduce where natural
- Self-contained, testable, composable

### Step 4 – Unit Testing
We prove our functions work as claimed (happy path, edges, errors). We use `testthat` in R and `pytest` in Python.

#### 4.1 Create test files
...

#### 4.2 R unit tests
...

#### 4.3 Run the R tests
In WSL terminal: `R -e "testthat::test_dir('tests/testthat')"`

In Positron console: `testthat::test_dir('tests/testthat')`

### Step 5 – Create a Simple Quarto Report

#### 5.1 Create the Quarto file
...

#### 5.2 Write the report content
...

#### 5.3 Render the report

In terminal (inside project folder):

```bash
quarto render quarto/iris-analysis-report.qmd
```

### Step 6 – Convert Project to R Package

To make the functions reusable, documented, and testable in a standard way, we convert the project into a minimal R package named `irisrap`.

Key lessons learned:
- Package names must follow CRAN rules (letters, numbers, dots; start with letter; no underscores).
- Nix-managed R libraries are read-only (`/nix/store/...`), so `devtools::install()` and `R CMD INSTALL` fail unless we direct installation to a writable user library.
- Non-interactive R sessions (e.g., `R -e`, Quarto rendering) may not automatically inherit shell variables like `R_LIBS_USER` — explicit prepending or startup configuration is often needed.

#### 6.1 Choose a valid package name and prepare folder

Avoid underscores or invalid characters in the folder name.

#### 6.2 Initialize minimal package structure
Create `DESCRIPTION`, `NAMESPACE`, and `R/` folder manually (since `usethis::create_package('.')` fails in existing Git repo due to nesting detection).

#### 6.3 Add roxygen2 documentation
Add full roxygen comments to `R/clean_and_summarize.R` (with `@export`, `@param`, `@return`, `@examples`, and `@importFrom` for tidyverse NSE).

#### 6.4 Generate documentation and namespace

```bash
R -e "devtools::document()"
```

This creates/updates `NAMESPACE` and `man/` folder with `.Rd` help files.

#### 6.5 Run package checks and tests

```bash
# Check (should pass with 0 errors; notes are acceptable)
R -e "devtools::check()"

# Run tests (should show all tests passing)
R -e "devtools::test()"
```

#### 6.6 Install package locally (Nix-specific workaround)
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

#### 6.7 Render the data product (Quarto report) using the package
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

