# Dockerfile - using official Nix base image

FROM nixos/nix:latest

# Set working directory
WORKDIR /app

# Copy project files
COPY . .

# Install R and rix from nixpkgs (declarative)
RUN nix-env -iA nixpkgs.R nixpkgs.rPackages.rix

# Generate the environment (default.nix)
RUN nix-shell -p R rPackages.rix --run "R -e 'source(\"gen-env.R\")'"

# Create writable user library for local irisrap package
RUN mkdir -p /root/R/library \
    && echo '.libPaths(c("/root/R/library", .libPaths()))' >> /root/.Rprofile

# Install local irisrap package
RUN nix-shell --run "R CMD INSTALL --library=/root/R/library ."

# Default command: run pipeline + render report
CMD ["sh", "-c", "R -e 'targets::tar_make()' && quarto render quarto/iris-analysis-report.qmd"]