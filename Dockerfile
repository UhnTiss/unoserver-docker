FROM eclipse-temurin:24.0.2_12-jdk-noble

ARG BUILD_CONTEXT="build-context" 
ARG UID=worker
ARG GID=worker
ARG USER_UID=1001  # Andere UID verwenden (statt 1000)
ARG VERSION_UNOSERVER=3.5.dev0+fork.1

# Metadaten
LABEL org.opencontainers.image.title="unoserver-docker"
LABEL org.opencontainers.image.description="Container image that contains unoserver and libreoffice including large set of fonts for file format conversions"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.documentation="https://github.com/unoconv/unoserver-docker/blob/main/README.adoc"
LABEL org.opencontainers.image.source="https://github.com/unoconv/unoserver-docker"
LABEL org.opencontainers.image.url="https://github.com/unoconv/unoserver-docker"

WORKDIR /

# Debian-kompatible Nutzer- und Gruppenerstellung
RUN useradd --system --create-home --uid ${USER_UID} --gid 0 ${UID}

# Alles in einem RUN-Befehl für kleineres Image
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates curl gnupg unzip file \
        python3 python3-pip python3.12-venv supervisor net-tools \
        libreoffice libreoffice-writer libreoffice-java-common \
        fonts-noto fonts-noto-cjk fonts-noto-extra \
        fonts-dejavu-core fonts-liberation fonts-freefont-ttf \
        xfonts-terminus fonts-font-awesome \
        fonts-hack-ttf fonts-inconsolata fonts-mononoki fonts-open-sans \
        fontconfig && \
    fc-cache -fv && \
    # Aufräumen, um Imagegröße zu reduzieren
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# UNOserver Installation
RUN python3 -m pip install --break-system-packages \
    unoserver==${VERSION_UNOSERVER} \
    --index-url https://nexus.sina-cluster.com:9081/repository/pypi-all/simple

# Supervisor und Entrypoint einrichten
COPY --chown=${UID}:0 ${BUILD_CONTEXT} /
RUN chmod +x /entrypoint.sh && \
    mkdir -p /var/run && \
    chown -R ${UID}:0 /run && \
    chmod -R g=u /run

USER ${UID}
WORKDIR /home/${UID}
ENV HOME="/home/${UID}"

VOLUME ["/data"]
EXPOSE 2003
ENTRYPOINT ["/entrypoint.sh"]