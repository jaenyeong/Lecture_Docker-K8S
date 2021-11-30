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
