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