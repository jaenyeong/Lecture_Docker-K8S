# 실습 과제

## 8주차 과제
7주차 `도커 컴포즈` 내용을 8주차 `Dockerized API`에 제출

### 진행단계
`Chapter07 도커 컴포즈` 수강 후 `Chapter01 OT & PC세팅(Kakao i Cloud 활용한 실습준비)` 수강 전

### 제출
* 2021년 10월 01일 (금)까지
* 피드백
  * 1차 : ~ 9/26(일) 17:00 까지
  * 2차 : ~ 9/27(월) 17:00 까지
  * 3차 : ~ 9/28(화) 17:00 까지
  * 4차 : ~ 9/30(목) 17:00 까지

### 제출 방법
* `Github Gist`에 `docker-compose.yml` 파일 작성
* 구글 form에 `Github Gist` 링크 제출
  * [제출 gist url](https://gist.github.com/jaenyeong/4557fcd67234ccbe845fbd40a61363be)

### 과제 설명
[1] FastAPI(Web)
* 같은 경로 내 `Dockerfile`을 빌드한 이미지 사용
  * `Dockerfile`을 포함한 기타 다른 소스는 템플릿으로 제공
* 컨테이너와 호스트는 `8000` 포트 통신
* `PostgreSQL` 서비스가 시작된 이후에 시작
* 컨테이너 종료 시 항상 재시작

[2] PostgreSQL
* 컨테이너와 호스트는 `5432` 포트 통신
* 컨테이너 종료 시 항상 재시작
* 환경변수 3가지 설정
  * `POSTGRES_USER: postgres`
  * `POSTGRES_PASSWORD: postgres`
  * `POSTGRES_DB: postgres`
* `/var/lib/postgresql/data`를 `pgdata` 볼륨으로 할당

[3] pgAdmin
* ~~컨테이너의 `5050` 포트와 호스트의 `80` 포트 연결~~
* 컨테이너 종료 시 항상 재시작
* 환경변수 2가지 설정
  * `PGADMIN_DEFAULT_EMAIL: admin@example.com`
  * `PGADMIN_DEFAULT_PASSWORD: admin`
* `/var/lib/pgadmin`를 `pgadmindata` 볼륨으로 할당

### 작업
* 템플릿 실습 다운로드
  * [템플릿 실습 소스](https://github.com/jaenyeong/Sample_Docker-FastAPI-app)
  * `$ git clone https://github.com/jaenyeong/Sample_Docker-FastAPI-app`
  * `$ cd Sample_Docker-FastAPI-app`
* `docker-compose.yml` 파일 수정
  * 파일 내용은 같은 경로에 `docker-compose.yaml` 파일 참조
* 한 번에 되지 않는 경우 `$ sudo docker-compose down` 명령 후 다시 실행
  * 서비스 내에 `volume` 설정 시 볼륨 경로를 `:` 바로 뒤에 붙여서 작성할 것
  * `logging - driver` 찾지 못함
    * `PGADMIN_DEFAULT_EMAIL`, `PGADMIN_DEFAULT_PASSWORD` 환경 변수 추가
  * 베이스 이미지 찾지 못함 (`build` 명령 경로)
  * 기존 컨테이너와 포트 충돌 또는 이미지나 컨테이너 재사용하는 경우
* 접속 확인
  * 브라우저에서 `http://172.16.248.2:8000/docs` 접속하여 API 테스트
* `Github Gist`에 파일 작성
  * `gist.github.com`에 접속 (로그인 후)
  * 파일명 등을 입력 후 `docker-compose.yml` 파일 내용을 복사
  * `Create secret gist`로 생성 후 구글 form에 링크 제출