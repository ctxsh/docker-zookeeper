# Zookeeper

Kuberentes optimized zookeeper container.  

## Example

#### Deploying a zookeeper cluster with custom configuration


```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: zkconfig
data:
  zoo.cfg.yaml: |
    size: 3
    properties:
      tickTime: 2000
      initLimit: 20
      syncLimit: 5
      dataDir: /data/zookeeper
      clientPort: 2181
      maxClientCnxns: 100
      metricsProvider.httpPort: 8088
...
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: zk
spec:
  serviceName: zookeeper
  replicas: 3
  selector:
    matchLabels:
      app: zookeeper
  template:
    metadata:
      name: zoo
      labels:
        app: zookeeper
    spec:
      containers:
      - name: zookeeper
        imagePullPolicy: Always
        image: ctxsh/zookeeper:3.6.1
        resources:
          requests:
            memory: "0.5Gi"
            cpu: "0.25"
        ports:
        - containerPort: 2181
          name: client
        - containerPort: 2888
          name: server
        - containerPort: 3888
          name: leader-election
        volumeMounts:
        - name: zkconfig
          mountPath: /etc/zookeeper.d
      volumes:
      - name: zkconfig
        configMap:
          name: zkconfig
```
