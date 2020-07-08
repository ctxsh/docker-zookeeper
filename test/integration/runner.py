#!/usr/bin/env python3

import logging
import argparse
from typing import List
from kazoo.client import KazooClient

logging.basicConfig()
log = logging.getLogger(__name__)
log.setLevel(logging.INFO)

def final_check(hosts: List[str]) -> int:
  zk = KazooClient(hosts=hosts)
  zk.start()

  for host in hosts:
    hostname = host.split(".")[0]
    log.info(f"Checking /test/{hostname}")
    if not zk.exists(f"/test/{hostname}"):
      log.error(f"Expected /test/{hostname} to exist, but it vanished")
      return 255
    
    log.info(f"Deleting /test/{hostname}")
    zk.delete(f"/test/{hostname}")
  
  zk.stop()
  return 0


def run_tests(host: str) -> int:
  zk = KazooClient(hosts=host)
  zk.start()

  hostname = host.split(".")[0]

  if zk.exists(f"/test/{hostname}"):
    log.warning("Cleaning up leftover cruft")
    zk.delete(f"/test/{hostname}", recursive=True)

  zk.ensure_path(f"/test/{hostname}")

  if not zk.exists(f"/test/{hostname}"):
    log.error("Path did not exist after creation")
    return 255
  
  zk.create(f"/test/{hostname}/znode", b"one")
  data, stat = zk.get(f"/test/{hostname}/znode")
  log.info(stat)
  log.info(data)
  if data.decode("utf-8") != "one":
    log.error("Node create/get failed")
    return 255
  else:
    log.info("Node create/get succeeded")
  
  zk.set(f"/test/{hostname}/znode", b"two")
  data, stat = zk.get(f"/test/{hostname}/znode")
  log.info(stat)
  log.info(data)
  if data.decode("utf-8") != "two":
    log.error("Node set/get failed")
    return 255
  else:
    log.info("Node set/get succeeded")

  zk.delete(f"/test/{hostname}/znode")
  children = zk.get_children(f"/test/{hostname}")
  if len(children) > 0:
    log.error("Delete failed")
    return 255
  else:
    log.info("Node delete succeeded")

  zk.stop()
  return 0

def main() -> int:
  parser = argparse.ArgumentParser()
  parser.add_argument("--count", default=3, help="The number of hosts in the cluster.")
  args = parser.parse_args()

  hosts = [f"zk-{i}.zookeeper.default.svc.cluster.local:2181" for i in range(int(args.count))]
  for host in hosts:
    log.info(f"Connecting to: {host}")
    err = run_tests(host)
    if err > 0:
      return err
  
  return final_check(hosts)

if __name__ == "__main__":
  main()