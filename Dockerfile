# Constructs an Ubuntu-based Docker image provisioned with the latest
# cardano-node and cardano-cli binaries as outlined by:
# https://docs.cardano.org/projects/cardano-node/en/latest/getting-started/install.html

# ------------------------------------------------------------------------------
# Use Ubuntu LTS
# ------------------------------------------------------------------------------
FROM ubuntu:latest

WORKDIR /usr/src
ENV DEBIAN_FRONTEND=noninteractive

# ------------------------------------------------------------------------------
# Install build dependencies
# ------------------------------------------------------------------------------
RUN apt update -y \
 && apt install automake build-essential curl pkg-config libffi-dev libgmp-dev libssl-dev libtinfo-dev libsystemd-dev zlib1g-dev make g++ tmux git jq wget libncursesw5 libtool autoconf -y


# ------------------------------------------------------------------------------
# Fetch and update Cabal
# ------------------------------------------------------------------------------
RUN curl -LJO https://downloads.haskell.org/~cabal/cabal-install-3.2.0.0/cabal-install-3.2.0.0-x86_64-unknown-linux.tar.xz \
 && tar -xf cabal-install-3.2.0.0-x86_64-unknown-linux.tar.xz  \
 && rm cabal-install-3.2.0.0-x86_64-unknown-linux.tar.xz  \
 && rm cabal.sig \
 && mv cabal /usr/local/bin/ \
 && cabal update

# ------------------------------------------------------------------------------
# Download and install GHC compiler
# ------------------------------------------------------------------------------
RUN curl -LJO https://downloads.haskell.org/ghc/8.10.2/ghc-8.10.2-x86_64-deb9-linux.tar.xz \
 && tar -xf ghc-8.10.2-x86_64-deb9-linux.tar.xz \
 && rm ghc-8.10.2-x86_64-deb9-linux.tar.xz \
 && cd ghc-8.10.2 \
 && ./configure \
 && make install \
 && cd .. \
 && rm -rf ghc-8.10.2

# # ------------------------------------------------------------------------------
# # Download and install libsodium
# # ------------------------------------------------------------------------------
RUN git clone https://github.com/input-output-hk/libsodium \
  && cd libsodium \
  && git checkout 66f017f1 \
  && ./autogen.sh \
  && ./configure \
  && make \
  && make install \
  && cd .. \
  && rm -rf libsodium

ENV LD_LIBRARY_PATH="/usr/local/lib:${LD_LIBRARY_PATH}"
ENV PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:${PKG_CONFIG_PATH}"

# ------------------------------------------------------------------------------
# Download, build, and install Cardano Node (v1.26.2)
# ------------------------------------------------------------------------------
RUN git clone https://github.com/input-output-hk/cardano-node.git \
  && cd cardano-node \
  && git fetch --all --recurse-submodules --tags \
  && git checkout tags/1.26.2 \
  && cabal configure --with-compiler=ghc-8.10.2 \
  && echo "package cardano-crypto-praos" >>  cabal.project.local \
  && echo "flags: -external-libsodium-vrf" >>  cabal.project.local \
  && cabal build all

RUN find . -name cardano-node -type f -executable -exec cp {} /usr/local/bin \;
RUN find . -name cardano-cli -type f -executable -exec cp {} /usr/local/bin \;


# ------------------------------------------------------------------------------
# Final stage will merely consist of an Ubuntu instance equipped
# with the compiled Cardano binaries
# ------------------------------------------------------------------------------
FROM ubuntu:latest

ENV LD_LIBRARY_PATH="/usr/local/lib:${LD_LIBRARY_PATH}"
ENV PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:${PKG_CONFIG_PATH}"

COPY --from=0 /usr/local/bin/cardano-node /usr/local/bin/cardano-cli /usr/local/bin/
COPY --from=0 /usr/local/lib/libsodium* /usr/local/lib/
