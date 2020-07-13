FROM python:3.6.3
RUN curl -sSL https://get.docker.com/builds/Linux/x86_64/docker-1.11.0.tgz | tar -xz; \
    mv docker/docker /usr/bin/docker; \
    rm -rf docker
RUN apt update; apt install -y dnsutils
COPY requirements.txt /requirements.txt
RUN pip install -r requirements.txt
RUN echo 'export PS1="tests:\w\$ "' > /.bashrc

ENTRYPOINT /bin/bash
