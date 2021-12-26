# Chapter 03 실습

## `User Account`, `Service Account`
* `root`로 전환
  * `$ sudo -i`
* `Static Token File`
  * `apiserver`에 토큰 등록, 리부팅
    * `# vim somefile.csv`
      ~~~csv
      password1,user1,uid001,"group1"
      password2,user2,uid002
      password3,user3,uid003
      password4,user4,uid004
      ~~~
  * 스태틱파드의 경로(`/etc/kubernetes/manifests/`) 확인
    * `# ls /etc/kubernetes/manifests/` 명령으로 조회
      ~~~
      etcd.yaml  kube-apiserver.yaml  kube-controller-manager.yaml  kube-scheduler.yaml
      ~~~
    * 위 스태틱파드의 경로는 설정에 따라 언제든 변경될 수 있음
    * 스태틱파드 경로 찾기
      * `# ps -eaf | grep kubelet` 명령으로 조회
        ~~~
        root     17381 17333  5 Nov28 ?        1-13:27:04 kube-apiserver --advertise-address=172.30.5.70 --allow-privileged=true --authorization-mode=Node,RBAC --client-ca-file=/etc/kubernetes/pki/ca.crt --enable-admission-plugins=NodeRestriction --enable-bootstrap-token-auth=true --etcd-cafile=/etc/kubernetes/pki/etcd/ca.crt --etcd-certfile=/etc/kubernetes/pki/apiserver-etcd-client.crt --etcd-keyfile=/etc/kubernetes/pki/apiserver-etcd-client.key --etcd-servers=https://127.0.0.1:2379 --kubelet-client-certificate=/etc/kubernetes/pki/apiserver-kubelet-client.crt --kubelet-client-key=/etc/kubernetes/pki/apiserver-kubelet-client.key --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname --proxy-client-cert-file=/etc/kubernetes/pki/front-proxy-client.crt --proxy-client-key-file=/etc/kubernetes/pki/front-proxy-client.key --requestheader-allowed-names=front-proxy-client --requestheader-client-ca-file=/etc/kubernetes/pki/front-proxy-ca.crt --requestheader-extra-headers-prefix=X-Remote-Extra- --requestheader-group-headers=X-Remote-Group --requestheader-username-headers=X-Remote-User --secure-port=6443 --service-account-issuer=https://kubernetes.default.svc.cluster.local --service-account-key-file=/etc/kubernetes/pki/sa.pub --service-account-signing-key-file=/etc/kubernetes/pki/sa.key --service-cluster-ip-range=10.96.0.0/12 --tls-cert-file=/etc/kubernetes/pki/apiserver.crt --tls-private-key-file=/etc/kubernetes/pki/apiserver.key
        root     17723     1  2 Nov28 ?        16:12:56 /usr/bin/kubelet --bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf --config=/var/lib/kubelet/config.yaml --network-plugin=cni --pod-infra-container-image=k8s.gcr.io/pause:3.5
        root     30916 22136  0 16:00 pts/0    00:00:00 grep --color=auto kubelet
        ~~~
      * 위에서 `--config=/var/lib/kubelet/config.yaml` 확인
        * `# cat /var/lib/kubelet/config.yaml`
          ~~~yaml
          apiVersion: kubelet.config.k8s.io/v1beta1
          authentication:
            anonymous:
              enabled: false
            webhook:
              cacheTTL: 0s
              enabled: true
            x509:
              clientCAFile: /etc/kubernetes/pki/ca.crt
          authorization:
            mode: Webhook
            webhook:
              cacheAuthorizedTTL: 0s
              cacheUnauthorizedTTL: 0s
          cgroupDriver: systemd
          clusterDNS:
          - 10.96.0.10
          clusterDomain: cluster.local
          cpuManagerReconcilePeriod: 0s
          evictionPressureTransitionPeriod: 0s
          fileCheckFrequency: 0s
          healthzBindAddress: 127.0.0.1
          healthzPort: 10248
          httpCheckFrequency: 0s
          imageMinimumGCAge: 0s
          kind: KubeletConfiguration
          logging: {}
          memorySwap: {}
          nodeStatusReportFrequency: 0s
          nodeStatusUpdateFrequency: 0s
          resolvConf: /run/systemd/resolve/resolv.conf
          rotateCertificates: true
          runtimeRequestTimeout: 0s
          shutdownGracePeriod: 0s
          shutdownGracePeriodCriticalPods: 0s
          staticPodPath: /etc/kubernetes/manifests
          streamingConnectionIdleTimeout: 0s
          syncFrequency: 0s
          volumeStatsAggPeriod: 0s
          ~~~
        * `staticPodPath: /etc/kubernetes/manifests` 부분으로 경로 확인 가능
  * `kube-apiserver.yaml` 수정
    * `# vim /etc/kubernetes/manifests/kube-apiserver.yaml`
      * `- --token-auth-file=` 옵션 추가
      ~~~yaml
      apiVersion: v1
      kind: Pod
      metadata:
        annotations:
          kubeadm.kubernetes.io/kube-apiserver.advertise-address.endpoint: 172.30.5.70:6443
        creationTimestamp: null
        labels:
          component: kube-apiserver
          tier: control-plane
        name: kube-apiserver
        namespace: kube-system
      spec:
        containers:
        - command:
          - kube-apiserver
          - --advertise-address=172.30.5.70
          - --allow-privileged=true
          - --authorization-mode=Node,RBAC
          - --client-ca-file=/etc/kubernetes/pki/ca.crt
          - --enable-admission-plugins=NodeRestriction
          - --enable-bootstrap-token-auth=true
          - --etcd-cafile=/etc/kubernetes/pki/etcd/ca.crt
          - --etcd-certfile=/etc/kubernetes/pki/apiserver-etcd-client.crt
          - --etcd-keyfile=/etc/kubernetes/pki/apiserver-etcd-client.key
          - --etcd-servers=https://127.0.0.1:2379
          - --kubelet-client-certificate=/etc/kubernetes/pki/apiserver-kubelet-client.crt
          - --kubelet-client-key=/etc/kubernetes/pki/apiserver-kubelet-client.key
          - --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname
          - --proxy-client-cert-file=/etc/kubernetes/pki/front-proxy-client.crt
          - --proxy-client-key-file=/etc/kubernetes/pki/front-proxy-client.key
          - --requestheader-allowed-names=front-proxy-client
          - --requestheader-client-ca-file=/etc/kubernetes/pki/front-proxy-ca.crt
          - --requestheader-extra-headers-prefix=X-Remote-Extra-
          - --requestheader-group-headers=X-Remote-Group
          - --requestheader-username-headers=X-Remote-User
          - --secure-port=6443
          - --service-account-issuer=https://kubernetes.default.svc.cluster.local
          - --service-account-key-file=/etc/kubernetes/pki/sa.pub
          - --service-account-signing-key-file=/etc/kubernetes/pki/sa.key
          - --service-cluster-ip-range=10.96.0.0/12
          - --tls-cert-file=/etc/kubernetes/pki/apiserver.crt
          - --tls-private-key-file=/etc/kubernetes/pki/apiserver.key
          - --token-auth-file=/etc/kubernetes/pki/somefile.csv
          image: k8s.gcr.io/kube-apiserver:v1.22.4
          imagePullPolicy: IfNotPresent
          livenessProbe:
            failureThreshold: 8
            httpGet:
              host: 172.30.5.70
              path: /livez
              port: 6443
              scheme: HTTPS
            initialDelaySeconds: 10
            periodSeconds: 10
            timeoutSeconds: 15
          name: kube-apiserver
          readinessProbe:
            failureThreshold: 3
            httpGet:
              host: 172.30.5.70
              path: /readyz
              port: 6443
              scheme: HTTPS
            periodSeconds: 1
            timeoutSeconds: 15
          resources:
            requests:
              cpu: 250m
              startupProbe:
          failureThreshold: 24
            httpGet:
              host: 172.30.5.70
              path: /livez
              port: 6443
              scheme: HTTPS
            initialDelaySeconds: 10
            periodSeconds: 10
            timeoutSeconds: 15
          volumeMounts:
          - mountPath: /etc/ssl/certs
            name: ca-certs
            readOnly: true
          - mountPath: /etc/ca-certificates
            name: etc-ca-certificates
            readOnly: true
          - mountPath: /etc/kubernetes/pki
            name: k8s-certs
            readOnly: true
          - mountPath: /usr/local/share/ca-certificates
            name: usr-local-share-ca-certificates
            readOnly: true
          - mountPath: /usr/share/ca-certificates
            name: usr-share-ca-certificates
            readOnly: true
        hostNetwork: true
        priorityClassName: system-node-critical
        securityContext:
          seccompProfile:
            type: RuntimeDefault
        volumes:
        - hostPath:
            path: /etc/ssl/certs
            type: DirectoryOrCreate
          name: ca-certs
        - hostPath:
            path: /etc/ca-certificates
            type: DirectoryOrCreate
          name: etc-ca-certificates
        - hostPath:
            path: /etc/kubernetes/pki
            type: DirectoryOrCreate
          name: k8s-certs
          - hostPath:
          path: /usr/local/share/ca-certificates
          type: DirectoryOrCreate
          name: usr-local-share-ca-certificates
          - hostPath:
          path: /usr/share/ca-certificates
          type: DirectoryOrCreate
          name: usr-share-ca-certificates
      ~~~
      * 단순히 `Static token` 파일 경로만 추가하면 에러 발생
        * 다른 옵션들의 경로(`hostpath`)는 이미 공유가 되고 있는 상태
        * 도커로 확인
          * `# docker ps -a | grep api`
            ~~~
            7da9d35c7a22   8a5cc299272d                             "kube-apiserver --ad…"   About a minute ago   Exited (1) About a minute ago             k8s_kube-apiserver_kube-apiserver-kjn-01_kube-system_18f565e705babf34543edba129d0afd3_5
            760e821fef4a   k8s.gcr.io/pause:3.5                     "/pause"                 5 minutes ago        Up 5 minutes                              k8s_POD_kube-apiserver-kjn-01_kube-system_18f565e705babf34543edba129d0afd3_1
            ~~~
          * `# docker logs 7da9d35c7a22`
            ~~~
            I1226 07:15:57.709760       1 server.go:553] external host was not specified, using 172.30.5.70
            I1226 07:15:57.710573       1 server.go:161] Version: v1.22.4
            Error: open /etc/kubernetes/pki/somefile.csv: no such file or directory
            ~~~
      * 따라서 이미 `volumes` 설정을 통해 공유되고 있는 `/etc/kubernetes/pki` 경로의 `Static token` 파일 위치
        * `# cp somefile.csv /etc/kubernetes/pki/`
        * 파일을 이동시키지 않고 `volumes` 필드(설정)를 추가하여 처리할 수도 있음
  * `kubectl`에 유저 정보 등록하고, 등록한 유저 권한으로 `kubectl get pod` 요청 수행
      ~~~
      kubectl config set-credentials user1 --token=password1
      kubectl config set-context user1-context --cluster=kubernetes --namespace=frontend --user=user1
      kubectl get pod --user user1
      ~~~
    * 결과 (`Forbidden` 결과가 출력되어야 함)
      ~~~
      Error from server (Forbidden): pods is forbidden: User "user1" cannot list resource "pods" in API group "" in the namespace "default"
      ~~~

## `Service Account` 생성과 사용
* 생성
  * `# kubectl create sa sa1`
    * `sa`는 `serviceaccount`의 약자
* 조회
  * `# kubectl get sa,secret`
    ~~~
    serviceaccount/default   1         28d
    serviceaccount/sa1       1         35s

    NAME                         TYPE                                  DATA   AGE
    secret/default-token-2f6g8   kubernetes.io/service-account-token   3      28d
    secret/dockersecret          kubernetes.io/dockerconfigjson        1      28d
    secret/mysecret              Opaque                                2      6d5h
    secret/mysql-pass            Opaque                                1      28d
    secret/sa1-token-4g6wk       kubernetes.io/service-account-token   3      35s
    ~~~
  * `# kubectl get secret default-token-2f6g8 -o yaml`
* 위에서 생성한 서비스 어카운트를 사용하는 파드 구성
  ~~~
  cat <<EOF | kubectl apply -f -
  apiVersion: v1
  kind: Pod
  metadata:
    name: nx
  spec:
    serviceAccountName: sa1
    containers:
    - image: nginx
      name: nx
      imagePullPolicy: IfNotPresent
  EOF
  ~~~
  * `imagePullPolicy: IfNotPresent` 옵션
    * 이미지가 기존에 존재하면 다운로드 하지 않음을 의미
  * 자동으로 마운트 됨 (비활성 옵션 설정 가능)
* 생성된 파드에 `sa1` 시크릿 전달 여부 확인 (자동 마운트 됨)
  * `# kubectl get pod nx -o yaml`
    ~~~yaml
    apiVersion: v1
    kind: Pod
    metadata:
      annotations:
        kubectl.kubernetes.io/last-applied-configuration: |
          {"apiVersion":"v1","kind":"Pod","metadata":{"annotations":{},"name":"nx","namespace":"default"},"spec":{"containers":[{"image":"nginx","imagePullPolicy":"IfNotPresent","name":"nx"}],"serviceAccountName":"sa1"}}
      creationTimestamp: "2021-12-26T08:17:02Z"
      name: nx
      namespace: default
      resourceVersion: "4565254"
      uid: 98da2b15-f7ab-4e59-bb72-252461997afe
    spec:
      containers:
      - image: nginx
        imagePullPolicy: IfNotPresent
        name: nx
        resources: {}
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
        volumeMounts:
        - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
          name: kube-api-access-dz6wv
          readOnly: true
      dnsPolicy: ClusterFirst
      enableServiceLinks: true
      nodeName: kjn-03
      preemptionPolicy: PreemptLowerPriority
      priority: 0
      restartPolicy: Always
      schedulerName: default-scheduler
      securityContext: {}
      serviceAccount: sa1
      serviceAccountName: sa1
      terminationGracePeriodSeconds: 30
      tolerations:
      - effect: NoExecute
        key: node.kubernetes.io/not-ready
        operator: Exists
        tolerationSeconds: 300
      - effect: NoExecute
        key: node.kubernetes.io/unreachable
        operator: Exists
        tolerationSeconds: 300
      volumes:
      - name: kube-api-access-dz6wv
        projected:
          defaultMode: 420
          sources:
          - serviceAccountToken:
              expirationSeconds: 3607
              path: token
          - configMap:
              items:
              - key: ca.crt
                path: ca.crt
              name: kube-root-ca.crt
          - downwardAPI:
              items:
              - fieldRef:
                  apiVersion: v1
                  fieldPath: metadata.namespace
                path: namespace
    status:
      conditions:
      - lastProbeTime: null
        lastTransitionTime: "2021-12-26T08:17:02Z"
        status: "True"
        type: Initialized
      - lastProbeTime: null
        lastTransitionTime: "2021-12-26T08:17:08Z"
        status: "True"
        type: Ready
      - lastProbeTime: null
        lastTransitionTime: "2021-12-26T08:17:08Z"
        status: "True"
        type: ContainersReady
      - lastProbeTime: null
        lastTransitionTime: "2021-12-26T08:17:02Z"
        status: "True"
        type: PodScheduled
      containerStatuses:
      - containerID: docker://cc645c8ff70834ab22180ef43776ba8109e139f455d1ad86b2d5fbf7b3e703ce
        image: nginx:latest
        imageID: docker-pullable://nginx@sha256:097c3a0913d7e3a5b01b6c685a60c03632fc7a2b50bc8e35bcaa3691d788226e
        lastState: {}
        name: nx
        ready: true
        restartCount: 0
        started: true
        state:
          running:
            startedAt: "2021-12-26T08:17:07Z"
      hostIP: 172.30.5.106
      phase: Running
      podIP: 10.40.0.1
      podIPs:
      - ip: 10.40.0.1
      qosClass: BestEffort
      startTime: "2021-12-26T08:17:02Z"
    ~~~
  * `# kubectl exec -it nx -- bash`
    * `# ls /var/run/secrets/kubernetes.io/serviceaccount`
      ~~~
      ca.crt	namespace  token
      ~~~
* 토큰 값을 변수에 전달, `curl` 명령 실행 (위에서 나오지 않은 상태로 실행)
  * `# TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)`
  * `# curl -X GET https://$KUBERNETES_SERVICE_HOST/api --header "Authorization: Bearer $TOKEN" --insecure`
    ~~~
    {
      "kind": "APIVersions",
      "versions": [
        "v1"
      ],
      "serverAddressByClientCIDRs": [
        {
          "clientCIDR": "0.0.0.0/0",
          "serverAddress": "172.30.5.70:6443"
        }
      ]
    }
    ~~~
  * 헤더에 토큰을 넣지 않으면 `403` 에러 발생
* 네임스페이스에 있는 파드 조회
  * `# curl -X GET https://$KUBERNETES_SERVICE_HOST/api/v1/namespaces/default/pods --header "Authorization: Bearer $TOKEN" -k`
* 파드에서 서비스 어카운트 사용
  * [특정 네임스페이스에 리스트 파드 조회](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.22/#list-pod-v1-core)

## 서비스 어카운트 연습문제
* 위에서 `nx`에서 나오지 않은 경우 `exit`로 탈출
* 서비스 어카운트를 생성하기전에 미리 확인
  * `# kubectl create sa http-go --dry-run=client -o yaml`
  ~~~
  apiVersion: v1
  kind: ServiceAccount
  metadata:
    creationTimestamp: null
    name: http-go
  ~~~
* `http-go`을 가진 서비스 어카운트와 파드를 생성, `http-go` 파드가 `http-go` 서비스 어카운트를 사용하도록 설정
  ~~~
  cat <<EOF | kubectl apply -f -
  ---
  apiVersion: v1
  kind: ServiceAccount
  metadata:
    creationTimestamp: null
    name: http-go
  ---
  apiVersion: v1
  kind: Pod
  metadata:
    name: http-go
  spec:
    serviceAccountName: http-go
    containers:
    - image: gasbugs/http-go
      name: http-go
      imagePullPolicy: IfNotPresent
  EOF
  ~~~
* 생성된 파드를 통해 디플로이먼트 리스트 요청
  ~~~
  kubectl exec -it http-go -- bash
  # GET /apis/apps/v1/namespaces/{namespace}/deployments
  TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
  curl -X GET https://$KUBERNETES_SERVICE_HOST/api/v1/namespaces/default/deployments --header "Authorization: Bearer $TOKEN" -k
  ~~~
  * 현재는 권한 없음이 정상

## `TLS` 인증서를 활용한 통신 이해
* K8S 인증서 위치 확인
  * `# ls /etc/kubernetes/pki`
    ~~~
    apiserver-etcd-client.crt     apiserver-kubelet-client.key  ca.crt  front-proxy-ca.crt      front-proxy-client.key  somefile.csv
    apiserver-etcd-client.key     apiserver.crt                 ca.key  front-proxy-ca.key      sa.key
    apiserver-kubelet-client.crt  apiserver.key                 etcd    front-proxy-client.crt  sa.pub
    ~~~
  * `# ls /etc/kubernetes/pki/etcd`
    ~~~
    ca.crt  ca.key  healthcheck-client.crt  healthcheck-client.key  peer.crt  peer.key  server.crt  server.key
    ~~~
* 이동 후 `apiserver` 인증서 정보 확인
  * `# cd /etc/kubernetes/pki/`
  * `# openssl x509 -in apiserver.crt -text`
* `kubeadm` 인증서, `CA` 만료기간 확인
  * `# kubeadm certs check-expiration`
    ~~~
    [check-expiration] Reading configuration from the cluster...
    [check-expiration] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -o yaml'

    CERTIFICATE                EXPIRES                  RESIDUAL TIME   CERTIFICATE AUTHORITY   EXTERNALLY MANAGED
    admin.conf                 Nov 28, 2022 05:12 UTC   336d                                    no
    apiserver                  Nov 28, 2022 05:12 UTC   336d            ca                      no
    apiserver-etcd-client      Nov 28, 2022 05:12 UTC   336d            etcd-ca                 no
    apiserver-kubelet-client   Nov 28, 2022 05:12 UTC   336d            ca                      no
    controller-manager.conf    Nov 28, 2022 05:12 UTC   336d                                    no
    etcd-healthcheck-client    Nov 28, 2022 05:12 UTC   336d            etcd-ca                 no
    etcd-peer                  Nov 28, 2022 05:12 UTC   336d            etcd-ca                 no
    etcd-server                Nov 28, 2022 05:12 UTC   336d            etcd-ca                 no
    front-proxy-client         Nov 28, 2022 05:12 UTC   336d            front-proxy-ca          no
    scheduler.conf             Nov 28, 2022 05:12 UTC   336d                                    no

    CERTIFICATE AUTHORITY   EXPIRES                  RESIDUAL TIME   EXTERNALLY MANAGED
    ca                      Nov 26, 2031 05:12 UTC   9y              no
    etcd-ca                 Nov 26, 2031 05:12 UTC   9y              no
    front-proxy-ca          Nov 26, 2031 05:12 UTC   9y              no
    ~~~
* 인증서 갱신
  * `# kubeadm certs renew all`

## `TLS` 인증서를 활용한 유저 생성
* 개인키, `csr` 생성 후 전자서명
  * 개인키 생성
    * `# openssl genrsa -out kjn.key 2048`
      ~~~
      Generating RSA private key, 2048 bit long modulus (2 primes)
      ................+++++
      .......+++++
      e is 65537 (0x010001)
      ~~~
  * `csr` 생성
    * `# openssl req -new -key kjn.key -out kjn.csr -subj "/CN=kjn/0=boanproject"`
      ~~~
      Can't load /root/.rnd into RNG
      140195633648064:error:2406F079:random number generator:RAND_load_file:Cannot open file:../crypto/rand/randfile.c:88:Filename=/root/.rnd
      req: Skipping unknown attribute "0"
      ~~~
      * 위처럼 에러가 발생할 경우 해당 위치에 파일을 생성 후 다시 시도
        * `# echo test > /root/.rnd`
      ~~~
      req: Skipping unknown attribute "0"
      ~~~
  * `csr`을 사용해 `CA` 권한으로 전자서명해 CRT 발급
    * `# openssl x509 -req -in kjn.csr -CA /etc/kubernetes/pki/ca.crt -CAkey /etc/kubernetes/pki/ca.key -CAcreateserial -out kjn.crt -days 365`
      ~~~
      Signature ok
      subject=CN = kjn
      Getting CA Private Key
      ~~~
      * `CAcreateserial` 옵션을 주지 않으면 생성되지 않음
  * 확인
    * `# ls kjn*`
      ~~~
      kjn.crt  kjn.csr  kjn.key
      ~~~
  * `csr` 삭제 (필요 없음)
    * `# rm kjn.csr`
* `kubectl` 설정에서 유저 정보 등록
  * 유저 정보 생성
    * `# kubectl config set-credentials kjn --client-certificate=kjn.crt  --client-key=kjn.key`
      ~~~
      User "kjn" set.
      ~~~
  * 유저와 클러스터 정보 연결
    * `# kubectl config set-context kjn@kubernetes --cluster=kubernetes --namespace=office --user=kjn`
      ~~~
      Context "kjn@kubernetes" created.
      ~~~
  * 컨텍스트를 사용해 접속
    * `# kubectl --context=kjn@kubernetes get pods`
      ~~~
      Error from server (Forbidden): pods is forbidden: User "kjn" cannot list resource "pods" in API group "" in the namespace "office"
      ~~~
      * 권한이 없기 때문에 `forbidden` 반환
  * 컨텍스트 스위칭을 사용
    * `# kubectl config use-context kjn@kubernetes`
      ~~~
      Switched to context "kjn@kubernetes".
      ~~~
    * 이후부터는 권한으로 에러 발생함
      * `# kubectl get pod`
        ~~~
        Error from server (Forbidden): pods is forbidden: User "kjn" cannot list resource "pods" in API group "" in the namespace "office"
        ~~~
  * 관리자 권한으로 돌아오기
    * `# kubectl config use-context kubernetes-admin@kubernetes`

## 유저 관리 연습문제
* `dev1`팀에 `john`이 참여 `john`을 위한 인증서를 만들고 승인.
  ~~~console
  openssl genrsa -out john.key 2048
  openssl req -new -key john.key -out john.csr -subj "/CN=john/0=dev1"
  openssl x509 -req -in john.csr -CA /etc/kubernetes/pki/ca.crt -CAkey /etc/kubernetes/pki/ca.key -CAcreateserial -out john.crt -days 365
  rm john.csr

  kubectl config set-credentials john --client-certificate=john.crt  --client-key=john.key
  kubectl config set-context john@kubernetes --cluster=kubernetes --namespace=dev1 --user=john
  kubectl --context=john@kubernetes get pods
  ~~~

## `kube config` 파일을 사용한 인증
* `# kubectl config view`
  * `# kubectl config view --raw`
  * `# kubectl config view --kube config=${config file}`

## `RBAC` 기반 권한 관리
* 권한 확인
  * `# kubectl get pod --user=kjn`
  * `# kubectl get pod --context=kjn@kubernetes`
  * `# kubectl get deploy --context=kjn@kubernetes`
* 네임스페이스 생성
  * `# kubectl create ns office`
* `kjn`에게 파드, 디플로이먼트 읽기 권한 할당하기
  ~~~
  cat <<EOF | kubectl apply -f -
  apiVersion: rbac.authorization.k8s.io/v1
  kind: Role
  metadata:
    namespace: office
    name: pod-deploy-reader
  rules:
  - apiGroups: ["apps", ""] # "" indicates the core API group
    resources: ["pods", "deployments"]
    verbs: ["get", "watch", "list"]
  ---
  apiVersion: rbac.authorization.k8s.io/v1
  kind: RoleBinding
  metadata:
    name: read-pods-deploys
    namespace: office
  subjects:
  - kind: User
    name: kjn
    apiGroup: rbac.authorization.k8s.io
  roleRef:
    kind: Role
    name: pod-deploy-reader
    apiGroup: rbac.authorization.k8s.io
  EOF
  ~~~
* 다시 확인
  * `# kubectl get pod --context=kjn@kubernetes`
  * `# kubectl get deploy --context=kjn@kubernetes`

## `RBAC` 권한 연습문제
* `john` 유저에게 `dev1` 네임스페이스에 대한 파드, 레플리카셋, 디플로이먼트를 조회, 생성 및 삭제할 수 있는 권한 부여
  ~~~
  kubectl create ns dev1

  cat <<EOF | kubectl apply -f -
  apiVersion: rbac.authorization.k8s.io/v1
  kind: Role
  metadata:
    namespace: dev1
    name: deploy-manager
  rules:
  - apiGroups: ["apps", ""] # "" indicates the core API group
    resources: ["pods", "deployments", "replicasets"]
    verbs: ["get", "watch", "list", "create", "delete"]
  ---
  apiVersion: rbac.authorization.k8s.io/v1
  kind: RoleBinding
  metadata:
    name: manage-deploys
    namespace: dev1
  subjects:
  - kind: User
    name: john
    apiGroup: rbac.authorization.k8s.io
  roleRef:
    kind: Role
    name: deploy-manager
    apiGroup: rbac.authorization.k8s.io
  EOF
  ~~~
* 권한 확인
  * `# kubectl get pod --context=john@kubernetes`
  * `# kubectl get deploy --context=john@kubernetes`
  * `# kubectl --context=john@kubernetes create deploy nx --image=nginx`
  * `# kubectl --context=john@kubernetes delete deploy nx`
  * `# kubectl --context=john@kubernetes delete rs nx`
