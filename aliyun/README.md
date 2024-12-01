删除
$ terraform state rm 'helm_release.argo_cd'
$ terraform state rm 'helm_release.crossplane'
$ terraform state rm 'module.k3s'


####
自建集群需要安装aliyun csi driver
```
https://github.com/kubernetes-sigs/alibaba-cloud-csi-driver/blob/master/docs/install.md
```
目前有效的版本是v1.5.0
需要提前获取阿里云的AccessKey和AccessSecret
```
kubectl create secret -n kube-system generic csi-access-key \
   --from-literal=id='LTA******************GWN' \
   --from-literal=secret='***********'
```
```
git clone https://github.com/kubernetes-sigs/alibaba-cloud-csi-driver.git
cd alibaba-cloud-csi-driver/deploy
git checkout tags/v1.5.0
helm upgrade --install alibaba-cloud-csi-driver ./chart --values chart/values-ecs.yaml --namespace kube-system
```


###集群前置操作，创建pv, pvc, secret, namespace
```
kubectl create namespace postgres
```
###数据库密码postgres
```
kubectl apply -n postgres -f psql-secret.yaml
```
```
kubectl delete pv postgres-volume-0
kubectl delete pv postgres-volume-1
kubectl apply -n postgres -f psql-pv.yaml
kubectl apply -n postgres -f psql-pvclaim.yaml
```

#check
```
kubectl get pv
kubectl get pvc -n postgres
```
#安装pgsql HA
```
helm upgrade --cleanup-on-fail \
  --namespace postgres \
  --install postgres oci://registry-1.docker.io/bitnamicharts/postgresql-ha \
  --values pgconfig.yaml
```

###pgadmin安装 账号/密码 admin@admin.com/admin123
```
kubectl apply -n postgres  -f pgadmin-secret.yaml
kubectl apply -n postgres  -f pgadmin-deployment.yaml
kubectl apply -n postgres  -f pgadmin-service.yaml
```

hostname: postgres-postgresql-ha-pgpool.postgres.svc.cluster.local
主机名：postgres-postgresql-ha-pgpool.postgres.svc.cluster.local
port: 5433 端口：5433
username: postgres 用户名：postgres
password: postgres 密码：postgres
https://miro.medium.com/v2/resize:fit:1400/format:webp/1*Qn_sdeHbV_6Dy5iTp-X4RQ.png

[service name].[namespace].svc.cluster.local
[服务名称]。[命名空间].svc.cluster.local