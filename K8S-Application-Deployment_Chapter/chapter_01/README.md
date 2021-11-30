# Chapter 01 실습

## 클러스터 환경 재구성
* K8S 설치 필요 사항
  * 인스턴스 4대를 사용해 구성
  * 마스터 노드 1개
    * K8S의 마스터 노드가 설정될 호스트
  * 워커 노드 3개
    * 클러스터에 컨테이너를 띄울 워커 노드 추가
  * 가상 머신은 `2CPU, 메모리 4GB` 사용 필요

## Kakao i Cloud VM 생성
* 기존에 사용하던 모든 VM 인스턴스 전체 삭제
* 새 인스턴스 4개 생성
  * `ubuntu18.04-cloudimage` 이미지 선택
    * `Ubuntu Server 18.04 LTS for Virtual Machine`
  * 마스터 노드 1개
    * `kjn-01`
  * 워커 노드 3개
    * `kjn-02`
    * `kjn-03`
    * `kjn-04`
* 인스턴스 설명 (식별할 수 있는 설명 작성)
  * `수강생 김재녕`
* 인스턴스 타입
  * `A1-2-CO vCPU: 2개 Memory: 4 GB`
* 볼륨 타입 / 크기
  * `Root Volume SSD 45 GiB`
  * `인스턴스와 함께 삭제` 선택
* 키페어
  * 기존에 생성해 사용하던 키페어 선택
* 네트워크
  * 프라이빗(`likelion-private-01`) 선택
  * 서브넷(`likelion-private-01 (172.30.4.0/22)`)은 기본 선택 사용
* 시큐리티
  * `default` 사용
* 검토
  ~~~
  1단계: 이미지 설정

  이미지 이름
  Ubuntu 18.04

  이미지 설명
  Ubuntu Server 18.04 LTS for Virtual Machine

  2단계: 인스턴스 설정

  인스턴스 개수
  4

  인스턴스 이름
  kjn-01

  인스턴스 설명
  수강생 김재녕

  인스턴스 타입
  A1-2-CO

  루트 볼륨
  SSD / 45 GB

  키페어
  kjn01

  3단계: 네트워크/보안 설정

  네트워크
  likelion-private-01

  서브넷
  likelion-private-01

  적용된 시큐리티 그룹
  default
  ~~~

## kubeadm 설치
* [설치 문서](https://kubernetes.io/ko/docs/setup/production-environment/tools/kubeadm/install-kubeadm/)
  * 우분투는 `iptables가 브리지된 트래픽을 보게 하기` 설정 안해도 됨
* 아래 설정을 모든 노드에 적용
* 루트 계정 사용
  * `$ sudo -i`
* `apt` 업데이트
  * `# apt update && apt install -y docker.io`
* 도커 확인
  * `# docker info`
* `kubeadm`, `kubelet`, `kubectl` 설치 (데미안 기반 배포판 명령 사용)
  * `kubeadm`
    * 클러스터를 부트스트랩하는 명령
  * `kubelet`
    * 클러스터의 모든 머신에서 실행되는 파드와 컨테이너 시작과 같은 작업을 수행하는 컴포넌트
  * `kubectl`
    * 클러스터와 통신하기 위한 커맨드 라인 유틸리티
  * 해당 명령들을 그대로 복붙하면 잘 안되는 경우가 있어 `kube_install.sh`파일로 작성하여 실행
    ~~~
    cat <<EOF > kube_install.sh
    sudo apt-get update
    sudo apt-get install -y apt-transport-https ca-certificates curl

    sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg

    echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

    sudo apt-get update
    sudo apt-get install -y kubelet kubeadm kubectl
    sudo apt-mark hold kubelet kubeadm kubectl

    EOF

    bash kube_install.sh
    ~~~
    * [1] apt 패키지 색인을 업데이트하고, 쿠버네티스 apt 리포지터리를 사용하는 데 필요한 패키지를 설치한다.
      ~~~
      # sudo apt-get update
      # sudo apt-get install -y apt-transport-https ca-certificates curl
      ~~~
    * [2] 구글 클라우드의 공개 사이닝 키를 다운로드 한다.
      ~~~
      # sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
      ~~~
    * [3] 쿠버네티스 apt 리포지터리를 추가한다.
      ~~~
      # echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
      apt 패키지 색인을 업데이트하고, kubelet, kubeadm, kubectl을 설치하고 해당 버전을 고정한다.

      # sudo apt-get update
      # sudo apt-get install -y kubelet kubeadm kubectl
      # sudo apt-mark hold kubelet kubeadm kubectl
      ~~~
  * 설치 확인
    * `# kubeadm version`
* `cgroup` 드라이버 구성
  * 과거에는 기본 설정 되어 있었으나 최근에는 설정 필요
    * 컨테이너 런타임과 `kubelet`의 `cgroup` 드라이버를 일치시켜야 함
    * 일치하지 않으면 `kubelet` 프로세스 오류 발생
  * `docker cgroupfs systemd` 검색하여 관련 자료 확인하여 설정
    ~~~
    cat <<EOF > /etc/docker/daemon.json
    {
      "exec-opts": ["native.cgroupdriver=systemd"]
    }
    EOF
    service docker restart
    ~~~
* 클러스터 구성
  * 마스터 노드에서 `# kubeadm init` 명령 실행
    * 마스터 노드가 여러 개라면 다소 복잡한 설정이 필요하나 하나인 경우는 간단
  * 설치 성공 시 화면
    ~~~
    [init] Using Kubernetes version: v1.22.4
    [preflight] Running pre-flight checks
    [preflight] Pulling images required for setting up a Kubernetes cluster
    [preflight] This might take a minute or two, depending on the speed of your internet connection
    [preflight] You can also perform this action in beforehand using 'kubeadm config images pull'
    [certs] Using certificateDir folder "/etc/kubernetes/pki"
    [certs] Generating "ca" certificate and key
    [certs] Generating "apiserver" certificate and key
    [certs] apiserver serving cert is signed for DNS names [kjn-01 kubernetes kubernetes.default kubernetes.default.svc kubernetes.default.svc.cluster.local] and IPs [10.96.0.1 172.30.4.144]
    [certs] Generating "apiserver-kubelet-client" certificate and key
    [certs] Generating "front-proxy-ca" certificate and key
    [certs] Generating "front-proxy-client" certificate and key
    [certs] Generating "etcd/ca" certificate and key
    [certs] Generating "etcd/server" certificate and key
    [certs] etcd/server serving cert is signed for DNS names [kjn-01 localhost] and IPs [172.30.4.144 127.0.0.1 ::1]
    [certs] Generating "etcd/peer" certificate and key
    [certs] etcd/peer serving cert is signed for DNS names [kjn-01 localhost] and IPs [172.30.4.144 127.0.0.1 ::1]
    [certs] Generating "etcd/healthcheck-client" certificate and key
    [certs] Generating "apiserver-etcd-client" certificate and key
    [certs] Generating "sa" key and public key
    [kubeconfig] Using kubeconfig folder "/etc/kubernetes"
    [kubeconfig] Writing "admin.conf" kubeconfig file
    [kubeconfig] Writing "kubelet.conf" kubeconfig file
    [kubeconfig] Writing "controller-manager.conf" kubeconfig file
    [kubeconfig] Writing "scheduler.conf" kubeconfig file
    [kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
    [kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
    [kubelet-start] Starting the kubelet
    [control-plane] Using manifest folder "/etc/kubernetes/manifests"
    [control-plane] Creating static Pod manifest for "kube-apiserver"
    [control-plane] Creating static Pod manifest for "kube-controller-manager"
    [control-plane] Creating static Pod manifest for "kube-scheduler"
    [etcd] Creating static Pod manifest for local etcd in "/etc/kubernetes/manifests"
    [wait-control-plane] Waiting for the kubelet to boot up the control plane as static Pods from directory "/etc/kubernetes/manifests". This can take up to 4m0s
    [apiclient] All control plane components are healthy after 11.506080 seconds
    [upload-config] Storing the configuration used in ConfigMap "kubeadm-config" in the "kube-system" Namespace
    [kubelet] Creating a ConfigMap "kubelet-config-1.22" in namespace kube-system with the configuration for the kubelets in the cluster
    [upload-certs] Skipping phase. Please see --upload-certs
    [mark-control-plane] Marking the node kjn-01 as control-plane by adding the labels: [node-role.kubernetes.io/master(deprecated) node-role.kubernetes.io/control-plane node.kubernetes.io/exclude-from-external-load-balancers]
    [mark-control-plane] Marking the node kjn-01 as control-plane by adding the taints [node-role.kubernetes.io/master:NoSchedule]
    [bootstrap-token] Using token: mlev5s.mrbxbsyvyqh4imn4
    [bootstrap-token] Configuring bootstrap tokens, cluster-info ConfigMap, RBAC Roles
    [bootstrap-token] configured RBAC rules to allow Node Bootstrap tokens to get nodes
    [bootstrap-token] configured RBAC rules to allow Node Bootstrap tokens to post CSRs in order for nodes to get long term certificate credentials
    [bootstrap-token] configured RBAC rules to allow the csrapprover controller automatically approve CSRs from a Node Bootstrap Token
    [bootstrap-token] configured RBAC rules to allow certificate rotation for all node client certificates in the cluster
    [bootstrap-token] Creating the "cluster-info" ConfigMap in the "kube-public" namespace
    [kubelet-finalize] Updating "/etc/kubernetes/kubelet.conf" to point to a rotatable kubelet client certificate and key
    [addons] Applied essential addon: CoreDNS
    [addons] Applied essential addon: kube-proxy

    Your Kubernetes control-plane has initialized successfully!

    To start using your cluster, you need to run the following as a regular user:

      mkdir -p $HOME/.kube
      sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
      sudo chown $(id -u):$(id -g) $HOME/.kube/config

    Alternatively, if you are the root user, you can run:

      export KUBECONFIG=/etc/kubernetes/admin.conf

    You should now deploy a pod network to the cluster.
    Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
      https://kubernetes.io/docs/concepts/cluster-administration/addons/

    Then you can join any number of worker nodes by running the following on each as root:

    kubeadm join 172.30.5.70:6443 --token jzq8p7.wvss4hh5bivmsyha \
      --discovery-token-ca-cert-hash sha256:462a49a3da2e5cba60a974a1ed7e7a33ff7120e7aeec9d5a3a3f4a06b38819a9
    ~~~
  * 마스터 노드에서 사용자 설정
    ~~~
    # mkdir -p $HOME/.kube
    # sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    # sudo chown $(id -u):$(id -g) $HOME/.kube/config
    ~~~
  * 워커 노드에서 조인 설정
    * `# kubeadm join 172.30.5.70:6443 --token jzq8p7.wvss4hh5bivmsyha \
      --discovery-token-ca-cert-hash sha256:462a49a3da2e5cba60a974a1ed7e7a33ff7120e7aeec9d5a3a3f4a06b38819a9`
  * 마스터 노드에서 설치 확인
    * `# kubectl get nodes` (`Not Ready` 상태)
  * 마스터 노드에 `CNI (Container Network Interface)` 설치
    * [해당 문서](https://kubernetes.io/ko/docs/concepts/cluster-administration/addons/)
    * 네트워킹 서드파티 플러그인 중 `weave net` 사용 (`calico` `weave net` 등)
      * [weave net](https://www.weave.works/docs/net/latest/kubernetes/kube-addon/)
      * `# kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"`
  * 마스터 노드에서 설치 재확인
    * `# kubectl get nodes` (`Ready` 상태)

## `Wordpress`, `MySQL` 배포
* [문서](https://kubernetes.io/ko/docs/tutorials/stateful-application/mysql-wordpress-persistent-volume/)
* 마스터 노드에 파일 생성
  * 도커 이미지 횟수 제한으로 도커 시크릿 생성
    * 도커 로그인
      * `# sudo docker login`
    * 시크릿 생성
      * `# kubectl create secret docker-registry dockersecret --docker-username="" --docker-password="" --docker-server=https://index.docker.io/v1/ --dry-run=client -o yaml > dockersecret.yaml`
    * 리소스 생성
      * `# kubectl apply -f dockersecret.yaml`
    * 확인
      * `# kubectl get secret`
    * `Docker.sock` 권한 설정
      * `# sudo chmod 666 /var/run/docker.sock`
    * 시크릿을 `default` 네임 스페이스의 모든 파드를 대상으로 적용
      * `# kubectl patch serviceaccount default -p "{\"imagePullSecrets\": [{\"name\": \"dockersecret\"}]}" -n default`
  * 디렉터리 생성
    * `# mkdir wordpress && cd wordpress`
  * `MySQL` 리소스 구성
    * 스토리지 클래스가 없는 상태에서 PVC를 만들면 안되기 때문에 `PersistentVolumeClaim` 설정 제외
    * `volumeMounts`, `volumes`도 제외
      * 디스크가 영구적이지 않으나 그대로 진행
    ~~~
    cat <<EOF >./mysql-deployment.yaml
    apiVersion: v1
    kind: Service
    metadata:
      name: wordpress-mysql
      labels:
        app: wordpress
    spec:
      ports:
        - port: 3306
      selector:
        app: wordpress
        tier: mysql
      clusterIP: None
    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: wordpress-mysql
      labels:
        app: wordpress
    spec:
      selector:
        matchLabels:
          app: wordpress
          tier: mysql
      strategy:
        type: Recreate
      template:
        metadata:
          labels:
            app: wordpress
            tier: mysql
        spec:
          containers:
          - image: mysql:5.6
            name: mysql
            env:
            - name: MYSQL_ROOT_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: mysql-pass
                  key: password
            ports:
            - containerPort: 3306
              name: mysql
    EOF
    ~~~
  * `Wordpress` 리소스 구성
    ~~~
    cat <<EOF >./wordpress-deployment.yaml
    apiVersion: v1
    kind: Service
    metadata:
      name: wordpress
      labels:
        app: wordpress
    spec:
      ports:
        - port: 80
      selector:
        app: wordpress
        tier: frontend
      type: LoadBalancer
    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: wordpress
      labels:
        app: wordpress
    spec:
      selector:
        matchLabels:
          app: wordpress
          tier: frontend
      strategy:
        type: Recreate
      template:
        metadata:
          labels:
            app: wordpress
            tier: frontend
        spec:
          containers:
          - image: wordpress:4.8-apache
            name: wordpress
            env:
            - name: WORDPRESS_DB_HOST
              value: wordpress-mysql
            - name: WORDPRESS_DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: mysql-pass
                  key: password
            ports:
            - containerPort: 80
              name: wordpress
    EOF
    ~~~
  * 시크릿 생성자 추가
    ~~~
    cat <<EOF >./kustomization.yaml
    secretGenerator:
    - name: mysql-pass
      literals:
      - password=test1234
    resources:
      - mysql-deployment.yaml
      - wordpress-deployment.yaml
    EOF
    ~~~
  * 정의한 파일을 토대로 리소스 생성
    * `# kubectl apply -k ./`
  * `yaml` 파일에서 `mysql-pass`를 못찾는 경우
    ~~~
    cat <<EOF | kubectl apply -f -
    apiVersion: v1
    kind: Secret
    metadata:
      name: mysql-pass
    type: Opaque
    data:
      password: $(echo -n "YOUR_PASSWORD" | base64 -w0)
    EOF
    ~~~
  * 확인
    * `# kubectl get svc`
      ~~~
      NAME              TYPE           CLUSTER-IP   EXTERNAL-IP   PORT(S)        AGE
      kubernetes        ClusterIP      10.96.0.1    <none>        443/TCP        79m
      wordpress         LoadBalancer   10.99.38.0   <pending>     80:31171/TCP   58m
      wordpress-mysql   ClusterIP      None         <none>        3306/TCP       58m
      ~~~
    * 브라우저에서 마스터 노드 IP로 접속 확인
      * `172.30.5.70:31171`
      * `admin`, `test12341234` 계정 생성

## CKA, CKAD, CKS
* [치트 시트 문서](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
  * 자동 완성 추가
    ~~~
    # setup autocomplete in bash into the current shell, bash-completion package should be installed first.
    source <(kubectl completion bash)

    # add autocomplete permanently to your bash shell.
    echo "source <(kubectl completion bash)" >> ~/.bashrc
    ~~~
  * `kubectl` 명령 축약
    * `# alias k=kubectl`
    * `# complete -F __start_kubectl k`

## Multi Container POD
* 하나의 파드에서 `nginx`, `redis` 이미지를 모두 실행하는 `yaml` 생성, 실행
* [문서](https://kubernetes.io/ko/docs/tasks/access-application-cluster/communicate-containers-same-pod-shared-volume/)
* 마스터 노드에서 실행
  ~~~
  cat <<EOF | kubectl apply -f -
  apiVersion: v1
  kind: Pod
  metadata:
    name: two-containers
  spec:
    containers:
    - name: nginx-container
      image: nginx:1.21.3
    - name: redis-container
      image: redis:6.2.6
  EOF
  ~~~
* 두 개 이상의 컨테이너가 올라와 있는 환경이라면, 로그를 확인하거나 `exec` 명령을 통해 컨테이너를 선택해야 함
  * `# kubectl logs two-containers nginx-container`
  * `# kubectl exec -it two-containers -c nginx-container -- bash`
    * `-c` 명령으로 컨테이너 지정

## Liveness Probe, Readiness Probe, Startup Probe
* [문서](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)
* 마스터 노드에서 실행
  * `# kubectl apply -f https://k8s.io/examples/pods/probe/exec-liveness.yaml`
    ~~~
    Events:
    Type     Reason     Age                  From               Message
    ----     ------     ----                 ----               -------
    Normal   Scheduled  3m10s                default-scheduler  Successfully assigned default/liveness-exec to kjn-03
    Normal   Pulled     3m5s                 kubelet            Successfully pulled image "k8s.gcr.io/busybox" in 2.575692202s
    Normal   Pulled     108s                 kubelet            Successfully pulled image "k8s.gcr.io/busybox" in 1.415225461s
    Warning  Unhealthy  65s (x6 over 2m30s)  kubelet            Liveness probe failed: cat: can't open '/tmp/healthy': No such file or directory
    Normal   Killing    65s (x2 over 2m20s)  kubelet            Container liveness failed liveness probe, will be restarted
    Normal   Pulling    34s (x3 over 3m8s)   kubelet            Pulling image "k8s.gcr.io/busybox"
    Normal   Pulled     32s                  kubelet            Successfully pulled image "k8s.gcr.io/busybox" in 1.445035856s
    Normal   Created    31s (x3 over 3m3s)   kubelet            Created container liveness
    Normal   Started    31s (x3 over 3m3s)   kubelet            Started container liveness
    ~~~
    * `(x6 over 2m30s)` 2분 30초 동안 6번 실패를 의미
  * `# kubectl apply -f https://k8s.io/examples/pods/probe/http-liveness.yaml`

## Sidecar Container
* `nginx-sidecar.yaml` 파일 생성
  * `# vi nginx-sidecar.yaml`
  ~~~yaml
  apiVersion: v1
  kind: Pod
  metadata:
    name: nginx-sidecar
  spec:
    containers:
    - name: nginx
      image: nginx
      ports:
      - containerPort: 80
      volumeMounts:
      - name: varlognginx
        mountPath: /var/log/nginx
    - name: sidecar-access
      image: busybox
      args: [/bin/sh, -c, 'tail -n+1 -f /var/log/nginx/access.log']
      volumeMounts:
      - name: varlognginx
        mountPath: /var/log/nginx
    - name: sidecar-error
      image: busybox
      args: [/bin/sh, -c, 'tail -n+1 -f /var/log/nginx/error.log']
      volumeMounts:
      - name: varlognginx
        mountPath: /var/log/nginx
    volumes:
    - name: varlognginx
      emptyDir: {}
  ~~~
  * 에러를 `tail`로 계속 출력
  * `busybox`
    * 하나의 실행 파일 안에 리눅스(유닉스) 도구(명령어)들을 모아 제공하는 소프트웨어
    * `IoT`, `Android` 등에서 자주 사용됨
* 파드 생성
  * `# kubectl apply -f nginx-sidecar.yaml`
* 접속 후 로그 확인
  * `# kubectl exec nginx-sidecar -- curl 127.0.0.1`
  * `# kubectl logs nginx-sidecar sidecar-access`

## Adapter Container
* [예제 코드](https://github.com/jaenyeong/Sample_k8s-adaptor-container-pattern)
* `pod.yaml`
  ~~~yaml
  apiVersion: v1
  kind: Pod
  metadata:
    name: adapter-container-demo
  spec:
    containers:
    - image: busybox
      command: ["/bin/sh"]
      args: ["-c", "while true; do echo $(date -u)'#This is log' >> /var/log/file.log; sleep 5;done"]
      name: main-container
      resources: {}
      volumeMounts:
      - name: var-logs
        mountPath: /var/log
    - image: bbachin1/adapter-node-server
      name: adapter-container
      imagePullPolicy: Always
      resources: {}
      ports:
        - containerPort: 3080
      volumeMounts:
      - name: var-logs
        mountPath: /var/log
    dnsPolicy: Default
    volumes:
    - name: var-logs
      emptyDir: {}
  ~~~
* 클러스터에 배포
  * `# kubectl apply -f https://raw.githubusercontent.com/jaenyeong/Sample_k8s-adaptor-container-pattern/master/pod.yml`
* 데이터 요청 (별도로 수행하지 않음)
  * `# kubectl get pod -o wide`
  * `# curl 10.40.0.4:3080/logs -s > text.txt`
* 포트포워딩
  * `# kubectl port-forward adapter-container-demo 8080:3080`
* 새로 마스터노드에 접속해 확인
  * `# curl localhost:8080/logs`

## Ambassador Container
* [예제 코드](https://github.com/jaenyeong/Sample_k8s-ambassador-container-pattern)
* 클러스터에 배포
  * `# kubectl apply -f https://raw.githubusercontent.com/jaenyeong/Sample_k8s-ambassador-container-pattern/master/pod.yml`
* 컨테이너로 요청
  * `# kubectl exec -it ambassador-container-demo -c ambassador-container -- curl localhost:9000`
  * 현재는 403으로 정상적으로 통신 불가 (응답이 오지 않는 것이 정상)
* 로그에서 통신 정보 확인
  * `# kubectl logs ambassador-container-demo main-container`

## Init Container
* [문서](https://kubernetes.io/ko/docs/concepts/workloads/pods/init-containers/)
* `myapp.yaml` 생성
  * `# vi myapp.yaml`
  ~~~yaml
  apiVersion: v1
  kind: Pod
  metadata:
    name: myapp-pod
    labels:
      app: myapp
  spec:
    containers:
    - name: myapp-container
      image: busybox:1.28
      command: ['sh', '-c', 'echo The app is running! && sleep 3600']
    initContainers:
    - name: init-myservice
      image: busybox:1.28
      command: ['sh', '-c', "until nslookup myservice.$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace).svc.cluster.local; do echo waiting for myservice; sleep 2; done"]
    - name: init-mydb
      image: busybox:1.28
      command: ['sh', '-c', "until nslookup mydb.$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace).svc.cluster.local; do echo waiting for mydb; sleep 2; done"]
  ~~~
  * 클러스터에 배포
    * `# kubectl apply -f myapp.yaml`
* `services.yaml`생성
  * `# vi services.yaml`
  ~~~yaml
  apiVersion: v1
  kind: Service
  metadata:
    name: myservice
  spec:
    ports:
    - protocol: TCP
      port: 80
      targetPort: 9376
  ---
  apiVersion: v1
  kind: Service
  metadata:
    name: mydb
  spec:
    ports:
    - protocol: TCP
      port: 80
      targetPort: 9377
  ~~~
  * 클러스터에 배포
    * `# kubectl apply -f services.yaml`

## job, cronjob
* [job 문서](https://kubernetes.io/ko/docs/concepts/workloads/controllers/job/)
* [병렬 처리, cronjob 문서](https://kubernetes.io/ko/docs/tasks/job/_print/)
* [cronjob 문서](https://kubernetes.io/ko/docs/concepts/workloads/controllers/cron-jobs/)
* `job` 예제
  ~~~yaml
  cat <<EOF | kubectl apply -f -
  apiVersion: batch/v1
  kind: Job
  metadata:
    name: pi
  spec:
    template:
      spec:
        containers:
        - name: pi
          image: perl
          command: ["perl",  "-Mbignum=bpi", "-wle", "print bpi(2000)"]
        restartPolicy: Never
    backoffLimit: 4
  EOF
  ~~~
* `job` 예제
  ~~~yaml
  cat <<EOF | kubectl apply -f -
  apiVersion: batch/v1
  kind: Job
  metadata:
    name: pi-parallelism
  spec:
    completions: 5 # 목표 완료 파드 개수
    parallelism: 2 # 동시 실행 가능 파드 개수
    template:
      spec:
        containers:
        - name: pi
          image: perl
          command: ["perl",  "-Mbignum=bpi", "-wle", "print bpi(2000)"]
        restartPolicy: Never
    backoffLimit: 4
  EOF
  ~~~
* 확인
  * `# kubectl get job,pod`
* `cronjob` 예제
  ~~~yaml
  cat <<EOF | kubectl apply -f -
  apiVersion: batch/v1
  kind: CronJob
  metadata:
    name: hello-1
  spec:
    concurrencyPolicy: Allow
    schedule: "*/1 * * * *"
    jobTemplate:
      spec:
        template:
          spec:
            containers:
            - name: hello
              image: busybox
              args:
              - /bin/sh
              - -c
              - date; echo Hello from the Kubernetes cluster
            restartPolicy: OnFailure
  EOF
  ~~~
* `리플레이스 정책을 적용한 cronjob` 예제
  ~~~yaml
  cat <<EOF | kubectl apply -f -
  apiVersion: batch/v1
  kind: CronJob
  metadata:
    name: hello-2
  spec:
    concurrencyPolicy: Replace
    schedule: "*/1 * * * *"
    jobTemplate:
      spec:
        template:
          spec:
            containers:
            - name: hello
              image: busybox
              args:
              - /bin/sh
              - -c
              - date; echo Hello from the Kubernetes cluster; sleep 100;
            restartPolicy: OnFailure
  EOF
  ~~~
* `cronjob` 확인
  * `# kubectl get cronjob`
  * `# kubectl get pod -w`
    * `watch` 옵션으로 확인
* `cronjob` 삭제
  * `# kubectl delete cronjob hello-1`

## 시스템 리소스 요구사항과 제한 설정
* [문서](https://kubernetes.io/ko/docs/concepts/configuration/manage-resources-containers/)
* `kube-system` 확인 (`apiserver` 할당된 리소스 확인)
  * `# kubectl get pod -n kube-system`
  * `# kubectl get pod -n kube-system kube-apiserver-kjn-01 -o yaml`
* 예제
  ~~~yaml
  cat <<EOF | kubectl apply -f -
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: nginx
  spec:
    replicas: 3
    selector:
      matchLabels:
        app: nginx
    template:
      metadata:
        labels:
          app: nginx
      spec:
        containers:
        - name: nginx
          image: nginx
          ports:
          - containerPort: 80
          resources:
            requests:
              memory: "200Mi"
              cpu: "1m"
            limits:
              memory: "400Mi"
              cpu: "2m"
  EOF
  ~~~
  * 확인
    * `# kubectl get pod -o wide`
  * 노드에 할당된 리소스 확인
    * `# kubectl describe nodes kjn-02`
    * `# kubectl describe nodes kjn-03`
* `limitRanges`
  * [문서](https://kubernetes.io/ko/docs/concepts/policy/limit-range/)
  * `# vim cpu-mem-min-max-default-lr.yaml`
    ~~~yaml
    apiVersion: v1
    kind: LimitRange
    metadata:
      name: cpu-mem-min-max-default-lr
    spec:
      limits:
      - max:
          cpu: "800m"
          memory: "1Gi"
        min:
          cpu: "100m"
          memory: "99Mi"
        default: # default Limit
          cpu: 700m
          memory: 900Mi
        defaultRequest:
          cpu: 110m
          memory: 111Mi
        type: Container
    ~~~
  * 실행
    * `# kubectl apply -f cpu-mem-min-max-default-lr.yaml`
  * 확인
   * `# kubectl get limitranges`
* 파드 실행 명령
  * `# kubectl run nginx-lr --image=nginx`
* `nginx-lr`의 `limitRanges` 정책에 따라 리소스 제한이 자동으로 `default` 값이 입력됐는지 확인
  * `# kubectl get pod nginx-lr -o yaml`
    ~~~yaml
    spec:
    containers:
    - image: nginx
      imagePullPolicy: Always
      name: nginx-lr
      resources:
        limits:
          cpu: 700m
          memory: 900Mi
        requests:
          cpu: 110m
          memory: 111Mi
    ~~~
