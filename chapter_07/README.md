# Chapter07 실습

## 깃허브
* 실습 소스를 `Github`에 저장 후 `VMware Fusion`에서 다운로드
  * `$ git clone https://github.com/jaenyeong/Sample_Docker-springboot-app.git springboot-sample-app`

## 샘플 소스를 통해 도커 컴포즈 실습
* 구성
  * `Spring Boot` + `Maria DB`
* 소스 경로 이동
  * `$ cd springboot-sample-app`
  * `$ cat docker-compose.yml` (내용이 없는 상태)
* 환경 변수 설정 (`docker-compose.yml` 파일 내에 작성)
  ~~~yaml
  services:
    mariadb:
      container_name: mariadb
      environment:
        MARIADB_ROOT_PASSWORD: root
        MARIADB_DATABASE: testdb
      restart: always
    
    sampleapp:
      container_name: springboot
      build: .
      environment:
        MARIADB_ADDRESS: mariadb
        MARIADB_USERNAME: root
        MARIADB_PASSWORD: root
      ports:
        - "8080:8080"
      restart: always
      depends_on:
        - mariadb
  ~~~
  * `container_name`
    * 서비스명과 컨테이너명을 다르게 설정
  * `mariadb` 서비스 환경 변수에 위와 같이 비밀번호만 설정 시 계정은 `root`로 설정됨
  * `build` 키워드로 현재 디렉터리 경로를 베이스 이미지로 빌드
    * 지정한 경로에 `Dockerfile` 유무 확인 필요
  * `sampleapp`의 `depends_on`을 통하여 `sampleapp` 서비스가 `mariadb` 서비스에 의존함을 명시
    * `mariadb` 서비스가 실행된 이후에 `sampleapp` 서비스를 실행
    * 하지만 컨테이너 상태만을 바라볼 뿐 실제 `mariadb` 서비스가 완전히 접속 또는 리스닝 상태를 확인하지는 않음
    * `depends_on`은 서비스명을 참조
* 실행
  * `$ sudo docker-compose up`
* 접속 확인
  * 브라우저에서 `http://172.16.248.2:8080/swagger-ui.html`
  * 화면에서 POST 요청 등으로 테스트