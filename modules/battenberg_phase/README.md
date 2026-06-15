# BATTENBERG_PHASE container

This module needs R + tidyverse + vcfR + Battenberg (for `getMad` and
`selectFastPcf`) plus `tabix` for indexing the output VCF.

## Build and push

```sh
cd modules/battenberg_phase
docker build -t <registry>/battenberg-phase:1.0 .
docker push <registry>/battenberg-phase:1.0
```

Then update the `container` directive in `modules/battenberg_phase/main.nf`
with the pushed image path (Nextflow will pull it via Singularity when
`-profile singularity` is used).

## Script

`bin/battenberg_phase.R` is auto-added to `$PATH` by Nextflow (module `bin/`
directories are added automatically), so it's invoked directly as
`battenberg_phase.R` in `main.nf`'s script block.
