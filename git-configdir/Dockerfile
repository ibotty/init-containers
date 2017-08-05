FROM centos:7
MAINTAINER Tobias Florek <tob@butter.sh>

ENV CONFIGDIR_SECRETDIR=/run/secrets/git-configdir
VOLUME [/home/initcontainer]

RUN yum install -y git \
 && yum clean all \
 && useradd -mu 1001 initcontainer \
 && chmod g+rwx /home/initcontainer

USER 1001
