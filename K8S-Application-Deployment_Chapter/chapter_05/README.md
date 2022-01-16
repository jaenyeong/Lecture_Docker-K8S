# Chapter 05 실습

## 시큐리티 컨텍스트
* [참조](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/)
* `$ sudo -i`
* 마스터 노드에 컨테이너 권한에 제한을 걸어둔 파드 실행
  * `# kubectl apply -f https://k8s.io/examples/pods/security/security-context.yaml`
    ~~~yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: security-context-demo
    spec:
      securityContext:
        runAsUser: 1000
        runAsGroup: 3000
        fsGroup: 2000
      volumes:
      - name: sec-ctx-vol
        emptyDir: {}
      containers:
      - name: sec-ctx-demo
        image: busybox
        command: [ "sh", "-c", "sleep 1h" ]
        volumeMounts:
        - name: sec-ctx-vol
          mountPath: /data/demo
        securityContext:
          allowPrivilegeEscalation: false
    ~~~
  * 타임아웃 에러 발생
    * `Unable to connect to the server: context deadline exceeded (Client.Timeout exceeded while awaiting headers)`
* 해당 파드 내부로 접속해 확인
  * `# kubectl exec -it security-context-demo -- sh`
    ~~~console
    / $ id
    uid=1000 gid=3000 groups=2000
    
    / $ ps
    PID   USER     TIME  COMMAND
        1 1000      0:00 sleep 1h
        8 1000      0:00 sh
       18 1000      0:00 ps
       
    / $ cd /data/demo/
    
    /data/demo $ echo hello > testfile
    
    /data/demo $ ls -al
    total 12
    drwxrwsrwx    2 root     2000          4096 Jan  2 14:45 .
    drwxr-xr-x    3 root     root          4096 Jan  2 14:40 ..
    -rw-r--r--    1 1000     2000             6 Jan  2 14:45 testfile
    
    /data/demo $ touch /data/test
    touch: /data/test: Permission denied
    
    /data/demo $ touch ~/test
    touch: //test: Permission denied
    
    /data/demo $ exit
    ~~~
    * `/data/demo` 경로 외에 작업 권한 없음
* 일반 컨테이너 생성
  * `# kubectl run -it --rm --image=gcr.io/google-samples/node-hello:1.0 node sh`
* `date` 명령을 사용해 싱크 설정
    ~~~
    # date +%T -s "12:00:00"
    date: cannot set date: Operation not permitted
    12:00:00
    # exit
    ~~~
    * `SYS_TIME` 등 권한이 없기 때문에 에러 발생
* 네트워크와 시스템 시간 관련 커널 권한을 가진 파드 생성
  * `# kubectl apply -f https://k8s.io/examples/pods/security/security-context-4.yaml`
    ~~~yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: security-context-demo-4
    spec:
      containers:
      - name: sec-ctx-4
        image: gcr.io/google-samples/node-hello:1.0
        securityContext:
          capabilities:
            add: ["NET_ADMIN", "SYS_TIME"]
    ~~~
  * `# kubectl exec -it security-context-demo-4 -- sh`
* `date` 명령을 사용해 싱크 설정
  ~~~
  # date +%T -s "12:00:00"
  12:00:00
  # exit
  ~~~
* 파드 정보 확인
  * `# kubectl get pod -o wide`
    ~~~
    NAME                      READY   STATUS    RESTARTS   AGE     IP          NODE     NOMINATED NODE   READINESS GATES
    security-context-demo     1/1     Running   0          27m     10.32.0.2   kjn-04   <none>           <none>
    security-context-demo-4   1/1     Running   0          5m49s   10.32.0.9   kjn-04   <none>           <none>
    ~~~
    * `security-context-demo-4` 파드가 4번 노드에 있기 때문에 4번 노드로 접속
  * 해당 4번 노드에 `ntp` 동기화를 비활성화 설정
    * `$ sudo -i`
    * `# timedatectl set-ntp false`
  * 마스터 노드에서 시간 확인
    * `# kubectl exec -it security-context-demo-4 -- sh`
      ~~~
      # date +%T -s "12:00:00"
      12:00:00
      # date
      Sun Jan  2 12:00:03 UTC 2022
      ~~~
  * 4번 노드에서 `ntp` 동기화를 다시 활성화 설정
    * `# timedatectl set-ntp true`
  * 마스터 노드에서 다시 확인
    ~~~
    # date
    Sun Jan  2 15:12:22 UTC 2022
    # exit
    ~~~

## 네트워크 정책 적용
* 이그레스 (`Egress`) 설명
  ~~~yaml
  apiVersion: networking.k8s.io/v1
  kind: NetworkPolicy
  metadata:
    name: test-network-policy
    namespace: default
  spec:
    podSelector:
      matchLabels:
        role: db
    policyTypes:
    - Egress
    egress:
    - to:
      - ipBlock:
          cidr: 10.0.0.0/24
      ports:
      - protocol: TCP
        port: 5978
  ~~~
  * 선택된 파드에서 나가는 트래픽에 대한 정책 설정
    * `policyTypes`을 `Egress`로 설정 시 기본적으로 모든 트래픽에 대해서 `denied`
  * `egress` 설정으로 화이트리스트 설정
    * `ipBlock`을 통해 허용하고자 하는 IP 대역 설정 가능
      * 여기서 `block`의 뜻은 차단이 아닌 덩어리
    * `Ports`에는 어떤 포트를 허용할 지 명시
* 인그레스 (`Ingress`) 설명
  ~~~yaml
  apiVersion: networking.k8s.io/v1
  kind: NetworkPolicy
  metadata:
    name: test-network-policy
    namespace: default
  spec:
    podSelector:
      matchLabels:
        role: db
    policyTypes:
    - Ingress
    ingress:
    - from:
      - ipBlock:
          cidr: 172.17.0.0/16
          except:
          - 172.17.1.0/24
      - namespaceSelector:
          matchLabels:
            app: myproject
      - podSelector:
          matchLabels:
            role: frontend
    ports:
    - protocol: TCP
      port: 6379
  ~~~
  * 선택된 파드로 들어오는 트래픽에 대한 정책 설정
    * `policyTypes`을 `Ingress`로 설정 시 기본적으로 모든 트래픽에 대해서 `denied`
  * `ingress` 설정으로 화이트리스트 설정
    * `ipBlock`을 통해 허용하고자 하는 IP 대역 설정 가능
      * 여기서 `block`의 뜻은 차단이 아닌 덩어리
    * `Except`를 사용하여 예외 항목 설정 가능
    * `Ports`에는 어떤 포트를 허용할 지 명시
* `Network Policy` 테스트
  * [네트워크 정책 구성 문서](https://cloud.google.com/kubernetes-engine/docs/tutorials/network-policy)
  * 마스터 노드에 네트워크 정책으로 보호할 새 파드 구성
    * `# kubectl run hello-web --labels app=hello --image=us-docker.pkg.dev/google-samples/containers/gke/hello-app:1.0 --port 8080 --expose`
  * 해당 파드를 보호하는 정책 설정
    * `# kubectl apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/kubernetes-engine-samples/61c260c6e208e54dc7cb586fa77bea9b2bc10f81/network-policies/hello-allow-from-foo.yaml`
    * 위 명령에서 사용한 설정은 아래와 같음
      * [해당 정책 설정 파일](https://github.com/GoogleCloudPlatform/kubernetes-engine-samples/blob/HEAD/network-policies/hello-allow-from-foo.yaml)
        ~~~yaml
        kind: NetworkPolicy
        apiVersion: networking.k8s.io/v1
        metadata:
          name: hello-allow-from-foo
        spec:
          policyTypes:
          - Ingress
          podSelector:
            matchLabels:
              app: hello
          ingress:
          - from:
            - podSelector:
                matchLabels:
                  app: foo
        ~~~
      * 위 설정 파일로도 적용 가능 `# kubectl apply -f hello-allow-from-foo.yaml`
  * 네트워크 정책이 정상적으로 설정 되었는 지 동작 확인 (`CNI` 통신 확인)
    * `CNI`는 K8S 네트워크 플러그인 인터페이스
    * `# kubectl run -l app=foo --image=alpine --restart=Never --rm -i -t test-1`
      * 새 명령 프롬프트에서 아래 명령으로 확인
      * `/ # wget -qO- --timeout=2 http://hello-web:8080`
      * 결과
        ~~~console
        Hello, world!
        Version: 1.0.0
        Hostname: hello-web
        ~~~
    * `/ # exit`
  * 다른 레이블을 사용하는 경우 동작 확인
    * `# kubectl run -l app=other --image=alpine --restart=Never --rm -i -t test-2`
    * 새 명령 프롬프트에서 아래 명령으로 확인
      * `/ # wget -qO- --timeout=2 http://hello-web:8080`
      * 결과
        ~~~console
        wget -qO- --timeout=2 http://hello-web:8080
        ~~~
    * `/ # exit`

## 네트워크 정책 적용 연습문제
* ![Network-Policy-Exercise](./Network-policy-exercise.png)
  * 위와 같이 통신이 가능하도록 네트워크 정책 설정할 것
  * 기존 구성 형태는 아래 참조
* 기본 구성 명령
  ~~~
  cat <<EOF | kubectl apply -f -
  # network-policy-exercise.yaml
  apiVersion: v1
  kind: Pod
  metadata:
    name: http-go-v1
    labels:
      app: http-go-v1
  spec:
    containers:
    - name: http-go
      image: gasbugs/http-go:v1
      ports:
      - containerPort: 8080
  ---
  apiVersion: v1
  kind: Pod
  metadata:
    name: http-go-v2
    labels:
      app: http-go-v2
  spec:
    containers:
    - name: http-go
      image: gasbugs/http-go:v2
      ports:
      - containerPort: 8080
  ---
  apiVersion: v1
  kind: Pod
  metadata:
    name: http-go-v3
    labels:
      app: http-go-v3
  spec:
    containers:
    - name: http-go
      image: gasbugs/http-go:v3
      ports:
      - containerPort: 8080

  ---
  apiVersion: v1
  kind: Service
  metadata:
    name: http-go-v1
  spec:
    selector:
      app: http-go-v1
    ports:
      - protocol: TCP
        port: 80
        targetPort: 8080
  ---
  apiVersion: v1
  kind: Service
  metadata:
    name: http-go-v2
  spec:
    selector:
      app: http-go-v2
    ports:
      - protocol: TCP
        port: 80
        targetPort: 8080
  ---
  apiVersion: v1
  kind: Service
  metadata:
    name: http-go-v3
  spec:
    selector:
      app: http-go-v3
    ports:
      - protocol: TCP
        port: 80
        targetPort: 8080
  EOF
  ~~~
* 풀이
  ~~~
  cat <<EOF | kubectl apply -f -
  # http-go-v1
  apiVersion: networking.k8s.io/v1
  kind: NetworkPolicy
  metadata:
    name: http-go-v1-network-policy
    namespace: default
  spec:
    podSelector:
      matchLabels:
        app: http-go-v1
    policyTypes:
    - Ingress
    ingress:
    - from:
      - podSelector:
          matchLabels:
            app: http-go-v2
      ports:
      - protocol: TCP
        port: 8080
  ---
  # http-go-v2
  apiVersion: networking.k8s.io/v1
  kind: NetworkPolicy
  metadata:
    name: http-go-v2-network-policy
    namespace: default
  spec:
    podSelector:
      matchLabels:
        app: http-go-v2
    policyTypes:
    - Ingress
    ingress:
    - from:
      - podSelector:
          matchLabels:
            app: http-go-v3
      ports:
      - protocol: TCP
        port: 8080
  ---
  # http-go-v3
  apiVersion: networking.k8s.io/v1
  kind: NetworkPolicy
  metadata:
    name: http-go-v3-network-policy
    namespace: default
  spec:
    podSelector:
      matchLabels:
        app: http-go-v3
    policyTypes:
    - Ingress
  EOF
  ~~~
* 실행 결과
  ~~~console
  networkpolicy.networking.k8s.io/http-go-v1-network-policy created
  networkpolicy.networking.k8s.io/http-go-v2-network-policy created
  networkpolicy.networking.k8s.io/http-go-v3-network-policy created
  ~~~
* 확인
  * X
    * `# kubectl exec http-go-v1 -- curl http-go-v2 -s` > X
    * `# kubectl exec http-go-v1 -- curl http-go-v3 -s` > X
    * `# kubectl exec http-go-v2 -- curl http-go-v1 -s` > X
    * `# kubectl exec http-go-v2 -- curl http-go-v3 -s` > X
    * `# kubectl exec http-go-v3 -- curl http-go-v1 -s` > X
    * `# kubectl exec http-go-v3 -- curl http-go-v2 -s` > X
  * O
    * `# kubectl exec http-go-v2 -- curl http-go-v1 -s` > O
    * `# kubectl exec http-go-v3 -- curl http-go-v2 -s` > O
  
## 감사 `Audit` 기능 활성화
* 마스터 노드에 감사 기능 활성화
* `# vim /etc/kubernetes/audit-policy.yaml`
  ~~~yaml
  apiVersion: audit.k8s.io/v1 # This is required.
  kind: Policy
  # RequestReceived 단계의 모든 요청에 대해 감사 이벤트를 생성하지 않음
  omitStages:
    - "RequestReceived"
  rules:
    # RequestResponse 수준에서 파드 변경 사항 기록
    - level: RequestResponse
      resources:
      - group: ""
        # 리소스 `파드`는 `RBAC` 정책과 일치하는 파드의 하위 리소스에 대한 요청과 일치하지 않음
        resources: ["pods"]
    # 메타데이터 수준에서 `pods/log`, `pods/status`를 기록
    - level: Metadata
      resources:
      - group: ""
        resources: ["pods/log", "pods/status"]

    # `controller-leader`라는 `configmap`에 요청을 기록하지 않는 설정
    - level: None
      resources:
      - group: ""
        resources: ["configmaps"]
        resourceNames: ["controller-leader"]

    # 엔드포인트 또는 서비스에서 `system:kube-proxy`에 의한 감시 요청을 기록하지 않음
    - level: None
      users: ["system:kube-proxy"]
      verbs: ["watch"]
      resources:
      - group: "" # core API group
        resources: ["endpoints", "services"]

    # 리소스가 아닌 특정 URL 경로에 인증된 요청을 기록하지 않음
    - level: None
      userGroups: ["system:authenticated"]
      nonResourceURLs:
      - "/api*" # Wildcard matching.
      - "/version"

    # `kube-system`에서 `configmap` 변경 사항의 요청 본문을 기록
    - level: Request
      resources:
      - group: "" # core API group
        resources: ["configmaps"]
      # 이 규칙은 `kube-system` 네임스페이스의 리소스에만 적용
      # 빈 문자열 ""을 사용하여 네임스페이스가 없는 리소스를 선택 가능
      namespaces: ["kube-system"]

    # 메타데이터 수준에서 다른 모든 네임스페이스의 `configmap` 및 비밀 변경 사항 기록
    - level: Metadata
      resources:
      - group: "" # core API group
        resources: ["secrets", "configmaps"]

    # 요청 수준에서 코어 및 확장의 다른 모든 리소스 기록
    - level: Request
      resources:
      - group: "" # core API group
      - group: "extensions" # Version of group should NOT be included.

    # 메타데이터 수준에서 다른 모든 요청을 기록하는 포괄 규칙
    - level: Metadata
      # Long-running requests like watches that fall under this rule will not
      # generate an audit event in RequestReceived.
      omitStages:
        - "RequestReceived"
  ~~~
* `kube-apiserver` API 서버(컨테이너)가 마스터 노드에 있는 위 설정을 가져갈 수 있도록 구성
  * 마스터 노드의 `kube-apiserver.yaml` 파일 내 `.spec.containers[0].command`에 정책 파일 경로와 로그 경로 추가
  * `# vim /etc/kubernetes/manifests/kube-apiserver.yaml`
    ~~~yaml
    - --audit-policy-file=/etc/kubernetes/audit-policy.yaml
    - --audit-log-path=/var/log/audit.log
    ~~~
    * 설정 파일의 유효성과 경로 확인할 것
  * 추가적으로 `.spec.containers[0].command`를 찾아 `volume mount` 인자 설정
    ~~~yaml
    volumeMounts:
     - mountPath: /etc/kubernetes/audit-policy.yaml
       name: audit
       readOnly: true
     - mountPath: /var/log/audit.log
       name: audit-log
       readOnly: false # 로그를 작성해야 하기 때문에 `false` 설정
    ~~~
    ~~~yaml
    volumes:
    - name: audit
      hostPath:
        path: /etc/kubernetes/audit-policy.yaml
        type: File
    - name: audit-log
      hostPath:
        path: /var/log/audit.log
        type: FileOrCreate
    ~~~
  * 다른 세션으로 마스터 노드에 접속하여 설정 적용(저장) 전 `kube-apiserver` 설정 파일 백업
    * `# cp /etc/kubernetes/manifests/kube-apiserver.yaml ./kube-apiserver.yaml.bak.20220117`
* `kube system` 확인
  * `# kubectl get pod -n kube-system`
* `/var/log/audit.log` 파일 로그 확인
  * `# tail -f /var/log/audit.log`
  * `# tail -n 1 /var/log/audit.log`

## `Trivy`를 활용한 컨테이너 취약점 진단
* 도커 컨테이너를 활용해 `Trivy` 설치
  * 컨테이너를 사용해 설치하면 호환성 등의 문제 없이 1분내로 구성
* 실행할 명령 설명
  * `# docker run --rm -v trivy-cache:/root/.cache/ -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest`
    * `--rm`
      * 컨테이너 종료 시 컨테이너를 바로 삭제하는 옵션
    * `-v trivy-cache:/root/.cache/`
      * 캐시 디렉터리 경로(파일) 공유(마운트)하는 볼륨 옵션
        * `Trivy`를 사용하려면 DB가 필요 (아무 데이터 없이 진단할 수 없기 때문)
          * 다만 실행할 때마다 기존 데이터를 다운로드하기 때문에 캐시 파일을 마운트하여
            최초 한번만 다운로드하여 영구적으로 사용할 수 있도록 볼륨을 공유
    * `-v /var/run/docker.sock:/var/run/docker.sock`
      * 소켓을 공유(마운트)하는 볼륨 옵션
        * 소켓을 공유해 현재 호스트에 구성된 도커 소켓을 통해 이미지 컨트롤
        * 소켓을 공유하는 이유는 내부 컨테이너가 외부 컨테이너와 통신(컨트롤)할 수 있는 방법을 제공하기 위함
          * 컨테이너 안에 컨테이너를 또 구성할 수 있음 (다만 복잡해짐)
* 마스터 노드에서 다음 명령 실행
  * `# docker run --rm -v trivy-cache:/root/.cache/ -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest`
  * `# docker run --rm -v trivy-cache:/root/.cache/ -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest image gasbugs/http-go`
  * 결과가 너무 많아 따로 기록하지 않음

## `kube-bench`를 활용한 K8S 보안 점검
* `kubectl`이 가능한 환경에서 `kube-bench` 설치
  * 마스터 노드에서 릴리즈 파일 다운로드
    * `# wget https://github.com/aquasecurity/kube-bench/releases/download/v0.6.3/kube-bench_0.6.3_linux_amd64.tar.gz`
    * `# tar -xf kube-bench_0.6.3_linux_amd64.tar.gz`
    * `# sudo mv kube-bench /usr/bin/`
  * 깃헙 프로젝트 다운로드
    * `# git clone https://github.com/aquasecurity/kube-bench`
    * `# cd kube-bench`
* 마스터 노드 점검
  * `~/kube-bench# kube-bench --config-dir `pwd`/cfg --config `pwd`/cfg/config.yaml run --targets=master`
    ~~~console
    [INFO] 1 Master Node Security Configuration
    [INFO] 1.1 Master Node Configuration Files
    [PASS] 1.1.1 Ensure that the API server pod specification file permissions are set to 644 or more restrictive (Automated)
    [PASS] 1.1.2 Ensure that the API server pod specification file ownership is set to root:root (Automated)
    [PASS] 1.1.3 Ensure that the controller manager pod specification file permissions are set to 644 or more restrictive (Automated)
    [PASS] 1.1.4 Ensure that the controller manager pod specification file ownership is set to root:root (Automated)
    [PASS] 1.1.5 Ensure that the scheduler pod specification file permissions are set to 644 or more restrictive (Automated)
    [PASS] 1.1.6 Ensure that the scheduler pod specification file ownership is set to root:root (Automated)
    [PASS] 1.1.7 Ensure that the etcd pod specification file permissions are set to 644 or more restrictive (Automated)
    [PASS] 1.1.8 Ensure that the etcd pod specification file ownership is set to root:root (Automated)
    [WARN] 1.1.9 Ensure that the Container Network Interface file permissions are set to 644 or more restrictive (Manual)
    [WARN] 1.1.10 Ensure that the Container Network Interface file ownership is set to root:root (Manual)
    [PASS] 1.1.11 Ensure that the etcd data directory permissions are set to 700 or more restrictive (Automated)
    [FAIL] 1.1.12 Ensure that the etcd data directory ownership is set to etcd:etcd (Automated)
    [PASS] 1.1.13 Ensure that the admin.conf file permissions are set to 644 or more restrictive (Automated)
    [PASS] 1.1.14 Ensure that the admin.conf file ownership is set to root:root (Automated)
    [PASS] 1.1.15 Ensure that the scheduler.conf file permissions are set to 644 or more restrictive (Automated)
    [PASS] 1.1.16 Ensure that the scheduler.conf file ownership is set to root:root (Automated)
    [PASS] 1.1.17 Ensure that the controller-manager.conf file permissions are set to 644 or more restrictive (Automated)
    [PASS] 1.1.18 Ensure that the controller-manager.conf file ownership is set to root:root (Automated)
    [PASS] 1.1.19 Ensure that the Kubernetes PKI directory and file ownership is set to root:root (Automated)
    [PASS] 1.1.20 Ensure that the Kubernetes PKI certificate file permissions are set to 644 or more restrictive (Manual)
    [PASS] 1.1.21 Ensure that the Kubernetes PKI key file permissions are set to 600 (Manual)
    [INFO] 1.2 API Server
    [WARN] 1.2.1 Ensure that the --anonymous-auth argument is set to false (Manual)
    [FAIL] 1.2.2 Ensure that the --token-auth-file parameter is not set (Automated)
    [PASS] 1.2.3 Ensure that the --kubelet-https argument is set to true (Automated)
    [PASS] 1.2.4 Ensure that the --kubelet-client-certificate and --kubelet-client-key arguments are set as appropriate (Automated)
    [FAIL] 1.2.5 Ensure that the --kubelet-certificate-authority argument is set as appropriate (Automated)
    [PASS] 1.2.6 Ensure that the --authorization-mode argument is not set to AlwaysAllow (Automated)
    [PASS] 1.2.7 Ensure that the --authorization-mode argument includes Node (Automated)
    [PASS] 1.2.8 Ensure that the --authorization-mode argument includes RBAC (Automated)
    [WARN] 1.2.9 Ensure that the admission control plugin EventRateLimit is set (Manual)
    [PASS] 1.2.10 Ensure that the admission control plugin AlwaysAdmit is not set (Automated)
    [WARN] 1.2.11 Ensure that the admission control plugin AlwaysPullImages is set (Manual)
    [WARN] 1.2.12 Ensure that the admission control plugin SecurityContextDeny is set if PodSecurityPolicy is not used (Manual)
    [PASS] 1.2.13 Ensure that the admission control plugin ServiceAccount is set (Automated)
    [PASS] 1.2.14 Ensure that the admission control plugin NamespaceLifecycle is set (Automated)
    [FAIL] 1.2.15 Ensure that the admission control plugin PodSecurityPolicy is set (Automated)
    [PASS] 1.2.16 Ensure that the admission control plugin NodeRestriction is set (Automated)
    [PASS] 1.2.17 Ensure that the --insecure-bind-address argument is not set (Automated)
    [FAIL] 1.2.18 Ensure that the --insecure-port argument is set to 0 (Automated)
    [PASS] 1.2.19 Ensure that the --secure-port argument is not set to 0 (Automated)
    [FAIL] 1.2.20 Ensure that the --profiling argument is set to false (Automated)
    [PASS] 1.2.21 Ensure that the --audit-log-path argument is set (Automated)
    [FAIL] 1.2.22 Ensure that the --audit-log-maxage argument is set to 30 or as appropriate (Automated)
    [FAIL] 1.2.23 Ensure that the --audit-log-maxbackup argument is set to 10 or as appropriate (Automated)
    [FAIL] 1.2.24 Ensure that the --audit-log-maxsize argument is set to 100 or as appropriate (Automated)
    [WARN] 1.2.25 Ensure that the --request-timeout argument is set as appropriate (Manual)
    [PASS] 1.2.26 Ensure that the --service-account-lookup argument is set to true (Automated)
    [PASS] 1.2.27 Ensure that the --service-account-key-file argument is set as appropriate (Automated)
    [PASS] 1.2.28 Ensure that the --etcd-certfile and --etcd-keyfile arguments are set as appropriate (Automated)
    [PASS] 1.2.29 Ensure that the --tls-cert-file and --tls-private-key-file arguments are set as appropriate (Automated)
    [PASS] 1.2.30 Ensure that the --client-ca-file argument is set as appropriate (Automated)
    [PASS] 1.2.31 Ensure that the --etcd-cafile argument is set as appropriate (Automated)
    [WARN] 1.2.32 Ensure that the --encryption-provider-config argument is set as appropriate (Manual)
    [WARN] 1.2.33 Ensure that encryption providers are appropriately configured (Manual)
    [WARN] 1.2.34 Ensure that the API Server only makes use of Strong Cryptographic Ciphers (Manual)
    [INFO] 1.3 Controller Manager
    [WARN] 1.3.1 Ensure that the --terminated-pod-gc-threshold argument is set as appropriate (Manual)
    [FAIL] 1.3.2 Ensure that the --profiling argument is set to false (Automated)
    [PASS] 1.3.3 Ensure that the --use-service-account-credentials argument is set to true (Automated)
    [PASS] 1.3.4 Ensure that the --service-account-private-key-file argument is set as appropriate (Automated)
    [PASS] 1.3.5 Ensure that the --root-ca-file argument is set as appropriate (Automated)
    [PASS] 1.3.6 Ensure that the RotateKubeletServerCertificate argument is set to true (Automated)
    [PASS] 1.3.7 Ensure that the --bind-address argument is set to 127.0.0.1 (Automated)
    [INFO] 1.4 Scheduler
    [FAIL] 1.4.1 Ensure that the --profiling argument is set to false (Automated)
    [PASS] 1.4.2 Ensure that the --bind-address argument is set to 127.0.0.1 (Automated)

    == Remediations master ==
    1.1.9 Run the below command (based on the file location on your system) on the master node.
    For example,
    chmod 644 <path/to/cni/files>

    1.1.10 Run the below command (based on the file location on your system) on the master node.
    For example,
    chown root:root <path/to/cni/files>

    1.1.12 On the etcd server node, get the etcd data directory, passed as an argument --data-dir,
    from the below command:
    ps -ef | grep etcd
    Run the below command (based on the etcd data directory found above).
    For example, chown etcd:etcd /var/lib/etcd

    1.2.1 Edit the API server pod specification file /etc/kubernetes/manifests/kube-apiserver.yaml
    on the master node and set the below parameter.
    --anonymous-auth=false

    1.2.2 Follow the documentation and configure alternate mechanisms for authentication. Then,
    edit the API server pod specification file /etc/kubernetes/manifests/kube-apiserver.yaml
    on the master node and remove the --token-auth-file=<filename> parameter.

    1.2.5 Follow the Kubernetes documentation and setup the TLS connection between
    the apiserver and kubelets. Then, edit the API server pod specification file
    /etc/kubernetes/manifests/kube-apiserver.yaml on the master node and set the
    --kubelet-certificate-authority parameter to the path to the cert file for the certificate authority.
    --kubelet-certificate-authority=<ca-string>

    1.2.9 Follow the Kubernetes documentation and set the desired limits in a configuration file.
    Then, edit the API server pod specification file /etc/kubernetes/manifests/kube-apiserver.yaml
    and set the below parameters.
    --enable-admission-plugins=...,EventRateLimit,...
    --admission-control-config-file=<path/to/configuration/file>

    1.2.11 Edit the API server pod specification file /etc/kubernetes/manifests/kube-apiserver.yaml
    on the master node and set the --enable-admission-plugins parameter to include
    AlwaysPullImages.
    --enable-admission-plugins=...,AlwaysPullImages,...

    1.2.12 Edit the API server pod specification file /etc/kubernetes/manifests/kube-apiserver.yaml
    on the master node and set the --enable-admission-plugins parameter to include
    SecurityContextDeny, unless PodSecurityPolicy is already in place.
    --enable-admission-plugins=...,SecurityContextDeny,...

    1.2.15 Follow the documentation and create Pod Security Policy objects as per your environment.
    Then, edit the API server pod specification file /etc/kubernetes/manifests/kube-apiserver.yaml
    on the master node and set the --enable-admission-plugins parameter to a
    value that includes PodSecurityPolicy:
    --enable-admission-plugins=...,PodSecurityPolicy,...
    Then restart the API Server.

    1.2.18 Edit the API server pod specification file /etc/kubernetes/manifests/kube-apiserver.yaml
    on the master node and set the below parameter.
    --insecure-port=0

    1.2.20 Edit the API server pod specification file /etc/kubernetes/manifests/kube-apiserver.yaml
    on the master node and set the below parameter.
    --profiling=false

    1.2.22 Edit the API server pod specification file /etc/kubernetes/manifests/kube-apiserver.yaml
    on the master node and set the --audit-log-maxage parameter to 30 or as an appropriate number of days:
    --audit-log-maxage=30

    1.2.23 Edit the API server pod specification file /etc/kubernetes/manifests/kube-apiserver.yaml
    on the master node and set the --audit-log-maxbackup parameter to 10 or to an appropriate
    value.
    --audit-log-maxbackup=10

    1.2.24 Edit the API server pod specification file /etc/kubernetes/manifests/kube-apiserver.yaml
    on the master node and set the --audit-log-maxsize parameter to an appropriate size in MB.
    For example, to set it as 100 MB:
    --audit-log-maxsize=100

    1.2.25 Edit the API server pod specification file /etc/kubernetes/manifests/kube-apiserver.yaml
    and set the below parameter as appropriate and if needed.
    For example,
    --request-timeout=300s

    1.2.32 Follow the Kubernetes documentation and configure a EncryptionConfig file.
    Then, edit the API server pod specification file /etc/kubernetes/manifests/kube-apiserver.yaml
    on the master node and set the --encryption-provider-config parameter to the path of that file: --encryption-provider-config=</path/to/EncryptionConfig/File>

    1.2.33 Follow the Kubernetes documentation and configure a EncryptionConfig file.
    In this file, choose aescbc, kms or secretbox as the encryption provider.

    1.2.34 Edit the API server pod specification file /etc/kubernetes/manifests/kube-apiserver.yaml
    on the master node and set the below parameter.
    --tls-cipher-suites=TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_128_GCM
    _SHA256,TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_RSA_WITH_AES_256_GCM
    _SHA384,TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_ECDSA_WITH_AES_256_GCM
    _SHA384

    1.3.1 Edit the Controller Manager pod specification file /etc/kubernetes/manifests/kube-controller-manager.yaml
    on the master node and set the --terminated-pod-gc-threshold to an appropriate threshold,
    for example:
    --terminated-pod-gc-threshold=10

    1.3.2 Edit the Controller Manager pod specification file /etc/kubernetes/manifests/kube-controller-manager.yaml
    on the master node and set the below parameter.
    --profiling=false

    1.4.1 Edit the Scheduler pod specification file /etc/kubernetes/manifests/kube-scheduler.yaml file
    on the master node and set the below parameter.
    --profiling=false


    == Summary master ==
    42 checks PASS
    11 checks FAIL
    11 checks WARN
    0 checks INFO

    == Summary total ==
    42 checks PASS
    11 checks FAIL
    11 checks WARN
    0 checks INFO
    ~~~
  * `[FAIL] 1.1.12 Ensure that the etcd data directory ownership is set to etcd:etcd (Automated)`
    * `etcd` 권한이 `root`한테 있음
      ~~~
      root@kjn-01:~/kube-bench# ls -al /var/lib/etcd/
      total 12
      drwx------  3 root root 4096 Jan  2 23:38 .
      drwxr-xr-x 45 root root 4096 Nov 28 14:20 ..
      drwx------  4 root root 4096 Jan  2 23:38 member
      ~~~
    * `etcd` 유저 생성 및 권한 할당
      * `# useradd etcd`
      * `# chown etcd. /var/lib/etcd`
    * 결과 확인
      * `[PASS] 1.1.12 Ensure that the etcd data directory ownership is set to etcd:etcd (Automated)`
  * `[FAIL] 1.2.2 Ensure that the --token-auth-file parameter is not set (Automated)`
    * 토큰 인증 파일 값 설정을 여부 확인 (안하기를 권장)
    * `kube-apiserver` 설정 파일에서 해당 부분 수정
      * `~/kube-bench# vim /etc/kubernetes/manifests/kube-apiserver.yaml`
    * 해당 설정 삭제
      * `- --token-auth-file=/etc/kubernetes/pki/somefile.csv`
    * 결과 확인
      * `[PASS] 1.2.3 Ensure that the --token-auth-file parameter is not set (Automated)`
  * `--targets=master` 옵션을 제외하면 전체 점검
    * 잘못된 데이터가 나올 수 있어 권장하지 않음
* 워커 노드 점검
  * `~/kube-bench# kube-bench --config-dir `pwd`/cfg --config `pwd`/cfg/config.yaml run --targets=node`
    ~~~console
    [INFO] 4 Worker Node Security Configuration
    [INFO] 4.1 Worker Node Configuration Files
    [PASS] 4.1.1 Ensure that the kubelet service file permissions are set to 644 or more restrictive (Automated)
    [PASS] 4.1.2 Ensure that the kubelet service file ownership is set to root:root (Automated)
    [PASS] 4.1.3 If proxy kubeconfig file exists ensure permissions are set to 644 or more restrictive (Manual)
    [PASS] 4.1.4 If proxy kubeconfig file exists ensure ownership is set to root:root (Manual)
    [PASS] 4.1.5 Ensure that the --kubeconfig kubelet.conf file permissions are set to 644 or more restrictive (Automated)
    [PASS] 4.1.6 Ensure that the --kubeconfig kubelet.conf file ownership is set to root:root (Automated)
    [PASS] 4.1.7 Ensure that the certificate authorities file permissions are set to 644 or more restrictive (Manual)
    [PASS] 4.1.8 Ensure that the client certificate authorities file ownership is set to root:root (Manual)
    [PASS] 4.1.9 Ensure that the kubelet --config configuration file has permissions set to 644 or more restrictive (Automated)
    [PASS] 4.1.10 Ensure that the kubelet --config configuration file ownership is set to root:root (Automated)
    [INFO] 4.2 Kubelet
    [PASS] 4.2.1 Ensure that the anonymous-auth argument is set to false (Automated)
    [PASS] 4.2.2 Ensure that the --authorization-mode argument is not set to AlwaysAllow (Automated)
    [PASS] 4.2.3 Ensure that the --client-ca-file argument is set as appropriate (Automated)
    [PASS] 4.2.4 Ensure that the --read-only-port argument is set to 0 (Manual)
    [PASS] 4.2.5 Ensure that the --streaming-connection-idle-timeout argument is not set to 0 (Manual)
    [FAIL] 4.2.6 Ensure that the --protect-kernel-defaults argument is set to true (Automated)
    [PASS] 4.2.7 Ensure that the --make-iptables-util-chains argument is set to true (Automated)
    [PASS] 4.2.8 Ensure that the --hostname-override argument is not set (Manual)
    [WARN] 4.2.9 Ensure that the --event-qps argument is set to 0 or a level which ensures appropriate event capture (Manual)
    [WARN] 4.2.10 Ensure that the --tls-cert-file and --tls-private-key-file arguments are set as appropriate (Manual)
    [PASS] 4.2.11 Ensure that the --rotate-certificates argument is not set to false (Manual)
    [PASS] 4.2.12 Verify that the RotateKubeletServerCertificate argument is set to true (Manual)
    [WARN] 4.2.13 Ensure that the Kubelet only makes use of Strong Cryptographic Ciphers (Manual)

    == Remediations node ==
    4.2.6 If using a Kubelet config file, edit the file to set protectKernelDefaults: true.
    If using command line arguments, edit the kubelet service file
    /etc/systemd/system/kubelet.service.d/10-kubeadm.conf on each worker node and
    set the below parameter in KUBELET_SYSTEM_PODS_ARGS variable.
    --protect-kernel-defaults=true
    Based on your system, restart the kubelet service. For example:
    systemctl daemon-reload
    systemctl restart kubelet.service

    4.2.9 If using a Kubelet config file, edit the file to set eventRecordQPS: to an appropriate level.
    If using command line arguments, edit the kubelet service file
    /etc/systemd/system/kubelet.service.d/10-kubeadm.conf on each worker node and
    set the below parameter in KUBELET_SYSTEM_PODS_ARGS variable.
    Based on your system, restart the kubelet service. For example:
    systemctl daemon-reload
    systemctl restart kubelet.service

    4.2.10 If using a Kubelet config file, edit the file to set tlsCertFile to the location
    of the certificate file to use to identify this Kubelet, and tlsPrivateKeyFile
    to the location of the corresponding private key file.
    If using command line arguments, edit the kubelet service file
    /etc/systemd/system/kubelet.service.d/10-kubeadm.conf on each worker node and
    set the below parameters in KUBELET_CERTIFICATE_ARGS variable.
    --tls-cert-file=<path/to/tls-certificate-file>
    --tls-private-key-file=<path/to/tls-key-file>
    Based on your system, restart the kubelet service. For example:
    systemctl daemon-reload
    systemctl restart kubelet.service

    4.2.13 If using a Kubelet config file, edit the file to set TLSCipherSuites: to
    TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384,TLS_RSA_WITH_AES_256_GCM_SHA384,TLS_RSA_WITH_AES_128_GCM_SHA256
    or to a subset of these values.
    If using executable arguments, edit the kubelet service file
    /etc/systemd/system/kubelet.service.d/10-kubeadm.conf on each worker node and
    set the --tls-cipher-suites parameter as follows, or to a subset of these values.
    --tls-cipher-suites=TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384,TLS_RSA_WITH_AES_256_GCM_SHA384,TLS_RSA_WITH_AES_128_GCM_SHA256
    Based on your system, restart the kubelet service. For example:
    systemctl daemon-reload
    systemctl restart kubelet.service


    == Summary node ==
    19 checks PASS
    1 checks FAIL
    3 checks WARN
    0 checks INFO

    == Summary total ==
    19 checks PASS
    1 checks FAIL
    3 checks WARN
    0 checks INFO
    ~~~

## `falco`를 활용한 K8S 컨테이너 보안 모니터링
* 파이썬 이미지 내에서 `apt` 명령 실행을 모니터링
  * `falco`를 먼저 설치하려면 모든 노드에 모두 설치 후 모니터링해야하기 때문에 해당 예제에서는 파이썬 먼저 세팅
* 마스터 노드에 파이썬 이미지 컨테이너 구성, 패키지 매니저 실행
  * `# kubectl run py --image=python:3.7 -- sleep infinity`
* 설치된 노드 확인
  * root@kjn-01:~# kubectl get pod -owide`
    ~~~console
    NAME            READY   STATUS    RESTARTS   AGE    IP          NODE     NOMINATED NODE   READINESS GATES
    nginx-sidecar   2/2     Running   0          23d    10.38.0.7   kjn-02   <none>           <none>
    py              1/1     Running   0          102s   10.40.0.1   kjn-03   <none>           <none>
    ~~~
* 위 결과대로 3번 노드에 `falco` 설치`
  ~~~console
  curl -s https://falco.org/repo/falcosecurity-3672BA8F.asc | apt-key add -
  echo "deb https://download.falco.org/packages/deb stable main" | tee -a /etc/apt/sources.list.d/falcosecurity.list
  apt-get update -y

  apt-get -y install linux-headers-$(uname -r)

  apt-get install -y falco
  ~~~
  * 첫 명령에서 `E: Type 'gpg' is not known on line 1 in source list` 에러가 나는 경우
    * `# cat /etc/apt/sources.list.d/falcosecurity.list` 명령으로 내용 확인 필요
    * 정상적인 경우 `deb https://download.falco.org/packages/deb stable main`
* 4번 노드에서 `falco` 실행
  * `# falco`
* 마스터 노드에서 파이썬 컨테이너로 접속하여 `apt` 명령 실행 및 `vim` 설치
  * `# kubectl exec py -- apt update`
  * `# kubectl exec py -- apt install -y vim`
* `syslog`에 `falco`를 `grep`하면 관련 로그 확인 가능
  * `# cat /var/log/syslog | grep falco`
    ~~~console
    Jan 22 21:40:37 kjn-03 falco: Falco version 0.30.0 (driver version 3aa7a83bf7b9e6229a3824e3fd1f4452d1e95cb4)
    Jan 22 21:40:38 kjn-03 falco: Falco initialized with configuration file /etc/falco/falco.yaml
    Jan 22 21:40:38 kjn-03 falco: Loading rules from file /etc/falco/falco_rules.yaml:
    Jan 22 21:40:38 kjn-03 falco: Loading rules from file /etc/falco/falco_rules.local.yaml:
    Jan 22 21:40:38 kjn-03 falco: Loading rules from file /etc/falco/k8s_audit_rules.yaml:
    Jan 22 21:40:39 kjn-03 kernel: [4780522.577041] falco: loading out-of-tree module taints kernel.
    Jan 22 21:40:39 kjn-03 kernel: [4780522.577850] falco: module verification failed: signature and/or required key missing - tainting kernel
    Jan 22 21:40:39 kjn-03 kernel: [4780522.579090] falco: driver loading, falco 3aa7a83bf7b9e6229a3824e3fd1f4452d1e95cb4
    Jan 22 21:40:39 kjn-03 kernel: [4780522.582092] falco: adding new consumer 00000000a2da6ebf
    Jan 22 21:40:39 kjn-03 kernel: [4780522.582103] falco: initializing ring buffer for CPU 0
    Jan 22 21:40:39 kjn-03 kernel: [4780522.589507] falco: CPU buffer initialized, size=8388608
    Jan 22 21:40:39 kjn-03 kernel: [4780522.589508] falco: initializing ring buffer for CPU 1
    Jan 22 21:40:39 kjn-03 kernel: [4780522.600843] falco: CPU buffer initialized, size=8388608
    Jan 22 21:40:39 kjn-03 kernel: [4780522.600846] falco: starting capture
    Jan 22 21:40:40 kjn-03 falco: Starting internal webserver, listening on port 8765
    Jan 22 21:40:40 kjn-03 falco: 21:40:40.341135114: Notice Privileged container started (user=root user_loginuid=0 command=container:34fbef3a0ba1 k8s_osd_rook-ceph-osd-0-86b55776d9-kpsv7_rook-ceph_59288888-611a-482d-9586-182e6303cf82_6 (id=34fbef3a0ba1) image=quay.io/ceph/ceph:v16.2.6)
    Jan 22 21:40:40 kjn-03 falco: 21:40:40.808602523: Notice Privileged container started (user=root user_loginuid=0 command=container:7fb4d068f91b k8s_POD_kube-proxy-gc5b5_kube-system_77fd080b-f651-48c7-a240-c67f9956a21a_0 (id=7fb4d068f91b) image=k8s.gcr.io/pause:3.5)
    Jan 22 21:40:41 kjn-03 falco: 21:40:41.029070812: Notice Privileged container started (user=root user_loginuid=0 command=container:68e84c76d6a6 k8s_POD_weave-net-x9c29_kube-system_d3edc0d3-4378-41d1-87b1-ed7cecbf07e1_0 (id=68e84c76d6a6) image=k8s.gcr.io/pause:3.5)
    Jan 22 21:40:41 kjn-03 falco: 21:40:41.181485041: Notice Privileged container started (user=root user_loginuid=0 command=container:a712ac659061 k8s_weave-npc_weave-net-x9c29_kube-system_d3edc0d3-4378-41d1-87b1-ed7cecbf07e1_0 (id=a712ac659061) image=ghcr.io/weaveworks/launcher/weave-npc:2.8.1)
    Jan 22 21:40:41 kjn-03 falco: 21:40:41.303702022: Notice Privileged container started (user=root user_loginuid=0 command=container:e3d9be72e687 k8s_weave_weave-net-x9c29_kube-system_d3edc0d3-4378-41d1-87b1-ed7cecbf07e1_1 (id=e3d9be72e687) image=ghcr.io/weaveworks/launcher/weave-kube:2.8.1)
    Jan 22 21:40:41 kjn-03 falco: 21:40:41.333804974: Notice Privileged container started (user=<NA> user_loginuid=0 command=container:c37e07aeeae6 k8s_POD_csi-rbdplugin-xmwl5_rook-ceph_76557d04-18ae-4c8b-9c2b-bb638c7f8caf_0 (id=c37e07aeeae6) image=k8s.gcr.io/pause:3.5)
    Jan 22 21:40:41 kjn-03 falco: 21:40:41.364637591: Notice Privileged container started (user=<NA> user_loginuid=0 command=container:1a5d9caa92b9 k8s_POD_csi-cephfsplugin-zd5nr_rook-ceph_45a961a9-3014-493f-9777-c5cfda5b3ce6_0 (id=1a5d9caa92b9) image=k8s.gcr.io/pause:3.5)
    Jan 22 21:40:41 kjn-03 falco: 21:40:41.461413593: Notice Privileged container started (user=<NA> user_loginuid=0 command=container:1bd955004427 k8s_driver-registrar_csi-rbdplugin-xmwl5_rook-ceph_76557d04-18ae-4c8b-9c2b-bb638c7f8caf_0 (id=1bd955004427) image=k8s.gcr.io/sig-storage/csi-node-driver-registrar:v2.3.0)
    Jan 22 21:40:41 kjn-03 falco: 21:40:41.492736367: Notice Privileged container started (user=root user_loginuid=0 command=container:45a1fa50178f k8s_driver-registrar_csi-cephfsplugin-zd5nr_rook-ceph_45a961a9-3014-493f-9777-c5cfda5b3ce6_0 (id=45a1fa50178f) image=k8s.gcr.io/sig-storage/csi-node-driver-registrar:v2.3.0)
    Jan 22 21:40:41 kjn-03 falco: 21:40:41.679434269: Notice Privileged container started (user=root user_loginuid=0 command=container:b1af48aebaf6 k8s_csi-rbdplugin_csi-rbdplugin-xmwl5_rook-ceph_76557d04-18ae-4c8b-9c2b-bb638c7f8caf_0 (id=b1af48aebaf6) image=quay.io/cephcsi/cephcsi:v3.4.0)
    Jan 22 21:40:41 kjn-03 falco: 21:40:41.709694589: Notice Privileged container started (user=root user_loginuid=0 command=container:2b06617e308d k8s_csi-cephfsplugin_csi-cephfsplugin-zd5nr_rook-ceph_45a961a9-3014-493f-9777-c5cfda5b3ce6_0 (id=2b06617e308d) image=quay.io/cephcsi/cephcsi:v3.4.0)
    Jan 22 21:40:41 kjn-03 falco: 21:40:41.740478760: Notice Privileged container started (user=root user_loginuid=0 command=container:e575f72f430f k8s_liveness-prometheus_csi-rbdplugin-xmwl5_rook-ceph_76557d04-18ae-4c8b-9c2b-bb638c7f8caf_0 (id=e575f72f430f) image=quay.io/cephcsi/cephcsi:v3.4.0)
    Jan 22 21:40:41 kjn-03 falco: 21:40:41.772196480: Notice Privileged container started (user=root user_loginuid=0 command=container:9999e8e7edbc k8s_liveness-prometheus_csi-cephfsplugin-zd5nr_rook-ceph_45a961a9-3014-493f-9777-c5cfda5b3ce6_0 (id=9999e8e7edbc) image=quay.io/cephcsi/cephcsi:v3.4.0)
    Jan 22 21:40:41 kjn-03 falco: 21:40:41.803031991: Notice Privileged container started (user=root user_loginuid=0 command=container:961a5a600b4a k8s_POD_es-cluster-2_elastic_f3f71f11-e29e-40c6-a81d-1285838b501a_0 (id=961a5a600b4a) image=k8s.gcr.io/pause:3.5)
    Jan 22 21:40:42 kjn-03 falco: 21:40:41.991878118: Notice Privileged container started (user=root user_loginuid=0 command=container:a3675064fdbd k8s_POD_rook-ceph-osd-0-86b55776d9-kpsv7_rook-ceph_59288888-611a-482d-9586-182e6303cf82_0 (id=a3675064fdbd) image=k8s.gcr.io/pause:3.5)
    Jan 22 21:47:24 kjn-03 falco: 21:47:24.121023428: Error Package management process launched in container (user=root user_loginuid=-1 command=apt update container_id=760b99ee4744 container_name=k8s_py_py_default_d9a2c454-70c8-455c-b176-893d437baeb2_0 image=python:3.7)
    Jan 22 21:47:47 kjn-03 falco: 21:47:47.818922828: Error Package management process launched in container (user=root user_loginuid=-1 command=apt install -y vim container_id=760b99ee4744 container_name=k8s_py_py_default_d9a2c454-70c8-455c-b176-893d437baeb2_0 image=python:3.7)
    ~~~
* 룰 적용
  * `# vim /var/falco/falco.yaml`
    ~~~yaml
    rules_file:
    - /etc/falco/falco_rules.yaml
    - /etc/falco/falco_rules.local.yaml # 사용자 정의 룰
    - /etc/falco/k8s_audit_rules.yaml
    - /etc/falco/rules.d
    ~~~
