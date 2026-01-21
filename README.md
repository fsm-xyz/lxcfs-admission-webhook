# Kubernetes Admission Webhook for LXCFS

## 本项目更改

+ go1.25.5
+ k8s 1.35 API
+ debian13
+ lxcfs 6.0.5
+ 从v1beta1 升级到 v1
+ 支持指定namespace
+ 支持指定pod annotation(todo)
+ 支持指定pod label(todo)
+ 支持/sys整个目录(6.0.5 lxcfs)

---

This project shows how to build and deploy an [AdmissionWebhook](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/#admission-webhooks) for [LXCFS](https://github.com/lxc/lxcfs).

## Prerequisites

Kubernetes with the `admissionregistration.k8s.io/v1` API enabled. Verify that by the following command:
```
kubectl api-versions | grep admissionregistration.k8s.io/v1
```
The result should be:
```
admissionregistration.k8s.io/v1
```

In addition, the `MutatingAdmissionWebhook` and `ValidatingAdmissionWebhook` admission controllers should be added and listed in the correct order in the admission-control flag of kube-apiserver.

## Build

1. 构建镜像并推送到自己的镜像中心
```sh
./build-all-registry.sh <registry> <namespace> <lxcfs-tag> <webhook-tag>
```

2. Install injector with lxcfs-admission-webhook

```sh
# 直接指定镜像进行安装
export LXCFS_IMAGE=lxcfs:6.0.5
export WEBHOOK_IMAGE=lxcfs-admission-webhook:v1
./deployment/install.sh lxcfs
```

## Test

1. Enable the namespace for injection

```
kubectl label namespace default lxcfs-admission-webhook=enabled
```

Note: All the new created pod under the namespace will be injected with LXCFS


2. Deploy the test deployment
 
```
kubectl apply -f deployment/web.yaml
```

3. Inspect the resource inside container


```
$ kubectl get pod -n <namespace>

NAME                                                 READY   STATUS    RESTARTS   AGE
lxcfs-admission-webhook-deployment-f4bdd6f66-5wrlg   1/1     Running   0          8m29s
lxcfs-pqs2d                                          1/1     Running   0          55m
lxcfs-zfh99                                          1/1     Running   0          55m
web-7c5464f6b9-6zxdf                                 1/1     Running   0          8m10s
web-7c5464f6b9-nktff                                 1/1     Running   0          8m10s

$ kubectl exec -ti web-7c5464f6b9-6zxdf sh
# free
             total       used       free     shared    buffers     cached
Mem:        262144       2744     259400          0          0        312
-/+ buffers/cache:       2432     259712
Swap:            0          0          0
#
```

## Cleanup

1. Uninstall injector with lxcfs-admission-webhook

```
deployment/uninstall.sh
```
