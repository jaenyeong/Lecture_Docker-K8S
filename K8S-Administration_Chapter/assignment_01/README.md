# 실습 과제

## 16주차 과제

### 진행단계
`Chapter08 백업 및 복구` 수강 후 

### 제출
* 2021년 11월 23일 (화)까지

### 제출 방법
* 메일 제출 (ohsk@kakao.com)
* 구글 form에 `문제 원인`을 기재하여 제출

### 과제 설명
TroubleShooting
* 제공되는 파일을 전체 노드에 다운로드, 실행
* 파드 생성이 가능토록 조치, 파드가 생성된 화면을 캡처하여 원인/해결방법 제출
  * 절차와 디버깅 순서는 로그 확인, 구조와 특징 염두하여 판단

### 작업
* `troubleshooting` 파일 전체 노드에 다운로드
  * `$ wget http://172.30.5.154/troubleshooting`
* 권한 부여
  * `$ chmod +x troubleshooting`
* 모든 노드 실행
* 실행 후 파드 상태
  ~~~
  [centos@kjn-master-01 ~]$ kubectl get pod -o wide
  NAME                        READY   STATUS        RESTARTS        AGE     IP               NODE                                    NOMINATED NODE   READINESS GATES
  counter                     1/1     Terminating   0               99m     192.168.21.170   kjn-worker-02.kr-central-1.c.internal   <none>           <none>
  dns-test                    1/1     Terminating   1 (6h15m ago)   6h18m   192.168.21.162   kjn-worker-02.kr-central-1.c.internal   <none>           <none>
  kjn-86dbc4f8c5-2bhrp        0/1     Pending       0               5m45s   <none>           <none>                                  <none>           <none>
  kjn-86dbc4f8c5-cttdj        1/1     Terminating   0               4d      192.168.23.80    kjn-worker-01.kr-central-1.c.internal   <none>           <none>
  kjn-86dbc4f8c5-s6xh7        1/1     Terminating   0               4d      192.168.23.78    kjn-worker-01.kr-central-1.c.internal   <none>           <none>
  kjn-86dbc4f8c5-tdjkz        0/1     Pending       0               5m45s   <none>           <none>                                  <none>           <none>
  kjn-86dbc4f8c5-tgd6k        1/1     Terminating   0               4d      192.168.23.79    kjn-worker-01.kr-central-1.c.internal   <none>           <none>
  kjn-86dbc4f8c5-zv4sq        0/1     Pending       0               5m45s   <none>           <none>                                  <none>           <none>
  my-nginx-5b56ccd65f-6mf6p   0/1     Pending       0               5m34s   <none>           <none>                                  <none>           <none>
  my-nginx-5b56ccd65f-h55hg   0/1     Pending       0               5m34s   <none>           <none>                                  <none>           <none>
  my-nginx-5b56ccd65f-tnsdh   1/1     Terminating   0               8h      192.168.21.147   kjn-worker-02.kr-central-1.c.internal   <none>           <none>
  my-nginx-5b56ccd65f-zhwhs   1/1     Terminating   0               8h      192.168.21.148   kjn-worker-02.kr-central-1.c.internal   <none>           <none>
  test                        1/1     Terminating   0               4d      192.168.23.77    kjn-worker-01.kr-central-1.c.internal   <none>           <none>
  ~~~
* 각 노드 상태 확인
  * `$ kubectl describe node kjn-master-01`
  * `$ kubectl describe node kjn-master-02`
  * `$ kubectl describe node kjn-master-03`
  * `$ kubectl describe node kjn-worker-01`
  * `$ kubectl describe node kjn-worker-02`
* 마스터 노드 테인트 해제
  * `$ kubectl taint nodes kjn-master-01.kr-central-1.c.internal node-role.kubernetes.io/master:NoSchedule-`
  * `$ kubectl taint nodes kjn-master-02.kr-central-1.c.internal node-role.kubernetes.io/master:NoSchedule-`
  * `$ kubectl taint nodes kjn-master-03.kr-central-1.c.internal node-role.kubernetes.io/master:NoSchedule-`
* 워커 노드 테인트 해제
  * `$ kubectl taint nodes kjn-worker-01.kr-central-1.c.internal node.kubernetes.io/unreachable:NoExecute-`
  * `$ kubectl taint nodes kjn-worker-01.kr-central-1.c.internal node.kubernetes.io/unreachable:NoSchedule-`
  * `$ kubectl taint nodes kjn-worker-02.kr-central-1.c.internal node.kubernetes.io/unreachable:NoExecute-`
  * `$ kubectl taint nodes kjn-worker-02.kr-central-1.c.internal node.kubernetes.io/unreachable:NoSchedule-`
* 워커 노드의 테인트를 해제해도 남아 있음
  * `$ kubectl describe node kjn-worker-02.kr-central-1.c.internal`
    ~~~
    Name:               kjn-worker-02.kr-central-1.c.internal
    Roles:              <none>
    Labels:             beta.kubernetes.io/arch=amd64
                        beta.kubernetes.io/os=linux
                        kubernetes.io/arch=amd64
                        kubernetes.io/hostname=kjn-worker-02.kr-central-1.c.internal
                        kubernetes.io/os=linux
    Annotations:        kubeadm.alpha.kubernetes.io/cri-socket: /var/run/dockershim.sock
                        node.alpha.kubernetes.io/ttl: 0
                        projectcalico.org/IPv4Address: 172.30.7.0/22
                        projectcalico.org/IPv4IPIPTunnelAddr: 192.168.21.128
                        volumes.kubernetes.io/controller-managed-attach-detach: true
    CreationTimestamp:  Sun, 17 Oct 2021 12:41:32 +0000
    Taints:             node.kubernetes.io/unreachable:NoExecute
                        node.kubernetes.io/unreachable:NoSchedule
    Unschedulable:      false
    Lease:
      HolderIdentity:  kjn-worker-02.kr-central-1.c.internal
      AcquireTime:     <unset>
      RenewTime:       Sun, 21 Nov 2021 14:38:56 +0000
    Conditions:
      Type                 Status    LastHeartbeatTime                 LastTransitionTime                Reason              Message
      ----                 ------    -----------------                 ------------------                ------              -------
      NetworkUnavailable   False     Sun, 17 Oct 2021 12:42:39 +0000   Sun, 17 Oct 2021 12:42:39 +0000   CalicoIsUp          Calico is running on this node
      MemoryPressure       Unknown   Sun, 21 Nov 2021 14:37:08 +0000   Sun, 21 Nov 2021 14:39:39 +0000   NodeStatusUnknown   Kubelet stopped posting node status.
      DiskPressure         Unknown   Sun, 21 Nov 2021 14:37:08 +0000   Sun, 21 Nov 2021 14:39:39 +0000   NodeStatusUnknown   Kubelet stopped posting node status.
      PIDPressure          Unknown   Sun, 21 Nov 2021 14:37:08 +0000   Sun, 21 Nov 2021 14:39:39 +0000   NodeStatusUnknown   Kubelet stopped posting node status.
      Ready                Unknown   Sun, 21 Nov 2021 14:37:08 +0000   Sun, 21 Nov 2021 14:39:39 +0000   NodeStatusUnknown   Kubelet stopped posting node status.
    Addresses:
      InternalIP:  172.30.7.0
      Hostname:    kjn-worker-02.kr-central-1.c.internal
    Capacity:
      cpu:                2
      ephemeral-storage:  20960236Ki
      hugepages-1Gi:      0
      hugepages-2Mi:      0
      memory:             3880164Ki
      pods:               110
    Allocatable:
      cpu:                2
      ephemeral-storage:  19316953466
      hugepages-1Gi:      0
      hugepages-2Mi:      0
      memory:             3777764Ki
      pods:               110
    System Info:
      Machine ID:                 cab9605edaa5484da7c2f02b8fd10762
      System UUID:                17908220-9E01-4F94-AFE4-8E4A6BF4025E
      Boot ID:                    17b3a5ce-e8e2-4047-ae0b-1190a015c3b0
      Kernel Version:             3.10.0-1160.25.1.el7.x86_64
      OS Image:                   CentOS Linux 7 (Core)
      Operating System:           linux
      Architecture:               amd64
      Container Runtime Version:  docker://20.10.9
      Kubelet Version:            v1.22.1
      Kube-Proxy Version:         v1.22.1
    PodCIDR:                      192.168.4.0/24
    PodCIDRs:                     192.168.4.0/24
    Non-terminated Pods:          (7 in total)
      Namespace                   Name                                        CPU Requests  CPU Limits  Memory Requests  Memory Limits  Age
      ---------                   ----                                        ------------  ----------  ---------------  -------------  ---
      default                     counter                                     0 (0%)        0 (0%)      0 (0%)           0 (0%)         116m
      default                     dns-test                                    0 (0%)        0 (0%)      0 (0%)           0 (0%)         6h36m
      default                     my-nginx-5b56ccd65f-tnsdh                   0 (0%)        0 (0%)      0 (0%)           0 (0%)         8h
      default                     my-nginx-5b56ccd65f-zhwhs                   0 (0%)        0 (0%)      0 (0%)           0 (0%)         8h
      ingress-nginx               ingress-nginx-controller-74c46cfd4-74xwd    100m (5%)     0 (0%)      90Mi (2%)        0 (0%)         4h47m
      kube-system                 calico-node-wqhxv                           250m (12%)    0 (0%)      0 (0%)           0 (0%)         35d
      kube-system                 kube-proxy-xf268                            0 (0%)        0 (0%)      0 (0%)           0 (0%)         3d23h
    Allocated resources:
      (Total limits may be over 100 percent, i.e., overcommitted.)
      Resource           Requests    Limits
      --------           --------    ------
      cpu                350m (17%)  0 (0%)
      memory             90Mi (2%)   0 (0%)
      ephemeral-storage  0 (0%)      0 (0%)
      hugepages-1Gi      0 (0%)      0 (0%)
      hugepages-2Mi      0 (0%)      0 (0%)
    Events:              <none>
    ~~~
  * 따라서 워커 노드에 kubelet을 실행
    * `$ sudo systemctl daemon-reload`
    * `$ sudo systemctl start kubelet`
* 파드를 삭제하려면
  * `$ kubectl delete pod --grace-period=0 --force --namespace default`
