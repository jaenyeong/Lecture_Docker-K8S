# K8S

## VM 인스턴스 접속 순서
* `openVPN` 실행
  * `Tunnelblink` 실행
* 라우팅 경로 추가
  * `$ ./kakao_vpn_route.sh` 명령 실행
* `ssh` 접속
  * `$ ssh -i [pem file] [kakao instance address]`

## Chapter01
 
OT & Setting
* `kakao i cloud`
  * [Kakao i 접속](https://console.kakaoi.io/)
  * 조직 URL : `likelion`
  * ID : `jaenyeong.dev@gmail.com`
  * PW : `8 + @`
* `Virtual Machine IP`
  * `kjn-master-01` - `172.30.5.108`
  * `kjn-master-02` - `172.30.4.36`
  * `kjn-master-03` - `172.30.7.28`
  * `kjn-worker01` - `172.30.6.245`
  * `kjn-worker02` - `172.30.7.0`

## Chapter02
 
IT Infra & K8S 배경지식
* 기본용어
  * CPU
  * 스레드
  * 코어
  * 캐시 메모리
  * 램
  * SSD
  * 그래픽카드
  * 기타
* 쿠버네티스
  * 쿠버네티스는 컨테이너화된 애플리케이션을 배포, 관리하기 위한 오픈소스 오케스트레이터
    * 다시 말해서 컨테이너 오케스트레이션 기술 구현체
  * 키잡이(`helmsman`)나 파일럿을 뜻하는 그리스어(퀴베르네테스 `kubernētēs`)에서 유래
  * 구글이 2014년에 쿠버네티스 프로젝트를 오픈소스화 (기존 이름 : `Borg`)
    * 쿠버네티스는 프로덕션 워크로드를 대규모로 운영하는 15년 이상의 구글 경험과 커뮤니티의 아이디어와 적용 사례가 결합되어 있음
  * 쿠버네티스에서 관리할 수 있는 가장 작은 단위는 파드(`Pod`)
    * `Pod`은 하나의 앱을 나타내고, 스토리지 리소스 및 IP 주소를 공유하는 1개 이상의 컨테이너로 구성
* `K8S`
  * `K8S` 표기는 "K"와 "s"와 그 사이에 있는 8글자를 나타내는 약식 표기
* [쿠버네티스 공식 사이트](https://kubernetes.io/ko/)
* [쿠버네티스 페이스북 커뮤니티](https://www.facebook.com/groups/k8skr/)

인프라 특장점을 고려하여 서비스 용도에 맞게 구성
* 장애 대응
* 성능 유지 용이
* 전체 관점으로 운용
* 고효율 / 고집적
* 빠른 시작 / 코드화 용이
* 앱에만 집중

클라우드에서 제공하는 리소스
* `On premise`
* `IaaS`
* `PaaS`
* `SaaS`

쿠버네티스에서 제공하는 리소스
* `Servers`
  * Pod(Container)
  * Replica Set
  * Deployment
* `Storage`
  * 로컬 스토리지
  * Cinder
  * Ceph
  * NFS
  * iSCSI
  * PV, PVC
* `Networking`
  * 서버 내 라우팅
  * 서비스(노드 포트)
  * 인그레스
  * 로드밸런서

쿠버네티스가 필요한 이유 (사용 한다면 아래와 같은 장점이 있음)
* 사실상 표준 (de facto)
* 서비스 디스커버리, 로드 밸런싱
  * DNS 이름을 사용하거나, 자체 IP 주소를 사용하여 컨테이너 노출 가능
  * 컨테이너에 대한 트래픽이 많은 경우 트래픽을 로드밸런싱하고 안정적인 배포 가능
* 스토리지 오케스트레이션
  * 로컬 저장소, 공용 클라우드 공급자 등과 같은 저장소를 자동 탑재
* 자동화된 롤아웃, 롤백
  * 배포된 컨테이너의 원하는 상태를 서술 가능
  * 배포용 새 컨테이너 생성, 제거, 모든 리소스를 새 컨테이너에 적용 가능
* 자동화된 배치 (bin packing)
  * 컨테이너화된 작업을 실행하는데 사용 가능한 클러스터 노드 제공
  * 컨테이너를 노드에 맞춰 리소스를 가장 잘 사용할 수 있도록 선택
* 자동화된 복구
  * 실패한 컨테이너를 다시 시작/교체 및 `사용자 정의 상태 검사`에 응답하지 않는 컨테이너를 제거
* 시크릿과 구성 관리
  * 암호, OAuth 토큰 및 SSH 키와 같은 중요한 정보를 저장하고 관리 가능

## Chapter03

K8S 아키텍처
* 설계 사상
  * 선언적 구성
    * 사용자가 원하는 형태를 명령(선언)식으로 구성 
      * 레플리카를 항상 5개씩 실행하고 싶을 때 > `레플리카를 5개 만들어`
    * 제어 루프 : `현재 상태를 관찰, 사용자가 원하는 상태로 유지`
  * 컨트롤러 구성
    * 각 기능별로 독립적으로 분산되게끔 설계 `유연하고 안정적이지만 복잡함`
  * 동적 그룹화 : `우리 팀원은 오렌지색 옷을 입은 사람들`
    * 반대인 정적 그룹화 : `우리 팀원은 철수와 영희`
    * 레이블(쿼리 가능), 애너테이션(메타데이터 용도)으로 구성
  * API 기반 상호작용
    * K8S 요소들이 서로 직접적으로 접근할 수 없음
    * 구성 요소를 대체 구현하기 용이

클러스터
* `클러스터`
  * `노드`라고 하는 `워커 머신` 집합
* `노드`
  * 컨테이너화된 앱을 실행하는 서버 (가상, 물리 둘다 가능)
* `워커 노드`
  * 앱의 구성요소인 `파드(컨테이너)`를 호스팅하는 노드
* `컨트롤 플레인`
  * `워커 노드`와 클러스터 내 `파드`를 관리

컨트롤 플레인(마스터 노드)
* `API 서버`
  * K8S API를 호출, 컨트롤 플레인의 프론트엔드, 수평 확장 가능
* `etcd`
  * 모든 클러스터 데이터를 담는 저장소로 사용되는 일관성/고가용성 키-값 저장소
* `스케줄러`
  * 새로 생성된 (노드가 배정되지 않은) 파드를 감지, 실행할 노드를 선택
* `컨트롤러 매니저`
  * `ReplicatSets`, `Deployment`, `Service`와 관련한 제어 루프 수행
  * 노드가 다운되면 통지/대응, 적정 수의 파드 유지, `Service`와 파드 연결 등
* `클라우드 컨트롤러 매니저`
  * `AWS`, `Azure`, `GCP` 등 클라우드에 연결하는 경우 활용

워커 노드
* `Kubelet` (프로세스라고 볼 수 있음)
  * 컨테이너가 동작하도록 관리, K8S 클러스터와 워커 노드의 CPU/Mem/Disk 간 연결
* `Kube-proxy`
  * K8S `Service(로드밸런서 리소스)`에 맞게 커널의 `netfilter(iptables)` 등을 관리
* `컨테이너 런타임`
  * 컨테이너 실행을 담당하는 소프트웨어(`Docker`, `containerd`, `CRI-O` 등)

K8S 설치 (구성도)
* 배포 도구 활용
  * `Kubeadm`, `Kops`, `Kubespray`
  * [차이점은 공식 문서 참조](https://github.com/kubernetes-sigs/kubespray/blob/master/docs/comparisons.md)
* `turnkey solution` 활용
  * `Redhat`, `Openshift`, `AWS EKS`, `MS AKS`
* [고가용성 토폴로지](https://kubernetes.io/ko/docs/setup/production-environment/tools/kubeadm/ha-topology/)
* 중첩된 etcd 토폴로지 vs 외부 etcd 토폴로지 : etcd 배포 위치 차이
  * 외부에 위치시키는 경우는 비용, 관리 측면에서 부담이 증가할 수 있음
  * 상황에 따라 etcd를 별도 분리하는 것 보다 로드밸런서를 하나 더 추가하는 것이 나을 수도 있음
    * active, standby
* `kubeadm HA topology` - `stacked etcd`
* `Kubeadm` 으로 `High Availability` 클러스터 설치
  * [링크](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/high-availability/)
* 3개의 마스터에 연결하기 위한 다양한 로드 밸런서 구성 방식이 있으나 해당 교육과정에서는 `ha-proxy` 로드밸런서 사용
  * 물리적인 L4 스위치
  * ha-proxy
  * nginx
  * CSP에서 제공하는 로드밸런서
  * 기타
* `Keepalived`를 사용하는 경우 (해당 교육 과정에서는 사용하지 않음)
  * `Keepalived` 끼리 대장을 정하고, 스위치에 대장(`vIP`)이라고 표시
  * `워커 노드`가 `vIP` 목적지로 패킷을 보내면 스위치는 대장에게 보냄
* `Haproxy`
  * `Haproxy` 설정을 동일하게 맞추면 어떤 노드가 대장이 되던지 해당 `haproxy`가 균형적으로 `controller node` 3개로 분배
    * `controller`가 죽는 경우는 보내지 않음

K8S 주요 용어 설명
* `Haproxy`
  * TCP, HTTP 기반 앱을 위한 `HA` 로드 밸런서 및 프록시 서버를 제공하는 무료 오픈 소스 소프트웨어
* `kubeadm`
  * 클러스터를 부트스트랩하는 명령
* `kubelet`
  * 클러스터의 모든 머신에서 실행되는 파드와 컨테이너 시작과 같은 작업을 수행하는 컴포넌트
* `kubectl`
  * 클러스터와 통신하기 위한 커맨드 라인 유틸리티
* `CRI (Container Runtime Interface)`
  * 도커 이외에도 다양한 컨테이너 런타임을 지원하기 위한 인터페이스
* `CNI (Container Network Interface)`
  * 단순 파드 간 연결을 담당하는 플러그인
* `Calico`
  * 교육 과정에서 사용할 `CNI` 플러그인 중 하나
  * 삼색 고양이라는 뜻

K8S 리소스
* 파드 (`POD`) 정의
  * 고래 떼를 일컬음 (도커 고래에서 유래)
  * 배포의 최소단위이자 스케일링의 단위, 특정 네임스페이스에 실행됨
  * 하나 이상의 컨테이너로 구성되어 있으며 앱에 친숙함 (환경 변수, 정상 여부 상태검사 정의 등이 용이함)
  * 1개 파드에 2개 이상의 각각 다른 이미지를 베이스로 한 컨테이너 실행 가능
  * 노드 `IP`와 별개로 파드 만의 고유한 `IP`를 할당받으며 파드 내의 컨테이너들은 `IP`를 공유함
  * 파드 내의 컨테이너들은 동일한 `볼륨`과 연결이 가능
* 기본 명령
  * `$ kubectl[command][TYPE][NAME][flags]`
* 파드 생성 정보가 담긴 `yaml` 파일 생성 예시
  * `$ kubectl run test --image=nginx --dry-run=client -o yaml > 1.yaml`
  * 일반적으로 `--dry-run` 명령은 실행 가능 여부 확인 명령
* 위 `yaml` 파일을 토대로 파드 적용(실행)
  * `$ kubectl apply -f 1.yaml`
* 파드 목록 확인
  * `$ kubectl get pod`
    ~~~
    NAME   READY   STATUS    RESTARTS   AGE
    test   1/1     Running   0          91m
    ~~~
  * `$ kubectl get pod -o wide`
    ~~~
    NAME   READY   STATUS    RESTARTS   AGE   IP               NODE                                    NOMINATED NODE   READINESS GATES
    test   1/1     Running   0          90m   192.168.21.129   kjn-worker-02.kr-central-1.c.internal   <none>           <none>
    ~~~
  * `$ kubectl describe pod test`
    ~~~
    Name:         test
    Namespace:    default
    Priority:     0
    Node:         kjn-worker-02.kr-central-1.c.internal/172.30.7.0
    Start Time:   Sun, 17 Oct 2021 12:53:27 +0000
    Labels:       run=test
    Annotations:  cni.projectcalico.org/containerID: 9f3b7afe03e4801c9b46c316f18dd645e886e106dfef7f6724f81c7df29ca79d
                  cni.projectcalico.org/podIP: 192.168.21.129/32
                  cni.projectcalico.org/podIPs: 192.168.21.129/32
    Status:       Running
    IP:           192.168.21.129
    IPs:
      IP:  192.168.21.129
    Containers:
      test:
        Container ID:   docker://83a720fe94894dc5d6c18579ff6ba6ef16e51115d62335390b41cb0216bb50dd
        Image:          nginx
        Image ID:       docker-pullable://nginx@sha256:644a70516a26004c97d0d85c7fe1d0c3a67ea8ab7ddf4aff193d9f301670cf36
        Port:           <none>
        Host Port:      <none>
        State:          Running
          Started:      Sun, 17 Oct 2021 12:53:48 +0000
        Ready:          True
        Restart Count:  0
        Environment:    <none>
        Mounts:
          /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-6w7rg (ro)
    Conditions:
      Type              Status
      Initialized       True
      Ready             True
      ContainersReady   True
      PodScheduled      True
    Volumes:
      kube-api-access-6w7rg:
        Type:                    Projected (a volume that contains injected data from multiple sources)
        TokenExpirationSeconds:  3607
        ConfigMapName:           kube-root-ca.crt
        ConfigMapOptional:       <nil>
        DownwardAPI:             true
    QoS Class:                   BestEffort
    Node-Selectors:              <none>
    Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                                node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
    Events:                      <none>
    ~~~
* 파드 로그 확인
  * `$ kubectl logs test`
    ~~~
    /docker-entrypoint.sh: /docker-entrypoint.d/ is not empty, will attempt to perform configuration
    /docker-entrypoint.sh: Looking for shell scripts in /docker-entrypoint.d/
    /docker-entrypoint.sh: Launching /docker-entrypoint.d/10-listen-on-ipv6-by-default.sh
    10-listen-on-ipv6-by-default.sh: info: Getting the checksum of /etc/nginx/conf.d/default.conf
    10-listen-on-ipv6-by-default.sh: info: Enabled listen on IPv6 in /etc/nginx/conf.d/default.conf
    /docker-entrypoint.sh: Launching /docker-entrypoint.d/20-envsubst-on-templates.sh
    /docker-entrypoint.sh: Launching /docker-entrypoint.d/30-tune-worker-processes.sh
    /docker-entrypoint.sh: Configuration complete; ready for start up
    2021/10/17 12:53:48 [notice] 1#1: using the "epoll" event method
    2021/10/17 12:53:48 [notice] 1#1: nginx/1.21.3
    2021/10/17 12:53:48 [notice] 1#1: built by gcc 8.3.0 (Debian 8.3.0-6)
    2021/10/17 12:53:48 [notice] 1#1: OS: Linux 3.10.0-1160.25.1.el7.x86_64
    2021/10/17 12:53:48 [notice] 1#1: getrlimit(RLIMIT_NOFILE): 1048576:1048576
    2021/10/17 12:53:48 [notice] 1#1: start worker processes
    2021/10/17 12:53:48 [notice] 1#1: start worker process 31
    2021/10/17 12:53:48 [notice] 1#1: start worker process 32
    ~~~
* 파드 안에 접속 (일반 셸)
  * `$ kubectl exec -it test -- /bin/sh`
* 워크로드
  * K8S에서 실행되는 앱
  * 단일 또는 여러 컴포넌트 상관없이 일련의 파드 집합 내에서 실행
* 워크로드 오브젝트
  * 파드는 `IP`를 1개만 소유 (`CNI` 플러그인이 할당)
    * [참고] `Multus (CNI)`를 활용하면 파드에 네트워크를 2개도 연결 가능
      * 상황에 따라 여러개의 네트워크가 필요할 수 있음 (예시 : 외부, 내부망을 사용하는 경우)
  * 컨테이너 네트워크 인터페이스 `CNI (Container Network Interface)`
    * 네크워크로 연결될 파드는 동일 노드 뿐 아니라 다른 노드에 위치할 수 있음
    * `CNI` 역할은 단순히 파드 간 연결을 용이하게 만드는 것
  * 컨테이너 런타임 (`Container Runtime`)
    * `CNI` 플러그인 실행파일을 호출, 컨테이너의 네트워킹 네임스페이스에 인터페이스를 추가/제거
      * `CNI` 플러그인 실행 파일로는 `Calico`가 대표적
* 컨트롤러 오브젝트
  * `ReplicaSet`
    * 노드 고장, 파드 삭제 등과 같은 상황에서 파드를 복제하여 개수를 유지하는 역할
  * `Deployment`
    * 구 버전에서 신 버전으로 복제, 위 `ReplicaSet` 관리
    * 일반적으로 파드를 하나씩 관리하기보다는 `Deployment`를 서비스 단위로서 관리
    * `Deployment` 생성 시 `Replica` 숫자 지정, 파드를 지워도 `ReplicaSet`에 의해 다시 재생
  * `DaemonSet`
    * 모든 노드에 동일한 파드를 실행시키고 싶은 경우 활용
    * 리소스 모니터링, 로그 수집기 등에 유용
    * 클러스터에 노드가 추가/삭제 되면 자동으로 파드도 생성/삭제됨
* 앱 업데이트 방법
  * 롤링
    * 장점
      * `Down Time` 없음
      * 추가 인프라 투자비 별로 없음
    * 단점
      * 신/구 버전 공존에 따른 개발 및 검증 사항 고려 필요
      * 신/구 버전이 같이 활용하는 인프라에서 문제 발생 가능
  * 블루 그린 (레드/블랙 업데이트나 AB 배포라고도 불림)
    * 장점
      * Down Time 없음
      * 복구가 빠름
    * 단점
      * 인프라 투자가 2배로 필요
      * 로드밸런서 추가 필요
  * 카나리
    * 장점
      * Downtime 없음
      * 아주 적은 사용자만 새 버전에 유입시키므로 영향 최소화
      * 추가 인프라 투자 별로 없음
    * 단점
      * 신/구 버전 공존에 따른 개발 및 검증 사항 고려 필요
      * 업데이트 시간이 롤링 업데이트보다 더 걸림
      * 로드 밸런서 추가 필요
* 로드밸런서 오브젝트
  * `Service`
    * 파드의 IP 변동을 대체하기 위한 고정 IP를 갖는 단위
      * 요청된 트래픽을 `Service`가 먼저 수신하여 파드로 전달
    * 파드는 임시(`ephemeral`) 오브젝트이자 TCP/UDP 로드밸런싱을 담당하는 추상적 개념
      * 파드는 생성시마다 `IP`가 변경됨
    * 생성
      * `$ kubectl create service`
    * 생성 + 연결
      * `$ kubectl expose service`
    * `Service` 종류
      * `Cluster IP` (교육 과정에서 사용)
        * 클러스터 내에서만 통신 가능
        * 외부 통신이 필요한 경우 프록시가 필요함 (프록시는 직접 구축해야 함)
      * `Node port` (교육 과정에서 사용)
        * 노드 상관없이 설정 포트로 요청이 오면 알맞은 파드로 로드밸런싱
        * 해당 파드의 존재 상관없이 모든 노드 전체에 해당함
      * `Load Balancer`
        * 각각 노드에 트래픽 분산처리 가능
        * 단일 `IP`로 여러 노드에 로드밸런싱 가능
          * 현재 카카오 클라우드 내에서는 사설 `IP`만 가능
      * `ExternalName`
        * 외부 서비스를 K8S 내부에서 호출할 때 활용
  * `Ingress`
    * HTTP(레벨) 로드밸런서 (HTTP 트래픽만 로드밸런싱)
    * `Service`로 라우팅 가능
* 스토리지 오브젝트
  * 컨테이너 내 디스크에 있는 파일은 임시적
  * 퍼시스턴트 볼륨은 지속적으로 존재
  * `PV (Persistent Volume)`
    * 관리자가 프로비저닝하거나 스토리지 클래스를 사용하여 동적으로 프로비저닝한 클러스터의 스토리지
  * `PVC (Persistent Volume Claim)`
    * 사용자의 스토리지에 대한 요청 (파드와 비슷한 명세) 또는 해당 리소스에 대한 요청
    * 리소스에 대한 클레임 검사 역할
  * 파드
    * 노드 리소스 사용
    * 파드 명세서 내 특정 수준의 리소스(CPU 및 메모리)를 요청
  * `PVC`
    * `PV` 리소스 사용
    * 클레임 명세서 내 특정 크기 및 접근 모드를 요청
      * 예시 : ReadWriteOnce, ReadOnlyMany, ReadWriteMany

## Chapter04

APIs and Access
* Label
  * 오브젝트를 식별하는데 도움이 되는 문자열 키/쌍 (쿼리 가능)
* Annotation
  * 단순 주석
  * 모든 API 오브젝트는 주석 포함 가능 (쿼리 불가능)
  * K8S의 실험적인 기능
  * 제작사별 특이한 기능, 메타데이터로 가능하므로 그래픽 아이콘도 가능
* 확인
  * `$ kubectl describe pod -n kube-system calico-kube-con`

API 접근
* API 서버
  * 중앙 접근 포인트 (Stateless)
    * `etcd` 활용
    * 복제 가능
  * 주요 기능
    * API 관리
      * 서버에서 API를 노출하고 관리하는 프로세스
    * 요청 처리
      * 클라이언트의 개별 API 요청을 처리하는 기능
      * 대부분 `HTTP` 형태로 요청, 컨텐츠는 `JSON` 기반이 많음
      * [인가](https://kubernetes.io/ko/docs/reference/access-authn-authz/authorization/)
    * 내부 제어 루프
      * API 작동에 필요한 백그라운드 작업을 담당
        * 대부분 컨트롤러 매니저에서 수행

V1 Group API, API 리소스
* API 그룹
  * K8S API를 더 쉽게 확장하게 설계
  * `REST` 경로와 오브젝트의 `apiVersion` 필드에 명시
* 두 종류의 API 그룹
  * V1 Group (Core/Legacy)
    * `/api/v1`
    * `apiVersion: v1`
  * 이름있는 그룹 (후속)
    * `/apis/$GROUP_NAME/$VERSION`
    * `apiVersion: $GROUP_NAME/$VERSION`
* [API 리소스 탐방](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.22/)
* API 버전
  * alpha
    * 불안정, 상용 환경에 부적합
  * beta
    * 안정적이나 최종 개선 예정
  * GA(General Availability)
    * 안정적

인증서
* 다양한 인증 방법 중 대부분 `PKI(공개 키 인프라)` 기반으로 상호 인증하는 방법을 사용
* `PKI(Public Key Infrastructure)`
  * 대칭키
    * 암호화와 복호화에 같은 암호키를 사용하는 알고리즘
  * 비대칭키
    * 공개키, 비밀키 존재
  * 공개된 키를 개인이나 집단을 대표하는 믿을 수 있는 주체와 엮는 것이며 인증기관(CA)의 등록, 인증 발행을 통해 성립
    * 인증기관 - `Certificate Authority`
* K8S 컨트롤 플레인에서 자체 CA 역할을 수행

RBAC(`Role Based Access Control`)
* 인증 모듈은 4개가 존재하는데 이 중에 `RBAC`가 가장 대표적이며 효과적인 방식
  * [RBAC Authorization](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)

Role, Cluster Role
* 작업 수행에 대한 권한
  * `어떤 resource에 어떤 verb 권한을?`
* 차이
  * `kind`에 들어가는 종류명
  * `namespace` 존재 여부 (범위만 다름)
* `Cluster Role` 사용 예시
  * 클러스터 관리자
  * K8S 컨트롤러
* `$ kubectl create role --help`
  * 실습 파일에 실행한 명령 목록 작성

RoleBinding, ClusterRoleBinding
* Role을 사용자/그룹/Service Account에 연결
  * `어떤 resource에 어떤 verb 권한을 + "누구에게 줄 것인가?"`
* 차이
  * `kind`에 들어가는 종류명
  * `namespace` 존재 여부 (범위만 다름)
* `Cluster Role` 사용 예시
  * 클러스터 관리자
  * K8S 컨트롤러
* `$ kubectl create rolebinding --help`
  * 실습 파일에 실행한 명령 목록 작성

Service Account
* 파드 내부에서 실행하는 프로세스가 K8S API를 호출할 때 활용
  * `$ kubectl create serviceaccount test`

## Chapter05

Scheduler
* 컨테이너를 적절한 노드에 스케줄링(배치)하는 역할(전용 바이너리)
* `nodeName`이 없는 파드가 있는지 API 서버를 지속적으로 감시
* 해당 파드를 적합한 노드로 선택, 파드의 `nodeName` 업데이트
* 해당 노드의 쿠블렛이 계속 API 서버를 모니터링, 자신의 것이면 실행

Scheduling 프로세스
* 스케줄러가 파드를 배치하는 주요 기준
  * 사전 조건
    * 파드가 특정 노드에 적합한지 확인
    * 예시) 파드에서 요청한 메모리 양을 노드가 감당할 수 있는지, 유저가 `node selector`로 지정한 경우
  * 우선 순위
    * 파드가 노드에서 실행할 수 있다고 가정, 상대적 가치를 판단
    * 예시) 이미지가 이미 존재하는 노드에 가중치를 부여 - 빠른 시작 가능, 동일한 서비스 내 파드라면 `spreading`
* 스케줄링은 한 순간에만 최적, 이후 충돌 등 다양한 이유로 실행중인 파드를 이동할 수 있음
  * 이 경우 해당 파드를 삭제, 재생성

Policy 정책
* 쿠버네티스 스케줄링과 다르게 운용자가 직접 스케줄링하고 싶다면 주로 아래 3가지 방안 활용
* `Node Selector`
  * 노드에도 파드에도 레이블을 부여하여 동일한 조건에 맞게 스케줄 되도록 설정
  * [문서](https://kubernetes.io/ko/docs/concepts/scheduling-eviction/assign-pod-node/)
  * 노드에 레이블 붙이기
    * 예시) `$ kubectl label nodes kubernetes-foo-node-1.c.a-robinson.internal disktype=ssd`
  * 파드에 node selector 추가하기
    ~~~
    spec:
      container:
      nodeSelector:
        disktype: ssd
    ~~~
* `Node Affinity`
  * Node Selector는 선택에 대한 요구사항을 이야기하는 사전 조건
  * 복잡한 선택에는 Affinity가 유연
    * 예시) 레이블 foo이면 A 또는 B 노드를 선택
      ~~~yaml
      kind:	Pod
      ...
      spec:
        affinity:
          nodeAffinity:
            requiredDuringSchedulingIgnoredDuringExecution:
              nodeSelectorTerms:
              - matchExpressions:
                # foo == A or B
                - key: foo
                  operator: In
                  values:
                  - A
                  - B
      ~~~
    * 예시) A, B 둘다 가능하지만 A로 라벨링 된 노드를 더 선호
      ~~~yaml
      kind:	Pod
      ...
      spec:
        affinity:
      nodeAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
          nodeSelectorTerms:
          - matchExpressions:
            # foo == A or B
            - key: foo
              operator: In
              values:
              - A
              - B
        preferredDuringSchedulingIgnoredDuringExecution:
          preference:
          - weight: 1
            matchExpressions:
            # foo == A
            - key: foo
              operator: In
              values:
              - A
      ~~~
* `Taint/Toleration`
  * Taint 
    * 스케쥴러가 pod를 배치할 때 Taint (오염)되어 있는 node들은 배치하지 않도록 함
  * Toleration
    * Taint가 묻어 있어도 배치할 수 있도록 함
  * Kubeadm은 설치 시, 자동으로 Controler Plane에 node-role.Kubernetes.io/master 테인트로 제어하여 일반 파드와 분리
  * `$ kubectl describe node kjn-master-01`

멀티 컨테이너 Pod
* `Deployment`를 파일로 수정
  * `Container`가 2번 들어가지 않으니 실수 주의
* 두 개의 컨테이너가 한 개의 `emptydir` 볼륨을 바라보게 하기
  * [볼륨 문서](https://kubernetes.io/docs/concepts/storage/volumes/)

Namespace
* 동일한 물리 클러스터를 기반으로 하는 여러 가상 클러스터(네임 스페이스)를 지원

Label, Selector
* 레이블은 파드와 같은 오브젝트에 첨부된 키와 값의 쌍
  * 식별을 위해 사용되지만 코어에 특별한 의미는 없음

Staticpod
* `kubectl`, `control plane`에서 관리하지 않는 파드
* `pod spec`을 디스크에 직접 쓸 수 있음
* `kubelet`은 시작과 함께 바로 지정된 컨테이너 시작
  * `kubelet`은 지속적으로 변경사항이 있는지 `Manifest` 파일을 지속적으로 모니터링
* 컨피그 파일 확인
  * `$ sudo cat /var/lib/kubelet/config.yaml`
  * `volumeMounts` > `mountPath` > `/var/lib/etcd` 경로에 `etcd-data` 볼륨 저장 됨
  * 특정 파일을 백업할 때 `etcd-data` 볼륨에 저장
* K8S 클러스터 복구 방법
  * 복구 하려면 사전에 백업받은 파일을 특정 경로에 위치 (`/var/lib/etcd2` 등)
  * 해당 `kubelet config.yaml` 파일 수정해야 K8S 클러스터를 복구할 수 있음
    * 스태틱 파드에 볼륨 마운트 설정을 위 백업 경로로 수정

클러스터 노드 작업
* `Cordon`
  * 노드에 더이상 어떤 파드도 스케줄링 되지 않도록 하는 기능
  * 예시) 오늘 야간에 정기점검이 잡혀있는 노드
* `Drain`
  * 노드에 있는 파드를 지금 바로 다른 노드로 이동시키는 기능
  * `drain` 명령 입력 시 `cordon` 수행 후 `drain`을 하게 됨
    * `cordon`이 조금 더 안정적
  * 예시) 해당 노드에 고장이 발생, 파드를 다른 곳에서 새로 시작하는 경우
* `Taint`
  * 파드가 부적절한 노드에 실행하지 않도록 설정하는 기능
  * 예시) `Toleration`과 결합하여 특정 파드만 실행시키고 싶은 경우 (`Control Plane`으로 사용하는 `Master Node`)

클러스터 업그레이드
* `kubelet`과 `kubeadm` 자체는 `kubeadm`으로 관리되지 않기에, OS 패키지 관리자인 `apt/yum`으로 설치 필요
* 순서
  * 컨트롤 플레인 1번 마스터 노드 먼저 업그레이드
  * 2/3번 마스터 업그레이드
  * 워커 노드 업그레이드 수행
* 참고
  * 업그레이드 시, `kubectl cordon/drain` 활용하여 사용자 워크로드를 조정해야 함
  * 업그레이드 완료 후, `uncordon`하여 다시 파드가 스케줄링 되도록 설정

## Chapter06

Storage
* 데이터 저장소
* 스토리지 종류
  * DAS
    * Direct Attached Storage - 직접
  * NAS
    * Network Attached Storage - LAN
  * SAN
    * Storage Area Network - Fiber chanel switch
  * 가격
    * DAS -> NAS -> SAN
  * 성능
    * NAS -> DAS = SAN
  * 확장성
    * DAS -> SAN -> NAS
* RAID
  * 0
    * 구매한 그대로 사용
  * 1
    * 구매한 절반만 사용
  * 5
    * 패리티비트를 이용해 데이터 복구, 2개 이상 고장시 복구 불가

Volumes
* 하나의 파일 시스템을 갖춘 하나의 접근 가능한 스토리지 영역
  * `$ sudo fdisk -l`
    * 디스크 파티션을 CRUD 할 수 있는 유틸리티 명령
  * `$ sudo cat /etc/fstab`
    * `fstab`은 파일 시스템 정보, 부팅 시 마운트 정보를 보관하는 파일

Persistent Volume
* PV (Persistent Volume)
  * 관리자가 프로비저닝하거나 스토리지 클래스를 사용하여 동적으로 프로비저닝한 클러스터의 스토리지
* PVC (Persistent Volume Claim)
  * 사용자의 스토리지에 대한 요청 (파드와 비슷)
  * 파드
    * 노드 리소스를 사용
    * 파드 명세서 내 특정 수준의 리소스 (CPU, 메모리) 요청
  * PVC
    * PV 리소스를 사용
    * 클레임 명세서 내 특정 크기 및 접근 모드를 요청
* [볼륨 문서](https://kubernetes.io/ko/docs/concepts/storage/volumes/)

ConfigMap
* 키-값 쌍으로 기밀이 아닌 데이터를 `저장`하는데 사용하는 API 오브젝트
* 컨테이너에 필요한 환경 설정 내용을 컨테이너 내부가 아닌 외부에 분리하는데 사용
* 클러스터가 구성된 `config` 방식을 이해하는데 활용 가능하고 클러스터를 업그레이드 할 때도 활용 가능
* [문서](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/)

## Chapter07

Service
* 여러 레플리카에 트래픽을 분산시키는 로드 밸런서 (TCP, UDP 모두 가능)
* 노드의 `kube-proxy`를 활용, 엔드포인트로 라우팅 되도록 처리
  * `kube-proxy`가 직접 `UserSpace Proxy` 역할 시
    * 서비스(`kube-proxy`)가 요청을 직접 네비게이션
    * 모든 파드의 요청이 서비스에게 전달됨
  * `kube-proxy`가 `iptables`를 통해 `netfilter` 조작하는 역할 시
    * `iptable`가 리눅스 커널 내 반영되어 파드의 요청을 `netfilter` 모듈을 통해 네비게이션
    * 서비스(`kube-proxy`)는 `iptables` 내용을 커널에 반영

DNS (`Domain Name System`)
* 호스트의 도메인명을 호스트의 네트워크 주소로 변경 또는 반대로 변환을 수행
* 공유기에서는 단말에 사설 IP를 할당하면서 DNS 주소도 배포 가능
  * 공유기를 나쁜 목적으로 활용한다면 어떤 도메인이든 특정 IP 주소를 반환하게 할 수 있음
* K8S에서는 `CoreDNS`라는 오픈 소스를 활용

Ingress
* 클러스터 내의 서비스에 대한 외부 접근을 관리하는 API 오브젝트
  * 일반적으로 HTTP를 관리(로드 밸런싱)
* 위에서 만든 `my-nginx`는 `ClusterIP` 서비스이기에 클러스터 내에서는 접속 가능하지만 외부에서는 접속 불가
* Controller
  * [인그레스 컨트롤러 문서](https://kubernetes.io/ko/docs/concepts/services-networking/ingress-controllers/)
  * 앞서 생성한 `Ingress`는 단순히 로드밸런싱에 필요한 정보일 뿐, 실제 로드 밸런싱을 수행할 프로그램이 있어야 함(인그레스 컨트롤러)
  * [nginx 인그레스 컨트롤러](https://kubernetes.github.io/ingress-nginx/deploy/)
* 컨트롤러 추가
  * `$ kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.48.1/deploy/static/provider/baremetal/deploy.yaml`
* Rule
  * 선택적 호스트
  * 경로 목록
  * 백엔드

## Chapter08

Logging & TroubleShooting
* SRE (Site Reliability Engineering)
  * IT 운영에 대한 접근 방식
  * 소프트웨어 공학의 관점들을 통합한 원칙으로, 이들을 인프라스트럭처와 운영 문제에 적용
    * 주된 목적은 상당한 스케일링이 가능하고 상당히 신뢰할만한 소프트웨어 시스템을 만드는 것
* 개발자와 운영자는 추구하는 가치가 다름
  * SRE는 DevOps를 구현
    * DevOps는 IT의 Silo, Ops, Network, Security 등을 허무는 방식, 가이드라인, 문화의 집합
    * SRE는 그동안 찾은 작업 방식, 이러한 사례로 구체화하는 신념, 그리고 역할에 대한 집합
* 메트릭&모니터링 / 용량관리 / 변화관리 / 긴급대응 / 문화
  * 메트릭&모니터링
    * 모니터링 지표를 정의, 정의된 지표를 모니터링 시스템으로 구성
    * 인사이트를 통해 시스템이 안정적인 상황과 또는 장애가 나는 지표는 무엇인지, 이유는 무엇인지, 어떻게 해결할지를 고민
    * 기본적으로 SRE에서 가장 중요한 부분은 모든 것을 데이터화하고, 이 데이터를 기반으로 의사결정 하는 것
  * 모니터링(Monitoring)
    * 쿼리 카운트와 종류, 에러 카운트와 종류, 프로세싱 타임, 서버의 라이프타임과 같은 수치를 실시간으로 수집/처리/집계/보여줌
  * 메트릭(Metric)
    * 특정 시스템에서 리소스, 응용 프로그램 작업 또는 비즈니스 특성이 특정 시점에서의 수치로 표현되는 것 (수치화)
    * 보통 키-밸류(key-value) 형태로 수집된 숫자가 일반적
  * 로깅(Logging)
    * 로깅은 메트릭보다 훨씬 많은 데이터를 포함하는 시스템이나 애플리케이션의 이벤트로 나타나며, 이러한 이벤트에 의해 생성되는 모든 정보를 포함
  * 트레이스(Tracing)
    * 특정 고유한 식별자가 모든 시스템에 걸쳐 전체 수명 주기 동안 추적될 수 있도록 제공하는 로깅의 특별한 경우
* 쿠버네티스에서 로깅
  * [문서](https://kubernetes.io/ko/docs/concepts/cluster-administration/logging/)
* 로깅 아키텍처
  * 노드 레벨
  * 클러스터 레벨
  * 로깅 에이전트와 함께 사이드카 컨테이너 사용
  * 로깅 에이전트가 있는 사이드카 컨테이너
  * 앱에서 직접 로그 노출

백업 및 복구
* 쿠버네티스 클러스터의 정보들을 갖고 있는 `etcd`
  * `etcd` 문제 발생 시 K8S 클러스터 전체가 영향을 받음
* Pod로 구동된 `etcd` 버전 확인 후 해당 `etcdctl` 설치
  * [etcd 문서](https://github.com/etcd-io/etcd/releases)
  * `$ kubectl describe -n kube-system pod etcd-kjn-master-01.kr-central-1.c.internal`

## Kubectl Docker secret
* `$ kubectl create secret docker-registry dockersecret --docker-username="" --docker-password="" --docker-server=https://index.docker.io/v1/ --dry-run=client -o yaml > dockersecret.yaml`