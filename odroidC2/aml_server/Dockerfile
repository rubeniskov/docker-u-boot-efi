FROM debian:jessie

ENV DAPPER_RUN_ARGS --port 3000:3000
ENV DAPPER_WORKDIR /src
ENV DAPPER_BUILDDIR $DAPPER_WORKDIR/build
ENV NVM_DIR /usr/local/nvm
ENV NODE_VERSION 5.1.0
ENV PATH /usr/local/nvm/versions/node/v${NODE_VERSION}/bin:${PATH}
ENV DAPPER_APP_DIR /var/aml_server

# Set the work directory
WORKDIR ${DAPPER_APP_DIR}
RUN mkdir -p $DAPPER_APP_DIR

# Copy aml server
ADD . ${DAPPER_APP_DIR}

# Replace shell with bash so we can source files
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# Download dependencies
RUN apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates curl

# Install nvm with node and npm
RUN curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.0/install.sh | bash \
    && source $NVM_DIR/nvm.sh \
    && nvm install $NODE_VERSION \
    && nvm alias default node \
    && nvm use default \
    && source ~/.bashrc \
    && echo -e 'Remove apt source list' \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get -y autoclean

# Installing app dependencies
RUN npm link

#ENTRYPOINT aml_server
CMD aml_server
