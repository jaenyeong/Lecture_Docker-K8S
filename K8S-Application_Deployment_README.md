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
  * `kjn-01` - `172.30.5.70`
  * `kjn-02` - `172.30.6.222`
  * `kjn-03` - `172.30.5.106`
  * `kjn-04` - `172.30.5.229`

`kubeadm`, `kubelet`, `kubectl`
* `kubeadm`
  * 클러스터를 부트스트랩하는 명령
* `kubelet`
  * 클러스터의 모든 머신에서 실행되는 파드와 컨테이너 시작과 같은 작업을 수행하는 컴포넌트
* `kubectl`
  * 클러스터와 통신하기 위한 커맨드 라인 유틸리티

`CKA`, `CKAD`, `CKS`
* `Certified Kubernetes Administrator`
  * Admin
* 약 $375, 온라인 시험 (쿠폰 검색하여 사용할 것)
* 재시험 1회 무료로 응시 가능
* 시험은 핸즈온(실습) 방식
* [치트 시트 문서](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
* 팁
  * `killer shell` 사용
  * 두 번의 무료 세션 제공 (36시간 * 2번 - 오픈 시간 중요)
    * 토요일 아침 -> 일요일 밤
  * 시험과 유사한 난이도
  * 커트라인은 70점 정도

### 파드 컨테이너 배포 디자인

Multi Container POD
* 하나의 파드에 다수의 컨테이너를 사용
  * 하나의 파드를 사용하면 같은 네트워크 인터페이스와 IPC, 볼륨 등 공유 가능
  * 효율적으로 통신, 데이터의 지역성을 보장하고 여러 개의 앱이 결합된 상태로 하나의 파드를 구성할 수 있음
  * 일반적으로 보조하는 앱을 같은 컨테이너에 적용

Liveness Probe, Readiness Probe, Startup Probe
* [문서](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)
* 프로브에서 파드 상태를 확인하는 3가지 방법
  * CLI
    * `0`은 정상, 이외에 비정상
  * TCP
    * `3 way handshake` 여부에 따라 판단
  * HTTP
    * `200 ~ 300` 은 정상, `400 ~ 500`은 비정상이라고 판단
* `Liveness Probe`
  * 컨테이너가 살았는지를 판단, 다시 시작하는 기능
  * 컨테이너의 상태를 스스로 판단, 교착 상태에 빠진 컨테이너를 재시작
  * 버그가 생겨도 높은 가용성
  * `Liveness Probe`는 일반적으로 검사하고자 하는 컨테이너에 설정
* `Readiness Probe`
  * 파드가 준비된 상태인지 확인, 정상 서비스를 시작하는 기능
    * 확인은 위 3가지 방법을 사용
  * 파드가 적절하게 준비되지 않으면 로드밸런싱을 하지 않음
* `Startup Probe`
  * 앱 시작 시기를 확인하여 가용성을 높이는 기능
    * 확인은 위 3가지 방법을 사용
    * 다만 조금 더 긴 텀으로 확인
  * `Liveness`, `Readiness`의 기능을 비활성화
    * `Liveness`, `Readiness`는 파드 성능에 영향을 줄 수 있음
    * 앱이 시작할 시간을 충분히 확보하는 것이 목적

`exec-liveness.yaml`
* `Liveness` CLI 설정 (파일 존재 여부 확인)
* 반환 값
  * `0` (컨테이너 유지)
  * 그 외 값 (컨테이너 재시작)
~~~yaml
apiVersion: v1
kind: Pod
metadata:
   labels:
   test: liveness
   name: liveness-exec
spec:
   containers:
   - name: liveness
   image: k8s.gcr.io/busybox
   args:
   - /bin/sh
   - -c
   - touch /tmp/healthy; sleep 30; rm -rf /tmp/healthy; sleep 600
   livenessProbe:
      exec:
         command:
         - cat
         - /tmp/healthy
      initialDelaySeconds: 5
      periodSeconds: 5
~~~

`http-liveness.yaml`
* `Liveness` 웹 설정 (HTTP 요청 확인)
* 서버 응답 코드
  * `200 ~ 300` (컨테이너 유지)
  * 그 외 응답코드 (컨테이너 재시작)
~~~yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    test: liveness
  name: liveness-http
spec:
  containers:
  - name: liveness
    image: k8s.gcr.io/liveness
    args:
    - /server
    livenessProbe:
      httpGet:
        path: /healthz
        port: 8080
        httpHeaders:
        - name: Custom-Header
          value: Awesome
      initialDelaySeconds: 3
      periodSeconds: 3
~~~

`tcp-liveness-readiness.yaml`
* `Readiness` TCP 설정
  * 준비 프로브는 8080포트 검사
  * 5초 후부터 검사 시작
  * 검사 주기는 10초
  * > 서비스를 시작해도 됨
* `Liveness` TCP 설정
  * 활성화 프로브는 8080포트 검사
  * 15초 후부터 검사 시작
  * 검사 주기는 20초
  * > 컨테이너를 재시작 안해도 됨
~~~yaml
apiVersion: v1
kind: Pod
metadata:
  name: goproxy
  labels:
    app: goproxy
spec:
  containers:
  - name: goproxy
    image: k8s.gcr.io/goproxy:0.1
    ports:
    - containerPort: 8080
    readinessProbe:
      tcpSocket:
        port: 8080
      initialDelaySeconds: 5
      periodSeconds: 10
    livenessProbe:
      tcpSocket:
        port: 8080
      initialDelaySeconds: 15
      periodSeconds: 20
~~~

Sidecar Container
* 오토바이의 사이드카에서 유래
* 기존 기능을 향상, 확장하는 것이 목적
* 파드의 파일 시스템을 공유하는 형태

Adapter Container
* 본질적으로 이질적인 앱을 적용 가능하도록 개선하는 컨테이너
* 원본 컨테이너에 대한 변경 없이 현재 컨테이너 기능을 시스템에 적용시키는 기능

Ambassador Container
* 국가공무원으로 외교를 대표하는 대사를 의미함
* 파드 외부의 서비스에 대한 엑세스를 간소화하는 특수 유형
* 파드에 `Ambassador` 컨테이너를 배치하여 통신을 대신해주는 역할을 소화
* 서비스의 인증이나 데이터의 변조, 감시 등의 다양한 작업이 가능함

Init Container
* 파드 컨테이너 실행 전에 초기화 역할을 하는 컨테이너
* 완전히 초기화가 진행된 다음에 주 컨테이너를 실행
* `Init` 컨테이너가 실패하면 성공할 때까지 파드를 반복해 재시작
* `restartPolicy`에 `Never` 값 설정 시 재시작하지 않음

`job`, `cronjob`
* 클러스터 운영 시 일정 주기마다 돌아야 하는 작업들이 존재
* 넷플릭스 아키텍처
  * 실시간 분석 (Online)
  * 준 실시간 분석 (Nearline)
  * 오프라인 분석 (Offline)
* `job` (작업)
  * `job`에서 하나 이상의 파드를 생성하고 지정된 수의 파드가 성공적으로 종료될 때까지 계속해서 파드의 실행을 재시도
  * `job` 삭제 시 잡이 생성한 파드가 정리됨
  * `job` 일시 중단 시 다시 재개될 때까지 활성 파드가 삭제됨
  * `job`을 사용하여 여러 파드를 병렬로 실행 가능
* `job`에 대한 병렬 실행 방법
  * 비병렬 `job` (기본값)
    * 일반적으로 파드가 하나만 실행되고 파드가 종료되면 `job`이 완료됨
  * 정해진 횟수를 반복하는 `job`
    * `.spec.completions`에 0이 아닌 양수를 지정, 설정하면 정해진 횟수까지 파드가 반복 실행
  * 병렬 실행 가능 수 지정
    * `.spec.parallelism`에 0이 아닌 양수를 지정, 정해진 개수만큼 파드가 동시 실행 가능
* cronjob
  * 예약 시간 작성 요령
    * 기존 리눅스 시스템의 `cron`(`crontab`)에서 표기하는 방법과 동일함
    * `cronjob.yaml` 파일에 예약 실행 시간과 실행할 컨테이너 작성
    * 일반적으로 하나의 `cronjob`에 하나의 작업을 실행하는 것을 권장
    * `* * * * *` 각각 `분`, `시`, `일`, `월`, `요일` 을 의미
      * 숫자 표기
  * 동시성 정책 설정
    * `spec.concurrencyPolicy` 동시성 정책 설정
    * 이미 하나의 `cronjob`이 실행 중인 경우 `cronjob`을 추가로 실행할 지 결정
      * `Allow`
        * 중복 실행 허용 (기본값)
      * `Forbid`
        * 중복 실행 금지
      * `Replace`
        * 현재 실행 중인 `cronjob`을 내리고 새로운 `cronjob`으로 대체

시스템 리소스 요구사항과 제한 설정
* CPU, 메모리는 집합적으로 리소스(컴퓨팅 리소스)라고 부름
* 자원 유형에는 기본 단위를 사용
* 리소스 요청 설정 방법 (최소)
  * `spec.containers[].resources.requests.cpu`
  * `spec.containers[].resources.requests.memory`
  * 스케줄링과 직접적인 연관이 있음
* 리소스 제한 설정 방법 (최대)
  * `spec.containers[].resources.limits.cpu`
  * `spec.containers[].resources.limits.memory`
* CPU는 코어 단위로 지정, 메모리는 바이트 단위
  * CPU : `m(millicpu)`
  * Memory : `Ti`, `Gi`, `Mi`, `Ki`, `T`, `G`, `M`, `K`
* 환경에 따른 CPU 의미
  * 1 AWS vCPU
  * 1 GCP 코어
  * 1 Azure vCore
  * 1 IBM vCPU
  * 1 하이퍼 스레딩 기능이 있는 베어 메탈 인텔 프로세서의 하이퍼 스레드
* `limitRanges`
  * 네임 스페이스안에서만 파드 또는 컨테이너별로 리소스를 제한하는 정책
  * 실행 시점이 중요
    * 기존에 이미 존재하던 파드(또는 컨테이너)에는 적용되지 않음
  * 중복된 `limitRanges`는 덮어
  * 기능 (네임 스페이스에서)
    * 파드나 컨테이너당 최소 또는 최대 컴퓨팅 리소스 사용량 제한
    * `PersistentVolumeClaim` 당 최소 또는 최대 스토리지 사용량 제한
    * 리소스에 대한 요청과 제한 사이의 비율 적용
    * 컴퓨팅 리소스에 대한 디폴트 `requests/limits`를 설정하고 런타임 중인 컨테이너에 자동 입력
  * 적용 방법
    * `Apiserver` 옵션에 `enable-admission-plugins=LimitRange`
  * 리소스 조회
    * `# kubectl describe limitrange -n ${네임스페이스}`
* `ResoucreQuata`
  * 네임스페이스별 리소스 제한
    * 제한하기 원하는 네임스페이스에 `ResourceQuata` 리소스 생성
    * 모든 컨테이너에는 CPU, 메모리에 대한 최소 요구사항, 제한 설정 필요
  * 리소스 조회
    * `# kubectl describe resourcequota -n ${네임스페이스}`

## Chapter02

### 쿠버네티스 저장소 활용과 롤링 업데이트

`Volume` 개요
* 볼륨(Volume)
  * 컨테이너가 외부 스토리지에 액세스하고 공유하는 방법
  * 파드의 각 컨테이너에는 고유의 분리된 파일 시스템이 존재
  * 볼륨은 파드의 컴포넌트이며 파드 스펙에 의해 정의
  * 독립적인 쿠버네티스 오브젝트가 아니기 때문에 스스로 생성 및 삭제 불가능
  * 각 컨테이너의 파일 시스템의 볼륨을 마운트하여 생성
* 종류
  * 임시 볼륨
    * `emptyDir`
      * 파일 시스템 공유하는 것처럼 구성
  * 로컬 볼륨
    * `hostpath`
      * 마스터 노드의 핵심 컴포넌트가 사용함 (`API`, `스케줄러`, `etcd` 등)
      * 모니터링 용도로 사용 (`/var/log`)
    * local
  * 네트워크 볼륨 (온프레미스)
    * `iSCSI`
    * `NFS`
    * `cepthFS`
    * `glusterFS`
  * 네트워크 볼륨 (클라우드 종속)
    * `gcePersistentDisk`
    * `awsEBS`
    * `azureFile`
* 주요 사용 가능한 볼륨 유형
  * `emptyDir`
    * 일시적인 데이터 저장, 비어있는 디렉터리
  * `hostpath`
    * 호스트 노드의 파일 시스템에서 파일이나 디렉터리를 마운트
  * `NFS`
    * 기존 NFS(`Network File System`) 공유가 파드에 장착
  * `gcePersistentDisk`
    * `GCE (Google Compute Engine)` 영구디스크 마운트
  * `persistentVolumeClaim`
    * 사용자가 특정 클라우드 환경에 세부 사항을 모른 채 GCE
  * `configMap`, `Secret`, `downwardAPI`
    * 특수 유형의 볼륨
* [persistentvolumeclaim 문서](https://kubernetes.io/ko/docs/concepts/storage/volumes/#persistentvolumeclaim)

`Secrets`, `Configmap` mount
* `ConfigMap` 마운트
  * 키-값 쌍으로 기밀이 아닌 일반 데이터를 저장하는데 사용하는 API 오브젝트
  * 파드는 볼륨에서 `환경 변수`, `커맨드-라인 인수` 또는 `구성 파일`로 컨피그맵을 사용
  * 컨피그맵 사용 시 컨테이너 이미지에서 환경별 구성을 분리, 앱을 쉽게 이식 가능
* `Secret` 마운트
  * 암호, 토큰 또는 키와 같은 소량의 중요한 데이터를 포함하는 오브젝트
  * 시크릿을 사용해 사용자 기밀 데이터를 앱 코드에 넣을 필요가 없음

`NFS`를 활용한 `Network Storage`
* `NFS` (`Network File System`)
  * 쿠버네티스에서 사용하는 프로토콜이나 쿠버네티스의 종속된 개념이 아님
  * 네트워크 환경 볼륨을 마운트할 수 있음 (NFS가 구성되어 있어야 함)

`PV`와 `PVC`
* `PV`는 클러스터 스토리지 (볼륨 그 자체)
  * `PV`는 네임스페이스에 속하지 않음
  * 관리자가 프로비저닝하거나 `StorageClass`를 사용하여 동적으로 프로비저닝한 클러스터의 스토리지
* `PVC`는 사용자가 `PV`에게 하는 요청
  * 사용자의 스토리지에 대한 요청 (`PV` 리소스 사용)
* 파드 개발자는 클러스터에서 네트워크 스토리지를 사용하려면 인프라를 잘 알아야 함
  * 앱을 배포하는 개발자가 스토리지 기술의 종류를 몰라도 상관없도록 하는 것이 이상적
  * 인프라 관련 처리는 클러스터 관리자의 유일한 도메인
* `PV`, `PVC`를 사용해 관리자와 사용자의 영역을 나눔
  * 인프라 세부 사항을 알지 못해도 클러스터의 스토리지를 사용할 수 있도록 제공하는 서비스
  * 파드 안에 영구 볼륨을 사용하도록 하는 방법은 다소 복잡함
* `mongo-pvc.yaml`
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
* `mongo-pv.yaml`
  ~~~yaml
  apiVersion: v1
  kind: PersistentVolume
  metadata:
    name: mongodb-pv
  spec:
    capacity:
      storage: 1Gi
    accessModes:
    - ReadWriteOnce
    - ReadOnlyMany
    persistentVolumeReclaimPolicy: Retain
    gcePersistentDisk:
      pdName: mongodb
      fsType: ext4
  ~~~
  * `persistentVolumeReclaimPolicy`
    * `Retain`
      * `PVC` 삭제 시 `PV`는 여전히 존재, 볼륨은 해제된 것으로 간주(취급)함
      * 연관된 스토리지 자산의 데이터를 수동으로 정리
    * `Delete`
      * 외부 인프라의 연관된 스토리지 자산을 모두 삭제
    * `Recycle`
      * `rm -rf /thevolume/*` 볼륨에 대한 기본 스크럽을 수행
      * 새 클레임에 대해 다시 사용할 수 있도록 함
    * 특수한 경우가 아니라면 `Retain` 보다 `Delete`를 사용해 완전히 삭제할 것
      * 많은 곳에서 공간을 공유하기 때문에 공간 확보 필요
    * 설정은 생성 후에도 재설정 가능

`StorageClass`
* 위 작업들을 자동으로 처리
  * 관리자가 제공하는 스토리지의 `classes`를 설명할 수 있는 방법을 제공
* `PV`를 직접 만드는 대신 사용자가 원하는 `PV` 유형을 선택하도록 하는 오브젝트 정의 기능
  * `PV`를 처리하는 주체가 사람에서 시스템으로 변환
* `PVC` 파일 제작
  * 파드와 `PVC` 모두 삭제 후 다시 업로드 (`apply` 명령 시 권한 에러 발생)
  * 위 `mongo-pvc.yaml` 파일 내용 변경
    * `storageClassName`의 값을 `""`에서 `storage-class`로 수정 (`PV` 동적 프로비저닝)
    * `PV` 동적 프로비저닝을 사용하면 사용할 디스크와 `PV`가 자동으로 생성됨
* 이대로는 `StorageClass`가 동작하지 않음 (`CSI`를 구성해야 함)
  * `CSI(Container Storage Interface)`는 디스크를 생성, 할당, 분배해 줌 (중개)

`rook-ceph`를 활용한 `Private Cloud StorageClass`
* `rook-ceph`
  * 오픈소스 클라우드 네이티브 스토리지 오케스트레이터
  * 온프레미스 환경에서 `storage-class`를 구성하는 도구
  * `ceph`은 파일 스토리지를 가상화시키는 클러스터를 구성할 수 있는 소프트웨어
  * `rook` 패키지 활용하면 K8S에서 보다 편리하게 `ceph`을 설치, 관리 가능
    * 물론 직접 설치도 가능

`StatefulSet`
* 앱의 상태(`stateful`)를 저장하고 관리하는 데 사용되는 K8S 객체(워크로드 API 오브젝트)
* 스테이트풀셋으로 생성되는 파드는 영구 식별자(파드 일련 번호)를 가지고 상태(ID, 디스크 등) 유지
  * 디플로이먼트는 파드를 삭제, 생성 시 상태가 유지되지 않는 한계가 존재
* 파드 집합의 디플로이먼트와 스케일링을 관리하며, 파드들의 순서 및 고유성을 보장
* 사용하는 경우
  * 안정적이고 고유한 네트워크 식별자가 필요한 경우 사용
  * 안정적이며 지속적인 스토리지
  * 질서 정연한 배치 및 확장
  * 주문, 자동 롤링 업데이트
* 문제점
  * 스테이트풀셋과 관련된 볼륨(파드마다 구성된 디스크)이 삭제되지 않음
  * 파드의 스토리지는 `PV`나 `StorageClass`로 프로비저닝 수행해야 함
  * 롤링업데이트를 수행하는 경우 수동으로 복구해야 할 수 있음
  * 파드 네트워크 ID를 유지하기 위해 헤드레스(`headless`) 서비스 필요
    * 파드를 직접 지정하기 때문에 서비스의 ID는 필요없지만 DNS를 만들기 위해 서비스가 필요
* 헤드레스(`headless`) 서비스는 `clusterIP`를 `None`으로 지정하여 생성
  * 헤드레스 서비스는 IP가 할당되지 않음
  * `kube-proxy`가 밸런싱이나 프록시 형태로 동작하지 않음 (파드를 직접 지정하면 되기 때문에 기능이 필요하지 않음)
    * 보통 서비스의 역할을 `kube-proxy`가 `IP-tables`, `netfilter` 등을 통해 추상화하지만 스테이트풀셋에서는 해주지 않음
  * 파드의 이름은 도메인명의 요소로 사용됨
  * 헤드레스 서비스는 실제로 서비스의 역할을 하지 않고 이름만 빌려줌
* 다수 파드 식별 요령
  * 스테이트풀셋으로 다수의 파드 생성이 가능
  * 하지만 스테이트풀셋은 상태를 유지하는 파드, 각각의 파드를 인식할 수 있는 방법을 알아야 함
  * 이를 통해 안정적인 네트워크 ID와 스토리지를 식별할 수 있음
  * 순차적으로 하나씩 배포하는데 앞의 파드가 준비 완료 상태가 된 후에 다음 파드 생성
  * 배포 순서는 `0`번째부터 `n-1`까지 (종료 순서는 역순)
* 업데이트 전략
  * `OnDelete`
    * 파드를 자동으로 업데이트하는 기능이 아님
    * 수동으로 삭제하면 스테이트풀셋의 `spec.template`를 적용한 새로운 파드가 생성됨
  * `RollingUpdate`
    * 한번에 하나씩 파드를 업데이트 함
    * `web-{n-1}`부터 `web-0` 순서(배포 역순)로 진행

`Deployment`
* 앱 다운타임 없이 업데이트 가능하도록 도와주는 리소스
* 레플리카셋(`replicaSet`), 레플리케이션컨트롤러(`replicationController`) 상위에 배포되는 리소스
  * 현재 레플리케이션컨트롤러는 잘 사용되지 않음
* 모든 파드 업데이트
  * 잠깐의 다운타임 발생
    * 새 파드를 실행, 작업이 완료되면 오래된 파드 삭제
  * 롤링 업데이트
* 작성 요령
  * `pod.yaml`의 `metadata`와 `spec` 부분을 그대로 옮김
  * `deployment.yaml`
    * `spec.template`
      * 배포할 파드 설정
    * `replicas`
      * 배포할 파드의 수를 명시
    * `label`
      * 디플로이먼트가 배포한 파드를 관리
  * 스케일링
    * `# kubectl edit deploy ${deployName}`
      * `yaml`파일을 직접 수정, `replicas` 조정
    * `# kubectl scale deploy ${deployName} --replicas=${number}`
      * `replicas` 조정

앱 롤링 업데이트와 롤백
* 새 파드를 실행, 작업이 완료되면 오래된 파드 삭제 (잠깐의 다운타임 발생)
  * 새 버전을 실행하는 동안 오래된 버전 파드와 연결
  * 서비스의 레이블셀렉터(`label selector`)를 수정하여 간단하게 수정 가능
* 레플리케이션컨트롤러가 제공하는 롤링 업데이트
  * 예전에는 `kubectl`을 사용해 스케일링을 사용하여 수동으로 롤링 업데이트 진행
    * `kubectl` 중단 시 업데이트는?
  * 레플리케이션컨트롤러 또는 레플리카셋을 통제할 수 있는 시스템(디플로이먼트)이 필요함
* 업데이트 전략 (`StrategyType`)
  * `Rolling Update`
    * 오래된 파드를 하나씩 제거하는 동시에 새로운 파드 추가
    * 요청을 처리할 수 있는 수는 그대로 유지
    * 반드시 이전 버전과 새 버전을 동시에 처리 가능하도록 설계한 경우에만 사용할 것
  * `Recreate`
    * 새 파드 생성 전에 이전 파드 모두 삭제
    * 여러 버전을 동시에 실행(서비스) 불가능
    * 잠깐의 다운타임 존재
  * 세부 설정
    * `maxSurge`
      * 기본값 `25%`, 개수로도 설정 가능
      * 최대로 추가 배포를 허용할 개수 설정
      * 4개인 경우 `25%`이면 1개가 설정됨
        * 총 5개까지 동시 파드 운영
    * `maxUnavailable`
      * 기본값 `25%`, 개수로도 설정 가능
      * 동작하지 않는 파드의 수 설정 (덜 운영해도 되는 수 설정)
      * 4개인 경우 `25%`이면 1개가 설정됨
        * 총 3(4-1)개는 운영해야 함
* 업데이트를 실패하는 경우
  * 부족한 할당량 (`Insufficient quota`)
  * 레디네스 프로브 실패 (`Readiness probe failures`)
  * 이미지 가져오기 에러 (`Image pull erros`)
  * 부족한 권한 (`Insufficient permissions`)
  * 제한 범위 (`Limit ranges`)
  * 앱 런타임 구성 에러 (`Application runtime misconfiguration`)
* 기본적으로 업데이트 실패 시 `600`초 후 업데이트를 중지
  ~~~yaml
  spec:
    processDeadlineSeconds: 600
  ~~~

## Chapter03

### 쿠버네티스 유저(권한) 관리

K8S 인증 체계
* 모든 통신은 `TLS`로 대부분의 엑세스는 `kube-apiserver`를 통해서만 통신해야 함
* 엑세스 가능한 유저
  * `X509 Client Certs`
    * `X509`는 인증서 형식
    * `kubeadm`로 구성 시 `kube config` 안에서 복제 했던 키를 사용(인증)하여 통신하는 방식
  * `Static Token File`
    * 인증 방식 중 가장 쉬운 편에 속함
    * 관리자가 생성한 토큰(파일)으로 통신 (적용 시 리부팅 필요)
    * 권장되는 방식은 아님
  * `Putting a Bearer Token in a Request`
    * 베어러 토큰을 사용해 통신
  * `Bootstrap Tokens`
    * `kubeadm` 구성 시 `init` 후에 `join` 시 필요한 부트스트랩 토큰 > 클러스터 참여 여부 결정
  * `Service Account Tokens`
    * 파드가 사용하는 앱 전용 토큰
  * `OpenID Connect Tokens`
    * `Azure Active Directory`
    * `Salesforce`
    * `Google` - (`GCP GKE`)
    * 기타
* 무엇을 할 수 있는가?
  * `RBAC Authorization` (`Role-Based Access Control`)
    * 역할 기반 엑세스 제어
    * 조직 내의 개별 사용자의 역할에 따라 컴퓨터 또는 네트워크 리소스에 대한 액세스 규제
    * 일반적으로 자주 사용되는 방식
  * `ABAC Authorization` (`Attribute-Based Access Control`)
    * 속성 기반 엑세스 제어
    * 속성을 결합하는 정책을 사용하여 사용자에게 엑세스 권한 부여
    * 복잡성 등을 고려했을 때 자주 사용되지 않음
  * `Node Authorization`
    * `kubelets`에서 만든 API 요청을 특별히 승인하는 특수 목적 권한 부여 모드
  * `WebHook Mode`
    * `HTTP` 콜백, 특정 이벤트 발생 시 `URL`에 메시지 전달

`User Account`, `Service Account`
* `User Account`
  * 일반 사용자를 위한 계정
* `Service Account`
  * 앱(파드)을 위한 계정
* `Static Token File`
  * `apiserver` 서비스 실행 시 `--token-auth-file=${SOMEFILE}`
    * `kube-apiserver` 수정 필요
    * `SOMEFILE` 확장자는 `csv`
  * API 서버를 리부팅해야 적용됨
  * `SOMEFILE`은 토큰, 사용자명, 사용자 `uid`, 그룹명(옵션)으로 구성된 최소 3열의 `csv` 파일
    * 예시 `token,user,uid,"group1,group2,group3"`
  * 적용 시 사용 방법
    * `HTTP` 요청 진행 시 아래 내용을 헤더에 포함
      * `Authorization: Bearer 31ada4fd-adec-460c-809a-9e56ceb75269`
    * `kubectl`에 등록해 사용하는 방법
      * `# kubectl config set-credentials user1 --token=password1`
      * `# kubectl config set-context user1-context --cluster=kubernetes --namespace=frontend --user=user1`
      * `# kubectl get pod --user user1`
* 서비스 어카운트
  * 직접 생성하지 않아도 `default` 서비스 어카운트가 생성됨
    * 파드에 서비스 어카운트 설정을 직접하지 않으면 `default` 서비스 어카운트를 사용하게 됨
  * 생성 시 시크릿(토큰)이 같이 생성됨
  * 일반적으로 별도의 권한을 부여하고 싶은 경우 `default`를 사용하기보다는 새로 생성하길 권장

`TLS` 인증서를 활용한 통신 이해
* 응용 계층인 `HTTP`와 `TCP` 계층 사이에서 작동
  * 앱에 독립적 -> `HTTP` 제어를 통한 유연성
  * 데이터의 암호화, 데이터 무결성, 서버 인증 기능, 클라이언트 인증 기능
* `CA`를 통해 `Certificate` 보장
* K8S에서 인증서 위치
  * `/etc/kubernetes/pki`
* 정확한 `TLS` 인증서 사용 확인
  * `manifests` 파일에서 실행하는 `certificate` 확인 필요
* 인증서 정보 확인
  * `# openssl x509 -in ${certificate} -text`
* 유효기간 확인
  * `# kubeadm certs check-expiration`
* `Automatic certificate renewal`
    * `kubeadm`은 컨트롤 플레인 업그레이드 시 모든 인증서를 자동 갱신
* `Manual certificate renewal`
  * `kubeadm certs renew all`

`TLS` 인증서를 활용한 유저 생성
* [1번 방법] `ca`를 사용하여 직접 `csr` 승인 (`certificate signing request`)
  * 개인키 생성
    * `# openssl genrsa -out kjn.key 2048`
  * 개인(`private`) 키를 기반으로 인증서 서명 요청 (`csr` 생성)
    * `# openssl req -new -key kjn.key -out kjn.csr -subj "/CN=kjn/0=boanproject"`
      * `CN` 사용자명
      * `O` 그룹명
      * `CA`에게 `csr` 파일로 인증 요청 가능
  * K8S 클러스터 인증 기관(`CA`)이 사용 요청을 승인해야 함
    * 내부에서 직접 승인 시 `pki` 경로에 있는 `ca.key`, `ca.crt`를 통해 승인 가능
    * `kjn.csr`을 승인하여 최종 인증서인 `kjn.crt` 생성
    * `-days` 옵션으로 인증서의 유효 기간 설정 (여기서는 500일)
      * `# openssl x509 -req -in kjn.csr -CA /etc/kubernetes/pki/ca.crt -CAkey /etc/kubernetes/pki/ca.key -CAcreateserial -out kjn.crt -days 500`
        * `CAcreateserial` 옵션을 주지 않으면 생성되지 않음
* [2번 방법] K8S에 `crt`를 등록
  * `crt` 사용을 위해 `kubectl` 명령으로 등록
    * `# kubectl config set-credentials kjn --client-certificate=.certs/kjn.crt --client-key=.certs/kjn.key`
    * `# kubectl config set-context kjn-context --cluster=kubernetes --namespace=office --user=kjn`
  * 다음 명령으로 사용자 권한으로 실행 가능 (지금은 사용자에게 권한을 할당하지 않아 실행 안됨)
    * `# kubectl --context=kjn-context get pods`

`kube config` 파일을 사용한 인증
* `kube config`
  * 파일 경로
    * `~/.kube/config`
  * 구성
    * `clusters`
      * 연결할 K8S 클러스터의 정보
    * `users`
      * 사용할 권한을 가진 사용
    * `contexts`
      * `cluster`, `user`를 함께 입력해 권한 할당
* `# kubectl config view`
  ~~~yaml
  apiVersion: v1
  clusters:
  - cluster:
      certificate-authority-data: DATA+OMITTED
      server: https://172.30.5.70:6443
    name: kubernetes
  contexts:
  - context:
      cluster: kubernetes
      namespace: dev1
      user: john
    name: john@kubernetes
  - context:
      cluster: kubernetes
      namespace: office
      user: kjn
    name: kjn@kubernetes
  - context:
      cluster: kubernetes
      user: kubernetes-admin
    name: kubernetes-admin@kubernetes
  - context:
      cluster: kubernetes
      namespace: frontend
      user: user1
    name: user1-context
  current-context: kubernetes-admin@kubernetes
  kind: Config
  preferences: {}
  users:
  - name: john
    user:
      client-certificate: /root/john.crt
      client-key: /root/john.key
  - name: kjn
    user:
      client-certificate: /root/kjn.crt
      client-key: /root/kjn.key
  - name: kubernetes-admin
    user:
      client-certificate-data: REDACTED
      client-key-data: REDACTED
  - name: user1
    user:
      token: REDACTED
  ~~~
  * `cluster` 주요 정보
    * `certificate-authority-data: DATA+OMITTED`
    * `server: https://172.30.5.70:6443`
  * `contexts` 주요 정보
    * `cluster`, `user` 정보를 하나의 컨텍스트로 묶음
  * `current-context` 현재 사용하는 컨텍스트 정보
  * `users` 주요 정보
    * `client-certificate-data` 등은 데이터 직접 삽입뿐 아니라 파일 경로 명시 가능
* 인증 사용자 변경
  * `# kubectl config use-context user@kube-cluster`

`RBAC` 기반 권한 관리
* 역할 기반 액세스 제어 (`Role-Based Access Control`)
  * 기업 내 개별 사용자의 역할을 기반으로 컴퓨터, 네트워크 리소스에 대한 엑세스 제어
  * `rabc.authorization.k8s.io API`를 사용하여 정의
  * 권한 결정을 내리고 관리자가 `Kubernetes API`를 통해 정책을 동적으로 구성
  * `RBAC`를 사용하여 룰을 정의하려면 `apiserver`에 `--authorization-mode=RBAC` 옵션 필요
* `RBAC`를 다루는 API는 4가지의 리소스 컨트롤
  * `Role`
  * `RoleBinding`
  * `ClusterRole`
  * `ClusterRoleBinding`
* `Role`, `RoleBinding` 차이
  * `Role`
    * `누가하는 것인지`를 정의하지 않고 `롤`만을 정의
    * 일반롤은 네임스페이스 단위로 역할을 관리
    * 클러스터롤은 네임스페이스의 상관없이 전체 클러스터에서 특정 자원을 관리할 롤을 정의
  * `RoleBinding`
    * `누가하는 것인지`만을 정의하고 `롤`은 정의하지 않음
    * 롤을 정의하는 대신, 참조할 롤을 정의 (`roleRef`)
    * 어떤 사용자에게 어떤 권한을 부여할 지 정하는 바인딩 리소스
    * 일반롤에는 롤바인딩, 클러스터롤에는 클러스터롤바인딩이 필요함

## Chapter04

### `ElasticSearch`를 활용한 로그 수집기

`ElasticSearch` (오픈소스 검색 엔진)
* 설명
  * 확장성이 뛰어난 전체 텍스트 검색, 분석 엔진
  * 대량의 데이터를 신속하게 거의 실시간으로 저장, 검색, 및 분석
  * 일반적으로 복잡한 검색 기능과 요구 사항이 있는 앱을 구동하는 기본 엔진, 기술
* 핵심 개념
  * `Near Realtime` (`NRT`)
    ~~~
    거의 실시간 플랫폼
    문서를 색인할 때부터 검색이 가능할 때까지 대기 시간이 매우 짧음 (일반적으로 1초)
    ~~~
  * `Cluster`
    ~~~
    전체 데이터를 함께 보유하고 모든 노드에서 연합 인덱싱 및 검색 기능을 제공하는 하나 이상의 노드 (서버) 모음
    클러스터는 기본적으로 `elasticsearch`라는 고유한 이름으로 식별하며,
    이 이름은 노드가 이름으로 클러스터에 참여하도록 설정된 경우 노드가 클러스터의 일부일 수 있기 때문에 중요함
    ~~~
  * `Node`
    ~~~
    노드는 클러스터의 일부이며 데이터를 저장하고 클러스터의 인덱싱 및 검색 기능에 참여하는 단일 서버
    단일 클러스터에서 원하는 만큼의 노드를 소유 가능
    또한 현재 네트워크에서 실행중인 다른 `Elasticsearch` 노드가 없다면,
    단일 노드를 시작하면 기본적으로 `elasticsearch`라는 새로운 단일 노드 클러스터가 형성
    ~~~
  * `Index`
    ~~~
    색인은 다소 유사한 특성을 갖는 문서의 콜렉션
    예를 들어 고객 데이터에 대한 색인, 제품 카탈로그에 대한 또 다른 색인,
    주문 데이터에 대한 또 다른 색인을 가질 수 있음
    색인은 이름(모두 소문자여야 함)로 식별되며,
    이 이름은 색인된 문서를 색인 작성, 검색, 갱신 및 삭제 시 색인을 참조하는 데 사용
    ~~~
  * `Documents`
    ~~~
    문서는 색인을 생성 할 수있는 기본 정보 단위
    예를 들어, 단일 고객에 대한 문서, 단일 제품에 대한 다른 문서 및 단일 주문에 대한 문서를 보유
    `JSON (JavaScript Object Notation)`으로 표현
    ~~~
  * `RESTFul API`
    ~~~
    `URI`를 사용한 동작이 가능
    `HTTP` 프로토콜로 `JSON` 문서의 입출력과 다양한 제어 `JSON` 문서의 입출력과 다양한 제어
    ~~~
  * `Type` (없어짐)
    ~~~
    사용자가 하나의 유형, 블로그 게시물을 다른 유형과 같이 여러 `Type`의 문서를 동일한 색인에 저장할 수 있도록
    색인의 논리적 범주 / 파티션으로 사용되는 유형
    더 이상 인덱스에 여러 유형을 작성할 수 없으며 이후 버전에서는 `Type`의 전체 개념이 제거됨
    ~~~

데이터 입력과 조회
* `REST API`
  * 웹의 창시자 `Roy fielding`의 논문에 의해서 소개
* 엘라스틱서치 노드와 통신하는 방법
* 클러스터와 상호 작용하는 데 사용할 수 있는 매우 포괄적이고 강력한 `REST API`를 제공
* API로 수행 가능한 작업
  * 클러스터, 노드, 색인 상태, 상태 및 통계 등 확인
  * 클러스터, 노드, 색인 데이터, 메타 데이터 등 관리
  * 데이터 입력과 검색 (CRUD) 및 인덱스 에 대한 검색 작업 수행
  * 페이징, 정렬, 필터링, 스크립팅, 집계 및 기타 여러 고급 검색 작업 실행
* 클러스터 상태 (`health`)
  * 클러스터의 진행 상태에 대한 기본적인 확인
  * 현재 `curl`을 통해 확인
  * `HTTP/REST` 호출 수행이 가능한 모든 툴 사용 가능
  * 클러스터 상태를 확인하기 위해 `_cat API` 사용
  * 녹색
    * 모든 것이 잘 동작하는 상태
    * 클러스터는 완전히 작동
  * 노란색
    * 모든 데이터를 사용할 수 있지만, 일부 복제본은 아직 할당되지 않음
    * 클러스터는 완전히 작동
  * 빨간색
    * 어떤 이유로든 일부 데이터를 사용 불가
    * 클러스터 부분 작동
* 데이터베이스가 가진 모든 데이터 확인
  * 갖고 있는 모든 인덱스 항목 조회
  * `index`는 일반 `RDB`에서의 데이터베이스 역할
  * `GET /_cat/indices?v`
* 엘라스틱서치 데이터 구조
  * 인덱스, 도큐먼트의 단위
  * 도큐먼트는 엘라스틱서치의 데이터가 저장되는 최소 단위
  * 여러 개의 도큐먼트는 하나의 인덱스로 구성
* `RDB`와 엘라스틱서치 비교
  * `Database` - `Index`
  * `Table` - `Type` (없어질 예정)
  * `Row` - `Document`
  * `Column` - `Field`
  * `Schema` - `Mapping`
* 엘라스틱서치 질의 방법
  * CLI `curl` 명령
  * `Postman` 앱
  * `KIBANA`의 `devtool`
* 인덱스 생성, 조회
  ~~~
  PUT /customer?pretty
  GET /_cat/indices?v
  
  # 또는 `curl`
  curl -X PUT "localhost:9200/customer?pretty"
  curl -X GET "localhost:9200/_cat/indices?v"
  ~~~
  * `URI`의 `_*`는 API 함수를 의미함
    * `_doc`는 도큐먼트 함수
* 도큐먼트 삭제
  * 문서를 삭제하는 것은 매우 간단함
    * 데이터 삭제 후 조회했을 때 `found`가 `false`임을 확인
  * 삭제 시 특징
    * 메타데이터는 그대로 유지됨
    * 삭제 후 다시 데이터를 입력하면 `_version` 값이 이어서 진행
    * 버전까지 초기화하려면 인덱스를 삭제해야 함
* 도큐먼트 수정
  * ID를 고쳐 쓰면 모든 내용이 교체됨
    * `POST customer/_doc/1`
    * ID를 쓰지 않거나 다른 ID를 사용하면 새롭게 저장됨
  * `6.x` 버전 이후부터는 `POST`, `PUT`을 혼용
* 도큐먼트 업데이트
  * `_update API` 제공 (`doc`, `source` 필드를 이용해 데이터 제어)
    * `POST customer/_update/1`
    * `doc`
      * 도큐먼트에 새로운 필드를 추가하거나 기존 필드 값을 변경할 때 사용
    * `script`
      * 프로그래밍 기법 사용
      * 입력된 내용에 따라 필드의 값 변경 등 처리

배치 프로세스
* `_bulk API`
  * 여러 작업을 일괄적으로 수행할 수 있는 기능
  * 최대한 적은 네트워크 트래픽으로 여러 작업을 가능한 빠르게 처리하는 것이 목적
  * 작업 중 실패해도 전체를 롤백하지 않음
  * 대량 API가 반환되면 각 액션에 대한 상태가 전송된 순서대로 반환
    * 특정 액션의 성공, 실패 여부를 확인 가능

검색 API
* `_search` 엔드포인트에서 엑세스
  * 엘라스틱서치는 쿼리에 사용하는 `JSON` 스타일 도메인 관련 `Query DSL`을 제공
* 검색 실행 방법
  * `URI`
    * 단순한 방법이 필요한 경우에 사용하는 방식
    * `GET /bank/_search?q=*&sort=account_number:asc&pretty`
      * `bank`
        * 찾을 인덱스 의미
      * `q=*`
        * 매개변수는 엘라스틱서치가 인덱스의 모든 문서와 일치하도록 하는 명령
      * `sort=account_number:asc`
        * `account_number` 필드를 기준으로 결과 오름차순 정렬
      * `pretty`
        * 보기 쉬운 형태의 `JSON` 결과를 반환
  * `본문`
    * 표현력을 높여 더 많은 정보를 전달하려면 이 방식으로 `JSON` 사용
* 검색 결과
  * `took`
    * 검색한 시간 (밀리 세컨드)
  * `timed_out`
    * 검색 시간 초과 여부
  * `_shared`
    * 검색된 파편의 수, 성공 및 실패한 파편의 수
  * `hits` (검색 결과)
    * `hits.total`
      * 검색 조건과 일치하는 총 문서
    * `hits.hits`
      * 검색 결과의 실제 배열 (초기 기본값은 10)
    * `hits.sort`
      * 결과 정렬 키 (점수순 정렬 시 누락)
* 본문 메서드 요청 방법
  ~~~
  POST /bank/_search
  {
    "query": { "match_all": {} }, "sort": [
      { "account_number": "asc" }
    ]
  }
  ~~~

`KIBANA`
* 소개
  * 엘라스틱서치와 함께 작동하도록 설계된 오픈소스 분석 및 시각화 플랫폼
    * 색인에 저장된 데이터를 검색, 보기 및 상호 작용
  * 고급 데이터 분석을 쉽게 수행하고 데이터를 다양한 차트나 테이블 및 앱에서 시각화
  * 간단한 브라우저 기반의 인터페이스를 통해 실시간으로 엘라스틱서치 쿼리의 변경 사항을 표시, 신속하게 동적 대시 보드를 공유
  * 설치가 간단함
* 데이터 준비
  * 매핑은 인덱스의 문서를 논리적 그룹으로 나누고 필드의 특성을 지정하는 것
    * 예를 들어 필드의 검색 가능성 또는 토큰화 여부, 별도의 단어로 분리되는지 여부 등
  * 데이터를 로드하기 전에 매핑을 먼저 수행할 것
    * 매핑을 수행하지 않으면 임의의 데이터 형태로 매핑됨
  * 엘라스틱서치의 데이터 타입
    * `keyword`
      * 키워드 필드는 분석되지 않음
      * 단일 단위로 처리 (문자열은 여러 단어가 포함됨)
    * `integer`
      * 정수형 데이터 타입
    * `geo_point`
      * 위도/경도 상 지리적 위치로 레이블을 지정
* 인덱스 패턴 정의
  * 엘라스틱서치에 로드된 각 데이터 세트에는 인덱스 패턴 존재
    * `shakespeare`
      * `shakespeare`란 인덱스 (`shakes*`)
    * `account`
      * `bank`란 인덱스
    * `logs`
      * `YYYY.MM.DD` 패턴의 날짜가 포함 (`logstash-2015.05*`)

파일 비트를 활용한 아파치 서버 로그 수집
* 우분투 환경의 아파치2 설치, 엑세스 로그 저장
* `Filebeat` 기능을 사용해 파일을 긁어옴
* `Logstash`는 `apache` 파싱 기능을 통해 데이터 필드를 각각 분할, 엘라스틱서치에 전송

## Chapter05

### 쿠버네티스 컨테이너 보안

시큐리티 컨텍스트
* 보안 컨텍스트
  * 서버 침해사고 발생 시 해당 사고에 관련된 권한을 최대한 축소하여 확대(확산) 방지
  * 상황에 따라 서비스 탈취 공격자가 모든 컨테이너 권한을 사용 가능
    * 침해 사고를 당한 서비스가 모든 권한(`root`, 노드 커널 기능 등)으로 동작하는 경우
    * 도커 `privileged` 등 (기본적으로 `unprivileged`)
  * 최소 권한 정책 등으로 취약점을 감소시킬 것
* 보안 컨텍스트 설정
  * 권한 상승 가능 여부 (`privileged`)
  * 프로세스 기본 `UID/GID`를 활용한 파일 등의 오브젝트 액세스 제어
    * 파드에 `UID`를 설정하면 모든 컨테이너에 적용
      * `securityContext` - `runAsUser`, `runAsGroup`, `fsGroup`
      * 컨테이너 내부에 유저 설정 시 이 설정이 가장 우선시 됨
  * `Linux Capabilities`를 활용한 커널 기능 추가
    * 적용 시 리눅스 커널에서 사용할 수 있는 권한 추가 설정 가능
  * 오브젝트에 보안 레이블을 지정하는 `SELinux (Security Enhanced Linux)` 기능
    * 모든 프로세스와 객체에 시큐리티 컨텍스트를 달아 관리하는 형태
    * 넷필터와 더불어 리눅스의 핵심 보안 기능 담당
      * 일반적으로 복잡하기 때문에 실무에서 제외되는 경우가 많음
  * `AppArmor`
    * 프로그램 프로필을 사용하여 개별 프로그램의 기능 제한
  * `Seccomp`
    * 프로세스의 시스템 호출을 필터링

네트워크 정책 사용
* 네트워크 정책 (`Network Policy`)
  * 파드 그룹이 서로 다른 네트워크 엔드포인트와 통신하는 방법 지정
  * `Network Policy` 리소스는 레이블을 사용해 파드 선택
  * 선택한 파드에 `허용되는 트래픽을 지정하는 규칙` 정의
  * 특정 파드를 선택하는 네임스페이스에 `Network Policy`가 있으면 해당 파드는 `Network Policy`에서 허용하지 않는 연결을 거부함
* 개별 사이트마다 또는 아키텍처마다 다를 수 있음
  * 정책을 다 다르게 가져갈 수 있기 때문에 자동화가 어려움
* 설정
  * 이그레스 (`Egress`)
    * 선택된 파드에서 나가는 트래픽에 대한 정책 설정
  * 인그레스 (`Ingress`)
    * 선택된 파드로 들어오는 트래픽에 대한 정책 설정
* 네트워크 정책이 겹치게 되는 경우
  * `OR` 연산을 수행해 하나라도 허용되는 정책에 포함되면 트래픽 허용

K8S 감사(`Aduit`) 기능 활성화
* K8S 감사 기능
  * 클러스터에서 발생하는 다양한 작업들에 대해 관리자가 모니터링을 하기 위해 `audit` 기능을 활성화
    * 실시간으로 각종 유저들이 사용하는 API 정보를 확인 가능
    * 보안 관련 레코드 세트를 시간순으로 저장
  * 클러스터는 사용자 정보와 K8S API를 사용하는 앱 및 컨트롤플레인 자체에서 발생하는 활동 감사(감시)
* `audit`를 통해 클러스터 관리자가 확인 가능한 정보
  * 무슨 일이 일어났는가?
  * 언제 일어났는가?
  * 누가 그것을 시작했는가?
  * 과거에 무슨 일이 있었는가?
  * 어디에서 관찰되었는가?
  * 어디에서 시작되었는가?
  * 결과는 어디로 흘러가는가?
* `kube-apiserver`를 통해 실행
  * 감사 레코드는 `kube-apiserver`를 통해 실행됨
  * 실행의 각 단계에 대한 각 요청은 감사 이벤트를 생성, 특정 정책에 따라 사전 처리되고 백엔드에 기록됨
  * 각 요청은 연결된 단계에 따라 기록하는 정보가 다름
  * 요청에 따른 기록 정보
    * `RequestReceived`
      * 감사 핸들러가 요청을 받자마자 실행되는 이벤트 단계
      * 핸들러 체인 아래로 위임되기 전에 생성되는 단계
    * `ResponseStarted`
      * 응답 헤더가 전송되었으나, 응답 본문이 전송되기 전 이벤트 단계
      * 이 단계는 장기 실행 요청(`watch` 등)에 대해서만 생성
    * `ResponseComplete`
      * 응답 본문이 완료되었으며 더 이상 바이트가 전송되지 않는 이벤트 단계
    * `Panic`
      * 패닉이 발생했을 때 생성되는 이벤트 단계
* 감사 정책
  * 기록해야 하는 이벤트와 포함해야 하는 데이터에 대한 규칙을 정의
  * 감사 정책 객체 구조는 `audit.k8s.io` API 그룹에 정의
  * 이벤트가 처리되면 규칙 목록과 순서대로 비교
  * 첫 번째로 일치하는 규칙은 이벤트의 감사 수준을 설정 (첫번째 작성된 규칙이 우선순위가 높음)
  * 감사 수준
    * `None`
      * 이 규칙과 일치하는 이벤트를 기록하지 않음
    * `Metadata`
      * 요청 메타데이터를 기록하지만 응답 본문은 기록하지 않음
        * 요청 사용자, 타임스탬프, 리소스, 동사 등
    * `Request`
      * 이벤트 메타데이터 및 요청 본문 기록 (응답 본문 X)
      * 리소스가 아닌 요청에는 적용되지 않음
    * `RequestResponse`
      * 이벤트 메타데이터 및 요청 본문 기록과 응답 본문을 기록
      * 리소스가 아닌 요청에는 적용되지 않음

`Trivy`를 활용한 컨테이너 취약점 진단
* 취약점을 진단(스캔)하는 도구 (오픈소스 프로젝트)
  * 컨테이너 이미지, 파일 시스템, Git 저장소, 미설정 구성 등
* OS 패키지(`알파인`, `RHEL`, `CentOS` 등), 언어별 패키지의 취약점 탐지
* 테라폼, DockerFile, K8S 같은 IaC 파일로 인프라를 스캔, 배포를 공격 위험에 노출시키는 잠재적 구성 문제 등을 검색하는 기능
  * `Iac`(`Infrastructure as Code`)는 수동 프로세스가 아닌 코드를 통해 인프라를 관리, 프로비저닝하는 것
* 바이너리를 설치하거나 컨테이너를 사용하는 등 다양한 간단한 방법으로 취약점 진단

`kube-bench`를 활용한 K8S 보안 점검
* `CIS`에서 클라우드에서 준수해야하는 다양한 보안 점검 리스트를 `benchmark`로 제공
  * `Center for Internet Security`
  * [CIS](https://www.cisecurity.org/benchmark/kubernetes/)
* `kube-bench`
  * 많은 사용자들이 K8S에 설정 취약성을 파악할 수 있도록 구성하는 것을 지원하는 오픈소스
    * `aquasecurity`에서 K8S에 사용할 수 있는 `kube-bench`를 구성
  * 모든 부분이 구현되어 있지는 않지만, 그래도 상당히 많은 부분이 자동화
  * 깃헙의 릴리즈 페이지를 통해 다양한 플랫폼에서 컴파일된 파일을 구성

`falco`를 활용한 K8S 컨테이너 보안 모니터링
* `falco`
  * 컨테이너 모니터링 도구
  * 클라우드 네이티브 런타임 보안 프로젝트
  * 사실상 K8S 위협 탐지 엔진
  * `CNCF`에 합류한 최초의 런타임 보안 프로젝트 (`CKS` 시험에도 나올 정도로 지원하는 프로젝트)
  * 리눅스의 `Sysdig`을 활용해 개발 (인큐베이션 수준 프로젝트)
  * 예기치 않은 앱 동작 감지, 런타임 시 위협에 대해 경고
* 호스트에 `falco` 설정 정보 확인
  * `log_syslog`
    * `true` 옵션은 `/var/log/syslog`에 falco 관련 로그를 함께 로깅한다는 것을 의미
  * `rules_file`
    * 이 섹션에는 실행 시 참조하는 룰의 위치가 명시됨

## 특강

### `Helm` 차트 튜토리얼

`Helm` 소개와 설치
* `Helm`
  * K8S 앱 관리를 지원하는 도구
  * 필요한 여러가지 `yaml` 파일, 컨피그맵, 파일 간 의존성 등을 하나의 패키지로 배포할 수 있도록 구성
    * 복잡한 K8S 앱을 정의, 설치, 업그레이드할 때 도움
    * 정의되어 있는 내용을 사용해 쉽게 구성
  * `CNCF` 졸업 프로젝트 (`Helm` 커뮤니티에서 유지 관리)
  * 최근에는 3버전 위주로 사용됨
* 특징
  * 복잡성 관리
    * 가장 복잡한 앱도 기술하고 앱을 반복적으로 설치 제공
  * 쉬운 업데이트
    * `Custom Hook`와 `in-place` 업그레이드 지원 (업그레이드 고통 경감)
  * 간단한 공유
    * 공용 또는 개인 서버에서 쉽게 버전관리와 공유, 호스팅 가능
  * 롤백
    * `Helm` 롤백을 사용하면 이전 버전 릴리스로 쉽게 롤백
* 구성
  * `Helm Client`
    * 헬름 클라이언트는 `kubeconfig`를 통한 질의 등을 위해 `kubectl`이 구성된 자리에 구성되어야 함
    * `Helm install` 명령을 사용하면 `K8S Apiserver`에 배포하게 됨
  * `Chart Repository`
    * 원하는 앱에 `yaml` 파일을 내려 받음
* 설치
  * K8S 클러스터에 엑세스해서 작업할 수 있는 환경이 구성된 곳에 설치
  * 호스트에 구성된 `kubectl`과 인증 설정이 있어야 정상적으로 동작
* 주의 사항
  * 헬름은 내부적으로 `PV`, `PVC` 등을 사용하기 때문에 `StorageClass`가 구성되어 있어야 함

헬름 차트 리포지터리 초기화
* 헬름은 외부에서 정의된 `yaml` 파일을 내려 받아 K8S에 앱을 배포
* `apt`, `yum` 과 같은 저장소를 별도로 두고 있음
* 외부 저장소를 `helm repo add` 명령으로 추가

## Chapter06

### K8S 모니터링

K8S 클러스터 컴포넌트 모니터링
* 모니터링 서비스 플랫폼
  * K8S의 메트릭 수집 모니터링 아키텍처에서 코어메트릭 파이프라인 경량화
  * 기존 `힙스터`를 `deprecated`하고 모니터링 표준으로 메트릭 서버(`metrics-server`) 도입
    * `metrics-server`는 별도 설치 필요
* 리소스 모니터링 도구
  * 클러스터 내 앱 성능을 검사
  * 각 레벨에서 앱의 리소스 사용량에 대한 상세 정보를 제공
  * 앱의 성능을 평가하고 병목 현상을 제거하여 전체 성능 향상을 도모
  * 종류
    * 리소스 메트릭 파이프라인 (불완전)
      * `kubectl top` 등 유틸리티 관련된 메트릭들로 제한된 집합을 제공
      * 단기 메모리 저장소인 `metrics-server`에 의해 수집
      * `metrics-server`는 모든 노드를 발견, `kubelet`에 CPU와 메모리 질의
      * `kubelet`은 `kubelet`에 통합된 `cAdvisor`를 통해 레거시 도커와 통합 후 `metrics-server` 리소스 메트릭으로 노출
      * `/metrics/resource/v1beta1` API를 사용
    * 완전한 메트릭 파이프라인
      * 보다 풍부한 메트릭에 접근
      * 클러스터의 현재 상태를 기반으로 자동으로 스케일링하거나 클러스터를 조정
      * 모니터링 파이프라인은 `kubelet`에서 메트릭을 가져옴
      * 대표적으로 `CNCF` 프로젝트인 메테우스가 있음
      * `custom.metrics.k8s.io`, `exteranl.metrics.k8s.io` API를 사용
* `metrics-server`
  * 메트릭스 서버는 K8S에서 리소스 메트릭 파이프라인을 구성하는 가장 기본적인 형태
  * 수동 설치 필요
    * `# kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.5.2/components.yaml`
* `HPA (Horizontal Pod Autoscaler)`

큐브 대시보드 설치와 사용
* 클러스터 용 범용 웹 기반 UI

프로메테우스 그라파나를 활용한 리소스 모니터링
* `SoundCloud`에서 구축된 오프소스 시스템 모니터링 및 경고 도구 키트
  * K8S 보다 오래됨
* 독립형 오픈소스 프로젝트
* K8S에 이어 두 번째 호스팅 프로젝트로 클라우드 네이티브 컴퓨팅 재단에 가입
* 메트릭을 타임시리즈 데이터(메트릭 정보 등)로 기록
* 레이블이라고 하는 선택적 키-밸류 쌍으로 기록된 타임스탬프와 함께 저장

`Istio`를 활용한 네트워크 `Mesh` 모니터링
* 다수의 컨테이너가 동작 시 모든 트래픽 관찰 및 정상 동작 모니터링이 어려움
* 개발자는 이식성을 위해 마이크로 서비스를 사용, 아키텍처 설계
* 운영자는 이 컨테이너들을 다양한 클러스터에 배포 및 관리
* 서비스 메시의 크기와 복잡성이 커짐에 따라 이해와 관리가 어려워짐
  * 예를 들어 로드 밸런싱, 장애 복구, 메트릭, 모니터링 등
* `Istio`는 K8S 환경의 네트워크 메시 이슈를 보다 간편하게 해결하기 위해 지원하는 환경

`EFK`를 활용한 K8S 로그 모니터링
* K8S에서 `EFK`를 사용하면 도커의 각 컨테이너 로그를 수집, 시각화, 분석 가능
* K8S 메모리 8GB 이상 필요
* 일반적으로엘라스틱스택은 주로 비츠 또는 로그스태시를 사용
* K8S에서는 `fluentd`를 사용해 수집하는 것이 트렌드
  * E (`Elasticsearch`)
    * 데이터 베이스 & 검색엔진
  * L (`Logstash`)
    * 데이터 수집기, 파이프라인 (F : `fluentd`를 대신 사용)
  * K (`Kibana`)
    * 그라파나의 역할, 대시보드 (`SIEM (Security information and event management)`, 머신러닝, `Alert`)

오토 스케일링 `HPA` 워크스루
* [연습 문서](https://kubernetes.io/ko/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/)
* 파드 스케일링의 두 가지 방법
  * HPA (`Horizontal Pod Autoscaler`)
    * 파드 자체를 복제, 처리할 수 있는 파드의 개수를 늘리는 방법
      * K8S에는 기본 오토스케일링 기능 내장
    * CPU 사용량을 관찰, `ReplicationController`, `Deployment`, `ReplicaSet`, `StatefulSet`의 파드 개수를 자동으로 스케일
      * 또는 사용자 정의 메트릭이나 다른 애플리케이션 지원 메트릭 등을 관찰
    * 크기를 조정할 수 없는 오브젝트(`DaemonSet` 등)에는 적용되지 않음
  * VPA (`Vertical Pod Autoscaler`)
    * 리소스를 증가시켜 파드의 사용 가능한 리소스를 늘리는 방법
  * CA (`Cluster Autoscaler`)
    * 번외로 클러스터 자체를 늘리는 방법 (노드 추가)

`Jaeger` 트레이싱 튜토리얼
* 마이크로 서비스를 위한 오픈소스 추적 시스템 (`OpenTracing` 표준 지원)
  * `예거`라고 발음
  * 처음에 `Uber Technologies`에 의해 오픈소스로 공개됨
  * 추적, 근본 원인 분석, 서비스 종속성 분석 등을 배포
  * 추적이 활성화된 소규모 서비스를 빌드해 튜토리얼 실습
* 용어
  * 에이전트
    * 사용자 데이터그램 프로토콜을 통해 전송된 범위에 대해 듣는 네트워크 데몬
  * 클라이언트
    * 분산 추적을 위해 `OpenTracing` API를 구현하는 구성 요소
  * 컬렉터
    * 범위를 수신하고 처리할 큐에 추가하는 구성 요소
  * 콘솔
    * 사용자가 분산 추적 데이터를 시각화할 수 있는 UI
  * 쿼리
    * 저장소에서 추적을 가져오는 서비스
  * 범위
    * 예거에서 작업의 논리적 단위 (이름, 시작 시간 및 작업의 기간 등을 포함)
  * 추적
    * 예거가 실행 요청을 제시하는 방식 (추적은 하나 이상의 범위로 구성)

## Chapter07

### K8S CI/CD

CI/CD 이해
* 기존에는 소프트웨어(서비스) 출시 또는 배포까지 오랜 준비과정이 필요
* 지속적 통합, 지속적 배포 (이를 위한 도구 포함)
* 이를 통해서 릴리스 시간과 주기 단축
  * 자동화된 파이프라인을 통해 코드 변경을 원활하게 진행 가능
* 장점
  * 출시 기간 단축
    * 애자일 및 데브옵스 기술 채택, 사용자에게 지속적인 개선 제공
    * 위험 감소, 검토 시간 단축
  * 코드 품질 개선
    * CI/CD 파이프라인의 핵심 기능 > 빌드할 때마다 실행되는 일련의 자동화 테스트
    * 프로덕션 환경으로 원활한 전환
    * 더 빠른 버그 수정
    * 효율적인 인프라
    * 진행 상황에 대한 평가 가능
    * 더 긴밀한 피드백 루프
    * 협업 및 커뮤니케이션
  * 창의력 극대화
* 도커와 K8S CI/CD 플랫폼 (프로세스)
  * 깃랩 리포지터리에 코드 푸시
  * 푸시 이벤트를 감지해 웹훅 리퀘스트를 사용해 젠킨스에 코드 전송
  * 젠킨스에서 빌드, 테스트 후 도커 레지스트리에 업로드
  * K8S 배포를 위한 매니페스트를 위해 두 번째 깃헙 리포지터리에 전송
  * 아르고를 사용해 실시간으로 현재 리포지터리와 클러스터 상태를 모니터링하고 비교, 조정

`harbor`를 활용한 컨테이너 레지스트리 구축
* `CNCF` 졸업 프로젝트 (오픈소스 레지스트리)
* 정책 및 역할 기반 엑세스 제어 제공
* 아티팩트 보호, 이미지 스캔 및 취악성 확인, 이미지 신뢰를 위한 서명
* 웹 대시보드 제공

도커를 활용한 `Jenkins` 설치와 CI 구성
* 어떤 규모로든 훌륭한 시스템을 구축하기 위한 도구
  * 선도적인 오픈소스 자동화 서버
  * 모든 프로젝트를 빌드, 배포 및 자동화하는 데 지원
  * 수백 개의 플러그인 제공

`Argo`를 활용한 CD 구축
* `Argo`는 K8S용 오픈소스 도구로 워크플로를 실행하고 클러스터를 관리 `GitOps` 수행
  * K8S의 CD를 담당, 컨테이너 네이티브 워크플로 엔진
  * 복잡한 워크플로 및 응용 프로그램의 실행을 쉽게 지정, 예약, 조정
* `Argo`의 워크플로 역할
  * 기존 CI/CD 파이프라인 역할
  * 순차적 및 병렬 단계와 종속성을 모두 갖춘 복잡한 작업 단순화
  * 복잡하고 분산된 응용 프로그램의 배포 오케스트레이션
  * 시간/이벤트 기반으로 워크플로 실행(정책)
* K8S에 `argo`를 배포하면 설치된 `kube-api`와 통신하며 클러스터를 관리

## Chapter08

### K8S MSA

MSA 소개
* 설명
  * 앱을 각자 책임이 명확한 작은 컴포넌트들로 분해, 이를 조합해 솔루션 제공
  * 각 컴포넌트는 작은 책임 영역을 담당하고 완전히 상호 독립적으로 배포
    * 마이크로 서비스는 비즈니스 영역의 한 부분의 책임만 담당
    * 여러 앱에서 재사용할 수 있어야 함
  * 소비자와 서비스 제공자 사이의 데이터 교환을 위해 `HTTP`, `JSON` 등과 같은 경량 통신 프로토콜 사용
    * 최근에는 `gRPC`, `GraphQL` 등의 비중도 높아짐
  * 앱은 항상 기술 중립적 프로토콜을 사용해 통신하기 때문에 서비스 구현 기술과는 무관
    * 마이크로 서비스 기반의 앱을 다양한 언어와 기술로 구축 가능
  * 작고 독립적이며 분산된 마이크로 서비스를 사용해 조직
    * 명확히 정의된 책임 영역을 담당하는 소규모 팀 형태
* 목적
  * 대규모 트래픽에도 중단되지 않는 가용성 높은 서비스 등의 결과를 기준으로 목적을 설명할 수 있어야 함
  * 동일한 이점을 주는 다른 방법도 많음
* 장점
  * 작은 서비스들로 나눠 각 서비스를 독립적으로 만듦 (`loosely coupled`)
  * 대용량 분산 환경에 적합
  * 복잡도 감소
  * 유연한 배포
  * 재사용성 > 확장성
  * 서비스별 hw/sw 플랫폼/기술의 도입 및 확장이 자유로움
  * 개발자가 이해하기 쉽고 개발/운영 매 단계의 생산성이 높음
  * CI/CD가 `biz cpapbility` 단위로 관련된 소수의 인원의 책임하에 이뤄짐
  * `Falut isolation` (장애 허용 시스템) 특성이 좋음
* 단점과 보완 방법
  * 장애 추적, 모니터링, 메시징 처리 어려움
    * `Sleuth` 등과 `ELK`, `EFK`, `Splunk` 등의 서비스를 연동하여 사용하는 방안 고려
  * 여러 서비스에 걸쳐 있는 기능의 경우 트랜잭션 처리 및 테스팅이 복잡함
    * 보상 트랜잭션 또는 부분적으로 `composite` 서비스로의 병합 고려
    * 지속적으로 테스팅 계획 및 방법 모색
  * 서비스간 의존성이 있는 경우 릴리스가 까다로움
    * 관련 개발 조직 간 `roll-out` 계획 마련과 의존성 관리 체계 수립
  * 서비스 수가 많고 유동적이기 때문에 CI/CD 및 서비스 관리상 문제의 여지가 꽤 있음
    * 서비스 레지스트리, 모니터링, 개발/디플로이 자동화 기술 고려 (`PaaS` 등)
  * 모놀리스 시스템에서 전환 시 리소스, 러닝 커브 등 비용이 높음
    * `B2C`, `SaaS` 앱 등은 처음부터 마이크로 서비스와 담당 조직을 고려하여 구성

`flask`를 활용한 웹페이지 렌더링
* 플라스크
  * 파이썬의 대표적인 웹 개발 프레임워크
  * 마이크로 프레임워크 (가볍고 간단함)
  * 지정한 라이브러리와 패키지만 설치됨 (효율성, 자유도 높음)
* 호출 과정
  * 특정 URL 호출
  * 뷰 함수 호출
  * 논리 실행
  * 논리 결과 응답 전송
  * 응답 값 HTML 표현
  * 클라이언트 전달
* `WSGI` (`Web Server Gateway Interface`)
  * `CGI`의 상위호환

사용하기 쉬운 REST API
* `Representational State Transfer`
  * HTTP URL로 자원을 명시, HTTP 메서드로 자원 접근 또는 서비스 요청
* 장점
  * HTTP 표준 프로토콜을 따르는 모든 프로토콜에서 사용 가능
  * 디자인 문제 최소화, 서버-클라이언트 간 역할 분리 용이
* 단점
  * 구버전 브라우저의 미지원때문에 제한적인 환경이 많음
* 특징
  * 서버와 클라이언트 구조
  * 무상태
  * 캐싱 처리 가능
  * 레이어드 아키텍처
* 구성
  * 도큐먼트
    * 데이터베이스 레코드
  * 컬렉션
    * 서버에서 관리하는 리소스 (디렉터리)
  * 스토어
    * 클라이언트에서 관리하는 리소스 저장소
* 설계 기본 규칙
  * 슬래시는 계층 관계를 의미
  * 가급적 언더바는 URI에 사용하지 않을 것을 권장
  * 대문자보다는 소문자 사용 권장
  * 가급적 파일 확장자는 포함하지 않을 것을 권장

`flask`를 활용한 REST API 구성
* [restfulapi](https://restfulapi.net/http-methods/)
