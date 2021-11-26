# Chapter 07 실습

## Service
* [서비스 문서](https://kubernetes.io/ko/docs/concepts/services-networking/connect-applications-service/)
* yaml 파일 추가
  * `$ kubectl apply -f https://raw.githubusercontent.com/kubernetes/website/main/content/ko/examples/service/networking/run-my-nginx.yaml`
  ~~~yaml
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: my-nginx
  spec:
    selector:
      matchLabels:
        run: my-nginx
    replicas: 2
    template:
      metadata:
        labels:
          run: my-nginx
      spec:
        containers:
        - name: my-nginx
          image: nginx
          ports:
          - containerPort: 80
  ~~~
  * 파드를 클러스터에 노출
* 파드 확인
  * `$ kubectl get pod -o wide`
* 서비스 생성, 파드와 연결 (`expose`)
  * `$ kubectl expose deployment/my-nginx`
* 확인 (`svc`는 `service`의 약자)
  * `$ kubectl get svc`
  * `$ kubectl describe svc my-nginx`

## DNS
* 서비스 확인
  * `$ kubectl get svc -A`
* `CoreDNS` 설치
  * `$ kubectl run --image=alpine dns-test -it -- /bin/sh`
  * 해당 명령 시 `error: timed out waiting for the condition` 에러 발생
  * `dns-test` 파드 상태를 보면 `ImagePullBackOff` 상태
  * 에러 원인
    * `카카오 iCloud`에서 베스티언 호스트를 통해 `docker hub`에 이미지 요청 `pull` 횟수가 한도 초과한 것
      * K8S에서 이미지를 가져올 때
    * IP 주소를 기준으로 이미지 풀 횟수가 6시간 100회 정도로 한정
    * 따라서 임시로 개별 도커허브 아이디를 사용하여 이미지 풀 횟수를 늘리는 방법으로 우회
  * 해결
    * [K8S 문서 참조](https://kubernetes.io/ko/docs/tasks/configure-pod-container/pull-image-private-registry/)
    * 개인별로 `docker hub` 계정을 사용할 것
      * `$ kubectl create secret docker-registry dockersecret --docker-username="" --docker-password="" --docker-server=https://index.docker.io/v1/ --dry-run=client -o yaml > dockersecret.yaml`
        * 위 명령에 `--docker-username`, `--docker-password` 삽입 후 실행
        ~~~yaml
        apiVersion: v1
        data:
          .dockerconfigjson: eyJhdXRocyI6eyJodHRwczovL2luZGV4LmRvY2tlci5pby92MS8iOnsidXNlcm5hbWUiOiJqYWVueWVvbmdkZXYiLCJwYXNzd29yZCI6Ijg3NDMwMDY1am5LISIsImF1dGgiOiJhbUZsYm5sbGIyNW5aR1YyT2pnM05ETXdNRFkxYW01TElRPT0ifX19
        kind: Secret
        metadata:
          creationTimestamp: null
          name: dockersecret
          type: kubernetes.io/dockerconfigjson
        ~~~
    * 적용
      * `$ kubectl apply -f dockersecret.yaml`
    * `secret` 확인
      * `$ kubectl get secret`
    * 실행할 파일(다운로드 할 이미지)에 적용
      ~~~yaml
      apiVersion: v1
      kind: Pod
      metadata:
        creationTimestamp: null
        labels:
          run: dns-test
        name: dns-test
      spec:
        containers:
        - image: alpine
          name: dns-test
          resources: {}
        dnsPolicy: ClusterFirst
        restartPolicy: Always
        imagePullSecrets:
        - name: dockersecret
      status: {}
      ~~~
    * [참고 URL](https://nirsa.tistory.com/148)
* 도메인 IP 정보 등 확인
  * `# nslookup my-nginx`
  * `# cat /etc/resolv.conf`

## Ingress
* 서비스 확인
  * `$ kubectl describe svc my-nginx`
* 외부에 로드밸런싱을 지원하는 `Ingress`를 통해 외부에서도 `nginx` 서비스에 접속 가능토록 실습
* `my-nginx` `yaml` 파일
  * `$ vi run-my-nginx.yaml`
  ~~~yaml
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: my-nginx
  spec:
    selector:
      matchLabels:
        run: my-nginx
    replicas: 2
    template:
      labels:
        run: my-nginx
    spec:
      containers:
      - name: my-nginx
        image: nginx
        ports:
        - containerPort: 80
  ~~~
* 서비스 생성, 확인
  * `$ kubectl expose deployment my-nginx`
    * 위 작업으로 이미 존재
  * `$ kubectl get svc my-nginx`
  * `$ curl ${클러스터 IP}` > nginx 페이지 확인
    * `$ curl 10.107.128.99`
* `minimal-ingress.yaml` 다운로드
  * `$ wget https://raw.githubusercontent.com/kubernetes/website/main/content/ko/examples/service/networking/minimal-ingress.yaml`
  * `$ cat minimal-ingress.yaml`
  * 서비스명을 `test`에서 `my-nginx`로 변경
    ~~~yaml
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: minimal-ingress
      annotations:
        nginx.ingress.kubernetes.io/rewrite-target: /
    spec:
      rules:
      - http:
        paths:
        - path: /testpath
          pathType: Prefix
          backend:
            service:
              name: my-nginx
              port:
                number: 80
    ~~~
    * 외부에서 `/testpath` 경로로 접근시 해당 서비스(`my-nginx`)로 포워딩
      * 그 외 경로는 X
* 실제로 로드밸런싱을 수행할 인그레스 컨트롤러 설치
  * [인그레스 컨트롤러 문서](https://kubernetes.io/ko/docs/concepts/services-networking/ingress-controllers/)
  * [nginx 인그레스 컨트롤러](https://kubernetes.github.io/ingress-nginx/deploy/)
  * `$ kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.0.5/deploy/static/provider/baremetal/deploy.yaml`
* `minimal-ingress.yaml` 생성, 확인
  * `$ kubectl apply -f minimal-ingress.yaml`
  * `$ kubectl get svc -A`
    ~~~
    NAMESPACE       NAME                                 TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
    default         kubernetes                           ClusterIP   10.96.0.1       <none>        443/TCP                      34d
    default         my-nginx                             ClusterIP   10.107.128.99   <none>        80/TCP                       4h12m
    ingress-nginx   ingress-nginx-controller             NodePort    10.98.43.210    <none>        80:31195/TCP,443:31436/TCP   10m
    ingress-nginx   ingress-nginx-controller-admission   ClusterIP   10.109.22.194   <none>        443/TCP                      10m
    kube-system     kube-dns
    ~~~
* IP 확인
  * `$ ip a | grep global`
    ~~~
    inet 172.30.5.108/22 brd 172.30.7.255 scope global dynamic eth0
    inet 172.17.0.1/16 brd 172.17.255.255 scope global docker0
    inet 192.168.213.128/32 scope global tunl0
    ~~~
* 브라우저에서 접속 확인
  * `http://172.30.5.108:31195/`
* 서비스 상태 확인
* `$ kubectl get service -n ingress-nginx`
* `$ kubectl describe svc -n ingress-nginx ingress-nginx-controller`
  ~~~
  Name:                     ingress-nginx-controller
  Namespace:                ingress-nginx
  Labels:                   app.kubernetes.io/component=controller
                            app.kubernetes.io/instance=ingress-nginx
                            app.kubernetes.io/managed-by=Helm
                            app.kubernetes.io/name=ingress-nginx
                            app.kubernetes.io/version=1.0.5
                            helm.sh/chart=ingress-nginx-4.0.7
  Annotations:              <none>
  Selector:                 app.kubernetes.io/component=controller,app.kubernetes.io/instance=ingress-nginx,app.kubernetes.io/name=ingress-nginx
  Type:                     NodePort
  IP Family Policy:         SingleStack
  IP Families:              IPv4
  IP:                       10.98.43.210
  IPs:                      10.98.43.210
  Port:                     http  80/TCP
  TargetPort:               http/TCP
  NodePort:                 http  31195/TCP
  Endpoints:                192.168.21.165:80
  Port:                     https  443/TCP
  TargetPort:               https/TCP
  NodePort:                 https  31436/TCP
  Endpoints:                192.168.21.165:443
  Session Affinity:         None
  External Traffic Policy:  Cluster
  Events:                   <none>
  ~~~
  * 위 명령으로 출력된 endpoint IP 주소로 다시 파드 조회
  * `$ kubectl get pod -A -o wide | grep 192.168.21.165`
* 로드 밸런싱 확인
  * 브라우저에서 `http://172.30.5.108:31195/testpath` 접속 시도 (안나옴)
  * 에러 확인
    * `$ kubectl describe ingress minimal-ingress`
      ~~~
      Name:             minimal-ingress
      Namespace:        default
      Address:
      Default backend:  default-http-backend:80 (<error: endpoints "default-http-backend" not found>)
      Rules:
      Host        Path  Backends
      ----        ----  --------
      *
                  /testpath   my-nginx:80 (192.168.21.147:80,192.168.21.148:80)
      Annotations:  nginx.ingress.kubernetes.io/rewrite-target: /
      Events:       <none>
      ~~~
    * 1.0.0 릴리스 버전은 `ingressclass`가 필요함 (인그레스의 등급을 나타냄)
  * 인그레스 컨트롤러가 1개일 때 해결 방법
    * `ingressclass` 생성 [문서](https://kubernetes.github.io/ingress-nginx/)
    * `$ vi ingressclass.yaml`
    ~~~yaml
    apiVersion: networking.k8s.io/v1
    kind: IngressClass
    metadata:
      labels:
        app.kubernetes.io/component: controller
      name: nginx
      annotations:
        ingressclass.kubernetes.io/is-default-class: "true"
    spec:
      controller: k8s.io/ingress-nginx
    ~~~
    * `$ kubectl apply -f ingressclass.yaml`
  * 인그레스 클래스 확인
    * `$ kubectl get ingressclass`
  * 미니멀 인그레스를 삭제 후 다시 생성(인그레스 클래스가 적용되지 않은 상태)
    * `$ kubectl delete ingress minimal-ingress`
    * `$ kubectl apply -f minimal-ingress.yaml`
  * 브라우저에서 다시 확인
    * `http://172.30.5.108:31195/testpath`
      * 위 설정 상 `/testpath` 경로만 로드 밸런싱되는 상태
* 파드 확인
  * `$ kubectl get pod`
  * `$ kubectl exec -it my-nginx-5b56ccd65f-tnsdh -- /bin/bash`
  * `# cd /usr/share/nginx/html`
  * `index.html` 파일을 변경하여 로드 밸런싱 확인