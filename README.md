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
