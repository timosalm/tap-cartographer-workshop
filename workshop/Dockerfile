FROM registry.tanzu.vmware.com/tanzu-application-platform/tap-packages@sha256:a8870aa60b45495d298df5b65c69b3d7972608da4367bd6e69d6e392ac969dd4

# All the direct Downloads need to run as root as they are going to /usr/local/bin
USER root

# Tanzu CLI
COPY tanzu-framework-linux-amd64.tar /tmp
RUN export TANZU_CLI_NO_INIT=true
RUN cd /tmp && tar -xvf "tanzu-framework-linux-amd64.tar" -C /tmp && \ 
    sudo install "cli/core/v0.11.6/tanzu-core-linux_amd64" /usr/local/bin/tanzu && \ 
    tanzu plugin install --local cli all

# Knative
RUN curl -L -o /usr/local/bin/kn https://github.com/knative/client/releases/download/knative-v1.4.1/kn-linux-amd64 && \
    chmod 755 /usr/local/bin/kn

# TBS CLI
RUN curl -L -o /usr/local/bin/kp https://github.com/vmware-tanzu/kpack-cli/releases/download/v0.5.0/kp-linux-0.5.0 && \
  chmod 755 /usr/local/bin/kp

# Installing Krew
# Source doc: https://krew.sigs.k8s.io/docs/user-guide/setup/install/
# RUN set -x; cd "$(mktemp -d)" &&
#   OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
#   ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
#   KREW="krew-${OS}_${ARCH}" &&
#   curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" &&
#   tar zxvf "${KREW}.tar.gz" &&
#   ./"${KREW}" install krew tree 
#   cp ~/.krew/bin/kubectl-krew /usr/local/bin/     
# RUN curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/download/v0.4.3/krew-linux_arm64.tar.gz" && \
#     tar zxvf krew-linux_arm64.tar.gz && \
#     KREW=./krew-linux_arm64 && \
#     "$KREW" install krew && \
#     cp ~/.krew/bin/kubectl-krew /usr/local/bin/     

# RUN echo 'export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"' >> ~/.bashrc

# SHELL ["/bin/bash", "-c"]

# ENV PATH=/usr/local/bin/:$PATH
# RUN kubectl krew install tree

# Utilities
RUN apt-get update && apt-get install -y unzip openjdk-11-jdk moreutils

# Cleanup directory

RUN rm -rf /tmp/*

USER 1001
COPY --chown=1001:0 . /home/eduk8s/
RUN fix-permissions /home/eduk8s
RUN rm /home/eduk8s/tanzu-framework-linux-amd64.tar
