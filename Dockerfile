FROM python:2.7.15-jessie

WORKDIR /app

# Download & install Application Manager

RUN wget https://arm1s11-eiffel004.eiffel.gic.ericsson.se:8443/nexus/content/repositories/releases/com/ericsson/orchestration/mgmt/packaging/am-package-manager/0.0.8/am-package-manager-0.0.8.tar.gz

RUN tar -zxvf am-package-manager-0.0.8.tar.gz
RUN /bin/sh /app/am-package-manager-0.0.8/install.sh
ENV PATH="${PATH}:/root/.local/bin"
COPY am-patches /root/.local/lib/python2.7/site-packages/am_package_manager/cli/
COPY am-patches /root/.local/lib/python2.7/site-packages/am_package_manager/generator/

# Setup Docker

RUN apt-get update
RUN apt-get -y install \
     apt-transport-https \
     ca-certificates \
     curl \
     gnupg2 \
     software-properties-common
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
RUN add-apt-repository \
       "deb [arch=amd64] https://download.docker.com/linux/debian \
       $(lsb_release -cs) \
       stable"
RUN apt-get update
RUN apt-get -y install docker-ce

# Setup helm

RUN mkdir -p bin
RUN wget https://storage.googleapis.com/kubernetes-helm/helm-v2.8.2-linux-amd64.tar.gz
RUN mv helm-v2.8.2-linux-amd64.tar.gz bin/helm-v2.8.2-linux-amd64.tar.gz
RUN cd bin/ && tar -zxvf helm-v2.8.2-linux-amd64.tar.gz
ENV PATH="/app/bin/linux-amd64:${PATH}"

# AM as Entrypoint
ENTRYPOINT ["/root/.local/bin/am-package-manager"]
