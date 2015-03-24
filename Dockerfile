FROM resin/rpi-raspbian:latest
MAINTAINER Tommy Ziegler <me@tommyziegler.com>

ENV EJABBERD_VERSION 15.03
ENV EJABBERD_USER ejabberd
ENV EJABBERD_ROOT /opt/ejabberd
ENV HOME $EJABBERD_ROOT
ENV PATH $EJABBERD_ROOT/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV DEBIAN_FRONTEND noninteractive
ENV XMPP_DOMAIN localhost

# Add ejabberd user and group
RUN groupadd -r $EJABBERD_USER \
    && useradd -r -m \
       -g $EJABBERD_USER \
       -d $EJABBERD_ROOT \
       -s /usr/sbin/nologin \
       $EJABBERD_USER

# Install requirements
RUN apt-get update \
    && apt-get -y --no-install-recommends install \
        wget \
        python2.7 \
        python-jinja2 \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install as user
USER $EJABBERD_USER

# Install ejabberd

RUN wget -q -O /tmp/ejabberd-installer.run "http://www.process-one.net/downloads/downloads-action.php?file=/ejabberd/$EJABBERD_VERSION/ejabberd-$EJABBERD_VERSION-linux-armhf-installer.run" \
    && chmod +x /tmp/ejabberd-installer.run \
    && cd $EJABBERD_ROOT \
    && mkdir _tmp \
    && cd _tmp \
    && /tmp/ejabberd-installer.run \
#            --mode unattended \
            --prefix $EJABBERD_ROOT \
            --adminpw ejabberd \
    && cd .. \
    && cp -r $EJABBERD_ROOT/_tmp/ejabberd-$EJABBERD_VERSION/* $EJABBERD_ROOT \
    && rm -rf $EJABBERD_ROOT/_tmp \
    && rm -rf /tmp/* \
    && mkdir $EJABBERD_ROOT/ssl \
    && rm -rf $EJABBERD_ROOT/database/ejabberd@localhost

# Make config
COPY ejabberd.yml.tpl $EJABBERD_ROOT/conf/ejabberd.yml.tpl
COPY ejabberdctl.cfg.tpl $EJABBERD_ROOT/conf/ejabberdctl.cfg.tpl
RUN sed -i "s/ejabberd.cfg/ejabberd.yml/" $EJABBERD_ROOT/bin/ejabberdctl \
    && sed -i "s/root/$EJABBERD_USER/g" $EJABBERD_ROOT/bin/ejabberdctl

# Wrapper for setting config on disk from environment
# allows setting things like XMPP domain at runtime
COPY ./run $EJABBERD_ROOT/bin/run

VOLUME ["$EJABBERD_ROOT/database", "$EJABBERD_ROOT/ssl"]
EXPOSE 5222 5269 5280 4560

CMD ["start"]
ENTRYPOINT ["run"]
