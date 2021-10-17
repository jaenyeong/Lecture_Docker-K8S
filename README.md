# 도커/쿠버네티스 온라인 부트캠프 with 카카오엔터프라이즈
[교육과정 보기](https://classlion.net/class/detail/21)
* 도커/쿠버네티스 A-Z 모두 배우는 6개월 집중 부트캠프
* 6개월 교육 과정 내 강의 노트와 과제 업로드

## [Settings]
실습 환경
* 순서
  * VMware Fusion Player 설치 및 실행
  * VMware Fusion에 Ubuntu 운영체제 설치
  * Ubuntu에 Docker 설치

VMware Fusion Player – 12.1.2 (for Intel-based Macs) / Personal Use License - Binaries
* [설치](https://my.vmware.com/group/vmware/evalcenter?p=fusion-player-personal)

Ubuntu - Bionic Beaver 18.04.5(LTS)
* [설치](https://mirror.kakao.com/ubuntu-releases/bionic/)
  * `ubuntu-18.04.6-live-server-amd64.iso`
* 설치 시 mirror address 변경
  * `http://kr.archive.ubuntu.com/ubuntu >>> http://mirror.kakako.com/ubuntu (new)`
* 계정 설정
  ~~~
  username : jaenyeong
  password : ****
  ~~~
* 설치 완료 후 Vmware IP 확인 (ifconfig)
  * 172.16.248.2/24

SSH(Secure Shell) 접속 (22 포트)
* 접속 `sudo ssh jaenyeong@172.16.248.2`
* ssh config 설정
  * 편집기, 에디터 등으로 `~/.ssh/config` 실행, `HOSTNAME` 설정
    ~~~
    ## Docker&KBS
    Host docker_vm
    HostName 172.16.248.2
    user jaenyeong
    ~~~

Docker - Docker Engine on Ubuntu 20.10.8 (community)
* [설치](https://docs.docker.com/engine/install/ubuntu/)
* 로컬 터미널에서 SSH로 서버에 붙어 도커 설치 (위 SSH 접속방법대로 접속)
* 도커 저장소 설치 (저장소를 통해 도커 설치 및 업데이트 가능)
  ~~~
  [1] 패키지 매니저 업데이트
  $ sudo apt-get update

  $ sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
  > 계속 진행을 원하냐는 질문에 y 입력

  [2] 도커 공식 GPG 키 추가
  $ curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

  [3] 안정화 버전의 저장소를 위한 설정
  $ echo \
    "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  ~~~
* 도커 엔진 설치
  ~~~
  [1] 패키지 매니저 업데이트
  $ sudo apt-get update

  [2-1] 최신 버전의 도커 엔진 설치
  $ sudo apt-get install docker-ce docker-ce-cli containerd.io
  > 계속 진행을 원하냐는 질문에 y 입력

  [2-2] 특정 버전의 도커 엔진 설치
  $ apt-cache madison docker-ce
  [or]
  $ sudo apt-get install docker-ce=<VERSION_STRING> docker-ce-cli=<VERSION_STRING> containerd.io

  [3] 정상적으로 도커 엔진이 설치 되었는지 확인
  $ sudo docker version
  $ sudo docker system info

  [4] 헬로우월드 이미지를 실행해 정상적으로 설치 되었는지 확인
  $ sudo docker container run hello-world
  ~~~

kakao i cloud - `Virtual Machine` 인스턴스 생성
* 레드햇(안정성), 우분투(빠른 기술 확장)
* 센토스는 레드햇과 비슷 > 현재 카카오는 센토스를 많이 사용함
* 기본(마스터) 인스턴스 생성
  * 인스턴스명 (3개 생성)
    * `kjn-master-01`
    * `kjn-master-02`
    * `kjn-master-03`
  * 인스턴스 설명
    * `수강생 김재녕`
  * 인스턴스 타입
    * `a1.2c4m` (기본) 선택
  * 볼륨 타입 크기
    * `10` GiB
  * 키페어
    * `kjn01` 이름으로 키페어 생성, 다운로드
  * 네트워크 구성
    * 네트워크 `likelion-private01` 선택
      * 서브넷 `likelion-private01 (172.30.4.0/22)`
        * 사용 중인 `IP` 125개, 사용 가능한 `IP` 1008개
    * `public` 선택 시 아직 카카오에서 외부에서 접근할 공개 `IP` 포워딩 기능이 구현되지 않은 듯함
  * 시큐리티 그룹
    * 인바운드
      * default (프로토콜 - all), (패킷 출발지 - @default), (포트 번호 - all)
      * default (프로토콜 - tcp), (패킷 출발지 - 0.0.0.0/0), (포트 번호 - all)
      * default (프로토콜 - tcp), (패킷 출발지 - 0.0.0.0/0), (포트 번호 - 22)
    * 아웃바운드
      * default (프로토콜 - all), (패킷 출발지 - @default), (포트 번호 - all)
      * default (프로토콜 - icmp), (패킷 출발지 - 0.0.0.0/0), (포트 번호 - all)
* 워커 인스턴스 생성
  * 인스턴스명 (2개 생성)
    * `kjn-worker-01`
    * `kjn-worker-02`
  * 인스턴스 설명
    * `수강생 김재녕`
  * 인스턴스 타입
    * `a1.2c4m` (기본) 선택
  * 볼륨 타입 크기
    * `20` GiB
  * 키페어
    * 위 인스턴스와 동일한 키페어 사용
  * 네트워크 구성
    * 네트워크 `likelion-private01` 선택
      * 서브넷 `likelion-private01 (172.30.4.0/22)`
        * 사용 중인 `IP` 133개, 사용 가능한 `IP` 1008개
    * `public` 선택 시 아직 카카오에서 외부에서 접근할 공인 `IP` 포워딩 기능이 구현되지 않은 듯함
  * 시큐리티 그룹
    * 인바운드
      * default (프로토콜 - all), (패킷 출발지 - @default), (포트 번호 - all)
      * default (프로토콜 - tcp), (패킷 출발지 - 0.0.0.0/0), (포트 번호 - all)
      * default (프로토콜 - tcp), (패킷 출발지 - 0.0.0.0/0), (포트 번호 - 22)
    * 아웃바운드
      * default (프로토콜 - all), (패킷 출발지 - @default), (포트 번호 - all)
      * default (프로토콜 - icmp), (패킷 출발지 - 0.0.0.0/0), (포트 번호 - all)
* `Virtual Machine IP`
  * `kjn-master-01` - `172.30.5.108`
  * `kjn-master-02` - `172.30.4.36`
  * `kjn-master-03` - `172.30.7.28`
  * `kjn-worker01` - `172.30.6.245`
  * `kjn-worker02` - `172.30.7.0`
* 사설 `IP`로 인스턴스 생성 테스트

환경 구성
* `공인 IP` - `사설 IP`
  * 연결 방법
    * 전용선
    * VPN
  * 클래스 A
    * 10.0.0.0 ~ 10.255.255.255 (10.0.0.0/8)
  * 클래스 B
    * 172.16.0.0 ~ 172.31.255.255 (172.16.0.0/12)
  * 클래스 C
    * 192.168.0.0 ~ 192.168.255.255 (192.168.0.0/16)
* `Bastion Host`
  * 중간 연결 프록시 (로드 밸런서)
  * 일반적으로 신뢰할 수 없는 네트워크 차단 등이 목적
  * 어떤 `공인 IP` 든지 허가되었다면 카카오 내부 망에 접속 가능하게 포워딩 서버 (터널링)
* `Open VPN`
  * 패킷 외부
    * `PC 공인 IP (OpenVPN Client)` - `Bastion Host 공인 IP (OpenVPN Server)`
  * 패킷 내부 (`OpenVPN` 양쪽 끝까지 도착했을 때)
    * `카카오 사설 대역을 받은 PC` - `카카오 사설 IP를 가진 카카오 오브젝트(카카오 클라우드)`
  * 정리하면 VPN 별로 `사설 IP`를 할당받는 것과 같음
  * VPN 다운로드
    * (다운로드 링크)[https://tunnelblick.net/downloads.html] 설치
      * `stable`
    * `.ovpn` 파일(`jaenyeong.dev@gmail.com.ovpn`)을 사용해 연결
      * `.ovpn`, `ta.key` 파일을 같은 경로에 위치
  * 카카오 사설망을 제외한 대역은 일반 네트워크로 전송
* 라우팅 설정
  * Public Subnet
    * `$ sudo route add -net 172.30.0.0 -netmask 255.255.252.0 10.8.0.1`
  * Private Subnet
    * `$ sudo route add -net 172.30.4.0 -netmask 255.255.252.0 10.8.0.1`
  * K8S API 서버 엔드포인트에 라우팅 룰 적용
    * `$ sudo route add -net [API 서버 엔드포인트 주소] -netmask 255.255.255.255 10.8.0.1`
    * API 엔드포인트가 K8S 엔진을 활용할 경우 필요 (따라서 생략)
  * 라우팅 확인
    * `$ netstat -nr | grep 10.8.`
  * 맥은 윈도우와 다르게 재부팅할 때마다 반복 입력해야 함
    * `kakao_vpn_route.sh` 파일 생성, 부팅할 때마다 실행 (`settings` 경로에 보관)
      ~~~bash
      sudo route add -net 172.30.0.0 -netmask 255.255.252.0 10.8.0.1
      sudo route add -net 172.30.4.0 -netmask 255.255.252.0 10.8.0.1
      netstat -nr | grep 10.8.
      ~~~

접속 확인
* `$ ssh -i [pem 파일 경로] [계정]@[kakao i cloud Virtual Marchine Private IP]`
  * `$ ssh -i kjn01.pem centos@172.30.5.108`
  * `IP`는 `kakao i` 접속, 확인 후 입력
  * `pem` 파일 권한이 없는 경우 (`chmod 400 or 600`)
    * `$ chmod 400 kjn01.pem` or `$ chmod 600 kjn01.pem`
* 편리한 `ssh` 접속을 위해 `/.ssh/config` 파일에 설정
  ~~~
  ## Docker&KBS kakao i cloud (kjn-master-01)
  Host kakao_m_01
  HostName 172.30.5.108
  user centos
  IdentityFile /Users/kimjaenyeong/Documents/Lecture_Docker_K8S/settings/kjn01.pem

  ## Docker&KBS kakao i cloud (kjn-master-02)
  Host kakao_m_02
  HostName 172.30.4.36
  user centos
  IdentityFile /Users/kimjaenyeong/Documents/Lecture_Docker_K8S/settings/kjn01.pem

  ## Docker&KBS kakao i cloud (kjn-master-03)
  Host kakao_m_03
  HostName 172.30.7.28
  user centos
  IdentityFile /Users/kimjaenyeong/Documents/Lecture_Docker_K8S/settings/kjn01.pem

  ## Docker&KBS kakao i cloud (kjn-worker-01)
  Host kakao_w_01
  HostName 172.30.6.245
  user centos
  IdentityFile /Users/kimjaenyeong/Documents/Lecture_Docker_K8S/settings/kjn01.pem

  ## Docker&KBS kakao i cloud (kjn-worker-02)
  Host kakao_w_02
  HostName 172.30.7.0
  user centos
  IdentityFile /Users/kimjaenyeong/Documents/Lecture_Docker_K8S/settings/kjn01.pem
  ~~~

강사님의 `Public key`를 생성한 인스턴스(VM)에 세팅 (평가를 위해 필수)
* 가급적 모든 인스턴스에 추가할 것
  * `kjn-master-01`
  * `kjn-master-02`
  * `kjn-master-03`
  * `kjn-worker-01`
  * `kjn-worker-02`
* `$ sudo yum install -y wget`
  * 또는 `$ sudo apt-get install -y wget`
* `$ wget http://172.30.5.154/instructor.pub`
* `$ cat instructor.pub >> ~/.ssh/authorized_keys`

K8S 설치 (kakao i cloud VM instance)
* 설치 전 접속
  * 생성해둔 라우트 셸 스크립트 실행하여 추가 `$ ./kakao_vpn_route.sh`
  * 마스터 1번 노드 `ssh` 접속 `$ ssh kakao_m_01`
* HAProxy 설치 설정
  * 마스터 1번 노드
    * 명령 실행
    ~~~
    # 0은 permissive 모드, 1은 enforce 모드
    # permissive는 정책에 어긋나는 동작이어도 허용하며 로그를 남김
    # enforce는 정책에 어긋나는 동작은 모두 차단 (SELinux)
    $ sudo setenforce 0
    $ sudo yum install haproxy -y

    $ sudo vi /etc/haproxy/haproxy.cfg
    ~~~
    * `haproxy.cfg` 파일에 내용 추가 (`shift + g` 버튼으로 맽 밑으로)
      ~~~
      # 위 명령 사이에 공백라인 확인할 것
      frontend kubernetes-master-lb
       # 앞에 한칸 공백 확인할 것
       bind 0.0.0.0:16443
       option tcplog
       mode tcp
       default_backend kubernetes-master-nodes

      backend kubernetes-master-nodes
       # 앞에 한칸 공백 확인할 것
       mode tcp
       balance roundrobin
       option tcp-check
       option tcplog
       # 생성한 마스터노드 Private IP 주소
       server master1 172.30.5.108:6443 check
       server master2 172.30.4.36:6443 check
       server master3 172.30.7.28:6443 check
      ~~~
    * 수정 내용 반영
      * `$ sudo systemctl daemon-reload && sudo systemctl restart haproxy`
    * `16443` 포트가 `Listen` 상태인지 확인
      * `$ netstat -nltp` or `$ sudo ss tnlp`
      * 결과
        ~~~
        (No info could be read for "-p": geteuid()=1000 but you should be root.)
        Active Internet connections (only servers)
        Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name
        tcp        0      0 0.0.0.0:22              0.0.0.0:*               LISTEN      -
        tcp        0      0 0.0.0.0:16443           0.0.0.0:*               LISTEN      -
        tcp        0      0 0.0.0.0:5000            0.0.0.0:*               LISTEN      -
        tcp6       0      0 :::22                   :::*                    LISTEN      -
        ~~~
* `Kubeadm` 설치
  * [Kubeadm 링크](https://kubernetes.io/ko/docs/setup/production-environment/tools/kubeadm/install-kubeadm/)
    * 배포 도구 중 하나로 클러스터 구축 도구
  * 모든 노드
    * 각 노드 `ssh` 접속 > `kakao_m_01`, `kakao_m_02`, `kakao_m_03`, `kakao_w_01`, `kakao_w_02`
    * 호스트명 확인
      * `$ hostname`
    * `/etc/hosts` 파일 수정
      * `$ sudo vi /etc/hosts` > 노드명, IP 등 입력
      ~~~
      172.30.5.108 kjn-master-01.kr-central-1.c.internal kjn-master-01
      172.30.4.36	 kjn-master-02.kr-central-1.c.internal kjn-master-02
      172.30.7.28	 kjn-master-03.kr-central-1.c.internal kjn-master-03
      172.30.6.245 kjn-worker-01.kr-central-1.c.internal kjn-worker-01
      172.30.7.0	 kjn-worker-02.kr-central-1.c.internal kjn-worker-02
      ~~~ 
      * 각 노드에서 `ping` 으로 확인
        * `$ ping -c 1 kjn-master-01.kr-central-1.c.internal`
        * `$ ping -c 1 kjn-master-02.kr-central-1.c.internal`
        * `$ ping -c 1 kjn-master-03.kr-central-1.c.internal`
        * `$ ping -c 1 kjn-worker-01.kr-central-1.c.internal`
        * `$ ping -c 1 kjn-worker-02.kr-central-1.c.internal`
        * `$ ping -c 1 kjn-master-01`
        * `$ ping -c 1 kjn-master-02`
        * `$ ping -c 1 kjn-master-03`
        * `$ ping -c 1 kjn-worker-01`
        * `$ ping -c 1 kjn-worker-02`
    * `iptables`가 브리지된 트래픽을 보게 하기
      * 모든 노드에 `br_netfilter` 모듈이 로드되었는지 확인
        * `$ lsmod | grep br_netfilter`
        * 명시적으로 로드 `$ sudo modprobe br_netfilter`
      ~~~
      cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
      br_netfilter
      EOF

      cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
      # 1 값이 활성화
      net.bridge.bridge-nf-call-ip6tables = 1
      net.bridge.bridge-nf-call-iptables = 1
      EOF
      sudo sysctl --system
      ~~~
    * 컨테이너 런타임(`Container Runtime Interface`) 설치 
      * `CRI` - 도커 이외에도 다양한 컨테이너 런타임을 지원하기 위한 인터페이스
      * 장치 매퍼 저장소 드라이버(`device-mapper-persistent-data lvm2`) 의존성 추가
        * `$ sudo yum install -y yum-utils device-mapper-persistent-data lvm2`
      * 도커 저장소 활성화 (추가) 및 확인
        * `$ sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo`
        * `$ cat /etc/yum.repos.d/docker-ce.repo`
      * `docker-ce` 설치
        * `$ sudo yum install docker-ce -y`
      * `container runtime cgroup driver` 및 `kubelet cgroup driver` 설정 (수정)
        * `docker.service` 설정 열기
          * `$ sudo vi /usr/lib/systemd/system/docker.service`
          * 기존 `ExecStart` 옵션에 `--exec-opt native.cgroupdriver=systemd` 추가
            * `ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd containerd.sock` 뒤에 추가
            ~~~
            ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd containerd.sock --exec-opt native.cgroupdriver=systemd
            ~~~
      * 위 설정 적용 (리로딩)
        * `$ sudo systemctl daemon-reload`
      * 설정 적용 후 도커 재시작
        * `$ sudo systemctl start docker && sudo systemctl enable docker`
        * 도커 재시작 명령 및 서버가 재기동 후 도커 자동시작 설정
      * `cgroup` 설정 확인
        * `$ sudo docker info | grep -i cgroup`
          ~~~
          Cgroup Driver: systemd
          Cgroup Version: 1
          ~~~
    * `kubeadm`, `kubelet` 및 `kubectl` 설치 (필수 프로그램)
      * 개념
        * `kubeadm`
          * 클러스터를 부트스트랩하는 명령
        * `kubelet`
          * 클러스터의 모든 머신에서 실행되는 파드와 컨테이너 시작과 같은 작업을 수행하는 컴포넌트
        * `kubectl`
          * 클러스터와 통신하기 위한 커맨드 라인 유틸리티
      * `Redhat` 기반 배포판 설치
        * `centos`는 `redhat`과 거의 유사하기 때문에 `redhat` 설치
        ~~~
        cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
        [kubernetes]
        name=Kubernetes
        baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
        enabled=1
        gpgcheck=1
        repo_gpgcheck=1
        gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
        exclude=kubelet kubeadm kubectl
        EOF
        ~~~
        * `Permissive` 모드로 `SELinux(Security-Enhanced Linux)` 설정 (효과적으로 비활성화)
          * `$ sudo setenforce 0`
            * `$ sudo getenforce` 명령으로 현재 모드 확인 가능
              * `Permissive` 모드가 아니라 `Enforcing`과 같은 다른 모드인 경우 실행
          * `$ sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config`
            * `SELinux`
              * 보안 강화 리눅스로 시스템 액세스 권한을 효과적으로 제어하는 보안 아키텍처
              * 현실적으로 사용하기 어려운 부분이 다소 있어 다른 보안 정책을 사용하는 경우가 흔함
                * 따라서 리부팅 하더라도 `SELinux`를 `Enforcing`에서 `Permissive`로 적용되게 변경
            * 직접 vi 에디터로 수정 가능
              * `$ vi /etc/selinux/config`
        * 처음에 `kubeadm`, `kubelet`, `kubectl`를 한단계 낮은 버전으로 설치
          * 교육 과정 중 최신 버전 업그레이드 내용을 포함하기 때문에 나중에 최신 버전으로 버전 업 예정
            * 기존 버전 확인
              * `$ sudo yum info kubelet --disableexcludes=Kubernetes -y`
            * `kubeadm`, `kubelet`, `kubectl` 설치
              * `$ sudo yum install kubelet-1.21.0 --disableexcludes=kubernetes -y`
              * `$ sudo yum install kubectl-1.21.0 --disableexcludes=kubernetes -y`
              * `$ sudo yum install kubeadm-1.21.0 --disableexcludes=kubernetes -y`
            * 서버 리로딩 후에도 `kubelet` 자동 실행 적용
              * `$ sudo systemctl enable --now kubelet`
          * 최신 버전 설치하는 경우 (문서 내용)
            * `$ sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes`
              * 한 번에 설치
            * `$ sudo systemctl enable --now kubelet`
        * `kubeadm.conf` 파일 `Environment` 옵션에 추가
          * `$ sudo vi /usr/lib/systemd/system/kubelet.service.d/10-kubeadm.conf`
            ~~~
            [Service]
            Environment="KUBELET_CGROUP_ARGS=--cgroup-driver=systemd --runtime-cgroups=/systemd/system.slice --kubelet-cgroups=/systemd/system.slice"
            ~~~
          * 추가 후 `daemon reload`, `kubelet restart` 수행
            * `$ sudo systemctl daemon-reload`
            * `$ sudo systemctl restart kubelet`
  * `kubeadm`을 사용해 클러스터 생성
    * [링크](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/high-availability/)
    * 마스터 1번 노드만 `Stacked control plane and etcd nodes` 설치
      * `$ sudo kubeadm init --pod-network-cidr=192.168.0.0/16 --control-plane-endpoint "$[MASTER1IP]:16443" --upload-certs`
        * `$ sudo kubeadm init --pod-network-cidr=192.168.0.0/16 --control-plane-endpoint "172.30.5.108:16443" --upload-certs`
        * `init --pod-network-cidr=192.168.0.0/16`는 `Calico` 활용 예정
          * 교육 과정 당시 `centos`에서 파드 간 통신하는 플러그인 중 `Calico(서드파티)`만 검증되어 사용
          * `kubeadm` 설치 시 자동으로 설치되지 않음 (별개의 서드파티 프로젝트)
          * `kubeadm` 설치 시 기본으로 설치되는 것
            * `CoreDNS`
              * `DNS` 매핑 역할 (계속 변경되는 파드의 `IP` 매핑 관리)
        * `--control-plane-endpoint` `HA prxoy`가 설치된 마스터 1번 노드의 해당 포트
        * `--upload-certs`는 인증서를 전달하여 손쉽게 구성
      * `$ sudo kubeadm init --control-plane-endpoint "LOAD_BALANCER_DNS:LOAD_BALANCER_PORT" --upload-certs`
      * 완료 메시지 `Your Kubernetes control-plane has initialized successfully!`
      * 완료 후 별도 저장 `$ vi finish.txt`
        ~~~
        # 클러스터 사용을 위해 적용하라는 의미
        To start using your cluster, you need to run the following as a regular user:

          mkdir -p $HOME/.kube
          sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
          sudo chown $(id -u):$(id -g) $HOME/.kube/config

        Alternatively, if you are the root user, you can run:

          export KUBECONFIG=/etc/kubernetes/admin.conf

        You should now deploy a pod network to the cluster.
        Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
          https://kubernetes.io/docs/concepts/cluster-administration/addons/

        You can now join any number of the control-plane node running the following command on each as root:

          kubeadm join 172.30.5.108:16443 --token 96zifn.hav80stwul4myqaj \
          --discovery-token-ca-cert-hash sha256:0cdba50fb8008c89e61925156a7158f11cd15baf295586184ac7d903deeb6054 \
          --control-plane --certificate-key 27b77419ec104ce2679b1f55ac9d699a318d5c0fc1f1724781b1f7eeb3938835

        Please note that the certificate-key gives access to cluster sensitive data, keep it secret!
        As a safeguard, uploaded-certs will be deleted in two hours; If necessary, you can use
        "kubeadm init phase upload-certs --upload-certs" to reload certs afterward.

        Then you can join any number of worker nodes by running the following on each as root:

        kubeadm join 172.30.5.108:16443 --token 96zifn.hav80stwul4myqaj \
          --discovery-token-ca-cert-hash sha256:0cdba50fb8008c89e61925156a7158f11cd15baf295586184ac7d903deeb6054
        ~~~
      * `.kube` 생성
        * `$ mkdir -p $HOME/.kube`
      * 어드민 설정 파일 복사
        * `$ sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config`
      * 복사한 컨피그(설정) 파일 권한 변경
        * `$ sudo chown $(id -u):$(id -g) $HOME/.kube/config`
      * `root`로 계정 전환 후 적용
        * `$ sudo su -`
        * `$ cp /home/centos/.kube/config ~/.kube/config`
        * `$ cd .kube`
        * `config`는 인증 관련 내용, `kubectl` 등을 사용할 수 있음
      * `curl` 호출해 `calico.yaml` 파일 다운로드 및 이동, 확인
        * `$ curl https://docs.projectcalico.org/manifests/calico.yaml -O`
        * `$ mv calico.yaml ~`
        * `$ cat calico.yaml`
      * `kubectl` 확인
        * `$ kubectl get nodes` or `$ kubectl get nodes -o wide`
      * K8S에 필요한 것 중 없는 것들은 `yaml` 파일로 생성하여 추가
        * `$ kubectl apply -f calico.yaml`
    * 마스터 2, 3번 노드
      * 뒤에 명령으로 다른 마스터 노드(컨트롤 플레인) 루트 계정에서 설정할 수 있음을 의미
        * `$ sudo su -` 명령으로 루트 전환 후 아래 명령 실행
        ~~~
        You can now join any number of the control-plane node running the following command on each as root:
        
        # 아래 명령을 마스터 2, 3번 노드에서 루트 계정으로 전환 후 실행
          kubeadm join 172.30.5.108:16443 --token 96zifn.hav80stwul4myqaj \
          --discovery-token-ca-cert-hash sha256:0cdba50fb8008c89e61925156a7158f11cd15baf295586184ac7d903deeb6054 \
          --control-plane --certificate-key 27b77419ec104ce2679b1f55ac9d699a318d5c0fc1f1724781b1f7eeb3938835
        ~~~
      * `kubectl` 확인
        * `$ kubectl get nodes` or `$ kubectl get nodes -o wide`
    * 워커 1, 2번 노드
      * 뒤에 명령으로 다른 워커 노드 루트 계정에서 설정할 수 있음을 의미
        * `$ sudo su -` 명령으로 루트 전환 후 아래 명령 실행
        ~~~
        Then you can join any number of worker nodes by running the following on each as root:

        # 아래 명령을 워커 1, 2번 노드에서 루트 계정으로 전환 후 실행
        kubeadm join 172.30.5.108:16443 --token 96zifn.hav80stwul4myqaj \
          --discovery-token-ca-cert-hash sha256:0cdba50fb8008c89e61925156a7158f11cd15baf295586184ac7d903deeb6054
        ~~~

`Kubectl`
* K8S 클러스터를 제어하기 위한 CLI
* `$ kubectl[command][TYPE][NAME][flags]`
  * `command`
    * 명령을 하려는 동사 (create, get, describe, delete)
  * `TYPE`
    * 리소스 타입
  * `NAME`
    * 리소스명
  * `flags`
    * 선택적 옵션
* `$ kubectl help` (`--help`)
* 자주 사용되는 `output flags`
  * `-o wide`
  * `-o yaml`
  * `-o json`
  * `--sort-by=<jsonpath_exp>`
  * `--dry-run=client -o yaml > filename.yaml`
* 예시
  * `$ kubectl run test --image=nginx --dry-run=client -o yaml > 1.yaml`
  * `$ kubectl apply -f 1.yaml`
  * `$ kubectl get pod`

인증서
* `Preflight-check` 완료 후 `kubeadm`은 CA(자체 인증) 파일과 키를 생성
  * 키 위치 (`/etc/kubernetes/pki`)
* `$ ll /etc/kubernetes/pki` 명령으로 목록 확인
  * `.crt` : 서버 인증서
  * `.key` : 서버 개인키

자동 완성 설정
* [링크](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#install-bash-completion)
* `Bash` 설정
  ~~~
  # bash-completion 패키지를 먼저 설치
  sudo yum install -y bash-completion
  # bash의 자동 완성 셸에 설정 
  source /usr/share/bash-completion/bash_completion
  # 자동 완성을 bash 셸에 영구적으로 추가
  echo "source <(kubectl completion bash)" >> ~/.bashrc
  # root권한으로 실행
  kubectl completion bash >/etc/bash_completion.d/kubectl
  ~~~
* `Zsh` 설정
  ~~~
  # 현재 셸에 zsh의 자동 완성 설정
  source <(kubectl completion zsh)
  # 자동 완성을 zsh 셸에 영구적으로 추가
  echo "[[ $commands[kubectl] ]] && source <(kubectl completion zsh)" >> ~/.zshrc
  ~~~