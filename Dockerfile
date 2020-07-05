FROM ctxsh/java:jre14

ARG VERSION=3.6.1
ARG URL=http://apache.mirrors.hoobly.com/zookeeper/zookeeper-$VERSION/apache-zookeeper-$VERSION-bin.tar.gz

ENV ZOOKEEPER_HOME /opt/zookeeper
ENV PATH $ZOOKEEPER_HOME/bin:$PATH

RUN : \
  && mkdir -p /opt/zookeeper \
  && curl -sL $URL | tar zxf - -C /opt/zookeeper --strip-components=1 \
  && cd /opt/zookeeper \
  && rm -rf *.txt *.md docs conf \
  && :

COPY src/opt/zookeeper/bin/ruok /opt/zookeeper/bin/ruok
COPY src/opt/zookeeper/bin/zk /opt/zookeeper/bin/zk

RUN : \
  && useradd -u 1000 -r zookeeper \
  && mkdir -p /etc/zookeeper \
  && mkdir -p /etc/zookeeper.d \
  && chown -R zookeeper:zookeeper /etc/zookeeper* \
  && chown -R zookeeper:zookeeper /opt/zookeeper \
  && chmod 755 /opt/zookeeper/bin/ruok \
  && chmod 755 /opt/zookeeper/bin/zk \
  && :

CMD [ "/opt/zookeeper/bin/zk", "--src", "/etc/zookeeper.d", "--dest", "/etc/zookeeper"]
