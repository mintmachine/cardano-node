FROM allanhart/cardano-node:latest

# ------------------------------------------------------------------------------
# Update package repository and upgrade to latest build
# ------------------------------------------------------------------------------
RUN apt update -y && apt upgrade -y && apt install build-essential -y

# ------------------------------------------------------------------------------
# Run the node as a non-root user
# ------------------------------------------------------------------------------
RUN adduser --disabled-password --gecos "" cardano
USER cardano

COPY start-relay.sh /home/cardano/
