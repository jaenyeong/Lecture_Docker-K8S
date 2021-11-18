# Chapter05 실습

## Pod / Replicaset 기본 실습
* Simple Pod 생성
  * `$ kubectl run test --image=nginx`
* 생성한 pod 확인
  * `$ kubectl get pod test`
  * `$ kubectl describe pod test`
* Replicaset 확인/생성
  * `$ kubeclt get replicasets`
  * `$ kubectl create replicaset test ~`
* Pod/Replicaset 삭제
  * `$ kubectl delete pod / replicaset ~`
* Replicaset을 edit 하여 pod 숫자
  * `$ kubectl edit replicaset ~`

## Deployment 기본 실습
* Deployment 생성 및 수정
  * `$ kubectl create deployment nginx_deployment --image=nginx --dry-run=client -o yaml > deployment.yaml`
  * $ vi deployment.yaml`
    ~~~yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      creationTimestamp: null
      labels:
        app: nginx_deployment
      name: nginx_deployment
    spec:
    replicas: 1
    selector:
      matchLabels:
        app: nginx_deployment
    strategy: {}
    template:
      metadata:
      creationTimestamp: null
      labels:
        app: nginx_deployment
      spec:
        containers:
        - image: nginx
          name: nginx
          resources: {}
    status: {}
    ~~~

## 라벨링
Node Selector
* `$ kubectl get nodes`
  ~~~
  kjn-master-01.kr-central-1.c.internal   Ready    control-plane,master   28d   v1.21.0
  kjn-master-02.kr-central-1.c.internal   Ready    control-plane,master   28d   v1.21.0
  kjn-master-03.kr-central-1.c.internal   Ready    control-plane,master   28d   v1.21.0
  kjn-worker-01.kr-central-1.c.internal   Ready    <none>                 28d   v1.21.0
  kjn-worker-02.kr-central-1.c.internal   Ready    <none>                 28d   v1.21.0
  ~~~
* 1번 워커노드에 라벨링, 확인
  * `$ kubectl label nodes kjn-worker-01.kr-central-1.c.internal disktype=ssd`
  * `$ kubectl describe node kjn-worker-01`
* `$ kubectl run diskssd --image=nginx --dry-run=client -o yaml > diskssd.yaml`
* `diskssd.yaml` 파일 수정
  * `$ vi diskssd.yaml`
  ~~~yaml
  apiVersion: v1
  kind: Pod
  metadata:
  creationTimestamp: null
  labels:
      run: diskssd
  name: diskssd
  spec:
  containers:
  - image: nginx
      name: diskssd
      resources: {}
  # nodeSelector disktype 추가
  nodeSelector:
      disktype: ssd
  dnsPolicy: ClusterFirst
  restartPolicy: Always
  status: {}
  ~~~
* 파드 생성
  * `$ kubectl apply -f diskssd.yaml`
  * `$ kubectl get pod -o wide`
* `워커 노드 2`에도 생성, 라벨링 확인
  * `name: diskssd` 을 `name: diskssd2`로 변경하여 생성
  * `$ kubectl apply -f diskssd.yaml`
  * `$ kubectl get pod -o wide`

Node affinity
* 위 `diskssd.yaml` 파일 복사
  * `$ cp diskssd.yaml diskssd-affinity.yaml`
* `diskssd-affinity.yaml` 파일 수정
  * `$ vi diskssd-affinity.yaml`
  ~~~yaml
  apiVersion: v1
  kind: Pod
  metadata:
    creationTimestamp: null
    labels:
      run: diskssd
    name: diskssd3
  spec:
    affinity:
      nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
        - key: disktype
          # In: 해당 value가 있는지 (키 + 쌍 모두 확인)
          # Exists: Key만 확인
          operator: In 
          values:
          - ssd
    containers:
    - image: nginx
      name: diskssd
      resources: {}
    dnsPolicy: ClusterFirst
    restartPolicy: Always
  status: {}
  ~~~
* 파드 생성, 확인
  * `$ kubectl apply -f diskssd-affinity.yaml`
  * `$ kubectl get pod -o wide`

Taint/Toleration
* 테인트 확인 (`Taints` 항목 확인)
  * `$ kubectl describe nodes kjn-master-01`
  * `$ kubectl describe nodes kjn-worker-01`
* 테스트 파드 생성, 확인
  * `$ kubectl run test --image=nginx`
  * `$ kubectl run test2 --image=nginx`
  * `$ kubectl get pod -o wide`
* 다시 삭제
  * `$ kubectl delete pod test`
  * `$ kubectl delete pod test2`
* 테인트 설정
  * `$ kubectl taint nodes kjn-worker-02.kr-central-1.c.internal tttest=no:NoSchedule`
* 다시 테스트 파드 생성, 확인
  * `$ kubectl run test --image=nginx`
  * `$ kubectl get pod -o wide`
* 테인트에 영향 없는 파드 생성
  * `$ kubectl run test2 --image=nginx --dry-run=client -o yaml > toleration.yaml`
  * `yaml` 파일에 `toleration` 설정 추가
    ~~~yaml
    apiVersion: v1
    kind: Pod
    metadata:
      creationTimestamp: null
      labels:
        run: test2
      name: test2
    spec:
      containers:
      - image: nginx
        name: test2
        resources: {}
      tolerations:
      - key: "tttest"
        operator: "Exists"
        effect: "NoSchedule"
      dnsPolicy: ClusterFirst
      restartPolicy: Always
    status: {}
    ~~~
* 생성, 확인
  * `$ kubectl apply -f toleration.yaml`
  * `$ kubectl get pod -o wide`
* 톨러레이션 설정은 지정하지 않으면 `operator`의 기본 값은 `Equal`
  * 톨러레이션은 키와 이펙트가 동일한 경우, 테인트와 일치
  * 다음 경우도 마찬가지
    * `operator`가 `Exists`인 경우
    * `operator`는 `Equal`이고 `value`는 `value`로 같음
* 테인트 확인, 제거
  * `$ kubectl describe node kjn-worker-02.kr-central-1.c.internal | grep -i taint`
  * `$ kubectl taint nodes kjn-worker-02.kr-central-1.c.internal tttest=no:NoSchedule-`
    * 마지막 `-`를 꼭 붙일 것

멀티 컨테이너 Pod
* `yaml` 파일 생성
  * `Deployment`를 파일로 수정 (`Container`가 2번 들어가지 않으니 실수 주의)
  * `$ kubectl run test --image=nginx --dry-run=client -o yaml > multicontainer.yaml`
  ~~~yaml
  apiVersion: v1
  kind: Pod
  metadata:
  creationTimestamp: null
  labels:
    run: test
  name: test
  spec:
    containers:
    - image: nginx
      name: gold
    - image: redis
      name: silver
    dnsPolicy: ClusterFirst
    restartPolicy: Always
  status: {}
  ~~~
* 생성, 확인
  * `$ kubectl apply -f multicontainer.yaml`
  * `$ kubectl get pod`
    ~~~
    NAME       READY   STATUS    RESTARTS   AGE
    diskssd    1/1     Running   0          11h
    diskssd2   1/1     Running   0          10h
    diskssd3   1/1     Running   0          10h
    test       2/2     Running   0          23s 
    ~~~
* 삭제
  * `$ kubectl delete pod test`
* 두 개의 컨테이너가 한 개의 `emptydir` 볼륨을 바라보게 하기
  * [볼륨 문서 참조](https://kubernetes.io/docs/concepts/storage/volumes/)
  * `$ vi emptydir.yaml`
    ~~~yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: test-pd
    spec:
      containers:
      - image: nginx
        name: test-container
        volumeMounts:
        - mountPath: /cache
          name: cache-volume
      - image: redis
        name: redis
        volumeMounts:
        - mountPath: /cache
          name: cache-volume
      volumes:
      - name: cache-volume
        emptyDir: {}
    ~~~
    * 파드가 죽으면 볼륨(cache-volume)도 같이 죽음
* 생성, 확인
  * `$ kubectl apply -f emptydir.yaml`
  * `$ kubectl get pod`
  * `$ kubectl describe pod test-pd`
* `test-container` 컨테이너 확인
  * 디폴트 컨테이너 선택
    * `$ kubectl exec -it test-pd -- /bin/sh`
  * 직접 지정
    * `$ kubectl exec -it test-pd -c test-container -- /bin/sh`
  * 테스트
    * `$ cd /cache`
    * `$ touch i_am_test_container`
    * `$ ls`
    * `$ cd ..`
    * `$ ls`
* `redis` 컨테이너 확인
  * `$ kubectl exec -it test-pd -c redis -- /bin/sh`
  * `$ cd /` > `$ ls`

네임스페이스
* 확인
  * `$ kubectl get pods -A`
* 네임스페이스 생성, 확인
  * `$ kubectl create namespace kakao`
  * `$ kubectl get namespace`
* 네임스페이스에 파드 생성, 확인
  * `$ kubectl run likelion --image=nginx --namespace=kakao`
  * `$ kubectl get pods`
* 네임스페이스로 파드 확인
  * `$ kubectl get pods -n kakao`

Label과 Selector
* 파드 명령어 확인
  * `$ kubectl get pod --help`
* 파드 생성
  * `$ kubectl run pod --image=nginx -l teacher=kjn --dry-run=client -o yaml > label.yaml`
    ~~~yaml
    apiVersion: v1
    kind: Pod
    metadata:
      creationTimestamp: null
      labels:
        teacher: kjn
      name: pod
    spec:
      containers:
      - image: nginx
        name: pod
        resources: {}
      dnsPolicy: ClusterFirst
      restartPolicy: Always
    status: {}
    ~~~
  * `$ kubectl apply -f label.yaml`
* 파드 조회
  * `$ kubectl get pod --selector teacher=kjn`
  * `$ kubectl get pod -l teacher=kjn`

Staticpod
* 스태틱 파드 설정 파일 경로
  * `$ cd /etc/kubernetes/manifests/`
  * 해당 경로에 있는 `yaml` 파일들은 스태틱 파드와 관련된 파일
    * etcd.yaml
    * kube-apiserver.yaml
    * kube-controller-manager.yaml
    * kube-scheduler.yaml
* 파드 확인
  * `$ kubectl get pod -A`
  * `$ kubectl get deployments.apps -A`
  * `$ kubectl get replicasets.apps -A`
* 기본 값 외우지 않고 `static pod manifest` 저장된 위치 찾기
  * `$ ps -ef | grep kubelet | grep conf`
* 컨피그 파일 확인
  * `$ sudo cat /var/lib/kubelet/config.yaml`
* `etcd-data` 볼륨은 `/var/lib/etcd` 경로에 저장
* 스태틱 파드 생성
  * 특정 파드에서만 특정 명령어를 실행 (`command` 명령)
  ~~~
  $ cd ~

  $ kubectl run --restart=Never --image=busybox static-busybox --dry-run=client -o yaml --command -- sleep 1000 > ./static-busybox.yaml

  $ cat ./static-busybox.yaml
  ~~~
* 정적 파드를 복사하여 생성
  * `$ sudo cp static-busybox.yaml /etc/kubernetes/manifests/`
* 파드 삭제
  * 삭제 시에도 파드를 삭제하는 것이 아닌 복사한 `static-busybox.yaml`을 삭제하여 파드 삭제
  * `$ cd /etc/kubernetes/manifests/` && `$ rm -rf static-busybox.yaml`
  * 삭제 명령 후 10초 정도 이후에 삭제됨(슬립 때문인 것으로 추정)

클러스터 노드 작업
* cordon
  * `$ kubectl cordon kjn-worker-01.kr-central-1.c.internal`
  * `$ kubectl describe node kjn-worker-01`
* drain
  * `$ kubectl drain kjn-worker-01.kr-central-1.c.internal`
  * 위 명령으로 안되는 경우
    * `$ kubectl drain kjn-worker-01.kr-central-1.c.internal --force --ignore-daemonsets`
* taint
  * `$ kubectl uncordon kjn-worker-01.kr-central-1.c.internal`
  * `$ kubectl describe node kjn-worker-01 | grep -i taint` (테인트 확인)
  * `$ kubectl describe node kjn-worker-02 | grep -i taint` (테인트 확인)
  * `$ kubectl run test --image=nginx`
  * `$ kubectl drain kjn-worker-02.kr-central-1.c.internal --delete-emptydir-data --ignore-daemonsets`
  * `$ kubectl get pod -o wide`
* drain
  * `$ kubectl uncordon kjn-worker-01.kr-central-1.c.internal`
  * `$ kubectl uncordon kjn-worker-02.kr-central-1.c.internal`
  * `$ kubectl drain kjn-worker-01.kr-central-1.c.internal`
* 다시 시작
  * `$ kubectl create deployment kjn --image=nginx -r 3`
  * `$ kubectl drain kjn-worker-02.kr-central-1.c.internal --ignore-daemonsets`
  * `$ kubectl uncordon kjn-worker-02.kr-central-1.c.internal --ignore-daemonsets`

클러스터 업그레이드
* [문서](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/)
* 버전 확인
  * `$ kubectl version` (1.21)
  * `$ kubeadm version` (1.21)
* 1번 마스터 노드
  * 업그레이드 전 drain
    * `$ sudo su -`
    * `# kubectl drain kjn-master-01.kr-central-1.c.internal --ignore-daemonsets`
  * 업그레이드 가능한 버전 확인
    * `# yum list --showduplicates kubeadm --disableexcludes=kubernetes`
  * 컨트롤 플레인 노드 업그레이드
    * `# yum install -y kubeadm-1.22.1-0 --disableexcludes=kubernetes`
  * 업그레이드 후 버전 확인
    * `# kubeadm version` (1.22)
  * 업그레이드 계획 확인
    * `# kubeadm upgrade plan`
      * `permission denied` 발생 시 루트 계정으로 전환
    * `preflight` 수행하여 클러스터가 정상인지 확인, `kube-system kubeadm-config` 컨피그맵 검사
    * 업그레이드 하는게 좋을지 알려줌 (root 계정으로 실행)
  * kubeadm 업그레이드
    * `# kubeadm upgrade apply v1.22.1`
  * uncordon
    * `# kubectl uncordon kjn-master-01.kr-central-1.c.internal`
* 2번 마스터 노드
  * 업그레이드 전 drain
    * `$ sudo su -`
    * `# kubectl drain kjn-master-02.kr-central-1.c.internal --ignore-daemonsets`
      * 루트 계정으로 전환하지 않으면 아래와 같은 에러 문구 출력
      * `The connection to the server localhost:8080 was refused - did you specify the right host or port?`
  * 업그레이드 가능한 버전 확인
    * `# yum list --showduplicates kubeadm --disableexcludes=kubernetes`
  * 컨트롤 플레인 노드 업그레이드
    * `# yum install -y kubeadm-1.22.1-0 --disableexcludes=kubernetes`
  * 업그레이드 후 버전 확인
    * `# kubeadm version` (1.22)
  * 업그레이드 계획 확인
    * `# kubeadm upgrade plan`
  * kubeadm 업그레이드
    * `# kubeadm upgrade node`
  * uncordon
    * `# kubectl uncordon kjn-master-02.kr-central-1.c.internal`
* 3번 마스터 노드
  * 업그레이드 전 drain
    * `$ sudo su -`
    * `# kubectl drain kjn-master-03.kr-central-1.c.internal --ignore-daemonsets`
      * 루트 계정으로 전환하지 않으면 아래와 같은 에러 문구 출력
      * `The connection to the server localhost:8080 was refused - did you specify the right host or port?`
  * 업그레이드 가능한 버전 확인
    * `# yum list --showduplicates kubeadm --disableexcludes=kubernetes`
  * 컨트롤 플레인 노드 업그레이드
    * `# yum install -y kubeadm-1.22.1-0 --disableexcludes=kubernetes`
  * 업그레이드 후 버전 확인
    * `# kubeadm version` (1.22)
  * 업그레이드 계획 확인
    * `# kubeadm upgrade plan`
  * kubeadm 업그레이드
    * `# kubeadm upgrade node`
  * uncordon
    * `# kubectl uncordon kjn-master-03.kr-central-1.c.internal`

kubelet, kubectl 업그레이드
* 1번 마스터 노드
  * `# kubectl drain kjn-master-01.kr-central-1.c.internal --ignore-daemonsets`
  * `# yum install -y kubelet-1.22.1-0 kubectl-1.22.1-0 --disableexcludes=kubernetes`
  * `# systemctl daemon-reload`
  * `# systemctl restart kubelet`
  * `# kubectl uncordon kjn-master-01.kr-central-1.c.internal`
* 2번 마스터 노드
  * `# kubectl drain kjn-master-02.kr-central-1.c.internal --ignore-daemonsets`
  * `# yum install -y kubelet-1.22.1-0 kubectl-1.22.1-0 --disableexcludes=kubernetes`
  * `# systemctl daemon-reload`
  * `# systemctl restart kubelet`
  * `# kubectl uncordon kjn-master-02.kr-central-1.c.internal`
* 3번 마스터 노드
  * `# kubectl drain kjn-master-03.kr-central-1.c.internal --ignore-daemonsets`
  * `# yum install -y kubelet-1.22.1-0 kubectl-1.22.1-0 --disableexcludes=kubernetes`
  * `# systemctl daemon-reload`
  * `# systemctl restart kubelet`
  * `# kubectl uncordon kjn-master-03.kr-central-1.c.internal`
* 1번 워커 노드
  * `$ sudo su -`
  * `# yum install -y kubeadm-1.22.1-0 --disableexcludes=kubernetes`
  * `# kubeadm upgrade node`
  * 1번 마스터 노드에서 처리
    * `# kubectl drain kjn-worker-01.kr-central-1.c.internal --ignore-daemonsets`
  * `# yum install -y kubelet-1.22.1-0 kubectl-1.22.1-0 --disableexcludes=kubernetes`
  * `# systemctl daemon-reload`
  * `# systemctl restart kubelet`
  * 1번 마스터 노드에서 처리
    * `# kubectl uncordon kjn-worker-01.kr-central-1.c.internal`
    * `# kubectl get nodes` 확인
* 2번 워커 노드
  * `$ sudo su -`
  * `# yum install -y kubeadm-1.22.1-0 --disableexcludes=kubernetes`
  * `# kubeadm upgrade node`
  * 1번 마스터 노드에서 처리
    * `# kubectl drain kjn-worker-02.kr-central-1.c.internal --ignore-daemonsets`
  * `# yum install -y kubelet-1.22.1-0 kubectl-1.22.1-0 --disableexcludes=kubernetes`
  * `# systemctl daemon-reload`
  * `# systemctl restart kubelet`
  * 1번 마스터 노드에서 처리
    * `# kubectl uncordon kjn-worker-02.kr-central-1.c.internal`
    * `# kubectl get nodes` 확인