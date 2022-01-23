# Chapter 08 실습

## `flask`를 활용한 웹페이지 렌더링
* `vscode` 원격 도커 연결
  * 마스터 노드에서 도커 상태 확인
    * `# service docker status`
      ~~~console
      ● docker.service - Docker Application Container Engine
         Loaded: loaded (/lib/systemd/system/docker.service; enabled; vendor preset: enabled)
         Active: active (running) since Sun 2022-01-23 18:52:16 KST; 4h 35min ago
           Docs: https://docs.docker.com
       Main PID: 22568 (dockerd)
          Tasks: 17
         CGroup: /system.slice/docker.service
                 └─22568 /usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock

      Jan 23 22:48:28 kjn-01 dockerd[22568]: time="2022-01-23T22:48:28.824571158+09:00" level=info msg="No non-localhost DNS nameservers are left in resolv.conf. Usi
      Jan 23 22:48:28 kjn-01 dockerd[22568]: time="2022-01-23T22:48:28.824608940+09:00" level=info msg="IPv6 enabled; Adding default IPv6 external servers: [nameserv
      Jan 23 22:54:10 kjn-01 dockerd[22568]: time="2022-01-23T22:54:08.877469913+09:00" level=warning msg="[resolver] connect failed: dial udp 127.0.0.53:53: i/o tim
      Jan 23 22:54:10 kjn-01 dockerd[22568]: time="2022-01-23T22:54:08.877559454+09:00" level=warning msg="[resolver] connect failed: dial udp 127.0.0.53:53: i/o tim
      Jan 23 23:19:28 kjn-01 dockerd[22568]: time="2022-01-23T23:19:22.899700181+09:00" level=error msg="bb46ef12c50da6f4dc42eb0eca7ddfcd88488acbbfb373859baea6c52f70
      Jan 23 23:21:02 kjn-01 dockerd[22568]: time="2022-01-23T23:21:01.818740601+09:00" level=info msg="ignoring event" container=61bbf7e7ffcff19c796aac74b5c0b633ef2
      Jan 23 23:25:29 kjn-01 dockerd[22568]: time="2022-01-23T23:25:29.641282481+09:00" level=info msg="ignoring event" container=4ca1112af1ce1e951b81e052797cea4ad81
      Jan 23 23:25:35 kjn-01 dockerd[22568]: time="2022-01-23T23:25:35.999601680+09:00" level=info msg="ignoring event" container=e1b38c54a41ffb3c491bddd14244a3b5783
      Jan 23 23:25:36 kjn-01 dockerd[22568]: time="2022-01-23T23:25:36.933310740+09:00" level=info msg="Container 850df3ab4596724a6ab1614a3ba753d9ea881a7ab6f2bfd0657
      Jan 23 23:25:37 kjn-01 dockerd[22568]: time="2022-01-23T23:25:37.239497451+09:00" level=info msg="ignoring event" container=850df3ab4596724a6ab1614a3ba753d9ea8
      ~~~
    * 위 결과의 `/lib/systemd/system/docker.service` 경로 수정
      * `# vim /lib/systemd/system/docker.service`
        * `ExecStart` 필드 값 끝에 `-H tcp://0.0.0.0`
        * 기본 포트는 `2375`
    * 적용을 위한 재시작
      * `# systemctl daemon-reload`
      * `# sudo service docker restart`
    * 로컬 도커에서 접속을 위해 컨텍스트 설정
      * `# docker context create --docker host=tcp://172.30.7.133:2375 my-remote`
    * 도커 컨텍스트 사용
      * `# docker context use my-remote`
    * 원래 컨텍스트로 변경
      * `# docker context use default`
  * vscode 실행
    * `docker`, `Remote - container` 플러그인 설치
    * `F1` 단축키를 누른 후 `settings` 검색
    * `Preferences: Open settings.json` 파일 설정 (반드시 `default`가 아닌 파일을 수정할 것)
      * `docker.host` 필드 값 수정
        * `tcp://172.30.7.133:2375`
* 플라스크 실습 환경 구성
  * 마스터 노드에서 도커 컴포즈 설치
    * `# apt update && apt install docker.io docker-compose -y`
  * 도커 컴포즈를 통해 엘라스틱서치, 플라스크 설치
    ~~~
    cat <<EOF > docker-compose.yaml
    version: '3.3'
    services:
      flask:
        image: gasbugs/flask-example
        container_name: flask
        command: sleep infinity
        ports:
          - 80:5000

      # Elasticsearch Docker Images: https://www.docker.elastic.co/
      elasticsearch:
        image: docker.elastic.co/elasticsearch/elasticsearch:7.16.2
        container_name: elasticsearch
        environment:
          - xpack.security.enabled=false
          - discovery.type=single-node
        ulimits:
          memlock:
            soft: -1
            hard: -1
          nofile:
            soft: 65536
            hard: 65536
        cap_add:
          - IPC_LOCK
        volumes:
          - elasticsearch-data:/usr/share/elasticsearch/data
        ports:
          - 9200:9200
          - 9300:9300

      kibana:
        container_name: kibana
        image: docker.elastic.co/kibana/kibana:7.16.2
        environment:
          - ELASTICSEARCH_HOSTS=http://elasticsearch:9200
        ports:
          - 5601:5601
        depends_on:
          - elasticsearch

    volumes:
      elasticsearch-data:
        driver: local
    EOF

    docker-compose -f docker-compose.yaml up -d
    ~~~
    * 엘라스틱서치와 키바나로 인해 너무 느린 경우 컨테이너 중지
      * `# docker ps` > `# docker container stop`
  * `vscode`에서 도커 선택
    * 컨테이너 우클릭하여 `Attach Visual Studio Code` 클릭
      * 폴더가 열려있지 않으면 원하는 컨테이너(`gasbugs/flask-example`의 `/app` 경로) 선택
  * `app.py` 파일 수정 및 실행
    ~~~py
    # app.py
    from flask import Flask, render_template

    #Flask 객체 인스턴스 생성
    app = Flask(__name__)

    @app.route('/') # 접속하는 url
    def index():
      return render_template('index.html')

    if __name__=="__main__":
      #app.run(debug=True)
      # host 등을 직접 지정하고 싶다면
      app.run(host="0.0.0.0", port="5000", debug=True)
    ~~~
    * `root@850df3ab4596:/app# python source/app.py`
      ~~~
       * Serving Flask app "app" (lazy loading)
       * Environment: production
         WARNING: This is a development server. Do not use it in a production deployment.
         Use a production WSGI server instead.
       * Debug mode: on
       * Running on http://0.0.0.0:5000/ (Press CTRL+C to quit)
       * Restarting with stat
       * Debugger is active!
       * Debugger PIN: 312-504-033
      127.0.0.1 - - [23/Jan/2022 15:00:01] "GET / HTTP/1.1" 200 -
      127.0.0.1 - - [23/Jan/2022 15:00:02] "GET /favicon.ico HTTP/1.1" 404 -
      ~~~
      * `http://0.0.0.0:5000`
  * URI를 활용한 변수 전달
    ~~~py
    from flask import Flask
    app = Flask(__name__)

    @app.route("/hello")
    def hello():
      return "<h1>Hello World! 2</h1>"

    @app.route("/profile/<username>")
    def profile(username):
      return "<h1>Profile Page</h1>" + username

    if __name__== "__main__":
      app.run(host='0.0.0.0', port=5000, debug=True)
    ~~~
    * `http://0.0.0.0:5000/hello`
    * `http://0.0.0.0:5000/profile/jaenyeong?`
  * 템플릿을 활용한 전달
    * `templates/form.html` 파일 생성
      ~~~html
      <form>
        {{var}}
        <p>이름: <input type="text" id="input"></p>
        <p>이름 입력 후 제출버튼을 누르세요.
          <input type="button" value="제출" onclick="alert('입력')"/>
        </p>
      </form>
      ~~~
    * `app.py` 파일 수정
      ~~~py
      from flask import Flask, render_template
      app = Flask(__name__)

      @app.route("/form")
      def form():
        return render_template('form.html')

      # 추가 변수를 전달하는 경우 페이지 렌더링
      @app.route("/form/<var>")
      def form_var(var):
        return render_template('form.html', var=var)
        
      if __name__ == "__main__":
        app.run(host='0.0.0.0', port=80, debug=True)
      ~~~
    * `http://0.0.0.0:5000/form/test`
  * 정적 파일 참조
    * `source/static/css/file.css` 파일
      ~~~css
      h1 {
          color-scheme: light;
          font-family: -apple-system,BlinkMacSystemFont,"Malgun Gothic","맑은 고딕",helvetica,"Apple SD Gothic Neo",sans-serif;
          list-style: none;
          font-size: 15px;
          line-height: 30px;
          font-weight: 700;
          letter-spacing: -.3px;
          display: block;
          text-decoration: none;
          color: #03c75a;
      }
      ~~~
    * `source/templates/form.html` 파일
      ~~~html
      <html>
          <head>
              <link rel='stylesheet' href="{{url_for('static', filename='css/file.css')}}"/>
          </head>
          <body>
              <form>
                  <h1> NAVER </h1>
                  <img src="{{url_for('static', filename='img/pets-3715733_960_720.png')}}"/>
                  {{var}}
                  <p>이름: <input type="text" id="input"></p>
                  <p>이름 입력 후 제출버튼을 누르세요.
                    <input type="button" value="제출" onclick="alert('입력')"/>
                  </p>
                </form>
          </body>
      </html>
      ~~~
    * `http://localhost:60021/form/test`

## `flask`를 활용한 REST API 구성
* 플라스크 REST API 라이브러리 설치
  * `# pip install flask_restx`
* 자동차 정보 관리 예제 (파이썬)
  ~~~py
  from flask import Flask, request, Response
  from flask_restx import Resource, Api, fields
  from flask import abort, jsonify


  app = Flask(__name__)
  api = Api(app)

  ns_cars = api.namespace('ns_cars', description='Car APIs')

  car_data = api.model(
      'Car Data',
      {
        "name": fields.String(description="model name", required=True),
        "price": fields.Integer(description="car price", required=True),
        "fuel_type": fields.String(description="fuel type", required=True),
        "fuel_efficiency": fields.String(description="fuel efficiency", required=True),
        "engine_power": fields.String(description="engine power", required=True),
        "engine_cylinder": fields.String(description="engine cylinder", required=True)
      }
  )

  car_info = {}
  number_of_vehicles = 0

  @ns_cars.route('/cars')
  class cars(Resource):
    def get(self):
      return {
          'number_of_vehicles': number_of_vehicles,
          'car_info': car_info
      }


  @ns_cars.route('/cars/<string:brand>')
  class cars_brand(Resource):
    # 브랜드 정보 조회
    def get(self, brand):
      if not brand in car_info.keys():
        abort(404, description=f"Brand {brand} doesn't exist")
      data = car_info[brand]

      return {
          'number_of_vehicles': len(data.keys()),
          'data': data
      }


    # 새로운 브랜드 생성
    def post(self, brand):
      if brand in car_info.keys():
        abort(409, description=f"Brand {brand} already exists")

      car_info[brand] = dict()
      return Response(status=201)


    # 브랜드 정보 삭제
    def delete(self, brand):
      if not brand in car_info.keys():
        abort(404, description=f"Brand {brand} doesn't exists")
        
      del car_info[brand]
      return Response(status=200)


    # 브랜드 이름 변경
    def put(self, brand):
      # todo
      return Response(status=200)
      

  @ns_cars.route('/cars/<string:brand>/<int:model_id>')
  class cars_brand_model(Resource):
    def get(self, brand, model_id):
      if not brand in car_info.keys():
        abort(404, description=f"Brand {brand} doesn't exists")
      if not model_id in car_info[brand].keys():
        abort(404, description=f"Car ID {brand}/{model_id} doesn't exists")

      return {
          'model_id': model_id,
          'data': car_info[brand][model_id]
      }

    @api.expect(car_data) # body
    def post(self, brand, model_id):
      if not brand in car_info.keys():
        abort(404, description=f"Brand {brand} doesn't exists")
      if model_id in car_info[brand].keys():
        abort(409, description=f"Car ID {brand}/{model_id} already exists")

      params = request.get_json() # get body json
      car_info[brand][model_id] = params
      global number_of_vehicles
      number_of_vehicles += 1
    
      return Response(status=200)
    

    def delete(self, brand, model_id):
      if not brand in car_info.keys():
        abort(404, description=f"Brand {brand} doesn't exists")
      if not model_id in car_info[brand].keys():
        abort(404, description=f"Car ID {brand}/{model_id} doesn't exists")

      del car_info[brand][model_id]
      global number_of_vehicles
      number_of_vehicles -= 1

      return Response(status=200)


    @api.expect(car_data)
    def put(self, brand, model_id):
      global car_info

      if not brand in car_info.keys():
        abort(404, description=f"Brand {brand} doesn't exists")
      if not model_id in car_info[brand].keys():
        abort(404, description=f"Car ID {brand}/{model_id} doesn't exists")
      
      params = request.get_json()
      car_info[brand][model_id] = params
      
      return Response(status=200)


  if __name__ == "__main__":
      app.run(debug=True, host='0.0.0.0', port=5000)
  ~~~
* 실행
  * `# python -i source/app.py`
  * 웹 브라우저 접속 `http://localhost:5000/`
* `CURL` 명령으로 테스트
  * `# curl -X 'GET' 'http://192.168.100.132/ns_cars/cars' -H 'accept: application/json'`
* 생성, 조회
  * `# curl -X 'POST' 'http://192.168.100.132/ns_cars/cars/bentz' -H 'accept: application/json' -d ''`
  * `# curl -X 'GET' 'http://192.168.100.132/ns_cars/cars' -H 'accept: application/json'`
* 특정 모델 입력
  ~~~
  curl -X 'POST' 'http://192.168.100.132/ns_cars/cars/bentz/0' \
    -H 'accept: application/json' \
    -H 'Content-Type: application/json' \
    -d '{
    "name": "e-class",
    "price": 1000000,
    "fuel_type": "gasoline",
    "fuel_efficiency": "9.1~13.2km/l",
    "engine_power": "367hp",
    "engine_cylinder": "I6"
  }'
  ~~~
* 입력 정보 조회
  ~~~
  # 특정 모델 조회
  curl -X 'GET' \
    'http://192.168.100.132/ns_cars/cars/bentz/0' \
    -H 'accept: application/json'

  # 전체 모델 조회
  curl -X 'GET' \
    'http://192.168.100.132/ns_cars/cars' \
    -H 'accept: application/json'
  ~~~
* 삭제
  ~~~
  curl -X 'DELETE' \
  'http://192.168.100.132/ns_cars/cars/bentz' -H 'accept: application/json'
  ~~~
