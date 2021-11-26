# Chapter06 실습

## Volumes
* `$ sudo fdisk -l`
  * 디스크 파티션을 CRUD 할 수 있는 유틸리티 명령
* `$ sudo cat /etc/fstab`
  * `fstab`은 파일 시스템 정보, 부팅 시 마운트 정보를 보관하는 파일

## PV (Persistent Volume)
* 파드를 삭제해도 PV가 남아 있는지 확인
* 1번 마스터 노드
  * `$ vi hostpath.yaml`
    ~~~yaml
    apiVersion: v1
    kind: Pod
    metadata:
    name: test-pd
    spec:
    containers:
    - image: k8s.gcr.io/test-webserver
      name: test-container
      volumeMounts:
      - mountPath: /test-pd
        name: test-volume
    volumes:
    - name: test-volume
      hostPath:
        # 호스트의 디렉터리 위치
        path: /data
        # 이 필드는 선택 사항이다
        type: Directory
    ~~~
  * 생성
    * `$ kubectl apply -f hostpath.yaml`
  * 확인
    * `$ kubectl get pod`
    * `$ kubectl get pod -o wide`
    * `$ kubectl describe pod test-pd`
  * 2번 워커 노드에 생성을 위해 대기중
    * 2번 워커 노드에서 `data` 디렉터리 생성
    * `$ sudo mkdir /data`
  * 잠시 후에 `data` 디렉터리가 생성된 것을 확인하면 2번 워커 노드에 파드 생성
* 2번 워커 노드
  * `$ sudo touch likelion`
* 1번 마스터 노드
  * 2번 워커 노드에 할당된 테스트 파드 삭제
  * `$ kubectl delete pod test-pd`
* 2번 워커 노드
  * 위에서 생성한 `likelion` 확인
  * `$ ls`
* 1번 마스터 노드
  * `hostpath.yaml` 파일 내 이미지 수정
    * `- image: k8s.gcr.io/test-webserver` -> `- image: nginx`
  * 파드 생성
    * `$ kubectl apply -f hostpath.yaml`
  * 파드 접속
    * `$ kubectl exec -it test-pd -- /bin/bash`
  * 테스트용 디렉터리 생성
    * `$ cd test-pd`
    * `$ touch likelion2`
* 2번 워커 노드
  * `likelion2` 확인
  * `$ ls`
* 1번 마스터 노드
  * 파드 삭제
    * `$ kubectl delete pod test-pd`
    * `$ kubectl get pod -o wide`
* 2번 워커 노드
  * `likelion2` 확인
  * `$ ls`

## ConfigMap
* 컨피그맵 생성
  * `$ kubectl create -f https://kubernetes.io/examples/configmap/configmap-multikeys.yaml`
  * `$ kubectl create -f https://kubernetes.io/examples/pods/pod-configmap-envFrom.yaml`
* 확인
  * `$ kubectl get cm` or `$ kubectl get configmap`
  * `$ kubectl describe configmap special-config`
* 컨테이너 환경 변수 생성
  * `$ kubectl create -f https://kubernetes.io/examples/pods/pod-single-configmap-env-variable.yaml`
* 확인
  * `$ kubectl logs dapi-test-pod`