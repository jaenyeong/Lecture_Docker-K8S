# 실습 과제

## 16주차 과제

### 진행단계
`Chapter08 백업 및 복구` 수강 후 

### 제출
* 2021년 11월 23일 (화)까지

### 제출 방법
* 메일 제출 (ohsk@kakao.com)
* 구글 form에 `복구 캡처 사진`을 첨부하여 제출

### 과제 설명
백업 및 복구
* 마스터 노드에 snapshot 파일 다운로드, 해당 파일로 복구
* 복구 후 파드 상태를 조회, 화면 캡처하여 제출
  * 3개의 마스터 노드 중 1개만 복구 완료하여도 통과 인정
* 힌트
  * 스태틱 파드의 볼륨 수정
  * 현재 각자 환경에 설치되어 실행중인 `etcd config`

### 작업
* `snapshot-pre-boot.db` 파일 마스터 노드에 다운로드
  * `$ wget http://172.30.5.154/snapshot-pre-boot.db`
* 복구
  * `$ sudo su -`
    * 루트 권한으로 하지 않은 경우 안됨..
  * `$ ETCDCTL_API=3 etcdctl --endpoints=https://172.30.5.108:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --name=master --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key --data-dir /var/lib/etcd-why-backup --initial-cluster=master=https://127.0.0.1:2380 --initial-cluster-token etcd-cluster-1 --initial-advertise-peer-urls=https://127.0.0.1:2380 snapshot restore /tmp/snapshot-pre-boot.db`
* `etcd.yaml` 파일에서 경로 수정
  * `$ sudo vi /etc/kubernetes/manifests/etcd.yaml`
  * `- hostPath:`
    * `path: /var/lib/etcd-why-backup`
* 기존 etcd 디렉터리 삭제
  * `$ sudo rm -rf /var/lib/etcd`