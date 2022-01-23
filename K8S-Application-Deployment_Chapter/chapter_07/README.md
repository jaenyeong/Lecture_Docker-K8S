# Chapter 07 실습

## Kakao iCloud VM 재구성
* 기존에 사용하던 VM들을 모두 초기화하고 새롭게 구성
* 마스터 및 워커 노드 인스턴스 생성 (`A1-2-CO` 타입)
  * `kjn-01`
  * `kjn-02`
  * `kjn-03`
* CI/CD 인스턴스 생성 (`A1-4-CO`)
   * `kjn-cicd`
 * 인스턴스 설명
   * `수강생 김재녕`
 * 볼륨 타입 크기
   * `50` GB
 * 키페어
   * 기존 키페어 사용
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
* `Virtual Machine IP`
  * `kjn-01` - `172.30.7.133`
  * `kjn-02` - `172.30.4.250`
  * `kjn-03` - `172.30.7.177`
  * `kjn-cicd` - `172.30.6.216`
* 편리한 `ssh` 접속을 위해 `/.ssh/config` 파일에 설정
  ~~~
  ## Docker&KBS kakao i cloud kjn-01 (master)
  Host kjn_01
  HostName 172.30.7.133
  user ubuntu
  IdentityFile /Users/kimjaenyeong/Documents/Lecture_Docker_K8S/settings/kjn01.pem

  ## Docker&KBS kakao i cloud kjn-02 (worker01)
  Host kjn_02
  HostName 172.30.4.250
  user ubuntu
  IdentityFile /Users/kimjaenyeong/Documents/Lecture_Docker_K8S/settings/kjn01.pem

  ## Docker&KBS kakao i cloud kjn-03 (worker02)
  Host kjn_03
  HostName 172.30.5.31
  user ubuntu
  IdentityFile /Users/kimjaenyeong/Documents/Lecture_Docker_K8S/settings/kjn01.pem

  ## Docker&KBS kakao i cloud kjn-cicd (CI/CD)
  Host kjn_cicd
  HostName 172.30.6.216
  user ubuntu
  IdentityFile /Users/kimjaenyeong/Documents/Lecture_Docker_K8S/settings/kjn01.pem
  ~~~
* 각 노드 인스턴스 접속 후
  * `$ sudo -i`
    ~~~
    rm /var/lib/dpkg/lock-fronted
    rm /var/lib/apt/lists/lock
    rm /var/cache/apt/archives/lock
    rm /var/lib/dpkg/lock*
    apt-get update
    ~~~
* CI/CD 노드를 제외한 모든 노드에 `wget` 설치
  * `# yum install -y wget` 또는 `# apt-get install -y wget`
    * 에러 발생 시 다음 명령 실행
      ~~~
      E: Could not get lock /var/lib/dpkg/lock-frontend - open (11: Resource temporarily unavailable)
      E: Unable to acquire the dpkg frontend lock (/var/lib/dpkg/lock-frontend), is another process using it?
      
      killall apt apt-get
      rm /var/lib/dpkg/lock-fronted
      rm /var/lib/apt/lists/lock
      rm /var/cache/apt/archives/lock
      rm /var/lib/dpkg/lock*
      dpkg --configure -a
      ~~~
* CI/CD 노드를 제외한 모든 노드에 `apt` 업데이트 및 `container-d` 설치
  * `# apt update && apt install -y docker.io`
* CI/CD 노드를 제외한 모든 노드에 `kubeadm` 설치
  ~~~
  cat <<EOF > kube_install.sh
  sudo apt-get update
  sudo apt-get install -y apt-transport-https ca-certificates curl docker.io

  sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg

  echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

  sudo apt-get update
  sudo apt-get install -y kubelet kubeadm kubectl
  sudo apt-mark hold kubelet kubeadm kubectl

  EOF

  bash kube_install.sh
  ~~~
* 도커 Cgroup 변경
  ~~~
  cat <<EOF > /etc/docker/daemon.json
  {
    "exec-opts": ["native.cgroupdriver=systemd"]
  }
  EOF

  service docker restart
  ~~~
  * `# docker info` 명령으로 `Cgroup Driver`가 `systemd`로 변경됐는지 확인
* 마스터 노드에서 `kubeadm` 초기화
  * `# kubeadm init`
* 마스터 노드에서 사용자 설정
  * `# mkdir -p $HOME/.kube`
  * `# sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config`
  * `# sudo chown $(id -u):$(id -g) $HOME/.kube/config`
* 워커 노드에서 조인 설정
  * `# kubeadm join 172.30.7.133:6443 --token grcs0p.v4q8kf6jw8eyjwdq --discovery-token-ca-cert-hash sha256:479604eed749ec5a9dfb7f18758fa59e028da0b9cc0d3c7fa0e10e4282783647`
* 마스터 노드에서 확인
  * `# kubectl get nodes`
* 마스터 노드에서 `CNI` 서드파티 플러그인 `weave` 설치 후 확인
  * `# kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"`
  * `# kubectl get nodes`

## 계정 정보
* Jenkins
  * ID
    * `jenkins`
  * PW
    * `test1234`
* Harbor
  * ID
    * `admin`
  * PW
    * `Test1234`
* Argo
  * ID
    * `admin`
  * PW
    * `<secret value>`
* Gogs
  * ID
    * `gogs`
  * PW
    * `test1234`

## 도커 및 컴포즈 설치
* CI/CD 노드(4번 노드)에 설정
~~~
# 관리자 권한
sudo -i

# docker 설치
apt update && apt install -y docker.io

# 도커 컴포즈 설치
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# 기존 컨테이너, 볼륨 삭제 (실행된 컨테이너가 없으면 무시)
docker rm --force `docker ps -a -q`
docker volume rm --force `docker volume ls -q`
~~~

## `harbor`를 활용한 컨테이너 레지스트리 구축
* CI/CD 노드에 스크립트를 사용해서 설치 진행 (`harbor io`)
  * `# wget https://gist.githubusercontent.com/kacole2/95e83ac84fec950b1a70b0853d6594dc/raw/ad6d65d66134b3f40900fa30f5a884879c5ca5f9/harbor.sh`
  * `# bash harbor.sh`
    ~~~console
    1) IP
    2) FQDN
    Would you like to install Harbor based on IP or FQDN? 1
    ~~~
    * IP 선택 (도메인이 없으므로)
* CI/CD 노드에 `HTTPS` 통신을 위해 인증서 구성 및 설정하여 설치 (`CA`와 `harbor`에서 사용할 `Certificate` 생성)
  ~~~console
  cd ~
  mkdir pki && cd pki

  # ca 키와 인증서 생성
  openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
      -out ca.crt \
      -keyout ca.key \
      -subj "/CN=ca"

  # harbor server 키와 인증서 생성
  openssl genrsa -out server.key 2048
  openssl req -new -key server.key -out server.csr -subj "/CN=harbor-server"
  openssl x509 -req -in server.csr -CA ca.crt \
                                    -CAkey ca.key \
                                    -CAcreateserial -out server.crt -days 365

  # 키와 인증서 복제
  mkdir -p /etc/docker/certs.d/server
  cp server.crt /etc/docker/certs.d/server/
  cp server.key /etc/docker/certs.d/server/
  cp ca.crt /etc/docker/certs.d/server/

  cp ca.crt /usr/local/share/ca-certificates/harbor-ca.crt
  cp server.crt /usr/local/share/ca-certificates/harbor-server.crt
  update-ca-certificates
  ~~~
  * 위 작업 중 에러 발생
    ~~~
    Can't load /root/.rnd into RNG
    140426573017536:error:2406F079:random number generator:RAND_load_file:Cannot open file:../crypto/rand/randfile.c:88:Filename=/root/.rnd
    ~~~
    * 해당 파일이 없어 나는 에러로 확인
      * `# echo -n 1234 > /root/.rnd`
* CI/CD 노드에 `harbor.yml` 템플릿을 사용해 harbor 설정 구성
  ~~~console
  cd ~/harbor
  vim harbor.yml
  ~~~
  * `harbor.yml` 설정 변경
    ~~~yaml
    # 현재 인스턴스의 IP
    hostname: 172.30.6.216

    # http related config
    http:
      # port for http, default is 80. If https enabled, this port will redirect to https port
      port: 80

    # https related config
    https:
      # https port for harbor, default is 443
      port: 443
      # The path of cert and key files for nginx
      # certificate: /your/certificate/path
      # private_key: /your/private/key/path
      certificate: /etc/docker/certs.d/server/server.crt
      private_key: /etc/docker/certs.d/server/server.key
   
    harbor_admin_password: Test1234
    ~~~
    * `hostname`
      * CI/CD 노드에 새 세션을 열어 `$ ip addr` 명령으로 IP 확인
    * `harbor_admin_password
      * 가급적 적절하게 변경해주는 것이 나음 (ID는 admin)
      * 기본 비밀번호를 그대로 두면 공격받기 쉬움
* CI/CD 노드에 준비, 설치 스크립트를 실행
  * 준비 스크립트는 이미지를 준비하고 인증서 파일을 위한 설정을 구성
  * `install.sh` 파일은 도커 컴포즈를 사용해 `harbor` 실행에 필요한 컨테이너들을 배포
  ~~~
  ./prepare
  # 도커 컴포즈를 다시 구성
  sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  
  ./install.sh
  ~~~
* 설치 후 웹 브라우저에서 접속
  * `https://172.30.6.216`
  * 접속이 안될 경우 시크릿 모드에서 접속 확인
    * 해당 페이지에서 아무것도 누르지 않고 `thisisunsafe` 입력
  * 로그인
    * `admin` / `Test1234`
  * 초기 접속 정보
    * ID
      * `harbor`
    * PW
      * `Test1234`
      * 위에서 수정하지 않으면 기본적으로 `Harbor12345`
  * 새 프로젝트 생성
    * 프로젝트명
      * `admin`
    * 공개여부
      * `private`
    * 기타
      * 그 외 기본 설정
* CLI에서 로그인
  * `# docker login 127.0.0.1 -u admin -p Test1234`
* 도커 `nginx` 이미지 내려 받기
  * `# docker pull nginx`
* 태깅
  * `# docker tag nginx 127.0.0.1/admin/nginx`
* harbor에 푸시
  * `# docker push 127.0.0.1/admin/nginx`

## `gogs`(경량화된 gitlab) 설치와 활용
* CI/CD 노드에 도커 컴포즈를 활용해 `gogs`와 데이터베이스 설치
  ~~~
  mkdir ~/gogs && cd ~/gogs
  wget https://gist.githubusercontent.com/ahromis/4ce4a58623847ca82cb1b745c2f83c82/raw/31e8ced3d7e08c602a1c0ca8994c063994971c7f/docker-compose.yml
  ~~~
  * `# vim docker-compose.yml`
    ~~~yaml
    version: '2'
    services:
      postgres:
        image: postgres:9.5
        restart: always
        environment:
         - "POSTGRES_USER=gogs"
         - "POSTGRES_PASSWORD=Test1234"
         - "POSTGRES_DB=gogs"
        volumes:
         - "db-data:/var/lib/postgresql/data"
        networks:
         - gogs
      gogs:
        image: gogs/gogs:latest
        restart: always
        ports:
         - "10022:22"
         - "3000:3000"
        links:
         - postgres
        environment:
         - "RUN_CROND=true"
        networks:
         - gogs
        volumes:
         - "gogs-data:/data"
        depends_on:
         - postgres

    networks:
      gogs:
        driver: bridge

    volumes:
      db-data:
        driver: local
      gogs-data:
        driver: local
    ~~~
  * 도커 컴포즈 실행
    * `# docker-compose -f docker-compose.yml up -d`
* 도커 프로세스 확인
  * `# docker ps -a`
    ~~~console
    CONTAINER ID   IMAGE                                  COMMAND                  CREATED          STATUS                             PORTS                                                                                NAMES
    79b682e20bf8   gogs/gogs:latest                       "/app/gogs/docker/st…"   27 seconds ago   Up 21 seconds (health: starting)   0.0.0.0:3000->3000/tcp, :::3000->3000/tcp, 0.0.0.0:10022->22/tcp, :::10022->22/tcp   gogs_gogs_1
    c6466f6cc433   postgres:9.5                           "docker-entrypoint.s…"   35 seconds ago   Up 1 second                        5432/tcp                                                                             gogs_postgres_1
    0197e1c7699f   goharbor/harbor-jobservice:v1.10.10    "/harbor/harbor_jobs…"   49 minutes ago   Up 49 minutes (healthy)                                                                                                 harbor-jobservice
    2d821d525ec3   goharbor/nginx-photon:v1.10.10         "nginx -g 'daemon of…"   49 minutes ago   Up 49 minutes (healthy)            0.0.0.0:80->8080/tcp, :::80->8080/tcp, 0.0.0.0:443->8443/tcp, :::443->8443/tcp       nginx
    2c850c66665f   goharbor/harbor-core:v1.10.10          "/harbor/harbor_core"    50 minutes ago   Up 49 minutes (healthy)                                                                                                 harbor-core
    cb4967bc8238   goharbor/registry-photon:v1.10.10      "/home/harbor/entryp…"   50 minutes ago   Up 50 minutes (healthy)            5000/tcp                                                                             registry
    146f47961e7b   goharbor/harbor-registryctl:v1.10.10   "/home/harbor/start.…"   50 minutes ago   Up 50 minutes (healthy)                                                                                                 registryctl
    674b451a7c16   goharbor/harbor-portal:v1.10.10        "nginx -g 'daemon of…"   50 minutes ago   Up 50 minutes (healthy)            8080/tcp                                                                             harbor-portal
    94d3b08880e1   goharbor/harbor-db:v1.10.10            "/docker-entrypoint.…"   50 minutes ago   Up 50 minutes (healthy)            5432/tcp                                                                             harbor-db
    a49fd3900400   goharbor/redis-photon:v1.10.10         "redis-server /etc/r…"   50 minutes ago   Up 50 minutes (healthy)            6379/tcp                                                                             redis
    7778f70b6973   goharbor/harbor-log:v1.10.10           "/bin/sh -c /usr/loc…"   50 minutes ago   Up 50 minutes (healthy)            127.0.0.1:1514->10514/tcp                                                            harbor-log
    ~~~
* 웹 브라우저에서 접속
  * `http://172.30.6.216:3000/install`
  * 각 설정 확인
    * `host`
      * `postgres:5432`
    * `도메인`
      * `172.30.6.216`
    * `HTTP 포트`
      * `3000`
    * `애플리케이션 URL`
      * `http://172.30.6.216/`
    * 관리자 계정
      * ID
        * `gogs`
      * PW
        * `Test1234`
      * 이메일
        * `test@test.com`
  * 저장소 생성
    * 저장소명
      * `flask-example`
    * 가시성
      * `private`
    * 라이센스
      * `Apache License 2.0`
    * Readme
      * `Default`
* CI/CD 노드에서 깃 설정
  * `# apt update && apt install git -y`
  * `# git config --global user.name gogs`
  * `# git config --global user.email test@test.com`
* 기존 깃헙의 자료를 가져와 `gogs`에 업로드
  ~~~
  git clone https://github.com/gasbugs/flask-example
  cd flask-example/
  rm -rf .git/
  git init
  git add .
  git commit -m "refresh commit"
  git remote add origin http://172.30.6.216:3000/gogs/flask-example.git
  git push -u origin master
  ~~~

## 도커를 활용한 `Jenkins` 설치와 CI 구성
* 도커 이미지를 사용해 Jenkins를 배포
  * `Jenkins`를 배포할 때는 일부 디렉토리를 공유하도록 설정, 도커 소켓 또한 공유하도록 구성
  * 이 소켓을 사용해 `Jenkins`는 호스트에 설치된 도커 기능을 사용 가능
* CI/CD 노드에 설치
  * 도커를 사용해 젠킨스 구성 및 도커 소켓 공유
  * `# docker run -d -p 8080:8080 --name jenkins -v /home/jenkins:/var/jenkins_home -v /var/run/docker.sock:/var/run/docker.sock -u root jenkins/jenkins:lts`
    * `-v /home/jenkins:/var/jenkins_home`
      * 볼륨마운트 : 젠킨스 내에 설치 내용을 보관하는 볼륨(저장소) 공유
    * `-v /var/run/docker.sock:/var/run/docker.sock`
      * 볼륨마운트 : 젠킨스에게 도커를 제어할 수 있는 소켓 공유
        * DooD (`Docker out of Docker`) or DinD (`Docker in Docker`)
        * 도커의 기능을 이용하기 위함
    * `-u root`
      * 설치를 용이하게 하기 위해 유저를 `root`로 설정
      * 실제로는 다른 유저로 지정하는 것을 권장
    * `jenkins/jenkins:lts`
      * 최신 Lts 젠킨스 이미지 사용
  * 젠킨스가 사용할 도커 클라이언트를 설치
    * `# docker exec jenkins apt update`
    * `# docker exec jenkins apt install -y docker.io`
* 웹 브라우저에서 젠킨스 접속
  * `http://172.30.6.216:8080`
  * 최초 접속 시 초기 패스워드 확인 필요 (unlock)
    * `# docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword`
    * `0881003d9f884e779b467a6715066b7c`
  * `Install sugested plugins` 선택
  * 플러그인 설치 후 관리자 계정 생성 (`Create First Admin User`)
    * ID
      * `jenkins`
    * PW
      * `Test1234`
    * Name
      * `Jaenyeong Kim`
    * Email
      * `test@test.com`
  * `Instance Cinfiguration` 설정
    * Jenkins URL : `http://172.30.6.216:8080/`
  * `Jenkins 관리` > `플러그인 관리`
    * `설치가능` 탭에서 `gogs` 검색하여 체크 후 `Download now and install after restart` 클릭해 설치
    * 재시작이 안되면 `설치가 끝나고 실행중인 작업이 없으면 Jenkins 재시작.` 체크
  * 새로운 잡 생성 (`http://172.30.6.216:8080/view/all/newJob`)
    * `Enter an item name`
      * `flask-example-docker-pipeline`
    * `Build Triggers`
      * `GitHub hook trigger for GITScm polling` 체크
    * `Pipeline`
      * `Pipeline script from SCM`
      * `SCM`
        * `Git` 선택
      * `Repository`
        * `http://172.30.6.216:3000/gogs/flask-example`
      * `Add Credentials`
        * 생성 후 선택
          * `Username`
            * `gogs`
          * `Password`
            * `Test1234`
          * ID
            * `gogs-cred`
* `gogs` 브라우저에서 웹훅(`Webhooks`) 설정
  * `Add a new webhook:`
    * `gogs` 선택
  * 페이로드 URL
    * `http://172.30.6.216:8080/gogs-webhook?job=flask-example-docker-pipeline`
      * 뒤에 `gogs-webhook` 이하 패스 파라미터 및 쿼리 스트링은 `gogs` 플러그인 컨벤션이라 준수할 것
* 젠킨스 브라우저에서 `credentials` 설정
  * `대시보드` > `Jenkins 관리` > `Credentials` > `Jenkins` 스토어 > `Global credentials (unrestricted)`
    * `http://172.30.6.216:8080/credentials/store/system/domain/_/`
  * `Add Credentials` 선택해 추가
    * `Username`
      * `admin`
    * `PW`
      * `Test1234` (다른 비밀번호랑 달리 앞에 대문자 주의)
    * ID
      * `harbor-cred`
* `gogs` 저장소에서 `jenkins` 파일 수정
  ~~~
  node {
       stage('Clone repository') {
           checkout scm
       }
       stage('Build image') {
           app = docker.build("172.30.6.216/admin/flask-example")
       }
       stage('Push image') {
           docker.withRegistry('https://172.30.6.216', 'harbor-cred') {
               app.push("${env.BUILD_NUMBER}")
               app.push("latest")
           }
       }
  }

  stage('Build image') {
    app = docker.build("172.30.6.216/admin/flask-example")
  }

  stage('Push image') {
    docker.withRegistry('https://172.30.6.216', 'harbor-cred')
    {
       app.push("${env.BUILD_NUMBER}")
       app.push("latest")
    }
  }
  ~~~

## `Argo`를 활용한 CD 구축
* `gogs`에서 새 마이그레이션 생성
  * `https://github.com/gasbugs/flask-example-apps`
  * `https://github.com/gasbugs/helm-charts`
* 마스터 노드에 `argo` 설치
  * `# kubectl create namespace argocd`
  * `# kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml`
* 배포 확인
  * `# kubectl get svc,pod -n argocd`
    ~~~
    NAME                            TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE
    service/argocd-dex-server       ClusterIP   10.97.101.6      <none>        5556/TCP,5557/TCP,5558/TCP   67s
    service/argocd-metrics          ClusterIP   10.111.103.228   <none>        8082/TCP                     67s
    service/argocd-redis            ClusterIP   10.104.228.59    <none>        6379/TCP                     67s
    service/argocd-repo-server      ClusterIP   10.107.113.199   <none>        8081/TCP,8084/TCP            67s
    service/argocd-server           ClusterIP   10.96.204.8      <none>        80/TCP,443/TCP               67s
    service/argocd-server-metrics   ClusterIP   10.110.208.126   <none>        8083/TCP                     67s

    NAME                                      READY   STATUS    RESTARTS   AGE
    pod/argocd-application-controller-0       1/1     Running   0          66s
    pod/argocd-dex-server-6f7fd44b9d-xh9hf    1/1     Running   0          67s
    pod/argocd-redis-84558bbb99-cxk6s         1/1     Running   0          67s
    pod/argocd-repo-server-784b48858f-mdcx2   0/1     Running   0          67s
    pod/argocd-server-74bf76596b-mh6bt        1/1     Running   0          67s
    ~~~
  * 로드밸런서 변경
    * `# kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'`
  * 확인
    * `# kubectl get svc argocd-server -n argocd -w`
    ~~~
    NAME            TYPE       CLUSTER-IP    EXTERNAL-IP   PORT(S)                      AGE
    argocd-server   NodePort   10.96.204.8   <none>        80:30440/TCP,443:32230/TCP   5m38s
    ~~~
  * 위 정보를 토대로 웹 브라우저에서 `argo` 접속
    * `https://172.30.7.133:30440`
    * ID
      * `admin`
    * PW
      * 시크릿 확인
        * `# kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`
        * `T2QLXgGLIyqYUeQb`
* `argo` 새 앱 생성
  * `Applicatio Name`
    * `flask-example-apps`
  * `Project`
    * `default`
  * `SYNC POLICY`
    * `MANUAL`
  * `SYNC OPTION`
    * `auto-Create Namespace` 체크
  * `repository` (`GIT` 선택)
    * `http://172.30.6.216:3000/gogs/flask-example-apps`
  * `Revision`
    * `main`
  * `Path
    * `flask-example-deploy`
  * `Cluster URL`
    * `https://kubernetes.default.svc`
  * `Namespace`
    * `flask-ns`
* `argo` 에서 `sync`
* 마스터 노드에서 확인
  * `# kubectl get ns`
    ~~~
    NAME              STATUS   AGE
    argocd            Active   18m
    default           Active   134m
    flask-ns          Active   31s
    kube-node-lease   Active   134m
    kube-public       Active   134m
    kube-system       Active   134m
    ~~~
* `argo` 새 앱 생성
  * `Applicatio Name`
    * `helm-charts`
  * `Project`
    * `default`
  * `SYNC POLICY`
    * `MANUAL`
  * `SYNC OPTION`
    * `auto-Create Namespace` 체크
  * `repository` (`HELM` 선택)
    * `http://172.30.6.216:3000/gogs/helm-charts/raw/main/stable`
      * `index` 파일의 `raw` 파일 경로에서 index 전까지 복사
  * `Chart`
    * `mychart`
  * `Cluster URL`
    * `https://kubernetes.default.svc`
  * `Namespace`
    * `mychart-ns`
* 마스터 노드에서 확인
  * `# kubectl get ns`
    ~~~
    NAME              STATUS   AGE
    argocd            Active   24m
    default           Active   141m
    flask-ns          Active   7m12s
    kube-node-lease   Active   141m
    kube-public       Active   141m
    kube-system       Active   141m
    mychart-ns        Active   11s
    ~~~
