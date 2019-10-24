#i ---- Builder State For MC Server
FROM debian:stable AS builder

ARG B_LINK_DOWN=https://hub.spigotmc.org/jenkins/job/BuildTools/lastSuccessfulBuild/artifact/target/BuildTools.jar
ARG B_BUILD_DIR=/tmp/build
ARG B_BUILD_OUT=/tmp/out
ARG B_VERSION=latest

ENV TERM=xterm
ENV DEBIAN_FRONTEND="noninteractive"

RUN echo "**** upgrade system ****" && \
        apt-get update && apt-get -y install apt-utils && apt-get -y upgrade && \
    echo "**** install dependencies ****" && \
        apt-get -y install \
            wget \
            git \
            coreutils \
            default-jre-headless

RUN echo "**** BuildTools ****" && \
        mkdir ${B_BUILD_DIR} ${B_BUILD_OUT} && \
        wget -O ${B_BUILD_DIR}/BuildTools.jar ${B_LINK_DOWN} && \
        #git config --global --unset core.autocrlf && \
        java -jar ${B_BUILD_DIR}/BuildTools.jar --output-dir ${B_BUILD_OUT} --rev ${B_VERSION} && \
        mv ${B_BUILD_OUT}/spigot-*.jar ${B_BUILD_OUT}/spigot.jar

#i ---- Release State
FROM xuvin/s6overlay:debian-latest AS release

ENV APPDIR=/app CONFDIR=/config TZ="Europe/Berlin"
ENV TERM=xterm
ENV DEBIAN_FRONTEND="noninteractive"
ENV EULA=false IP=127.0.0.1 PORT=25565 WDIR=/config/worlds
ENV JARNAME=spigot XMS=1G XMX=1G UPGJAR=0

COPY --from=builder /tmp/out/spigot.jar ${APPDIR}

RUN echo "**** upgrade system ****" && \
        apt-get update && apt-get -y upgrade  && \
    echo "**** install packages ****" && \
        mkdir -p /usr/share/man/man1 && \
        apt-get -y install \
            tzdata \
            default-jre-headless

ADD rootfs /

WORKDIR /config

ENTRYPOINT [ "/init" ]