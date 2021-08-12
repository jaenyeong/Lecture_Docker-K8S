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

# 배운 점

## Chapter01
Intro

## Chapter02
도커 간단 정의
* 도커는 컨테이너에서 앱을 실행, 운영할 수 있도록 도와주는 플랫폼
* 도커는 IaaS, PaaS의 단점을 보완
  * IaaS는 이식성은 좋으나 불필요한 자원 사용에 대한 비용과 리소스 증가
  * PaaS는 비용과 리소스가 저렴하나 특정 클라우드에 종속된 앱을 마이그레이션 하기 쉽지 않음
* 설정은 PDF 파일 참조

컨테이너와 MSA(Micro Service Architecture)
* 컨테이너
  * Host OS에 앱의 실행 공간을 각각 구성하여 IP, 디렉터리 등을 분리시켜 놓은 것
* MSA
  * 앱 별로 요구되는 환경을 배타적으로 세팅한 각 컨테이너를 통합하여 구축한 큰 시스템

레지스트리(도커 이미지 저장소)
* 도커허브
  * 깃허브처럼 공개된 도커 레지스트리

도커 역할
* 앱이 실행되는데 필요한 각종 리소스들을 한데 묶어 하나의 이미지로 생성
  * OS, 미들웨어, 네트워크 설정 등
* 생성된 이미지를 컨테이너 실행에 사용

도커 정의 정리
* 도커는 앱과 앱의 실행 환경을 정의한 이미지를 생성, 공유
* 이와 동시에 생성한 이미지를 기반으로 컨테이너를 작동할 수 있도록 하는 플랫폼
* 개발, 테스트, 스테이징, 운영 등 각기 다른 환경 설정에 도움을 줌
* 또한 개발자가 배포까지 수행할 수 있는 환경 구축도 도와줌

## Chapter03
도커 컨테이너
* 앱이 실행되는 환경, 의존성, 정보 등을 담고 있음
* 컨테이너는 도커가 설정한 네트워크 설정 및 저장장치 등으로 구성
* 기본적으로 OS가 없음
* 각각의 컨테이너 안에 앱은 독립된 영역을 보장 받음

도커 엔진
* 이미지 및 컨테이너를 생성하고 실행하는 코어 기능을 수행하는 컴포넌트
* 일반적으로 '도커' 라는 용어는 도커 컴포넌트 중에 도커 엔진을 가리킴

도커 컴포넌트
* Docker Registry
  * 이미지 공유
* Docker Compose
  * 멀티 컨테이너 통합 관리
* Docker Machine
  * 클라우드 환경에서 도커 실행 환경 명령을 내려 설치(생성) 및 제어
* Docker Swarm
  * 클러스터 관리
  * 현재는 쿠버네티스가 표준으로 자리 잡아 스웜 대신 사용 (대체제)

자주 쓰이는 도커 실행 (컨테이너) 기본 명령어
* `run` (create + start) : 컨테이너 생성과 동시에 실행
  * `$ sudo docker container run -d -p 80:80 --name apache httpd:latest`
  * 이미 이미지를 가지고 있는 경우 충돌 발생
* `create` : 컨테이너만 생성
* `start` : 이미 생성된 컨테이너를 실행
  * `$ sudo docker container start apache`
* `-it` : `-i` + `-t`
  * `-i` (--interative) : 표준 입력창을 엶
  * `-t` (--tty) : 장치에 tty를 할당
  * `-it` 명령어를 붙이지 않으면 cli로 컨테이너 제어 불가능
* `--name` : 컨테이너의 이름 설정
  * 해당 명령으로 컨테이너의 이름을 직접 지정하지 않으면 무작위(임의로 조합)로 설정됨
* `rename` : 컨테이너 이름 재설정
  * `$ sudo docker rename [my_container] [my_new_container]`
  * `$ sudo docker rename apache apache_server`
* `-d` (--detach) : 컨테이너를 백그라운드에서 실행
* `-p` (--publish) : 호스트/컨테이너 간에 포트포워딩 세팅
  * `$ sudo docker -p [docker port]:[local port]`
  * 백그라운드에 한정된 명령은 아님
* `exec` : 컨테이너 외부에서 컨테이너 내부의 프로세스 실행
  * `$ sudo docker container exec -it apache /bin/echo "Hello, Docker!"`
  * `$ sudo docker container exec -it apache bash`
* `logs` : 로그 출력
* `stop` : 컨테이너 중지
  * `$ sudo docker container stop apache`
* `restart` : 컨테이너 재시작(종료 후)
  * `$ sudo docker container restart apache`
* `attach` : 구동 중인 컨테이너에게 연결
  * `$ sudo docker container attach apache`
* `top` : 컨테이너 내부의 구동중인 프로세스 확인
  * `$ sudo docker container top apache`
* `stats` : 컨테이너 구동 확인
  * `$ sudo docker container stats apache`
  * `$ sudo docker container stats apache --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"`
* `ls` : 컨테이너 목록 조회
  * `$ sudo docker container ls`
* `cp` : 컨테이너 내부에 파일 복사
  * `sudo docker cp [OPTIONS] SRC_PATH|- CONTAINER:DEST_PATH`
  * `$ sudo docker container cp apache:/usr/local/apache2/htdocs/index.html /tmp/index.html`
  * `$ sudo docker container cp /tmp/index.html apache:/usr/local/apache2/htdocs/index.html`
* `diff` : 컨테이너 변경 사항 확인
  * `$ sudo docker diff apache`
  * A(added), C(changed), D(deleted)
  ~~~
  C /usr
  C /usr/local
  C /usr/local/apache2
  C /usr/local/apache2/htdocs
  C /usr/local/apache2/htdocs/index.html
  C /usr/local/apache2/logs
  A /usr/local/apache2/logs/httpd.pid
  C /root
  A /root/.bash_history
  ~~~

컨테이너의 종류
* 대화형 컨테이너
  * 실시간으로 리소스를 모니터링 하는 것과 같이 CLI를 직접 사용하는 경우
  * 최신 버전의 센토스 이미지를 사용하여 컨테이너 생성하여 실행
    ~~~
    $ sudo docker container run --interative --tty --name centos centos:latest
    $ sudo docker container run -i -t --name centos centos:latest
    $ sudo docker container run -it --name centos centos:latest
    모두 동일한 명령어
    ~~~
    * 센토스 정상 실행 확인 (루트 권한으로 실행됨)
      * `echo "Hello, Docker!"` 명령으로 확인 (CLI `#`표시 확인)
* 백그라운드 컨테이너
  * 레지스트리용 컨테이너, 웹서버 실행 등의 경우 (일반적으로 사용되는 경우)
  * 최신 버전의 아파치 웹서버 이미지를 사용하여 컨테이너 생성하여 실행
    ~~~
    $ sudo docker container run -d -p 80:80 --name apache httpd:latest
    ~~~

실행중인 컨테이너 확인
* CLI 명령으로 확인
  * `$ sudo docker container ls`
* 브라우저에서 접속하여 확인
  * `http://172.16.248.2:80`
* 웹서버의 로그 확인
  * `$ sudo docker container logs apache`

도커 컨테이너 생명주기 (Lifecycle)
* 생성, 시작, 정지, 삭제
