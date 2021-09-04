# 실습 과제

## 5주차 과제

### 진행단계
`Chapter05 도커 레지스트리` 수강 후 `Chapter06 도커 볼륨 / 네트워크` 수강 전

### 제출
* 2021년 9월 10일 (금)까지
* 9월 8일 (수) 15시에 제출본 일괄 확인 후 피드백

### 제출 방법
* 구글 form에 `Dockerfile` 업로드

### 과제 설명
[1] 도커 이미지 생성
* 80포트를 `Dockerfile`에 명시
* ~~웹 서버 이미지를 컨테이너로 실행할 때, `Connection Established` 메시지를 콘솔에 출력~~
  * 해당 조건 삭제
* 헬스 체크
  * 컨테이너 상태를 2초 간격으로 모니터링
  * 타임아웃 시간을 5초로 설정
  * 접속이 5번 이상 실패하면 비정상으로 설정

[2] 생성한 도커 이미지를 도커 허브에 업로드
* 도커 허브에 로그인 후 저장소를 생성하여 생성한 이미지 업로드
  * 다른 유저가 확인 가능하도록 저장소를 `public` 설정
  * 이미지를 업로드할 때 이미지 태그는 1.0으로 설정

### 작업
* `Dockerfile` 수정
  ~~~
  FROM nginx:alpine
  WORKDIR /usr/share/nginx/html
  RUN rm -rf ./*
  COPY ./* ./
  
  EXPOSE 80
  
  # Add exec permission to sh
  #RUN chmod +x ./docker-entrypoint.sh
  #ENTRYPOINT ["./docker-entrypoint.sh"]
  #CMD ["nginx", "-g", "daemon off;"]
  
  ENTRYPOINT ["nginx", "-g", "daemon off;"]
  
  HEALTHCHECK --interval=2s --timeout=5s --retries=5 \
  CMD curl -f http://localhost/ || exit 1
  ~~~
  * `Dockerfile`에서 `CMD`, `ENTRYPOINT` 명령 사용 시 주의
    * `ENTRYPOINT`와 `CMD`를 함께 사용하는 경우 `CMD` 명령이 `ENTRYPOINT` 명령의 파라미터(인수)로 붙음
      * `CMD`, `ENTRYPOINT` 선언 순서는 상관없음
    ~~~
    # [정상 동작]
    ENTRYPOINT ["./docker-entrypoint.sh"]
    CMD ["nginx", "-g", "daemon off;"]
    
    # [CMD가 ENTRYPOINT 명령 파라미터(인수)로 붙어 오류]
    ENTRYPOINT ["nginx", "-g", "daemon off;"]
    CMD ["./docker-entrypoint.sh"]
    
    # [CMD가 ENTRYPOINT 명령 파라미터(인수)로 붙어 오류]
    # 명령의 순서는 상관 없음
    CMD ["./docker-entrypoint.sh"]
    ENTRYPOINT ["nginx", "-g", "daemon off;"]
    
    # [정상 동작]
    # 명령의 순서는 상관 없음
    CMD ["nginx", "-g", "daemon off;"]
    ENTRYPOINT ["./docker-entrypoint.sh"]
    ~~~
* `Dockerfile`에서 실행할 셸 스크립트 `docker-entrypoint.sh` 작성
  ~~~
  #!/bin/bash #!/bin/sh
  
  echo "Connection Established"
  ~~~
* 생성한 `Dockerfile`을 사용하여 이미지 생성
  * `$ sudo docker image build -t jaenyeongdev/portfolio:1.0 .`
* `Dockerhub` 로그인
  * `$ sudo docker login`
* `Dockerhub`에 생성한 이미지 `push`
  * `$ sudo docker push jaenyeongdev/portfoilo:1.0`
    * `$ sudo docker push jaenyeongdev/portfolio:tagname`
    * `$ sudo docker <계정명>/<저장소명>:[태그]`
  * `push` 중 권한 오류가 발생하는 경우
    ~~~
    Error loading config file: /home/jaenyeong/.docker/config.json: open /home/jaenyeong/.docker/config.json: permission denied
    ~~~
    * 해당 경로에서 `$ ls -al` 명령으로 소유 계정, 그룹 등 권한 확인
      * `$ sudo chgrpdocker /home/jaenyeong/.docker/config.json`
      * `$ sudo chmod g+r /home/user/.docker/config.json`
  * `Dockerhub` 에서 업로드 된 도커 이미지 확인
* 도커 `nginx` 실행 확인
  * `$ sudo docker container run -p 80:80 jaenyeongdev/portfolio:1.0`
    * `$ sudo docker container run [OPTIONS] IMAGE [COMMAND] [ARG...]`
  * 브라우저에서 `http://172.16.248.2:80` 접속하여 `nginx` 실행 확인