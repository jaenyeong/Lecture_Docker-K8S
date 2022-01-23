# Chapter 06 실습

## 클러스터 컴포넌트 모니터링
* `$ sudo -i`
* 마스터 노드에 메트릭 서버 설치
  * `# kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.5.2/components.yaml`
* 설치 여부 확인
  * `# kubectl top pod`
    * 결과 `Error from server (ServiceUnavailable): the server is currently unable to handle the request (get pods.metrics.k8s.io)`
    * kubelet에 접근 시 필요한 인증 정보를 갖고 있지 않아 발생하는 에러
* 서버 수정 (`arg`에 내용 추가)
  * `# kubectl edit deployments.apps -n kube-system metrics-server`
    * `- --kubelet-insecure-tls`
  * `kubelet` 접근 시 필요한 인증을 하지 않게끔 설정
* 확인
  * `# kubectl get pod -n kube-system -w`
* 메트릭 서버를 활용해 리소스 확인
  * `# kubectl top nodes`
    ~~~console
    NAME     CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
    kjn-01   206m         10%    1596Mi          41%
    kjn-02   184m         9%     2751Mi          71%
    kjn-03   1137m        56%    2362Mi          61%
    kjn-04   <unknown>                           <unknown>               <unknown>               <unknown>
    ~~~
  * `# kubectl top pod`
    ~~~console
    NAME                                             CPU(cores)   MEMORY(bytes)
    jaenyeong-helm-charts-mychart-5577757f8f-8qvmp   1m           2Mi
    nginx-sidecar                                    1m           44Mi
    py                                               0m           2Mi
    ~~~

## 큐브 대시보드 설치와 활용
* [문서](https://kubernetes.io/ko/docs/tasks/access-application-cluster/web-ui-dashboard/)
* 설치
  * `# kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.4.0/aio/deploy/recommended.yaml`
* 대시보드 배포 확인
  * `# kubectl get svc -n kubernetes-dashboard`
    ~~~console
    NAME                        TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
    dashboard-metrics-scraper   ClusterIP   10.98.153.19    <none>        8000/TCP   24s
    kubernetes-dashboard        ClusterIP   10.99.212.156   <none>        443/TCP    24s
    ~~~
* `spec.type` 필드를 `ClusterIP` → `NodePort`로 변경해 외부에서 접근이 가능하도록 설정
  * `nodePort` 옵션도 하나 추가하고 `30443`로 구성
  * `# kubectl edit svc kubernetes-dashboard -n kubernetes-dashboard`
* 웹 브라우저에서 `30443` 포트로 접속해 확인
  * `https://172.30.5.70:30443`
* 접속이 되지 않는 경우
  * 고급 옵션으로 가서 안전하지 않음을 클릭
    * 만약 고급 버튼이 없다면 페이지를 클릭하고 `thisisunsafe`라고 타이핑
* 접속 시 토큰 발급
  * 샘플 유저 생성 시 전체 클러스터 권한 소유 주의
  ~~~
  cat <<EOF | kubectl apply -f -
  # 서비스어카운트 생성
  apiVersion: v1
  kind: ServiceAccount
  metadata:
    name: admin-user
    namespace: kubernetes-dashboard
  ---
  # 클러스터롤바인딩 생성
  apiVersion: rbac.authorization.k8s.io/v1
  kind: ClusterRoleBinding
  metadata:
    name: admin-user
  roleRef:
    apiGroup: rbac.authorization.k8s.io
    kind: ClusterRole
    name: cluster-admin
  subjects:
  - kind: ServiceAccount
    name: admin-user
    namespace: kubernetes-dashboard
  EOF

  # 토큰 가져오기
  kubectl -n kubernetes-dashboard get secret $(kubectl -n kubernetes-dashboard get sa/admin-user -o jsonpath="{.secrets[0].name}") -o go-template="{{.data.token | base64decode}}"
  ~~~
* 토큰으로 로그인
  * `eyJhbGciOiJSUzI1NiIsImtpZCI6IldwbVEyZHJOYTI2WkQ2WVBJMEdpQk84aVdYd3dCdGxBY1hqSlh6am4wUEUifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJrdWJlcm5ldGVzLWRhc2hib2FyZCIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VjcmV0Lm5hbWUiOiJhZG1pbi11c2VyLXRva2VuLWhuNHY4Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZXJ2aWNlLWFjY291bnQubmFtZSI6ImFkbWluLXVzZXIiLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC51aWQiOiJmMTk2ZTU1ZC0zNzYwLTRjZjUtODkwYS03ZDU2NTc5NzUyYTYiLCJzdWIiOiJzeXN0ZW06c2VydmljZWFjY291bnQ6a3ViZXJuZXRlcy1kYXNoYm9hcmQ6YWRtaW4tdXNlciJ9.oFokUrHL-3T3yEvyKPYNjCVlnzATT6WW3alPLxsLyz9xkjNQZvck-4eCfADKk8rDYKxpdg7Mg7mqjKphdtgxgVPA7uBs9-UJXuphO0VyYeGweUUZjDeAy4B49-9_VoBxtWv3-LcLECv9q_B0vYgeDn4Xjb5QUMgUiEB9X4nFmIHA75ZZ1wd_0c3CymSECXMe-xyVutKEvuW2eMx0-QVOfvXZG9u-dfSiG-eg2QapxVATrG5sutFHDQN7dUimpjHmYBm1V4F8pkZnfLxhyFETAa87uiuRK_0n_1sy7XjmPgZu7zpzFOSz0D5hqF3GWhnjAMG5RmTWz_5nGkBblXyGSw`

## 프로메테우스 그라파나를 활용한 리소스 모니터링
* 프로메테우스와 그라파나를 위한 헬름 저장소를 추가
  * `# helm repo add prometheus-community https://prometheus-community.github.io/helm-charts`
  * `# helm repo add grafana https://grafana.github.io/helm-charts`
  * `# helm repo update`
* 헬름 배포를 위해 그라파나와 프로메테우스의 `values.yaml`을 구성할 디렉터리를 하나 구성
  * `# mkdir grafana_prometheus && cd grafana_prometheus`
* `values-prometheus.yaml`를 생성
  ~~~
  cat <<EOF > values-prometheus.yaml
  server:
    enabled: true

    persistentVolume:
      enabled: true
      accessModes:
        - ReadWriteOnce
      mountPath: /data
      size: 10Gi
    replicaCount: 1

    ## Prometheus data retention period (default if not specified is 15 days)
    ##
    retention: "15d"
  EOF
  ~~~
* `values-grafana.yaml`를 생성
  * `pvc`를 구성하여 스토리지를 구성하여 설정정보를 유지할 수 있도록 구성
  ~~~
  cat << EOF > values-grafana.yaml
  replicas: 1

  service:
    type: NodePort

  persistence:
    type: pvc
    enabled: true
    # storageClassName: default
    accessModes:
      - ReadWriteOnce
    size: 10Gi
    # annotations: {}
    finalizers:
      - kubernetes.io/pvc-protection

  # Administrator credentials when not using an existing secret (see below)
  adminUser: admin
  adminPassword: test1234!234
  EOF
  ~~~
* 프로메테우스를 위한 네임스페이스를 구성하고 위 설정대로 `yaml` 파일을 배포
  * `# kubectl create ns prometheus`
  * `# helm install prometheus prometheus-community/prometheus -f values-prometheus.yaml -n prometheus`
  * `# helm install grafana grafana/grafana -f values-grafana.yaml -n prometheus`
* 로그인
  * ID
    * `admin`
  * PW
    * `test1234!234`
* 왼쪽 메뉴에서 `Configuration` – `Data Sources` 메뉴에서 데이터 소스 추가
* 프로메테우스를 선택하고 URL에 앞서 자동 생성된 `service`의 이름을 입력
  * `http://prometheus-server`을 입력하고 `save & test` 클릭

## `Istio`를 활용한 네트워크 메시 모니터링
* 마스터 노드에 `Istioctl` 설치
  ~~~
  curl -L https://istio.io/downloadIstio | sh -
  cd istio-1.12.2
  export PATH=$PWD/bin:$PATH # 실행 경로를 환경 변수에 추가
  istioctl # kubectl 설정을 사용
  ~~~
* `istio`를 K8S에 설치
  * `# istioctl install --set profile=default --skip-confirmation`
* 디폴트 네임스페이스에 적용
  * `# kubectl label namespace default istio-injection=enabled`
* `bookinfo` 프로젝트 배포
  * 잘못 설치한 경우 삭제
    * `# kubectl delete all --all`
    * `# kubectl delete limitrange default-limit-range`
  * `# kubectl delete -f samples/bookinfo/platform/kube/bookinfo.yaml`
  * `# kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml`
* `ingress gateway`와 북인포 프로젝트 연결을 수행
  * 이 과정은 `gateway`를 만들어서 구성이 되는데 게이트웨이의 룰에 의해 어떻게 로드밸런싱 할지 결정됨
    * `# kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml`
    * `# kubectl get svc -n istio-system -l istio=ingressgateway`
* 대시보드와 데이터베이스를 설치하고 서비스를 오픈
  ~~~
  kubectl apply -f samples/addons/ .yaml
  kubectl apply -f samples/addons/prometheus.yaml
  istioctl dashboard kiali # localhost:20001 서비스를 오픈
  ~~~

## `EFK`를 활용한 K8S 로그 모니터링
* 디렉터리 생성, 파일 압축 해제
  ~~~
  mkdir efk && cd efk
  <file download>
  # wget https://blogattach.naver.com/54c148f8ebb7b06c40a2c7f4cc2e552b86db22c572/20211003_33_blogfile/isc0304_1633192930812_gYBc80_zip/efk.zip
  unzip efk.zip
  kubectl apply -f ns.yaml
  kubectl apply -f ./*
  ~~~
* 엘라스틱 서치 서비스 확인
  * `# kubectl get svc -n elastic`

## 오토 스케일링 `HPA` 워크스루
* 마스터 노드에서 부하 테스트를 위한 파드 생성
  * `# kubectl apply -f https://k8s.io/examples/application/php-apache.yaml`
    ~~~yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: php-apache
    spec:
      selector:
        matchLabels:
          run: php-apache
      replicas: 1
      template:
        metadata:
          labels:
            run: php-apache
        spec:
          containers:
          - name: php-apache
            image: k8s.gcr.io/hpa-example
            ports:
            - containerPort: 80
            resources:
              limits:
                cpu: 500m
              requests:
                cpu: 200m

    ---

    apiVersion: v1
    kind: Service
    metadata:
      name: php-apache
      labels:
        run: php-apache
    spec:
      ports:
      - port: 80
      selector:
        run: php-apache
    ~~~
    * 위 `requests` 필드의 값을 기준으로 스케일링 됨
      * `limits` 필드 값이 최대이나 최대값까지 사용하면 이 경우 `250%`를 사용하는 것
* HPA 생성
  * `# kubectl autoscale deployment php-apache --cpu-percent=50 --min=1 --max=10`
* HPA 확인
  * `# kubectl get hpa`
    ~~~
    NAME         REFERENCE               TARGETS         MINPODS   MAXPODS   REPLICAS   AGE
    php-apache   Deployment/php-apache   <unknown>/50%   1         10        0          9s
    ~~~
* 마스터 노드 새 세션에서 부하 증가
  * `$ sudo -i`
  * `# kubectl run -i --tty load-generator --rm --image=busybox --restart=Never -- /bin/sh -c "while sleep 0.01; do wget -q -O- http://php-apache; done"`
  * 다음 결과가 나오면 종료
    ~~~
    If you don't see a command prompt, try pressing enter.
    OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!
    ~~~
* 기존 세션에서 확인
  * `# kubectl get hpa -w`
    ~~~console
    NAME         REFERENCE               TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
    php-apache   Deployment/php-apache   2%/50%    1         10        1          2m26s
    php-apache   Deployment/php-apache   2%/50%    1         10        1          2m45s
    php-apache   Deployment/php-apache   1%/50%    1         10        1          3m
    php-apache   Deployment/php-apache   2%/50%    1         10        1          3m15s
    php-apache   Deployment/php-apache   74%/50%   1         10        1          3m45s
    php-apache   Deployment/php-apache   114%/50%   1         10        2          4m
    php-apache   Deployment/php-apache   2%/50%     1         10        3          4m15s
    ~~~

## `Jaeger` 트레이싱 튜토리얼
* 추적이 활성화된 소규모 서비스를 빌드해 튜토리얼 실습
* 마스터 노드에 예거 설치 (올인원 이미지)
  * `# docker run -d --name jaeger -p 16686:16686 -p 6831:6831/udp jaegertracing/all-in-one:1.22`
  * `# apt install python3-pip -y`
  * `# pip3 install jaeger-client`
  * `# pip3 install requests`
* 정보를 받아오는 주소
  * `http://ip-api.com/json/naver.com`
    ~~~json
    // 20220123111005
    // http://ip-api.com/json/naver.com

    {
      "status": "success",
      "country": "South Korea",
      "countryCode": "KR",
      "region": "41",
      "regionName": "Gyeonggi-do",
      "city": "Bundang-gu",
      "zip": "13606",
      "lat": 37.3827,
      "lon": 127.119,
      "timezone": "Asia/Seoul",
      "isp": "NBP",
      "org": "",
      "as": "AS23576 NAVER Cloud Corp.",
      "query": "223.130.200.104"
    }
    ~~~
* 파이썬을 실행하고 다음 명령을 실행
  * `# vim python-jaeger-example.py`
  * `# python3 python-jaeger-example.py`
    ~~~py
    import logging
    from jaeger_client import Config
    import requests

    def init_tracer(service):
        logging.getLogger('').handlers = []
        logging.basicConfig(format='%(message)s', level=logging.DEBUG)

        config = Config(
            config={
                'sampler': {
                    'type': 'const',
                    'param': 1,
                },
                'logging': True,
            },
            service_name=service,
        )

        # this call also sets opentracing.tracer
        return config.initialize_tracer()

    tracer = init_tracer('first-service')

    with tracer.start_span('get-ip-api-jobs') as span:
        try:
            res = requests.get('http://ip-api.com/json/naver.com')
            result = res.json()
            print('Getting status %s' % result['status'])
            span.set_tag('jobs-count', len(res.json()))
            for k in result.keys():
                span.set_tag(k, result[k])

        except:
            print('Unable to get site for')

    input('')
    ~~~
  * 결과
    ~~~console
    Initializing Jaeger Tracer with UDP reporter
    Using selector: EpollSelector
    Using sampler ConstSampler(True)
    opentracing.tracer initialized to <jaeger_client.tracer.Tracer object at 0x7fb23ca334e0>[app_name=first-service]
    Starting new HTTP connection (1): ip-api.com
    http://ip-api.com:80 "GET /json/naver.com HTTP/1.1" 200 270
    Getting status success
    Reporting span b5579729080f119:38bad3c484de0081:0:1 first-service.get-ip-api-jobs
    ~~~
