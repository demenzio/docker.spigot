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
            build-essential \
            default-jre-headless

RUN echo "**** BuildTools ****" && \
        mkdir ${B_BUILD_DIR} ${B_BUILD_OUT} && \
        wget -O ${B_BUILD_DIR}/BuildTools.jar ${B_LINK_DOWN} && \
        #git config --global --unset core.autocrlf && \
        java -jar ${B_BUILD_DIR}/BuildTools.jar --output-dir ${B_BUILD_OUT} --rev ${B_VERSION} && \
        mv ${B_BUILD_OUT}/spigot-*.jar ${B_BUILD_OUT}/spigot.jar

RUN echo "**** MCRCON ****" && \
       cd ${B_BUILD_DIR} && \
       git clone https://github.com/Tiiffi/mcrcon.git && \
       cd mcrcon && \
       make && \
       cp ${B_BUILD_DIR}/mcrcon/mcrcon ${B_BUILD_OUT}

#i ---- Release State
FROM xuvin/s6overlay:debian-latest AS release

ENV APPDIR=/app CONFDIR=/config TZ="Europe/Berlin"
ENV PATH="${APPDIR}/bin:${PATH}"
ENV TERM=xterm
ENV DEBIAN_FRONTEND="noninteractive"
ENV EULA=false IP=127.0.0.1 PORT=25565 WDIR=/config/worlds
ENV JARNAME=spigot XMS=1G XMX=1G UPGJAR=0

COPY --from=builder /tmp/out/spigot.jar ${APPDIR}
COPY --from=builder /tmp/out/mcrcon ${APPDIR}/bin/

RUN echo "**** upgrade system ****" && \
        apt-get update && apt-get -y upgrade  && \
    echo "**** install packages ****" && \
        mkdir -p /usr/share/man/man1 && \
        apt-get -y install \
            tzdata \
            nano \
            default-jre-headless

ADD rootfs /

WORKDIR /config

EXPOSE 25565

ENTRYPOINT [ "/init" ]