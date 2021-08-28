# Chapter04 실습

## Dockerfile을 통해 이미지 생성 실습
~~~
$ mkdir docker && cd docker
$ touch Dockerfile
$ nano Dockerfile
~~~
* ~~~
  # FROM 절에 사용되는 이미지는 캐싱되어 기존에 이미지를 사용 가능하면 재사용
  FROM ubuntu:18.04
  ~~~
~~~
$ sudo docker build -t myubuntu:1.0 .
$ nano Dockerfile
~~~
* ~~~
  FROM ubuntu:18.04
  # 이미지 빌드 중간에 명령 프롬프트로 인수 값을 전달 할수 없기 때문에 -y 붙임
  RUN apt-get update -y
  
  RUN apt-get upgrade -y
  ~~~
실습 중 `apt-get update` 에러 발생
* DNS 등 네트워크연결이 원활하지 않아 발생한 것으로 보임
* VMware Fusion 재부팅 후 다시 실행
    * DNS 설정보다 먼저 확인해 볼 것
* 에러 메시지
  ~~~
  jaenyeong@ubuntu_server:~/docker$ cat Dockerfile
  FROM ubuntu:18.04
  
  RUN apt-get update -y
  RUN apt-get upgrade -y
  jaenyeong@ubuntu_server:~/docker$ sudo docker build -t myubuntu:1.1 .
  Sending build context to Docker daemon  2.048kB
  Step 1/3 : FROM ubuntu:18.04
  ---> 39a8cfeef173
  Step 2/3 : RUN apt-get update -y
  ---> Running in 9a43349fd66c
  Err:1 http://archive.ubuntu.com/ubuntu bionic InRelease
  Temporary failure resolving 'archive.ubuntu.com'
  Err:2 http://security.ubuntu.com/ubuntu bionic-security InRelease
  Temporary failure resolving 'security.ubuntu.com'
  Err:3 http://archive.ubuntu.com/ubuntu bionic-updates InRelease
  Temporary failure resolving 'archive.ubuntu.com'
  Err:4 http://archive.ubuntu.com/ubuntu bionic-backports InRelease
  Temporary failure resolving 'archive.ubuntu.com'
  Reading package lists...
  W: Failed to fetch http://archive.ubuntu.com/ubuntu/dists/bionic/InRelease  Temporary failure resolving 'archive.ubuntu.com'
  W: Failed to fetch http://archive.ubuntu.com/ubuntu/dists/bionic-updates/InRelease  Temporary failure resolving 'archive.ubuntu.com'
  W: Failed to fetch http://archive.ubuntu.com/ubuntu/dists/bionic-backports/InRelease  Temporary failure resolving 'archive.ubuntu.com'
  W: Failed to fetch http://security.ubuntu.com/ubuntu/dists/bionic-security/InRelease  Temporary failure resolving 'security.ubuntu.com'
  W: Some index files failed to download. They have been ignored, or old ones used instead.
  Removing intermediate container 9a43349fd66c
  ---> 57ac23457213
  Step 3/3 : RUN apt-get upgrade -y
  ---> Running in 370d54ff15fd
  Reading package lists...
  Building dependency tree...
  Reading state information...
  Calculating upgrade...
  0 upgraded, 0 newly installed, 0 to remove and 0 not upgraded.
  Removing intermediate container 370d54ff15fd
  ---> 82007038efec
  Successfully built 82007038efec
  Successfully tagged myubuntu:1.1
  ~~~

## Dockerfile 명령어 실습
### 첫번째 실습
~~~
# 기본 홈 경로에서 시작
$ mkdir ex01 && cd ex01
$ touch Dockerfile && nano Dockerfile
~~~
* ~~~
  FROM ubuntu:18.04
  RUN apt-get update -y
  RUN apt-get install apache2 -y
  EXPOSE 80
  # 컨테이너가 실행된 후 해당 명령을 수행, 셸 방식
  CMD apachectl -D FOREGROUND
  ~~~
~~~
$ sudo docker build -t apache2:1.0 .
~~~
* 브라우저에서 `172.16.248.2` 접속하여 아파치 실행 상태 확인
* ~~~
  FROM ubuntu:18.04
  RUN apt-get update -y
  RUN apt-get install apache2 -y
  EXPOSE 80
  
  # CMD apachectl -D FOREGROUND
  # 아래 명령은 exec 형식
  CMD ["apachectl", "-D", "FOREGROUND"]
  ~~~
~~~
$ sudo docker build -t apache2:1.1 .
~~~
~~~
# 한 번 실행했던 부분들은 캐싱처리 됨
Sending build context to Docker daemon  2.048kB
Step 1/5 : FROM ubuntu:18.04
---> 39a8cfeef173
Step 2/5 : RUN apt-get update -y
---> Using cache
---> 99ae8fa91912
Step 3/5 : RUN apt-get install apache2 -y
---> Using cache
---> b0b58221e59a
Step 4/5 : EXPOSE 80
---> Using cache
---> 354d1c8790f0
Step 5/5 : CMD ["apachectl", "-D", "FOREGROUND"]
---> Running in fa52a23004d3
Removing intermediate container fa52a23004d3
---> 95da4aed51b6
Successfully built 95da4aed51b6
Successfully tagged apache2:1.0
~~~
~~~
$ sudo docker container stop webserver
$ sudo docker ps
$ sudo docker container run -d -p 80:80 --name webserver2 apache2:1.1
~~~

### 두번째 실습
~~~
# 기본 홈 경로에서 시작
$ mkdir ex02 && cd ex02
~~~
* ~~~
  FROM ubuntu:18.04
  
  ENTRYPOINT ["top"]
  # 대화형 
  CMD ["-d", "5"]
  ~~~
~~~
$ sudo docker build -t top .
$ sudo docker container run -it top
# 기존 5초가 아닌 1초마다 출력
$ sudo docker container run -it top -d 1
~~~

### 세번째 실습
~~~
# 기본 홈 경로에서 시작
$ mkdir ex03 && cd ex03
$ nano Dockerfile.base
~~~
* ~~~
  FROM ubuntu:18.04
  
  ONBUILD RUN echo "Hello, Docker"
  ~~~
~~~
# 베이스 파일을 빌드하기 위해 베이스 도커파일명을 명시 
$ sudo docker build -t base -f Dockerfile.base .
~~~
~~~
$ nano Dockerfile
~~~
* ~~~
  FROM base
  ~~~
~~~
$ sudo docker build -t hello .
~~~

### 네번째 실습
~~~
# 기본 홈 경로에서 시작
$ mkdir ex04 && cd ex04
$ nano Dockerfile
~~~
* ~~~
  FROM ubuntu:18.04
  ENV DIRPARENT /parent
  ENV DIRCHILD child
  WORKDIR $DIRPARENT/$DIRCHILD

  RUN ["pwd"]
  ~~~
~~~
$ sudo docker build -t dir .
~~~

### 다섯번째 실습
~~~
# 기본 홈 경로에서 시작
$ mkdir ex05 && cd ex05
$ nano Dockerfile
~~~
* ~~~
  FROM ubuntu:18.04
  LABEL title="My Ubuntu"
  ARG MESSAGE="complete"
  RUN adduser --disabled-password --gecos "" jaenyeong
  RUN whoami
  USER jaenyeong
  RUN whoami
  RUN echo $MESSAGE
  ~~~
~~~
$ sudo docker build -t myubuntu .
~~~

### 여섯번째 실습
~~~
# 기본 홈 경로에서 시작
$ mkdir ex06 && cd ex06
$ touch index.html
$ nano Dockerfile
~~~
* ~~~
  FROM ubuntu:18.04

  WORKDIR /html
  ADD index.html .
  RUN ["pwd"]
  RUN ls -al
     
  WORKDIR /inside-html
  COPY index.html .
  RUN ["pwd"]
  RUN ls -al
  ~~~
~~~
$ sudo docker build -t addcopy .
~~~
* `ADD` 명령어 뒤에 URL을 사용하여 파일 다운로드 후 추가하는 방법은 권장하지 않음
  * 불필요한 용량을 낭비하게 됨
  * 이런 경우 `curl`, `wget` 등을 `RUN`과 함께 사용하여 내려 받은 후 `COPY` 명령으로 로컬 파일을 복사할 것을 권고
