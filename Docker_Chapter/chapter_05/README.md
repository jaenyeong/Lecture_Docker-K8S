# Chapter05 실습

## 깃허브
* 실습 소스를 `Github`에 저장 후 `VMware Fusion`에서 다운로드
  * `$ git clone https://github.com/jaenyeong/Sample_Docker-portfolio.git portfolio`

## 도커허브
* 레지스트리 생성
  * 저장소명 `jaenyeongdev/portfolio`
* 실습 소스를 사용하여 이미지 생성
  * `$ cd portfolio`
  * `$ sudo docker build -t jaenyeongdev/portfolio:1.0 .`
* 도커허브 로그인
  * `$ sudo docker login`
* 도커허브 푸시
  * `$ sudo docker push jaenyeongdev/portfolio:1.0`
* 헷갈리지 않게 실습 소스를 새 디렉토리에 클론
  * `$ mkdir project-new && cd project-new`
  * `$ git clone https://github.com/jaenyeong/Sample_Docker-portfolio.git portfolio`
  * `$ cd portfolio`
  * `$ nano Dockerfile`
  * `$ sudo docker build -t jaenyeongdev/portfolio:1.1 .`
* 이미지 확인
  * `$ sudo docker image ls`
* 무료 계정은 비공개 저장소가 계정당 1개

## 도커 로컬 레지스트리 구축
* 로컬 레지스트리 생성을 위해 레지스트리 컨테이너 실행
  * `$ sudo docker run -d -p 5000:5000 --restart always --name registry registry:2`
* 이미지 태깅
  * `$ sudo docker tag jaenyeongdev/portfolio:1.1 localhost:5000/portfolio:1.1`
* 로컬 레지스트리에 이미지 공유
  * `$ sudo docker push localhost:5000/portfolio:1.0`
* 로컬 레지스트리에서 이미지 다운로드
  * `$ sudo docker image pull localhost:5000/portfolio:1.0`

## GCP 아티팩트 레지스트리
* `Artifact Registry`는 이미지 저장소, `Cloud Build`는 이미지 빌드
* GCP 콘솔에 접속 > 새 프로젝트 생성
  * 프로젝트명 : `docker-registry`
  * 프로젝트 ID : `jaenyeong-docker-registry`
* `API 및 서비스` -> `라이브러리` -> `Artifact Registry`, `Cloud Build`
* `Artifact Registry` 저장소 생성
  * 저장소명 : `portfolio`
  * 형식 : `Docker`
  * 위치 유형 : `리전`
    * `asia-northeast3(서울)`
  * 암호화 : `Google 관리 암호화 키`
* 리눅스 도커 보안 그룹 설정
  * `$ sudo usermod -a -G docker jaenyeongdev`
  * 위 명령 실행 후 `VMware Fusion` 재부팅
* google cloud SDK 패키지 경로 추가
  * `$ echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list`
* google cloud SDK 공개키 내려받기
  * `$ curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -`
* google cloud SDK 설치
  * `$ sudo apt-get update && sudo apt-get install google-cloud-sdk`
  * 용량이 커서 시간이 다소 소요됨
* google cloud SDK 초기화
  * `gcloud init`
  * 위 명령 실행 후 google 계정에 로그인 링크 > 링크에 접속, 인증코드를 복사 > 프롬프트에 붙여넣기
    * 로그인을 묻는 질문에 `Y` 입력
    * 프로젝트 선택에서 `jaenyeong-docker-registry` 선택
* GCP Registry 저장소 인증
  * `$ sudo gcloud auth configure-docker asia-northeast3-docker.pkg.dev`
  * 해당 명령은 루트 권한이 필요, 반드시 `sudo` 명령 같이 사용
  * 실행 후 `/home/<usename>/docker/config.json` 파일과 함께 저장소 경로가 등록 됨
* 이미지 태깅
  * [GCP 콘솔](https://console.cloud.google.com/artifacts/docker/jaenyeong-docker-registry/asia-northeast3/portfolio?project=jaenyeong-docker-registry)에서 복사 가능
    * `asia-northeast3-docker.pkg.dev/jaenyeong-docker-registry/portfolio`
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
* 다시 태그, 푸시 실습
  * Gcloud 계정 설정
    * 로그아웃
      * `$ sudo gcloud auth revoke jaenyeong.dev@gmail.com`
    * 로그인
      * `$ sudo gcloud auth login`
  * `$ sudo docker tag jaenyeongdev/portfolio:1.1 asia-northeast3-docker.pkg.dev/jaenyeong-docker-registry/portfolio/portfolio:1.1`
  * `$ sudo docker push asia-northeast3-docker.pkg.dev/jaenyeong-docker-registry/portfolio/portfolio:1.1`

GCP Cloud Build
* GCP 콘솔 > `Cloud Build` > `트리거` > `저장소 연결`
  * 소스 선택
    * `Github` 선택
  * 인증
    * 권한 허가 설정 : `Authorize Google Cloud Build` 선택
  * Google Cloud Build 설치
  * 저장소 선택
    * `push` 내역을 가져오기 위해 `Google Cloud Build 설치` 선택
    * `Only Select repositories` 선택, 저장소 선택 후 `Install` 선택
  * 트리거 만들기(선택사항)
    * 위에서 선택한 저장소 연결
    * `트리거 만들기` 선택
      * 트리거 이름 : `portfolio-trigger`
      * `이벤트` > `트리거를 호출하는 저장소 이벤트` > `브랜치로 푸시` 선택
      * `구성` > `유형` > `Dockerfile` 선택
  * `Cloud Build` > `설정` > `서비스 계정 권한`
    * `서비스 계정` 상태를 `사용 설정됨`으로 설정
    * `Cloud Build` 상태를 `사용 설정됨`으로 설정
  * GCP 대시보드에서 이미지 생성 결과 확인
