# `Helm` 차트 실습

## 헬름 설치
* [설치 문서](https://helm.sh/docs/intro/install/#from-script)
* `$ sudo -i`
* `kubectl`이 구성된 마스터 노드에서 설치 진행
  ~~~
  curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
  chmod 700 get_helm.sh
  ./get_helm.sh
  helm -h
  ~~~
* 기본 `StorageClass`로 `rook-ceph-block`을 사용하도록 설정
  * `# kubectl patch storageclass rook-ceph-block -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'`
* `rook-ceph-block`가 `default`인지 확인
  * `# kubectl get sc`
    ~~~
    NAME                        PROVISIONER                  RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
    my-sc                       rook-ceph.rbd.csi.ceph.com   Delete          Immediate           true                   28d
    rook-ceph-block (default)   rook-ceph.rbd.csi.ceph.com   Delete          Immediate           true                   29d
    ~~~

## 공개 리포지터리를 활용한 앱 배포와 삭제
* 마스터 노드에서 진행
* 저장소 확인
  * `# helm repo list`
  * 결과 `Error: no repositories to show`
* 저장소 추가
  * `# helm repo add bitnami https://charts.bitnami.com/bitnami`
    * 결과 `"bitnami" has been added to your repositories`
* 저장소 목록 업데이트
  * `# helm repo update`
* 검색
  * `# helm search repo bitnami`
    ~~~console
    NAME                                        	CHART VERSION	APP VERSION  	DESCRIPTION
    bitnami/bitnami-common                      	0.0.9        	0.0.9        	DEPRECATED Chart with custom templates used in ...
    bitnami/airflow                             	11.4.0       	2.2.3        	Apache Airflow is a platform to programmaticall...
    bitnami/apache                              	9.0.1        	2.4.52       	Chart for Apache HTTP Server
    bitnami/argo-cd                             	3.0.2        	2.2.3        	Declarative, GitOps continuous delivery tool fo...
    bitnami/argo-workflows                      	0.2.2        	3.2.6        	Argo Workflows is meant to orchestrate Kubernet...
    bitnami/aspnet-core                         	3.0.3        	6.0.1        	ASP.NET Core is an open-source framework create...
    bitnami/cassandra                           	9.1.5        	4.0.1        	Apache Cassandra is an open source distributed ...
    bitnami/cert-manager                        	0.4.2        	1.6.1        	Cert Manager is a Kubernetes add-on to automate...
    bitnami/common                              	1.10.4       	1.10.0       	A Library Helm Chart for grouping common logic ...
    bitnami/concourse                           	0.2.2        	7.6.0        	Concourse is a pipeline-based continuous thing-...
    bitnami/consul                              	10.2.3       	1.11.2       	Highly available and distributed service discov...
    bitnami/contour                             	7.3.3        	1.19.1       	Contour Ingress controller for Kubernetes
    bitnami/contour-operator                    	0.2.5        	1.19.1       	The Contour Operator extends the Kubernetes API...
    bitnami/dataplatform-bp1                    	9.0.8        	1.0.1        	OCTO Data platform Kafka-Spark-Solr Helm Chart
    bitnami/dataplatform-bp2                    	10.0.8       	1.0.1        	OCTO Data platform Kafka-Spark-Elasticsearch He...
    bitnami/discourse                           	5.2.3        	2.7.13       	A Helm chart for deploying Discourse to Kubernetes
    bitnami/dokuwiki                            	12.2.1       	20200729.0.0 	DokuWiki is a standards-compliant, simple to us...
    bitnami/drupal                              	11.0.4       	9.3.3        	One of the most versatile open source content m...
    bitnami/ejbca                               	5.1.2        	7.4.3-2      	Enterprise class PKI Certificate Authority buil...
    bitnami/elasticsearch                       	17.7.2       	7.16.3       	A highly scalable open-source full-text search ...
    bitnami/etcd                                	6.13.2       	3.5.1        	etcd is a distributed key value store that prov...
    bitnami/external-dns                        	6.1.2        	0.10.2       	ExternalDNS is a Kubernetes addon that configur...
    bitnami/fluentd                             	5.0.1        	1.14.4       	Fluentd is an open source data collector for un...
    bitnami/geode                               	0.4.3        	1.14.2       	Apache Geode is a data management platform that...
    bitnami/ghost                               	16.0.1       	4.32.3       	A simple, powerful publishing platform that all...
    bitnami/grafana                             	7.6.4        	8.3.4        	Grafana is an open source, feature rich metrics...
    bitnami/grafana-operator                    	2.2.2        	4.1.1        	Kubernetes Operator based on the Operator SDK f...
    bitnami/grafana-tempo                       	1.0.2        	1.2.1        	Grafana Tempo is an open source, easy-to-use an...
    bitnami/haproxy                             	0.3.1        	2.5.1        	HAProxy is a TCP proxy and a HTTP reverse proxy...
    bitnami/harbor                              	11.2.2       	2.4.1        	Harbor is an an open source trusted cloud nativ...
    bitnami/influxdb                            	3.0.2        	2.1.1        	InfluxDB&trade; is an open source time-series d...
    bitnami/jasperreports                       	12.0.4       	7.8.1        	The JasperReports server can be used as a stand...
    bitnami/jenkins                             	8.1.3        	2.319.2      	The leading open source automation server
    bitnami/joomla                              	12.0.3       	4.0.6        	Joomla! is an award winning open source CMS pla...
    bitnami/jupyterhub                          	0.4.2        	1.5.0        	JupyterHub brings the power of notebooks to gro...
    bitnami/kafka                               	14.9.3       	2.8.1        	Apache Kafka is a distributed streaming platform.
    bitnami/keycloak                            	6.0.1        	16.1.0       	Keycloak is a high performance Java-based ident...
    bitnami/kiam                                	0.4.2        	3.6.0        	kiam is a proxy that captures AWS Metadata API ...
    bitnami/kibana                              	9.3.2        	7.16.3       	Kibana is an open source, browser based analyti...
    bitnami/kong                                	5.0.3        	2.7.0        	Kong is an open source Microservice API gateway...
    bitnami/kube-prometheus                     	6.6.3        	0.53.1       	kube-prometheus collects Kubernetes manifests t...
    bitnami/kube-state-metrics                  	2.2.4        	2.3.0        	kube-state-metrics is a simple service that lis...
    bitnami/kubeapps                            	7.7.2        	2.4.2        	Kubeapps is a dashboard for your Kubernetes clu...
    bitnami/kubernetes-event-exporter           	1.3.2        	0.11.0       	This tool allows exporting the often missed Kub...
    bitnami/kubewatch                           	3.2.23       	0.1.0        	Kubewatch is a Kubernetes watcher that currentl...
    bitnami/logstash                            	3.7.3        	7.16.3       	Logstash is an open source, server-side data pr...
    bitnami/magento                             	19.2.3       	2.4.3        	A feature-rich flexible e-commerce solution. It...
    bitnami/mariadb                             	10.3.2       	10.5.13      	Fast, reliable, scalable, and easy to use open-...
    bitnami/mariadb-cluster                     	1.0.2        	10.2.14      	DEPRECATED Chart to create a Highly available M...
    bitnami/mariadb-galera                      	6.2.1        	10.6.5       	MariaDB Galera is a multi-master database clust...
    bitnami/mean                                	6.1.2        	4.6.2        	DEPRECATED MEAN is a free and open-source JavaS...
    bitnami/mediawiki                           	13.0.2       	1.37.1       	Extremely powerful, scalable software and a fea...
    bitnami/memcached                           	6.0.1        	1.6.13       	Chart for Memcached
    bitnami/metallb                             	2.6.2        	0.11.0       	The Metal LB for Kubernetes
    bitnami/metrics-server                      	5.10.14      	0.5.2        	Metrics Server is a cluster-wide aggregator of ...
    bitnami/minio                               	10.0.3       	2022.1.8     	Bitnami Object Storage based on MinIO&reg; is a...
    bitnami/mongodb                             	10.31.4      	4.4.11       	NoSQL document-oriented database that stores JS...
    bitnami/mongodb-sharded                     	3.11.2       	4.4.11       	NoSQL document-oriented database that stores JS...
    bitnami/moodle                              	12.0.2       	3.11.5       	Moodle&trade; is a learning platform designed t...
    bitnami/mxnet                               	2.4.2        	1.9.0        	A flexible and efficient library for deep learning
    bitnami/mysql                               	8.8.23       	8.0.28       	Chart to create a Highly available MySQL cluster
    bitnami/nats                                	7.1.3        	2.7.0        	An open-source, cloud-native messaging system
    bitnami/nginx                               	9.7.3        	1.21.5       	Chart for the nginx server
    bitnami/nginx-ingress-controller            	9.1.3        	1.1.1        	Chart for the nginx Ingress controller
    bitnami/node                                	16.2.5       	16.13.2      	Event-driven I/O server-side JavaScript environ...
    bitnami/node-exporter                       	2.4.1        	1.3.1        	Prometheus exporter for hardware and OS metrics...
    bitnami/oauth2-proxy                        	2.0.1        	7.2.1        	A reverse proxy and static file server that pro...
    bitnami/odoo                                	20.2.3       	15.0.20220110	A suite of web based open source business apps.
    bitnami/opencart                            	11.0.4       	3.0.3-8      	A free and open source e-commerce platform for ...
    bitnami/orangehrm                           	11.0.3       	4.9.0-0      	DEPRECATED OrangeHRM is a free HR management sy...
    bitnami/osclass                             	13.0.3       	8.0.1        	Osclass is a php script that allows you to quic...
    bitnami/owncloud                            	11.0.4       	10.9.1       	A file sharing server that puts the control and...
    bitnami/parse                               	15.1.1       	4.10.4       	Parse is a platform that enables users to add a...
    bitnami/phabricator                         	11.0.30      	2021.26.0    	DEPRECATED Collection of open source web applic...
    bitnami/phpbb                               	11.0.3       	3.3.5        	Community forum that supports the notion of use...
    bitnami/phpmyadmin                          	9.0.2        	5.1.2        	phpMyAdmin is a free software tool written in P...
    bitnami/postgresql                          	10.16.2      	11.14.0      	Chart for PostgreSQL, an object-relational data...
    bitnami/postgresql-ha                       	8.2.6        	11.14.0      	Chart for PostgreSQL with HA architecture (usin...
    bitnami/prestashop                          	14.0.3       	1.7.8-2      	A popular open source ecommerce solution. Profe...
    bitnami/prometheus-operator                 	0.31.1       	0.41.0       	DEPRECATED The Prometheus Operator for Kubernet...
    bitnami/pytorch                             	2.3.24       	1.10.1       	Deep learning platform that accelerates the tra...
    bitnami/rabbitmq                            	8.26.3       	3.9.13       	Open source message broker software that implem...
    bitnami/rabbitmq-cluster-operator           	2.2.1        	1.11.0       	The RabbitMQ Cluster Kubernetes Operator automa...
    bitnami/redis                               	16.1.0       	6.2.6        	Open source, advanced key-value store. It is of...
    bitnami/redis-cluster                       	7.1.3        	6.2.6        	Open source, advanced key-value store. It is of...
    bitnami/redmine                             	17.2.2       	4.2.3        	A flexible project management web application.
    bitnami/solr                                	3.0.2        	8.11.1       	Apache Solr is an open source enterprise search...
    bitnami/sonarqube                           	0.2.4        	9.2.4        	SonarQube is an open source quality management ...
    bitnami/spark                               	5.8.4        	3.2.0        	Spark is a fast and general-purpose cluster com...
    bitnami/spring-cloud-dataflow               	5.0.5        	2.9.2        	Spring Cloud Data Flow is a microservices-based...
    bitnami/sugarcrm                            	1.0.6        	6.5.26       	DEPRECATED SugarCRM enables businesses to creat...
    bitnami/suitecrm                            	10.0.3       	7.12.2       	SuiteCRM is a completely open source enterprise...
    bitnami/tensorflow-inception                	3.3.2        	1.13.0       	DEPRECATED Open-source software library for ser...
    bitnami/tensorflow-resnet                   	3.4.2        	2.7.0        	Open-source software library serving the ResNet...
    bitnami/testlink                            	10.0.3       	1.9.20       	Web-based test management system that facilitat...
    bitnami/thanos                              	9.0.1        	0.24.0       	Thanos is a highly available metrics system tha...
    bitnami/tomcat                              	10.1.5       	10.0.16      	Apache Tomcat is an open-source web server desi...
    bitnami/wavefront                           	3.1.25       	1.8.0        	Chart for Wavefront Collector for Kubernetes
    bitnami/wavefront-adapter-for-istio         	1.0.18       	0.1.5        	Wavefront Adapter for Istio is a lightweight Is...
    bitnami/wavefront-hpa-adapter               	1.0.8        	0.9.8        	Wavefront HPA Adapter for Kubernetes is a Kuber...
    bitnami/wavefront-prometheus-storage-adapter	1.0.21       	1.0.5        	Wavefront Storage Adapter is a Prometheus integ...
    bitnami/wildfly                             	13.1.3       	26.0.1       	Wildfly is a lightweight, open source applicati...
    bitnami/wordpress                           	13.0.4       	5.8.3        	WordPress is the world's most popular blogging ...
    bitnami/zookeeper                           	8.0.1        	3.7.0        	A centralized service for maintaining configura...
    ~~~
* 네임스페이스 생성
  * `# kubectl create ns mysql`
* `MySQL` `mysql` 네임스페이스에 배포
  * `# helm install mysqlname bitnami/mysql -n mysql`
    ~~~console
    NAME: mysqlname
    LAST DEPLOYED: Sun Jan 23 00:24:37 2022
    NAMESPACE: mysql
    STATUS: deployed
    REVISION: 1
    TEST SUITE: None
    NOTES:
    CHART NAME: mysql
    CHART VERSION: 8.8.23
    APP VERSION: 8.0.28

    ** Please be patient while the chart is being deployed **

    Tip:

      Watch the deployment status using the command: kubectl get pods -w --namespace mysql

    Services:

      echo Primary: mysqlname.mysql.svc.cluster.local:3306

    Execute the following to get the administrator credentials:

      echo Username: root
      MYSQL_ROOT_PASSWORD=$(kubectl get secret --namespace mysql mysqlname -o jsonpath="{.data.mysql-root-password}" | base64 --decode)

    To connect to your database:

      1. Run a pod that you can use as a client:

          kubectl run mysqlname-client --rm --tty -i --restart='Never' --image  docker.io/bitnami/mysql:8.0.28-debian-10-r0 --namespace mysql --command -- bash

      2. To connect to primary service (read/write):

          mysql -h mysqlname.mysql.svc.cluster.local -uroot -p"$MYSQL_ROOT_PASSWORD"



    To upgrade this helm chart:

      1. Obtain the password as described on the 'Administrator credentials' section and set the 'root.password' parameter as shown below:

          ROOT_PASSWORD=$(kubectl get secret --namespace mysql mysqlname -o jsonpath="{.data.mysql-root-password}" | base64 --decode)
          helm upgrade --namespace mysql mysqlname bitnami/mysql --set auth.rootPassword=$ROOT_PASSWORD
    ~~~
* 배포된 `MySQL` 확인
  * `# kubectl get pod -n mysql`
* `MySQL` 비밀번호 확인
  * `# kubectl get secret --namespace mysql mysqlname -o jsonpath="{.data.mysql-root-password}" | base64 --decode`
* `MySQL` 접속
  * `# kubectl -n mysql exec -it mysqlname-0 -- mysql -u root -p`
* 헬름 리스트 확인
  * `# helm list -n mysql`
* 상태 확인
  * `# helm status mysqlname -n mysql`
* 배포된 패키지 삭제
  * `# helm uninstall mysqlname -n mysql`

## 새로운 차트 생성과 실행
* 헬름 차트 생성
  * `# helm create mychart`
* 차트 구조 확인
  * `# sudo apt update && sudo apt install tree -y`
  * `# tree mychart`
* 템플릿 자료 확인
  * `# head -n 20 mychart/templates/deployment.yaml`
  * `# cat mychart/templates/service.yaml`
* 설치 시 서비스에 `value` 전달
  * `# helm install --dry-run --debug mychart ./mychart/ --set service.type=LoadBalancer --set service.port=8080`
* `yaml` 파일로 서비스에 `value` 전달
  * `# vim mychart/values.yaml`
    ~~~yaml
    ...
    replicaCount: 1
    
    image:
      repository: httpd
      pullPolicy: IfNotPresent
      # Overrides the image tag whose default is the chart appVersion.
      tag: "alpine3.14" # 이미지 태그 정보 추가
    ...
    service:
      type: ClusterIP # LoadBalancer로 변경
      port: 80
    ~~~
* 헬름 차트 설정 점검
  * `# helm lint mychart`
* 헬름 차트 배포
  * `# helm install mychart ./mychart/`

## 차트 패키징 및 `Github Repository`를 활용한 배포
* [블로그 참조](https://blog.naver.com/isc0304/222515622985)
* `Github` 저장소 생성
  * [샘플 헬름 차트 저장소](https://github.com/jaenyeong/Sample_Helm-charts)
* 헬름을 사용할 수 있는 마스터 노드에 다운로드
  * `# git clone https://github.com/jaenyeong/Sample_Helm-charts.git`
* 헬름 차트 디렉터리 이동
  * `# cd Sample_Helm-charts`
* 헬름 패키지 명령을 통해 차트 디렉터리 전달
  * `# helm create mychart`
  * `# helm create mychart2`
  * `# helm package mychart`
    * 결과 `Successfully packaged chart and saved it to: /root/Sample_Helm-charts/mychart-0.1.0.tgz`
  * `# helm package mychart2`
    * 결과 `Successfully packaged chart and saved it to: /root/Sample_Helm-charts/mychart2-0.1.0.tgz`
* 확인
  * `# ls`
    * 결과 `mychart  mychart-0.1.0.tgz  mychart2  mychart2-0.1.0.tgz`
* 삭제
  * `rm -rf mychart mychart2`
* 인덱스 파일 생성
  * `# helm repo index ./`
* 확인
  * `# ls`
    * 결과 `index.yaml  mychart-0.1.0.tgz  mychart2-0.1.0.tgz`
* 수정
  * `# cat index.yaml`
* 깃 커밋
  * `# git add .`
  * `# git commit -m 'init'`
  * `# git config --global user.email "jaenyeong.dev@gmail.com"`
  * `# git config --global user.name "jaenyeong"`
  * `# git push`
    * [토큰 설정](https://github.com/settings/apps)
      * `repo`, `write:package` 권한 체크 후 토큰 생성
    * 생성된 토큰으로 `push`
* 헬름 저장소 추가
  * `# helm repo add jaenyeong-helm-charts https://raw.githubusercontent.com/jaenyeong/Sample_Helm-charts/main/`
    * 결과 `"jaenyeong-helm-charts" has been added to your repositories`
    * 깃 저장소에 `index` 파일 `raw` 경로를 헬름 저장소로 추가
* 헬름 저장소 확인
  ~~~
  root@kjn-01:~/Sample_Helm-charts# helm repo list
  NAME                 	URL
  bitnami              	https://charts.bitnami.com/bitnami
  jaenyeong-helm-charts	https://raw.githubusercontent.com/jaenyeong/Sample_Helm-charts/main/
  
  root@kjn-01:~/Sample_Helm-charts# helm search repo jaenyeong-helm-charts
  NAME                          	CHART VERSION	APP VERSION	DESCRIPTION
  jaenyeong-helm-charts/mychart 	0.1.0        	1.16.0     	A Helm chart for Kubernetes
  jaenyeong-helm-charts/mychart2	0.1.0        	1.16.0     	A Helm chart for Kubernetes
  ~~~
* 설치
  * `# helm install jaenyeong-helm-charts jaenyeong-helm-charts/mychart`
    ~~~console
    NAME: jaenyeong-helm-charts
    LAST DEPLOYED: Sun Jan 23 02:29:42 2022
    NAMESPACE: default
    STATUS: deployed
    REVISION: 1
    NOTES:
    1. Get the application URL by running these commands:
      export POD_NAME=$(kubectl get pods --namespace default -l "app.kubernetes.io/name=mychart,app.kubernetes.io/instance=jaenyeong-helm-charts" -o jsonpath="{.items[0].metadata.name}")
      export CONTAINER_PORT=$(kubectl get pod --namespace default $POD_NAME -o jsonpath="{.spec.containers[0].ports[0].containerPort}")
      echo "Visit http://127.0.0.1:8080 to use your application"
      kubectl --namespace default port-forward $POD_NAME 8080:$CONTAINER_PORT
    ~~~
* 헬름 설치 상태 확인
  ~~~console
  root@kjn-01:~/Sample_Helm-charts# kubectl get pod
  NAME                                             READY   STATUS    RESTARTS   AGE
  jaenyeong-helm-charts-mychart-5577757f8f-8qvmp   1/1     Running   0          77s
  nginx-sidecar                                    2/2     Running   0          24d
  py                                               1/1     Running   0          9h
  root@kjn-01:~/Sample_Helm-charts# kubectl edit svc
  service/hello-web edited
  service/http-go-v1 skipped
  service/http-go-v2 skipped
  service/http-go-v3 skipped
  service/jaenyeong-helm-charts-mychart skipped
  service/kubernetes skipped
  ~~~
