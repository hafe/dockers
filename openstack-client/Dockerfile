FROM ubuntu:15.04
MAINTAINER hafe

# An image with all the OpenStack client packages installed

RUN sed -i 's/archive.ubuntu.com/ftp.acc.umu.se/g' /etc/apt/sources.list

RUN apt-get update && apt-get install -y \
    libffi-dev \
    libssl-dev \
    python-dev \
    python-pip

RUN pip install \
    python-ceilometerclient \
    python-cinderclient \
    python-glanceclient \
    python-heatclient \
    python-keystoneclient \
    python-neutronclient \
    python-novaclient \
    python-swiftclient \
    python-openstackclient

RUN apt-get install -y curl

#RUN pip install \
#    python-troveclient \
#    python-manilaclient

ADD bashrc /root/.bashrc

WORKDIR /root

