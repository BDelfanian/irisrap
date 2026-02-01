# Reproducible Analytical Pipeline - Final Project

**Course:** Reproducible Analytical Pipelines<a href="https://rap4mads.eu/" target="_blank" rel="noopener noreferrer nofollow"></a>  
**Student:** Behrouz Delfanian  
**Date:** January 2026  
**Location:** Luxembourg

## Project Goal
Simple analytical task on `iris` built-in dataset  
Goal: cover all main course pillars in one coherent pipeline.

## Reproducibility instructions

```bash
git clone https://github.com/yourusername/rap-final-behrouz.git
cd rap-final-behrouz
direnv allow
# Then open in Positron
```
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
