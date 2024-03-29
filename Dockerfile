FROM centos:centos7 as prepare

ENV installer_type=server

WORKDIR /tmp

COPY distr/* ./

RUN for file in *.tar.gz; do tar -zxf "$file"; done \
  && rm -rf *-nls-* *-ws-* *-crs-* \
  && rm -rf *.tar.gz

FROM centos:centos7 as base
#MAINTAINER "grahovsky" <grahovsky@gmail.com>

# install epel
RUN yum -y install epel-release && \
    # install dependences
    yum -y update && \
    yum -y install fontconfig \
    glibc-langpack-en \
    ImageMagick \
    xorg-x11-font-utils \
    cabextract && \
    yum clean all

# locale
ENV LANG ru_RU.UTF-8
ENV LANGUAGE=ru_RU.UTF-8
RUN localedef -f UTF-8 -i ru_RU ru_RU.UTF-8

# create user with specific id for okd
ARG OKD_USER_ID=1004140000
ENV OKD_USER_ID=$OKD_USER_ID
RUN groupadd -f --gid $OKD_USER_ID grp1cv8 && \
    useradd --uid $OKD_USER_ID --gid $OKD_USER_ID --comment '1C Enterprise 8 server launcher' --no-log-init --home-dir /home/usr1cv8 usr1cv8

# add rpm
COPY --from=prepare /tmp/*.rpm /tmp/
# install 1c
RUN yum localinstall -y /tmp/*.rpm && yum clean all && rm -f /tmp/*.rpm

# install fonts
#RUN rpm -i https://downloads.sourceforge.net/project/mscorefonts2/rpms/msttcore-fonts-installer-2.6-1.noarch.rpm
COPY --from=prepare /tmp/fonts/* /home/usr1cv8/.fonts/

# Add config 1c
COPY config/logcfg.xml /opt/1cv8/x86_64/conf/
COPY config/srv1cv83 /etc/sysconfig/
RUN echo "DisableUnsafeActionProtection=.*" >> /opt/1cv8/x86_64/conf/conf.cfg

# Add path 1cv8
ENV PATH="/opt/1cv8/x86_64/8.3.18.1698:${PATH}"

# Add directory and premission
RUN mkdir -p /opt/1cv8/x86_64/conf/ && \
    mkdir -p /var/log/1c/dumps/ && chown -R usr1cv8:grp1cv8 /var/log/1c/ && chmod 755 /var/log/1c && \
    chown -R usr1cv8:grp1cv8 /home/usr1cv8/.fonts && fc-cache -fv

# set rootpass for debug
#RUN echo 'root' | passwd root --stdin

# add sudo permissions for change hostname
#RUN echo "usr1cv8 ALL=(root) NOPASSWD: /usr/bin/chmod" >> /etc/sudoers

#Environment Variables
ARG AGENT_PORT=1540
ENV AGENT_PORT=$AGENT_PORT

ARG MANAGER_PORT=1541
ENV MANAGER_PORT=$MANAGER_PORT

ARG RAS_PORT=1545
ENV RAS_PORT=$RAS_PORT

ARG RAGENT_PORT=1560
ENV RAGENT_PORT=$RAGENT_PORT

ARG ONEC_VERSION=8.3.18.1698
ENV ONEC_VERSION=$ONEC_VERSION

# expose ports
EXPOSE $AGENT_PORT $MANAGER_PORT $RASPORT $RAGENT_PORT

# set volumes
VOLUME /home/usr1cv8/.1cv8 /var/log/1c

COPY entrypoint.sh /tmp/

USER usr1cv8

ENTRYPOINT ["/bin/sh", "-x", "/tmp/entrypoint.sh"]
CMD ["ragent"]
