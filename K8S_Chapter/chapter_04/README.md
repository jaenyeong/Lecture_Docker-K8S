# Chapter04 실습

## APIs and Access
* Role, Cluster Role
  ~~~
  # role을 yaml 파일로 생성
  $ kubectl create role pod-reader --verb=get --verb=list --verb=watch --resource=pods --dry-run=client -o yaml > pod-reader-role.yaml

  # 아무것도 생성되지 않음
  $ kubectl get role

  $ cat pod-reader-role.yaml

  # clusterrole을 yaml 파일로 생성
  $ kubectl create clusterrole pod-reader --verb=get --verb=list --verb=watch --resource=pods --dry-run=client -o yaml > pod-reader-cluster.yaml

  # 비교
  $ diff pod-reader-role.yaml pod-reader-cluster.yaml

  $ kubectl apply -f pod-reader-role.yaml

  # pod-reader-role 생성 확인
  $ kubectl get role

  $ kubectl apply -f pod-reader-cluster.yaml

  # pod-reader-cluster 생성 확인
  $ kubectl get clusterrole | grep pod

  # kubeadm 확인 (실행 당시 not found)
  $ kubectl edit role kubeadm -n kube-public

  # kube-proxy 확인
  $ kubectl edit role kube-proxy -n kube-system
  ~~~
* RoleBinding, ClusterRoleBinding, serviceaccount
  ~~~
  # serviceaccount 생성
  $ kubectl create serviceaccount jnkim

  # rolebinding 생성
  $ kubectl create rolebinding jnkim-pod-reader --role=pod-reader --serviceaccount=default:jnkim

  # 확인
  $ kubectl get rolebinding
  $ kubectl describe rolebinding jnkim-pod-reader
  ~~~