# Chapter 02 실습

## 실습 전 모든 파드 삭제
* `$ sudo -i`
* `# kubectl get pod`
* `# kubectl delete all --all`
* `# kubectl delete limitrange --all`
  * `limitrange`는 별도로 삭제해야 함

## Secrets, ConfigMap 마운트
* 컨피그맵 마운트
  * 원하는 내용을 넣어 파일 구성
    ~~~console
    cat <<EOF >./example-redis-config.yaml
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: example-redis-config
    data:
      redis-config: |
        maxmemory 2mb
        maxmemory-policy allkeys-lru
    EOF
    ~~~
    * `# kubectl apply -f ./example-redis-config.yaml`
    * `# kubectl get configmap`
  * 컨피그맵 사용 예제 배포
    ~~~
    $ kubectl apply -f https://raw.githubusercontent.com/kubernetes/website/main/content/en/examples/pods/config/redis-pod.yaml
    ~~~
    * 직접 `sh`을 통해 컨피그맵이 적절히 전달 됐는지 확인
      * `# kubectl exec -it redis -- sh`
      * `# cd /redis-master`
      * `# ls`
      * `# cat redis.conf`
    * `redis cli`를 통해 컨피그맵이 적절히 전달됐는지 확인
      * `# kubectl exec -it redis -- redis-cli`
      * `127.0.0.1:6379> CONFIG GET maxmemory-policy`
        1) "maxmemory-policy"
        2) "allkeys-lru"
      * `127.0.0.1:6379> CONFIG GET maxmemory`
        1) "maxmemory"
        2) "2097152"
* 시크릿 마운트
  * 시크릿에 전달할 데이터와 시크릿 생성
    * `# echo -n admin > username`
    * `# echo -n 1q2w3e > password`
    * `# kubectl create secret generic mysecret --from-file=username --from-file=password`
      * `-n` 옵션은 마지막에 줄바꿈이 들어가지 않게함
    * 확인
      * `# kubectl get secret mysecret`
      * `# kubectl get secret mysecret -o yaml`
        ~~~yaml
        apiVersion: v1
        data:
          password: MXEydzNl
          username: YWRtaW4=
        kind: Secret
        metadata:
          creationTimestamp: "2021-12-20T02:06:53Z"
          name: mysecret
          namespace: default
          resourceVersion: "3476781"
          uid: 9e9771c2-36ff-4f1c-8257-6415e393c700
        type: Opaque
        ~~~
        * `base64`로 `username`, `password` 값이 인코딩 되어 있음
          * `# echo MXEydzNl | base64 -d`
          * `# echo YWRtaW4= | base64 -d`
  * 시크릿 사용 예제 배포
    ~~~console
    cat <<EOF | kubectl apply -f -
    apiVersion: v1
    kind: Pod
    metadata:
      name: mypod
    spec:
      containers:
      - name: mypod
        image: redis
        volumeMounts:
        - name: foo
          mountPath: "/etc/foo"
          readOnly: true
      volumes:
      - name: foo
        secret:
          secretName: mysecret
    EOF
    ~~~
    * 확인
      ~~~
      # kubectl exec -it mypod -- bash

      # cd /etc/foo/
      # ls
      # cat username
      # cat password
      ~~~

## `PV`와 `PVC`
* mongo-pvc.yaml
  ~~~yaml
  apiVersion: v1
  kind: PersistentVolumeClaim
  metadata:
    name: mongodb-pvc
  spec:
    resources:
      requests:
        storage: 1Gi
    accessModes:
    - ReadWriteOnce
    storageClassName: ""
  ~~~
  * `mongodb-pvc`
    * 클레임 사용 시 필요함
  * `storage`
    * 요청할 스토리지 크기
  * `-ReadWriteOnce`
    * 접근 권한, 단일 클라이언트에 읽기/쓰기 지원
  * `storageClassName`
    * 동적 프로비저닝에서 사용
    * 작성은 해야 하나 값은 비워둬야 함 (작성하지 않으면 디폴트로 다른 값이 설정됨)

## `rook-ceph`
* `kakao i cloud` 접속하여 새 디스크 생성 및 연결
  * 워커 노드 (2,3,4번 노드)에 새 볼륨 추가
    * 각 노드마다 현재 연결할 수 있는 볼륨이 없는 상태
  * `VM` 페이지에서 `Volume` 탭에서 `볼륨 만들기` 선택, 생성
    * 각 노드마다 한 개씩 새 볼륨 생성
      * 볼륨명: `kjn-02-volume-2`, 볼륨 타입/크기: `100GIB`
      * 볼륨명: `kjn-03-volume-2`, 볼륨 타입/크기: `100GIB`
      * 볼륨명: `kjn-04-volume-2`, 볼륨 타입/크기: `100GIB`
  * 생성한 볼륨을 각 노드에 연결
    * 해당 `VM 인스턴스` 페이지에서 `볼륨` 탭에서 `볼륨 추가` 선택하여 위에서 생성한 볼륨 연결
    * 각 노드 번호와 맞는 볼륨 연결
* `lsblk` 명령으로 확인
  * lsblk`는 리눅스 디바이스 정보를 출력하는 명령어 (`blkid` 보다 더 자세한 정보 표시)
    * `blkid`
      * `block device`의 파일 시스템 유형이나 속성(LABEL, UUID 등)을 출력하는 유틸리티
  ~~~
  NAME    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
  vda     252:0    0   45G  0 disk
  ├─vda1  252:1    0 44.9G  0 part /
  ├─vda14 252:14   0    4M  0 part
  └─vda15 252:15   0  106M  0 part /boot/efi
  vdb     252:16   0  100G  0 disk
  ~~~
* 마스터 노드에 `rook`로 `ceph` 설치
  * `git clone`하여 설치 시작
  * 한 번에 모든 명령을 실행하지 않고 하나씩 실행
  * `rook` 프로젝트에는 다양한 기능이 있지만, 여기서는 `kubernetes ceph`만 설치
  ~~~console
  # git clone --single-branch --branch release-1.7 https://github.com/rook/rook.git

  # cd rook/cluster/examples/kubernetes/ceph
  # kubectl create -f crds.yaml -f common.yaml -f operator.yaml
  # kubectl create -f cluster.yaml
  ~~~
  * 네임스페이스 확인
    * `# kubectl get ns`
  * 파드 확인
    * `# kubectl -n rook-ceph get pod -w`
      * `ceph`와 `csi` 로딩 완료까지 대기 (몇 분 소요)
      * `-w`는 `watch` 옵션으로 업데이트(설치) 진행과정 확인 가능
    ~~~
    csi-cephfsplugin-7h9x5                             3/3     Running     0          5m12s
    csi-cephfsplugin-96wjw                             3/3     Running     0          5m12s
    csi-cephfsplugin-provisioner-689686b44-jwjgg       6/6     Running     0          5m12s
    csi-cephfsplugin-provisioner-689686b44-v8pwh       6/6     Running     0          5m12s
    csi-cephfsplugin-zd5nr                             3/3     Running     0          5m12s
    csi-rbdplugin-5qpvp                                3/3     Running     0          5m14s
    csi-rbdplugin-66rsw                                3/3     Running     0          5m14s
    csi-rbdplugin-provisioner-5775fb866b-9pqsq         6/6     Running     0          5m13s
    csi-rbdplugin-provisioner-5775fb866b-x5gsj         6/6     Running     0          5m13s
    csi-rbdplugin-xmwl5                                3/3     Running     0          5m14s
    rook-ceph-crashcollector-kjn-02-57bbfcc989-w7gtc   1/1     Running     0          2m19s
    rook-ceph-crashcollector-kjn-03-cddd5dbc6-2jp24    1/1     Running     0          2m18s
    rook-ceph-crashcollector-kjn-04-85db8fb79f-775z2   1/1     Running     0          109s
    rook-ceph-mgr-a-744c5cc54f-g5shs                   1/1     Running     0          2m34s
    rook-ceph-mon-a-557d474f66-hmxwd                   1/1     Running     0          5m47s
    rook-ceph-mon-b-675475bbd4-2cdh4                   1/1     Running     0          4m8s
    rook-ceph-mon-c-6d687d68f9-ld6qj                   1/1     Running     0          3m39s
    rook-ceph-operator-5c4cbc8784-nq5pg                1/1     Running     0          8m6s
    rook-ceph-osd-0-5d5d588b4c-bn9fw                   1/1     Running     0          115s
    rook-ceph-osd-1-844fdf57b4-ktjls                   1/1     Running     0          111s
    rook-ceph-osd-2-7bdc85c6b5-m6bpj                   1/1     Running     0          110s
    rook-ceph-osd-prepare-kjn-02--1-2vlmj              0/1     Completed   0          2m19s
    rook-ceph-osd-prepare-kjn-03--1-xpwjw              0/1     Completed   0          2m19s
    rook-ceph-osd-prepare-kjn-04--1-dp544              0/1     Completed   0          2m19s
    ~~~
* 마스터 노드에 툴박스, `ceph csi` 설치
  * 툴박스
    * `ceph`를 모니터링할 수 있는 툴을 구성하는 컨테이너
    * `# kubectl create -f toolbox.yaml`
  * `csi` (`Container Storage Interface`)
    * 각 노드 컨테이너에서 스토리지를 사용할 수 있는 인터페이스 제공
    * `# kubectl create -f csi/rbd/storageclass.yaml`
  * 툴박스 컨테이너로 접속하여 상태 확인
    * `# kubectl -n rook-ceph exec -it $(kubectl -n rook-ceph get pod -l "app=rook-ceph-tools" -o jsonpath='{.items[0].metadata.name}') -- bash`
    * 내부에서 명령 실행
      * `# ceph status`
        ~~~
        cluster:
        id:     f9e5fee6-2ccf-49cb-b3f4-751c284c9371
        health: HEALTH_OK

        services:
          mon: 3 daemons, quorum a,b,c (age 13m)
          mgr: a(active, since 11m)
          osd: 3 osds: 3 up (since 12m), 3 in (since 12m)

        data:
          pools:   2 pools, 96 pgs
          objects: 1 objects, 19 B
          usage:   18 MiB used, 300 GiB / 300 GiB avail
          pgs:     96 active+clean
        ~~~
      * `# ceph osd pool stats`
        ~~~
        pool device_health_metrics id 1
          nothing is going on

        pool replicapool id 2
          nothing is going on
        ~~~
  * 스토리지 클래스 확인
    * `# kubectl get sc`
      * 위에서 툴박스 컨테이너에 들어가 있는 상태라면 `exit`로 빠져 나와서 실행
      ~~~
      NAME              PROVISIONER                  RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
      rook-ceph-block   rook-ceph.rbd.csi.ceph.com   Delete          Immediate           true                   4m7s
      ~~~
      * `RECLAIM POLICY`(반환 정책) 옵션이 `Delete` 값인지 확인할 것
  * `PVC` 생성 및 디스크 매칭 확인
    ~~~console
    cat <<EOF | kubectl apply -f -
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: mongo-pvc
    spec:
      # 딜러지정
      storageClassName: rook-ceph-block
      # 권한
      accessModes:
      - ReadWriteOnce
      resources:
        requests:
          storage: 2Gi
    EOF
    ~~~
  * 파드 생성하여 파드와 연결
    * `# vim mongo-pod`
      ~~~yaml
      apiVersion: v1
      kind: Pod
      metadata:
        name: mongodb
      spec:
        containers:
        - image: mongo
          name: mongodb
          volumeMounts:
          - name: mongodb-data
            mountPath: /data/db
          ports:
          - containerPort: 27017
            protocol: TCP
        volumes:
        - name: mongodb-data
          persistentVolumeClaim:
            claimName: mongo-pvc
      ~~~
    * 파드 생성
      * `# kubectl apply -f mongo-pod`
    * 몽고디비 `PVC` 확인
      * `# kubectl get pvc`
  * 삭제
    * `# kubectl delete pod mongodb`
    * `# kubectl delete pvc mongo-pvc`
      * 몇 초 소요
  * 삭제 결과 확인
    * `# kubectl get pv`

## 스토리지 클래스 연습문제
* 문제
  * `httpd`를 사용할 수 있도록 `POD`, `PVC`, `StorageClass` 정의하여 동적 프로비저닝 수행
  * `httpd`를 사용할 수 있도록 자동으로 `POD`, `PVC`, `StorageClass` 정의, 생성
* 찾아보기
  * [도커 허브](https://hub.docker.com/_/httpd)에서 `httpd` 확인
    * `mountPath` 경로값 `/usr/local/apache2/htdocs/`
  * 일반적으로 K8S 페이지에서 검색해서 `yaml` 샘플 획득
    * `https://kubernetes.io/search/?q=pvc`
* 마스터 노드에서 아래 풀이 실행
  ~~~console
  cat <<EOF | kubectl apply -f -
  # pod
  apiVersion: v1
  kind: Pod
  metadata:
    name: httpd
  spec:
    containers:
    - name: httpd
      image: httpd
      volumeMounts:
      - mountPath: "/usr/local/apache2/htdocs/"
        name: htdocs # 아래 볼륨 이름과 일치해야 함
    volumes:
    - name: htdocs
      persistentVolumeClaim:
        claimName: httpd-pvc # 아래 pvc 이름과 일치해야 함
  ---
  # pvc
  apiVersion: v1
  kind: PersistentVolumeClaim
  metadata:
    name: httpd-pvc
  spec:
    accessModes:
    - ReadWriteOnce
    volumeMode: Filesystem
    resources:
      requests:
        storage: 8Gi
    storageClassName: my-sc # 아래 스토리지 클래스 이름과 일치해야 함
  ---
  # storageclass
  # rook/cluster/examples/kubernetes/ceph/csi/rbd/storageclass.yaml
  apiVersion: storage.k8s.io/v1
  kind: StorageClass
  metadata:
    name: my-sc
  provisioner: rook-ceph.rbd.csi.ceph.com
  parameters:
    clusterID: rook-ceph # namespace:cluster
    pool: replicapool
    imageFormat: "2"
    imageFeatures: layering
    csi.storage.k8s.io/provisioner-secret-name: rook-csi-rbd-provisioner
    csi.storage.k8s.io/provisioner-secret-namespace: rook-ceph # namespace:cluster
    csi.storage.k8s.io/controller-expand-secret-name: rook-csi-rbd-provisioner
    csi.storage.k8s.io/controller-expand-secret-namespace: rook-ceph
    csi.storage.k8s.io/node-stage-secret-name: rook-csi-rbd-node
    csi.storage.k8s.io/node-stage-secret-namespace: rook-ceph # namespace:cluster
    csi.storage.k8s.io/fstype: ext4
  allowVolumeExpansion: true
  reclaimPolicy: Delete
  EOF
  ~~~
  * 확인
    * `# kubectl get pvc,pv`
      ~~~console
      NAME                              STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
      persistentvolumeclaim/httpd-pvc   Bound    pvc-20cec1aa-9f0e-4e46-9b62-bf9d9b96539c   8Gi        RWO            my-sc          65s

      NAME                                                        CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM               STORAGECLASS   REASON   AGE
      persistentvolume/pvc-20cec1aa-9f0e-4e46-9b62-bf9d9b96539c   8Gi        RWO            Delete           Bound    default/httpd-pvc   my-sc                   59s
      ~~~
    * `# kubectl get pod`
      ~~~
      NAME    READY   STATUS    RESTARTS   AGE
      httpd   1/1     Running   0          82s
      mypod   1/1     Running   0          5d5h
      redis   1/1     Running   0          5d5h
      ~~~
  * 해당 `httpd` 파드가 `curl`, `wget` 명령을 인식하지 못해 포트포워드 후 확인
    * `# kubectl port-forward httpd 8888:80`
    * 새 세션으로 마스터 노드에 접속하여 확인
      * `$ curl 127.0.0.1:8888`
        ~~~html
        <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">
        <html>
         <head>
          <title>Index of /</title>
         </head>
         <body>
        <h1>Index of /</h1>
        <ul></ul>
        </body></html>
        ~~~
* `ceph` 디스크 확인 방법
  * 생성된 디스크 확인
    * `# kubectl get pv -o yaml | grep vol`
      ~~~
            volumeAttributes:
              imageName: csi-vol-f42ac77e-6556-11ec-8f52-c61648871a4f
            volumeHandle: 0001-0009-rook-ceph-0000000000000002-f42ac77e-6556-11ec-8f52-c61648871a4f
          volumeMode: Filesystem
      ~~~
      * 공백 동일하게 출력
* 툴박스 실행
  * `# kubectl -n rook-ceph exec -it $(kubectl -n rook-ceph get pod -l "app=rook- ceph-tools" -o jsonpath='{.items[0].metadata.name}') -- bash`
  * 툴박스 안에서 디스크 이미지 리스트 확인
    * `# rbd ls -p replicapool`
      ~~~
      csi-vol-f42ac77e-6556-11ec-8f52-c61648871a4f
      ~~~
    * `# rbd info csi-vol-f42ac77e-6556-11ec-8f52-c61648871a4f -p replicapool`
      ~~~
      rbd image 'csi-vol-f42ac77e-6556-11ec-8f52-c61648871a4f':
    	size 8 GiB in 2048 objects
    	order 22 (4 MiB objects)
    	snapshot_count: 0
    	id: b5e47f92dae2
    	block_name_prefix: rbd_data.b5e47f92dae2
    	format: 2
    	features: layering
    	op_features:
    	flags:
    	create_timestamp: Sat Dec 25 07:47:48 2021
    	access_timestamp: Sat Dec 25 07:47:48 2021
    	modify_timestamp: Sat Dec 25 07:47:48 2021
      ~~~

## `StatefulSet`
* 전반적으로 디플로이먼트와 설정 방법이 유사
  * `serviceName`
    * 서비스 지정
  * `terminationGracePeriodSeconds`
    * graceful 종료를 위해 대기하는 시간 설정
  * `volumeMounts`
    * 영구 스토리지를 연결하고자 하는 위치
  * `volumeClaimTemplates`
    * 안정적인 스토리지 제공
* 예제
  * `vim stateful-nginx.yaml`
    ~~~yaml
    # stateful-nginx.yaml
    apiVersion: v1
    kind: Service
    metadata:
      name: nginx
      labels:
        app: nginx
    spec:
      ports:
      - port: 80
        name: web
      clusterIP: None # headless
      selector:
        app: nginx
    ---
    apiVersion: apps/v1
    kind: StatefulSet
    metadata:
      name: web
    spec:
      selector:
        matchLabels:
          app: nginx # has to match.spec.template.metadata.labels
      serviceName: "nginx"
      replicas: 3 # by default is 1
      template:
        metadata:
          labels:
            app: nginx # has to match.spec.selector.matchLabels
        spec:
          terminationGracePeriodSeconds: 10
          containers:
          - name: nginx
            image: k8s.gcr.io/nginx-slim:0.8
            ports:
            - containerPort: 80
              name: web
            volumeMounts:
            - name: www
              mountPath: /usr/share/nginx/html
      volumeClaimTemplates:
      - metadata:
          name: www
        spec:
          accessModes: [ "ReadWriteOnce" ]
          storageClassName: "rook-ceph-block"
          resources:
            requests:
              storage: 1Gi
    ~~~
  * 실행
    * `# kubectl apply -f stateful-nginx.yaml`
  * 확인
    * `# kubectl get sc`
      ~~~
      NAME              PROVISIONER                  RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
      my-sc             rook-ceph.rbd.csi.ceph.com   Delete          Immediate           true                   6h11m
      rook-ceph-block   rook-ceph.rbd.csi.ceph.com   Delete          Immediate           true                   29h
      ~~~
    * `# kubectl get pod,pvc,pv`
      ~~~
      pod/httpd   1/1     Running   0          6h11m
      pod/mypod   1/1     Running   0          5d11h
      pod/redis   1/1     Running   0          5d12h
      pod/web-0   1/1     Running   0          42s
      pod/web-1   1/1     Running   0          19s
      pod/web-2   1/1     Running   0          11s

      NAME                              STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS      AGE
      persistentvolumeclaim/httpd-pvc   Bound    pvc-20cec1aa-9f0e-4e46-9b62-bf9d9b96539c   8Gi        RWO            my-sc             6h11m
      persistentvolumeclaim/www-web-0   Bound    pvc-9fd912e0-3562-494c-abb4-9d19c1a4bf7b   1Gi        RWO            rook-ceph-block   42s
      persistentvolumeclaim/www-web-1   Bound    pvc-618d1134-f3fb-4c20-bfa6-c3b879f52d3a   1Gi        RWO            rook-ceph-block   19s
      persistentvolumeclaim/www-web-2   Bound    pvc-383464e9-0cd7-4e2e-9e1a-b7569858648d   1Gi        RWO            rook-ceph-block   11s

      NAME                                                        CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM               STORAGECLASS      REASON   AGE
      persistentvolume/pvc-20cec1aa-9f0e-4e46-9b62-bf9d9b96539c   8Gi        RWO            Delete           Bound    default/httpd-pvc   my-sc                      6h11m
      persistentvolume/pvc-383464e9-0cd7-4e2e-9e1a-b7569858648d   1Gi        RWO            Delete           Bound    default/www-web-2   rook-ceph-block            10s
      persistentvolume/pvc-618d1134-f3fb-4c20-bfa6-c3b879f52d3a   1Gi        RWO            Delete           Bound    default/www-web-1   rook-ceph-block            19s
      persistentvolume/pvc-9fd912e0-3562-494c-abb4-9d19c1a4bf7b   1Gi        RWO            Delete           Bound    default/www-web-0   rook-ceph-block            41s
      ~~~
  * 확장 후 다시 확인
    * `# kubectl scale statefulset web --replicas=5`
    * `# kubectl get pod,pvc,pv`
      ~~~
      NAME        READY   STATUS              RESTARTS   AGE
      pod/httpd   1/1     Running             0          6h15m
      pod/mypod   1/1     Running             0          5d11h
      pod/redis   1/1     Running             0          5d12h
      pod/web-0   1/1     Running             0          5m7s
      pod/web-1   1/1     Running             0          4m44s
      pod/web-2   1/1     Running             0          4m36s
      pod/web-3   1/1     Running             0          32s
      pod/web-4   0/1     ContainerCreating   0          9s

      NAME                              STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS      AGE
      persistentvolumeclaim/httpd-pvc   Bound    pvc-20cec1aa-9f0e-4e46-9b62-bf9d9b96539c   8Gi        RWO            my-sc             6h15m
      persistentvolumeclaim/www-web-0   Bound    pvc-9fd912e0-3562-494c-abb4-9d19c1a4bf7b   1Gi        RWO            rook-ceph-block   5m7s
      persistentvolumeclaim/www-web-1   Bound    pvc-618d1134-f3fb-4c20-bfa6-c3b879f52d3a   1Gi        RWO            rook-ceph-block   4m44s
      persistentvolumeclaim/www-web-2   Bound    pvc-383464e9-0cd7-4e2e-9e1a-b7569858648d   1Gi        RWO            rook-ceph-block   4m36s
      persistentvolumeclaim/www-web-3   Bound    pvc-5a961bef-dcb3-4741-b1b2-a68732d7c070   1Gi        RWO            rook-ceph-block   32s
      persistentvolumeclaim/www-web-4   Bound    pvc-3c2574d3-7e78-47e0-99b7-6c7022b14307   1Gi        RWO            rook-ceph-block   9s

      NAME                                                        CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM               STORAGECLASS      REASON   AGE
      persistentvolume/pvc-20cec1aa-9f0e-4e46-9b62-bf9d9b96539c   8Gi        RWO            Delete           Bound    default/httpd-pvc   my-sc                      6h15m
      persistentvolume/pvc-383464e9-0cd7-4e2e-9e1a-b7569858648d   1Gi        RWO            Delete           Bound    default/www-web-2   rook-ceph-block            4m35s
      persistentvolume/pvc-3c2574d3-7e78-47e0-99b7-6c7022b14307   1Gi        RWO            Delete           Bound    default/www-web-4   rook-ceph-block            9s
      persistentvolume/pvc-5a961bef-dcb3-4741-b1b2-a68732d7c070   1Gi        RWO            Delete           Bound    default/www-web-3   rook-ceph-block            32s
      persistentvolume/pvc-618d1134-f3fb-4c20-bfa6-c3b879f52d3a   1Gi        RWO            Delete           Bound    default/www-web-1   rook-ceph-block            4m44s
      persistentvolume/pvc-9fd912e0-3562-494c-abb4-9d19c1a4bf7b   1Gi        RWO            Delete           Bound    default/www-web-0   rook-ceph-block            5m6s
      ~~~
  * 축소 후 다시 확인
    * `# kubectl scale statefulset web --replicas=1`
    * `# watch kubectl get pod,pvc,pv`
      ~~~
      NAME        READY   STATUS    RESTARTS   AGE
      pod/httpd   1/1     Running   0          6h17m
      pod/mypod   1/1     Running   0          5d11h
      pod/redis   1/1     Running   0          5d12h
      pod/web-0   1/1     Running   0          7m15s

      NAME                              STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS      AGE
      persistentvolumeclaim/httpd-pvc   Bound    pvc-20cec1aa-9f0e-4e46-9b62-bf9d9b96539c   8Gi        RWO            my-sc             6h17m
      persistentvolumeclaim/www-web-0   Bound    pvc-9fd912e0-3562-494c-abb4-9d19c1a4bf7b   1Gi        RWO            rook-ceph-block   7m15s
      persistentvolumeclaim/www-web-1   Bound    pvc-618d1134-f3fb-4c20-bfa6-c3b879f52d3a   1Gi        RWO            rook-ceph-block   6m52s
      persistentvolumeclaim/www-web-2   Bound    pvc-383464e9-0cd7-4e2e-9e1a-b7569858648d   1Gi        RWO            rook-ceph-block   6m44s
      persistentvolumeclaim/www-web-3   Bound    pvc-5a961bef-dcb3-4741-b1b2-a68732d7c070   1Gi        RWO            rook-ceph-block   2m40s
      persistentvolumeclaim/www-web-4   Bound    pvc-3c2574d3-7e78-47e0-99b7-6c7022b14307   1Gi        RWO            rook-ceph-block   2m17s

      NAME                                                        CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM               STORAGECLASS      REASON   AGE
      persistentvolume/pvc-20cec1aa-9f0e-4e46-9b62-bf9d9b96539c   8Gi        RWO            Delete           Bound    default/httpd-pvc   my-sc                      6h17m
      persistentvolume/pvc-383464e9-0cd7-4e2e-9e1a-b7569858648d   1Gi        RWO            Delete           Bound    default/www-web-2   rook-ceph-block            6m43s
      persistentvolume/pvc-3c2574d3-7e78-47e0-99b7-6c7022b14307   1Gi        RWO            Delete           Bound    default/www-web-4   rook-ceph-block            2m17s
      persistentvolume/pvc-5a961bef-dcb3-4741-b1b2-a68732d7c070   1Gi        RWO            Delete           Bound    default/www-web-3   rook-ceph-block            2m40s
      persistentvolume/pvc-618d1134-f3fb-4c20-bfa6-c3b879f52d3a   1Gi        RWO            Delete           Bound    default/www-web-1   rook-ceph-block            6m52s
      persistentvolume/pvc-9fd912e0-3562-494c-abb4-9d19c1a4bf7b   1Gi        RWO            Delete           Bound    default/www-web-0   rook-ceph-block            7m14s
      ~~~
      * 디스크와 `PV`는 그대로 남음 (다시 확장하면 똑같이 다시 붙음)
  * 헤드레스 서비스 확인
    * `web-0`으로 들어가서 확인
      * `# kubectl exec -it web-0 -- bash`
      * `# curl web-0.nginx.default`
  * [스테이트풀셋 문서](https://kubernetes.io/ko/docs/concepts/workloads/controllers/statefulset/)

## 앱 롤링 업데이트와 롤백
* 디플로이먼트 업데이트
  * 준비
    * `# kubectl delete all --all --force`
      * 맨 뒤에 `--force` 옵션으로 강제로 삭제하면 조금 더 빨리 처리됨
    * `# kubectl create deploy http-go --image=gasbugs/http-go:v1 --dry-run=client -oyaml > http-go-v1-deploy.yaml`
    * `# kubectl apply -f http-go-v1-deploy.yaml --record=true`
      * `--record=true`은 기록 옵션 (`deprecated` 예정)
        * `Flag --record has been deprecated, --record will be removed in the future`
    * `# kubectl expose deploy http-go --type=NodePort --port=80 --target-port=8080`
    * `# kubectl scale deploy http-go --replicas=3`
* 모니터링 스크립트 구성
  * 기존 세션이 아닌 새로운 세션에서 마스터 노드 접속하여 실행
  * `$ sudo -i`
  * `# kubectl get pod`
  * `while true; do curl 172.30.5.70:32064; sleep 1; done;`
    * 마스터 노드의 IP
    * `# kubectl get svc` 명령으로 `NodePort`의 포트 확인
* 업데이트 속도 조절
  * `# kubectl patch deployment http-go -p '{"spec": {"minReadySeconds": 10}}'`
* `set image` 명령으로 업데이트 시작
  * `# kubectl set image ${resource_type} ${resource_name} ${container_name}=${image_name} --record=true`
  * `# kubectl set image deploy http-go http-go=gasbugs/http-go:v2 --record=true`
* `yaml` 파일을 통해 업데이트
  * 기존 `http-go-v1-deploy.yaml`을 복제, `http-go-v3-deploy.yaml` 생성
    * `# cp http-go-v1-deploy.yaml http-go-v3-deploy.yaml`
    * `http-go-v3-deploy.yaml` 수정
      * `# vim http-go-v3-deploy.yaml`
        * `replicas` 속성 값을 3으로 변경
        * `image` 속성에서 이미지명을 `v3`로 변경
    * 실행
      * `# kubectl apply -f http-go-v3-deploy.yaml --record=true`
* 확인
  * `# kubectl get rs`
    ~~~
    NAME                 DESIRED   CURRENT   READY   AGE
    http-go-5bcb89d449   0         0         0       32m
    http-go-7887c68b47   3         3         3       11m
    http-go-7dfd967844   0         0         0       18m
    ~~~
* 업데이트 히스토리 확인
  * `# kubectl rollout history deploy http-go`
    ~~~
    deployment.apps/http-go
    REVISION  CHANGE-CAUSE
    1         kubectl apply --filename=http-go-v1-deploy.yaml --record=true
    2         kubectl set image deploy http-go http-go=gasbugs/http-go:v2 --record=true
    3         kubectl apply --filename=http-go-v3-deploy.yaml --record=true

    ~~~
* 롤백
  * 이전 버전으로 롤백
    * `# kubectl rollout undo deploy http-go`
    * 롤백 후 확인
      * `# kubectl rollout history deploy http-go`
      ~~~
      deployment.apps/http-go
      REVISION  CHANGE-CAUSE
      1         kubectl apply --filename=http-go-v1-deploy.yaml --record=true
      3         kubectl apply --filename=http-go-v3-deploy.yaml --record=true
      4         kubectl set image deploy http-go http-go=gasbugs/http-go:v2 --record=true

      ~~~
    * 계속 이전 버전으로 롤백을 시도하면 위에 `REVISION`이 `3`,`4`만 반복하게 됨
  * 특정 리비전으로 롤백
    * `# kubectl rollout undo deploy http-go --to-revision=1`

## 연습문제
* `mongo` 이미지를 사용해 업데이트, 롤백 실행
  * 모든 `revison` 내용을 기록할 것
  * `mongo:4.2` 이미지를 사용해 디플로이먼트를 생성할 것
    * `Replicas: 10`
    * `maxSurge: 50%`
    * `maxUnavailable: 50%`
  * `# vim mongo-4.2-deploy.yaml`
    ~~~yaml
    # kubectl apply -f mongo-4.2-deploy.yaml --record=true
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: mongo
      labels:
        app: mongo
    spec:
      strategy:
        rollingUpdate:
          maxSurge: 50%
          maxUnavailable: 50%
        type: RollingUpdate
      replicas: 10
      selector:
        matchLabels:
          app: mongo
      template:
        metadata:
          labels:
            app: mongo
        spec:
          containers:
          - name: mongo
            image: mongo:4.2
    ~~~
  * 확인
    * `# kubectl get deploy,pod`
      ~~~
      NAME                      READY   UP-TO-DATE   AVAILABLE   AGE
      deployment.apps/http-go   3/3     3            3           49m
      deployment.apps/mongo     10/10   10           10          52s

      NAME                           READY   STATUS    RESTARTS   AGE
      pod/http-go-5bcb89d449-4lc9v   1/1     Running   0          9m31s
      pod/http-go-5bcb89d449-bt868   1/1     Running   0          9m47s
      pod/http-go-5bcb89d449-zcf8b   1/1     Running   0          10m
      pod/mongo-6866645f8d-4k7dx     1/1     Running   0          52s
      pod/mongo-6866645f8d-6g5bq     1/1     Running   0          52s
      pod/mongo-6866645f8d-8fc5s     1/1     Running   0          52s
      pod/mongo-6866645f8d-f4qxv     1/1     Running   0          52s
      pod/mongo-6866645f8d-h5xtn     1/1     Running   0          52s
      pod/mongo-6866645f8d-lplrv     1/1     Running   0          52s
      pod/mongo-6866645f8d-lv9tx     1/1     Running   0          52s
      pod/mongo-6866645f8d-m264p     1/1     Running   0          52s
      pod/mongo-6866645f8d-mdjgf     1/1     Running   0          52s
      pod/mongo-6866645f8d-vdfjm     1/1     Running   0          52s
      ~~~
  * 업데이트 실행
    * `# kubectl set image deploy mongo mongo=mongo:4.4 --record=true`
  * 파드의 이미지 정보 확인
    * `# kubectl get pod -ojsonpath='{..image}'`
      ~~~
      gasbugs/http-go:v1 gasbugs/http-go:v1 gasbugs/http-go:v1 gasbugs/http-go:v1 gasbugs/http-go:v1 gasbugs/http-go:v1 mongo:4.2 mongo:4.2 mongo:4.2 mongo:4.2 mongo:4.2 mongo:4.2 mongo:4.2 mongo:4.2 mongo:4.2 mongo:4.2 mongo:4.4 mongo:4.4 mongo:4.4 mongo:4.4 mongo:4.4 mongo:4.4 mongo:4.4 mongo:4.4 mongo:4.4 mongo:4.4 mongo:4.4 mongo:4.4 mongo:4.4 mongo:4.4 mongo:4.4 mongo:4.4 mongo:4.4 mongo:4.4 mongo:4.4 mongo:4.4root@kjn-01:~#
      ~~~
  * `revision` 확인
    * `# kubectl rollout history deploy`
      ~~~
      deployment.apps/http-go
      REVISION  CHANGE-CAUSE
      3         kubectl apply --filename=http-go-v3-deploy.yaml --record=true
      4         kubectl set image deploy http-go http-go=gasbugs/http-go:v2 --record=true
      5         kubectl apply --filename=http-go-v1-deploy.yaml --record=true

      deployment.apps/mongo
      REVISION  CHANGE-CAUSE
      1         kubectl apply --filename=mongo-4.2-deploy.yaml --record=true
      2         kubectl set image deploy mongo mongo=mongo:4.4 --record=true

      ~~~
  * `mongo:4.2`로 롤백 후 확인
    * `# kubectl rollout undo deploy mongo`
    * `# kubectl rollout history deploy`
      ~~~
      deployment.apps/http-go
      REVISION  CHANGE-CAUSE
      3         kubectl apply --filename=http-go-v3-deploy.yaml --record=true
      4         kubectl set image deploy http-go http-go=gasbugs/http-go:v2 --record=true
      5         kubectl apply --filename=http-go-v1-deploy.yaml --record=true

      deployment.apps/mongo
      REVISION  CHANGE-CAUSE
      2         kubectl set image deploy mongo mongo=mongo:4.4 --record=true
      3         kubectl apply --filename=mongo-4.2-deploy.yaml --record=true

      ~~~
