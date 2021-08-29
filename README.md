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

## Chapter04
도커 이미지
* 도커 이미지는 실행에 필요한 모든 것을 담고 있음
* 실행에 필요한 이미지가 없는 경우 도커허브(레지스트리)에서 해당 이미지를 찾아 받아옴
* 이미지는 단일 이미지인 경우가 거의 없음 (대부분 다중 이미지)
* 즉 이미지는 베이스 이미지 위에 설정, 파일들을 한데 모아 빌드한 것
* 도커 파일을 통해 이미지 생성
* `Digest` - 도커 허브에서 이미지를 식별하는 고유 값
* 태그는 이미지를 버전별로 관리하는데 사용됨
  * 태그 중 `latest`는 장기 지원 버전을 의미
  * 레지스트리별로 명명 규칙이 상이하게 존재하기 때문에 태그를 통해 이미지명 설정
* 도커 허브의 `Official Image`는 공식적으로 인증을 받은 이미지

도커 이미지 명령어
* `pull` : 도커 이미지 받기
  ~~~
  > 아래 3개는 모두 같은 명령어
  $ sudo docker image pull ubuntu
  $ sudo docker image pull ubuntu:focal
  $ sudo docker image pull ubuntu:latest
  
  $ sudo docker image pull 이미지명[:태그]
  ~~~
* `ls` : 이미지 목록 조회
  * `$ sudo docker image ls`
  * 옵션
    * `--all`, `-a`
      * 숨겨진 중간 단계에 이미지까지 모두 조회
    * `--format`
      * 출력 포맷 설정
    * `--digests`
      * 다이제스트를 포함하여 조회
    * `--quiet`, `q`
      * 이미지 ID만 조회
* `inspect` : 이미지 정보 조회 (JSON 형식)
  * `$ sudo docker image inspect ubuntu:18.04`
  * 원하는 내용만 조회
    * `$ sudo docker image inspect --format="{{ .RepoTags }}" ubuntu:18.04`
* `tag` - 이미지에 태그 설정
  ~~~
  $ sudo docker image tag ubuntu:18.04 jaenyeong/ubuntuos:1.0
  
  $ sudo docker image tag 대상이미지명[:태그] [사용자명/]이미지명[:태그]
  ~~~
* `rm` : 삭제
  * 옵션
    * `--force`, `-f`
      * 이미지 강제 삭제
      * 태그된 이미지를 삭제하면 태그만 풀림
      * 여러곳에서 링크된 이미지는 삭제가 불가능 하기 때문에 해당 옵션 사용
    ~~~
    sudo docker image rm jaenyeong/ubuntuos:1.0
    sudo docker image rm ubuntu:18.04
  
    sudo docker image rm 이미지명[:태그]
    sudo docker image rm 이미지ID
    ~~~
* `container commit` : 실행중인 컨테이너로부터 이미지 생성
  * 컨테이너의 당시 상태를 스냅샷 상태로 본떠 생성
  * 옵션
    * `--author`, `-a`
      * 이미지 작성자 등록
    * `--message`, `-m`
      * 커밋 메시지 등록
  ~~~
  # 사전에 실행
  $ sudo docker container run -d -p 80:80 --name apache httpd
  
  $ sudo docker container commit -a "jaenyeong" apache jaenyeong/apacheweb:1.0
  ~~~
* `container export` : 실행중인 컨테이너로부터 파일 생성
  ~~~
  $ sudo docker container export apache > apache.tar
  # sudo docker container export 컨테이너명 > [경로/]파일명
  ~~~
  * 생성한 파일을 `import` 명령어를 사용하여 이미지 생성 가능
* `image` : 파일을 이미지로 생성
  * `$ sudo docker image import apache.tar jaenyeong/apacheweb:1.1`
  * `container`가 아닌 `image`로 명령 실행

Dockerfile
* 새로운 도커 이미지를 생성하는데 필요한 베이스 이미지, 설정을 작성한 파일
* 예시
  ~~~
  FROM ubuntu:18.04
  
  RUN apt-get -y update && apt-get -y upgrade
  RUN apt-get -y install nginx
  
  EXPOSE 80
  
  CMD ["nginx", "-g", "daemon off;"]
  ~~~
  * `ubuntu`에 `nginx` 웹서버를 설치하고 80 포트를 열어놓는 내용
  * `FROM`
    * 베이스 이미지 설정
  * `RUN`
    * 이미지를 생성에 필요한 미들웨어나 앱을 세팅하기 위한 명령을 실행
  * `EXPOSE`
    * 호스트와 연결할 포트 설정
  * `CMD`
    * 생성된 이미지를 기반으로 구동된 컨테이너에서 명령을 실행
    * 하나의 `Dockerfile`에서 한 번의 명령만 유효

Dockerfile 빌드
* 도커에서 빌드는 `Dockerfile`을 기반으로 이미지를 생성하는 것
  ~~~
  $ mkdir docker && cd docker
  $ touch Dockerfile
  $ nano Dockerfile
  
  $ sudo docker build -t sample:1.0 /home/(USER)/docker
  ~~~
  * `sudo docker build -t` : 도커 이미지를 생성하는 기본 명령
  * `sample:1.0` : 태그, `[이미지명]:[버전]`과 같은 형태로 작성
  * `/home/(USER)/docker` : 경로

Dockerfile 명령어
* `FROM` : 베이스 이미지 설정
  * 일반적으로 도커 허브의 이미지를 탐색해 빌드하지만 사용자가 생성한 이미지를 통해 빌드도 가능
* `RUN` : 이미지를 빌드할 때 실행할 명령 설정
  * `RUN`을 통해 작동하는 명령은 아직 컨테이너가 작동하는 상태가 아님 
  * Shell, Exec 형식으로 작성 가능
  * 두 가지가 혼용되는 경우가 많음, 실행할 셸 혹은 프로그램을 지정한다는 측면에서 Exec 형식을 더 권장
* `CMD` : 이미지를 통해 생성된 컨테이너 내부에서 실행되는 명령
  * `CMD` 명령은 단 하나만 유효, 여러 개의 명령이 있다면 마지막 것만 실행
  * 사용자가 넘긴 인수의 값을 사용
  * Shell, Exec 형식 모두 사용 가능
* `ENTRYPOINT` : 이미지를 통해 생성된 컨테이너 내부에서 실행되는 명령
  * `CMD` 명령과의 차이
    * `ENTRYPOINT` 명령은 사용자가 어떤 인수를 명령으로 넘기더라도 `Dockerfile`에 명시된 명령을 그대로 실행
    * `CMD` 명령은 컨테이너를 실행할 때 사용자가 인수를 넘기면 기존에 작성된 내용을 덮어씀
* `ONBUILD` : 이미지 빌드 완료 후 명령 실행
  * 실제로 빌드 후 아무 동작도 일어나지 않음
  * `ONBUILD`가 작성된 `Dockerfile`을 베이스 이미지로 한 자식 이미지 파일을 빌드할 때 실행
* `HEALTHCHECK` : 컨테이너의 상태 체크
  * 해당 옵션으로 컨테이너 내부에 로그를 남길 수 있음
  * 옵션
    * `--interval` : 컨테이너 체크 간격 설정
    * `--timeout` : 설정한 시간에 정상작동 하지 않으면 타임아웃 처리
    * `--retries` : 재시도 횟수 설정
* `ENV` : 환경변수 설정
  * `RUN`, `CMD`, `ENTRYPOINT`에서 모두 사용 가능
  * 변수 앞에 `$`를 접두사로 붙여 사용 가능
  * 해당 변수는 컨테이너가 구동된 후에도 유효
* `WORKDIR` : 작업 디렉토리 할당
  * 리눅스의 `cd`와 유사
  * `Dockerfile` 내부에서 경로를 이동할 때 사용 + 이렇게 빌드된 이미지를 대화형 컨테이너로 실행할 때 프롬프트의 최초 위치를 결정
* `USER` : 특정 사용자 할당
  * 기본적으로 `ubuntu`가 베이스 이미지라면 기본 유저는 `root`
* `LABEL` : 이미지 버전 정보, 작성자 등 레이블 정보 등록
  * 각종 메타데이터를 이미지에 기록
  * `docker image inspect` 명령어 실행 후 `Labels` 항목에서 확인 가능
* `ARG` : `Dockerfile` 내부의 변수를 설정
  * 빌드 시점에만 유효한 변수를 할당
  * `ENV`와 다르게 명령어를 실행할 때만 작동
  * 일반적으로 인증 키 정보 등을 변수로 선언하는 경우가 많은데 `docker history`로 조회가 가능하니 주의할 것
* `EXPOSE` : 포트 할당
  * 단순히 포트의 사용 방식을 알려주는 문서의 성격을 띔
  * 실제로 호스트에서 컨테이너의 포트와 통신하도록 listening 상태를 만들어주지 않음 (외부로 노출되지 않음)
  * 컨테이너에서 호스트의 통신 요청에 응답하기 위해서는 반드시 `container run` 단계에서 `-p` 옵션을 통해 포트를 설정해야 함
* `ADD` : 파일 또는 디렉토리 추가
  * `COPY` 명령과 유사한 기능을 제공하나 2개의 추가 기능 보유
    * `URL`을 통한 파일 복사
      * 이는 로컬뿐 아니라 웹에 파일도 이미지를 빌드할 때 추가 가능함을 의미 
    * 로컬에서 파일을 복사하는 경우 압축을 해제하여 복사
      * 웹에서 다운로드한 파일은 압축은 해제되나 `tar` 형태는 유지
      * 압축을 자동으로 해제하기 때문에 `tar`, `tar.gz` 등의 파일을 복사하는 경우 주의
  * `ADD` 명령어 뒤에 URL을 사용하여 파일 다운로드 후 추가하는 방법은 권장하지 않음
    * 불필요한 용량을 낭비하게 됨
    * 이런 경우 `curl`, `wget` 등을 `RUN`과 함께 사용하여 내려 받은 후 `COPY` 명령으로 로컬 파일을 복사할 것을 권고
* `COPY` : 파일 복사
* `VOLUME` : 볼륨 마운트
* `STOPSIGNAL` : 시스템 콜 시그널 설정
* `SHELL` : 컨테이너에서 사용할 기본 쉘 설정

## Chapter05
도커 레지스트리
* 도커의 이미지 저장소
* Building, Running, Shipping(Sharing)
* 공유 레지스트리 종류
  * 도커 허브 (default)
  * 로컬 레지스트리 (사용자가 직접 구축)
  * 컨테이너 레지스트리 (클라우드 사업자가 제공)
* 레지스트리를 사용하는 이유
  * 보안 (IAM)
    * 이미지 자체 암호화가 필요
    * 접근 권한 통제
  * 배포 파이프라인 효율화
    * CI/CD

도커 허브
* 기본적으로 참조하는 레지스트리
* [도커허브](https://hub.docker.com/) 계정, 저장소 생성
  * 무료 계정 제약 사항
    * 하나의 저장소만 Private 설정 가능
    * `Automated Builds` 기능 사용 못함
      * `push`한 소스를 기반으로 이미지를 빌드해주는 기능
* 샘플 코드 복사
  ~~~
  $ mkdir /<프로젝트명>
  $ cd /<프로젝트명>
  $ git clone https://github.com/jaenyeong/Sample_Docker-portfolio.git
  ~~~
  * 이미지 빌드
    ~~~
    $ sudo docker build -t <계정명>/<저장소명>:[태그명] .
    $ sudo docker build -t jaenyeongdev/portfolio:1.0 .
    ~~~
    * ~~~
      # alpine은 경량화 리눅스 배포판 입니다.
      # 도커 베이스 이미지로 alpine 리눅스를 활용하는 이유는
      # 이미지 용량을 적게 차지할 뿐만 아니라 처리속도가 빠르기 때문
      FROM nginx:alpine
    
      # 이 경로는 nginx 웹서버의 index.html 파일이 위치한 곳
      # 브라우저를 통해 웹서버로 접근했을 때 로드되는 페이지가 바로 이 곳을 참조하여 렌더링
      WORKDIR /usr/share/nginx/html
    
      # 클론한 소스를 이미지에 복사하기 위해 기존 이미지 내의 파일을 전부 삭제
      RUN rm -rf ./*
    
      # Dockerfile이 위치한 경로의 html, css, js 등의 파일을 이미지 내로 복사
      COPY ./* ./
    
      # nginx 웹서버 기동
      ENTRYPOINT ["nginx", "-g", "daemon off;"]
      ~~~
* 도커 허브에 이미지 공유 시엔 빌드할 때 반드시 명명규칙 준수할 것
  * `<계정명>:<저장소명>`
* 도커 허브 로그인
  * `$ sudo docker login`
* 도커 허브 이미지 공유
  ~~~
  $ sudo docker <계정명>/<저장소명>:[태그명]
  $ sudo docker push jaenyeongdev/portfoilo:1.0
  ~~~

로컬 레지스트리
* 이미지가 저장되는 레지스트리를 컨테이너 상에 구축할 수 있음
* 도커에서 `Registry`라는 이름으로 제공
* `Registry` 컨테이너 실행
  ~~~
  # --restart always는 도커 엔진이 재시작 될 때 자동으로 컨테이너를 재시작하도록 하는 옵션
  $ sudo docker run -d -p 5000:5000 --restart always --name registry registry:2
  ~~~
* 이미지 태깅
  ~~~
  $ sudo docker tag <기존 이미지명>:[태그명] <레지스트리 컨테이너 IP>/<이미지명>:[태그명]
  $ sudo docker tag jaenyeongdev/portfoilo:1.0 localhost:5000/portfolio:1.0
  ~~~
* 컨테이너에 구축한 레지스트리에 이미지를 공유하는 경우 반드시 명명규칙 준수할 것
  * `<컨테이너 IP>:<포트>/<이미지명>`
  * 컨테이너를 실행할 때 `5000`으로 지정한 포트를 구성상 변경이 필요한 경우 태그 설정에도 반영 필요
* 이미지 공유
  * `$ sudo docker push localhost:5000/portfolio:1.0`

GCP Artifact Registry
* 패키지와 도커 컨테이너 이미지를 저장, 관리
  * CI/CD
    * `Cloud Build`의 아티팩트 저장, `Google Cloud` 런타임에 배포
  * 공급망
  * VPN 서비스 제어 (보안)
  * 단일 프로젝트 내 여러 저장소 생성 가능
* GCP 콘솔 > 프로젝트 생성
  * GCP에서는 프로젝트 단위로 앱을 관리
    * `Firebase` 등의 서비스도 GCP에서 관리되는 요소 중 하나
* 결제 계정 생성
* 서비스 사용 등록
  * `API 및 서비스 - 라이브러리` 메뉴 참조
    * `Artifact Registry`, `Cloud Build` 서비스 사용 선택
* GCP 저장소 생성
  * `Artifact Registry` 콘솔에서 `저장소 만들기` 선택
  * 저장소 설정
    * 형식 `Docker`
    * 리전 `asia-northeast3(서울)`
  * 암호화 `Google 관리 암호화` 선택
* 리눅스 도커 보안 그룹 설정
  * `$ sudo usermod -a -G docker [계정명]`
* google cloud SDK 패키지 경로 추가
  * `$ echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list`
* google cloud SDK 공개키 내려받기
  * `$ curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -`
* google cloud SDK 설치
  * `$ sudo apt-get update && sudo apt-get install google-cloud-sdk`
* google cloud SDK 초기화
  * `gcloud init`
  * 위 명령 실행 후 google 계정에 로그인 링크 > 링크에 접속, 인증코드를 복사 > 프롬프트에 붙여넣기
* GCP Registry 저장소 인증
  * `$ sudo gcloud auth configure-docker asia-northeast3-docker.pkg.dev`
  * 해당 명령은 루트 권한이 필요, 반드시 `sudo` 명령 같이 사용
  * 실행 후 `/home/<usename>/docker/config.json` 파일과 함께 저장소 경로가 등록 됨
* 이미지 태깅
  ~~~
  # sudo docker tag jaenyeongdev/portfolio:1.0 asia-northeast3-docker.pkg.dev/[프로젝트ID]/[저장소명]/portfolio
  $ sudo docker tag jaenyeongdev/portfolio:1.0 asia-northeast3-docker.pkg.dev/jaenyeong-docker-registry/portfolio/portfolio
  ~~~
  * GCP의 레지스트리에도 이미지를 업로드 할 때 반드시 이미지명 명명규칙 준수
* 이미지 공유
  ~~~
  # sudo docker push asia-northeast3-docker.pkg.dev/[프로젝트ID]/[저장소명]/portfolio
  $ sudo docker push asia-northeast3-docker.pkg.dev/jaenyeong-docker-registry/portfolio/portfolio
  ~~~

GCP Cloud Build
* GCP에서 제공되는 도커 이미지 자동 빌드 기능
  * `Github`, `Bitbucket`의 `push` 된 소스를 기반으로 도커 이미지를 자동으로 빌드
* 트리거 생성, 저장소 연결
  * 'Cloud Build' 메뉴에서 '트리거'를 누른 후 저장소 `연결` 버튼 선택
  * `Github` 선택 후 로그인
  * 계정 연동 여부 창 > `Authorize Google Cloud Build` 선택
  * `push` 내역을 가져오기 위해 `Google Cloud Build 설치` 선택
  * 설치 대상 계정 선택
  * `Google Cloud Build` 적용
    * 계정에 생성된 저장소 전체에 적용
      * `All repositories` 선택 후 `Install` 선택
    * 특정 저장소만 적용
      * `Only Select repositories` 선택 후 `Install` 선택
  * GCP `Cloud Build` 기능을 적용할 저장소를 선택, `확인` 버튼 선택
  * 전송, 트리거 설명 체크박스에 체크
* 트리거 설정
  * 이벤트 > `브랜치로 푸시` 선택
  * 구성 > `Dockerfile` 선택
* 서비스 계정 권한 사용 설정
  * `Cloud Build` 설정의 서비스 계정 탭 > 표시된 두 항목을 '사용 설정됨' 상태로 변경
* `Github`에 소스 `push` 후 빌드 확인
  * 빌드와 관련한 성공/실패 로그는 GCP 대시보드에서 확인 가능
