FROM ctxsh/java:jre14 as extract

ARG VERSION=3.6.1
ARG URL=https://archive.apache.org/dist/zookeeper/zookeeper-${VERSION}/apache-zookeeper-${VERSION}-bin.tar.gz

WORKDIR /output

RUN : \
  && mkdir -p opt/zookeeper \
  && curl -sL $URL | tar zxf - -C opt/zookeeper --strip-components=1 \
  && cd opt/zookeeper \
  && rm -rf *.txt *.md docs conf \
  && :

FROM ctxsh/java:jre14

ENV ZOOKEEPER_HOME /opt/zookeeper
ENV PATH $ZOOKEEPER_HOME/bin:$PATH
ENV S6_KEEP_ENV=1
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2

COPY --from=extract /output /
COPY ruok /opt/zookeeper/bin/ruok
COPY zookeeper /etc/zookeeper
COPY entrypoints /etc/cont-init.d
COPY permissions /etc/fix-attrs.d

RUN : \
  && useradd -u 1000 -r zookeeper \
  && mkdir -p /etc/zookeeper \
  && mkdir -p /var/lib/zookeeper \
  && chown -R zookeeper:zookeeper /etc/zookeeper* \
  && chown -R zookeeper:zookeeper /var/lib/zookeeper \
  && chmod 755 /opt/zookeeper/bin/ruok \
  && :

EXPOSE 2181
EXPOSE 7000

HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 CMD [ "/opt/zookeeper/bin/ruok" ]
ENTRYPOINT ["/init"]
CMD ["/opt/zookeeper/bin/zkServer.sh", "--config", "/etc/zookeeper", "start-foreground"]
