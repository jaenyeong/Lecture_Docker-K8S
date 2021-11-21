# Chapter 08 실습

## Logging & TroubleShooting
* 쿠버네티스에서 로깅
  * [문서](https://kubernetes.io/ko/docs/concepts/cluster-administration/logging/)
  * `$ kubectl apply -f https://k8s.io/examples/debug/counter-pod.yaml`
    * 위 작업에서 또 이미지 풀 횟수 초과로 실패 시 `yaml` 파일 새로 생성하여 실행
    ~~~yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: counter
    spec:
      containers:
      - name: count
        image: busybox
        args: [/bin/sh, -c, 'i=0; while true; do echo "$i: $(date)"; i=$((i+1)); sleep 1; done']
      imagePullSecrets:
      - name: dockersecret
    ~~~
  * `$ kubectl logs counter`
* 로그 실제 위치?
  * 해당 워커 노드에 접속 (2번 워커 노드)
    * `$ ls -lrt /var/log/containers/counter_default_count-e8053f8e4fe0eff219e5b4f96dc28b2569d3407dd310b179b5ca98009f1b56df.log`
      * 위 명령 입력시 최종 로그 경로를 출력
        * `/var/log/pods/default_counter_1e2e59ec-8ac3-41e7-a3f1-58117175ff4a/count/0.log`
        * `$ sudo head -3 /var/log/pods/default_counter_1e2e59ec-8ac3-41e7-a3f1-58117175ff4a/count/0.log`

## 모니터링 클러스터 컴포넌트
* `$ kubectl top node`
* `$ kubectl top pod`
* `$ kubectl top --help`

## 백업 및 복구
* [etcd 문서](https://github.com/etcd-io/etcd/releases)
* Pod로 구동된 `etcd` 버전 확인 후 해당 `etcdctl` 설치
  * `$ kubectl get pod -n kube-system` (`etcd` 파드명 확인)
  * 정보 확인
    * `$ kubectl describe -n kube-system pod etcd-kjn-master-01.kr-central-1.c.internal`
  * 버전 명시 변수 선언
    * `$ ETCD_VER=v3.5.0`
  * 설치
    * `$ wget https://storage.googleapis.com/etcd/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz`
  * 압축 해제
    * `$ tar xzvf etcd-${ETCD_VER}-linux-amd64.tar.gz`
  * 위치 이동
    * `$ sudo mv etcd-${ETCD_VER}-linux-amd64/etcdctl /usr/local/bin/etcdctl`
  * 설치 확인
    * `$ etcdctl version`
* [etcd 명령어](https://discuss.kubernetes.io/t/etcd-backup-and-restore-management/11019/11)

* 백업
  ~~~
  ETCDCTL_API=3 etcdctl --endpoints=https://[127.0.0.1]:2379 --cacert=/etc/kubernetes/pki/et cd/ca.crt \ --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/serv er.key \ snapshot save /tmp/snapshot-pre-boot.db
  ~~~
* 복구
  ~~~
  ETCDCTL_API=3 etcdctl --endpoints=https://[127.0.0.1]:2379 --cacert=/etc/kubernetes/pki/et cd/ca.crt \ --name=master \ --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernet es/pki/etcd/server.key \ --data-dir /var/lib/etcd-from-backup \ --initial-cluster=master=h ttps://127.0.0.1:2380 \ --initial-cluster-token etcd-cluster-1 \ --initial-advertise-peer- urls=https://127.0.0.1:2380 \ snapshot restore /tmp/snapshot-pre-boot.db
  ~~~
  * 복구할 때 데이터 디렉터리(`--data-dir`)를 다르게 설정(할당)하는 것이 좋음
    * 그대로 사용한다면(기존 경로에 덮어 썼을 때) 잘못 됐을 때 그 전으로 되돌릴 수 없음
    * 위처럼 `etcd-from-backup`나 다른 이름으로 변경하여 설정할 것