#!/usr/bin/env python3

import os
import sys
import shutil
import jinja2
import logging
import socket
from pathlib import Path

FORMAT = '%(asctime)-15s %(message)s'
logging.basicConfig(format=FORMAT)
log = logging.getLogger(__name__)


class Commands:
  whitelist: str = os.environ.get("ZK_4LW_COMMANDS_WHITELIST", "*")


class MetricsProvider:
  className: str = os.environ.get("ZK_METRICS_PROVIDER_CLASS_NAME", "org.apache.zookeeper.metrics.prometheus.PrometheusMetricsProvider")
  httpPort: str = os.environ.get("ZK_METRICS_PROVIDER_HTTP_PORT", "7000")
  exportJvmInfo: str = os.environ.get("ZK_METRICS_PROVIDER_EXPORT_JVM_INFO", "true")


class AutoPurge:
  snapRetainCount: str = os.environ.get("ZK_AUTOPURGE_SNAP_RETAIN_COUNT", "60")
  purgeInterval: str = os.environ.get("ZK_AUTOPURGE_PURGE_INTERVAL", "1")


class Properties:
  tickTime: str = os.environ.get("ZK_TICK_TIME", "2000")
  initLimit: str = os.environ.get("ZK_INIT_LIMIT", "20")
  syncLimit: str = os.environ.get("ZK_SYNC_LIMIT", "5")
  dataDir: str = os.environ.get("ZK_DATA_DIR", "/var/lib/zookeeper")
  clientPort: str = os.environ.get("ZK_CLIENT_PORT", "2181")
  maxClientCnxns: str = os.environ.get("ZK_MAX_CLIENT_CNXNS", "60")
  autopurge: "AutoPurge" = AutoPurge()
  metricsProvider: "MetricsProvider" = MetricsProvider()
  commands: "Commands" = Commands()


class Server:
  size: int = int(os.environ.get("ZK_SIZE", "0"))
  host: str = socket.getfqdn()
  hostname: str = ""
  name: str = ""
  domain: str = ""
  ordinal: str = ""
  myid: str = ""

  def __init__(self: "Server") -> None:
    # Hostnames are expected to look like this: zk-0.zookeeper.default.svc.cluster.local
    # It's also expected that each will live in the same namespace/cluster
    hostname, domain = self.host.split(".", 1)
    name, ordinal = hostname.rsplit("-", 1)

    self.name = name
    self.ordinal = ordinal
    self.domain = domain
    self.hostname = hostname

    myid = os.environ.get("ZK_MYID", None)
    if myid:
      self.myid = myid
    else:
      self.myid = ordinal


class Zk:
  def __init__(self: "Zk", properties: "Properties", server: "Server") -> None:
    self.properties = properties
    self.server = server

  def render_zoo_cfg(self: "Zk") -> None:
    template = self.get_template("zoo.cfg.j2")
    with open("/etc/zookeeper/zoo.cfg", "w") as f:
      log.info("Generating zoo.cfg")
      f.write(template.render(properties=self.properties, server=self.server))
  
  def render_myid(self: "Zk") -> None:
    template = self.get_template("myid.j2")
    if self.server.size > 1:
      with open(f"{self.properties.dataDir}/myid", "w") as f:
        log.info("Generating myid")
        f.write(template.render(myid=self.server.myid))

  def get_template(self: "Zk", name: str) -> jinja2.Template:
    loader = jinja2.FileSystemLoader(searchpath="/etc/zookeeper/templates.d")
    env = jinja2.Environment(loader=loader)
    return env.get_template(name)


####################################################################################
# Generate zookeeper config files
####################################################################################
# Check for a mounted directory with configs and use it instead of the generated
# configs.
mounted_configs = Path("/conf.d")
configs = Path("/etc/zookeeper")
if mounted_configs.exists():
  log.info(f"Configs are mounted at /conf.d - transferring")
  shutil.rmtree(configs)
  os.symlink(mounted_configs, configs)
  sys.exit(0)

properties = Properties()
server = Server()

log.info(f"Hostname: {server.hostname}")
log.info(f"Domain: {server.domain}")
log.info(f"Name: {server.name}")
log.info(f"Ordinal: {server.ordinal}")

zk = Zk(properties, server)
zk.render_myid()
zk.render_zoo_cfg()
