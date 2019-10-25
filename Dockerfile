FROM rocker/tidyverse

RUN Rscript -e 'install.packages(c("coda","mvtnorm","devtools","loo"))'
RUN Rscript -e 'devtools::install_github("rmcelreath/rethinking")'
RUN Rscript -e 'install.packages("bayesplot")'
RUN Rscript -e 'install.packages("tidybayes")'
RUN Rscript -e 'install.packages("rstan")'
RUN Rscript -e 'install.packages("abind")'
RUN Rscript -e 'install.packages("pdfetch")'

