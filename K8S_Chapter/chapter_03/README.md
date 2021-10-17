# Chapter03 실습

## 레플리카 생성
* 레플리카 생성 및 확인
  * `$ kubectl create deployment deploy-test --image nginx --replicas=3`
  * `$ kubectl get deployments.apps deploy-test -o wide`
  * `$ kubectl get pod`
  * `$ kubectl get replicaset`
* 파드 삭제 후 파드 재생성 확인
  * `$ kubectl delete pod deploy-test-84f98964bb-58xtl`
  * `$ kubectl get pod`