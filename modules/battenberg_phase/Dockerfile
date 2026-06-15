FROM rocker/tidyverse:4.3.2

# htslib tools (tabix/bgzip) for indexing the output VCF
RUN apt-get update && apt-get install -y --no-install-recommends \
    tabix \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    zlib1g-dev \
    libbz2-dev \
    liblzma-dev \
    && rm -rf /var/lib/apt/lists/*

# R dependencies
RUN R -e "install.packages(c('optparse', 'vcfR', 'remotes'), repos = 'https://cloud.r-project.org')"

# Bioconductor dependencies required by Battenberg / ASCAT
RUN R -e "install.packages('BiocManager', repos = 'https://cloud.r-project.org'); BiocManager::install(c('GenomicRanges', 'VariantAnnotation', 'IRanges', 'Biostrings', 'Rsamtools'), update = FALSE, ask = FALSE)"

# copynumber was removed from Bioconductor; install the maintained GitHub fork
RUN R -e "remotes::install_github('aroneklund/copynumber', upgrade = 'never')"

# ASCAT (Battenberg dependency)
RUN R -e "remotes::install_github('VanLoo-lab/ascat/ASCAT', upgrade = 'never')"

# Battenberg (provides getMad and selectFastPcf used by battenberg_phase.R)
RUN R -e "remotes::install_github('Wedge-Oxford/battenberg', upgrade = 'never')"
