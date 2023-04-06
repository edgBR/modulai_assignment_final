FROM ubuntu:22.04

ENV R_BASE_VERSION 4.1.0
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y software-properties-common dirmngr && \
    rm -rf /var/lib/apt/lists/*

RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9
RUN add-apt-repository 'deb https://cloud.r-project.org/bin/linux/ubuntu jammy-cran40/'

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get install -y --no-install-recommends \    
    apt-utils \
    r-base-core \
    r-base-dev \
    ca-certificates \
    libssl-dev \
    libxml2-dev \
    curl \
    libsqliteodbc \
    libcurl4-gnutls-dev

ENV RENV_PATHS_CACHE=/renv/cache
RUN R -e "install.packages('renv', repos = c(CRAN = 'https://cloud.r-project.org'))"


COPY . /opt/ml/
WORKDIR /opt/ml/code
 
COPY renv.lock /opt/ml/code/renv.lock
RUN R -e 'renv::restore(prompt = FALSE)'

EXPOSE 8080
ENTRYPOINT ["Rscript", "main.R"]
