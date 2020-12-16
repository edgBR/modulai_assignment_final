FROM ubuntu

ENV R_BASE_VERSION 4.0.3
RUN apt-get update && \
    apt-get install -y software-properties-common && \
    rm -rf /var/lib/apt/lists/*

RUN add-apt-repository 'deb https://cloud.r-project.org/bin/linux/ubuntu focal-cran40/'

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get install -y --no-install-recommends \    
    apt-utils \
    r-base-core \
	  r-base \
	  r-base-dev \
	  r-recommended \
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
