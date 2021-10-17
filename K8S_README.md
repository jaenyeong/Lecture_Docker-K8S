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