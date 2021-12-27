# Chapter 04 실습

## 첨부파일 설명
* `accounts.json`
  * 무작위로 생성된 데이터로 구성된 가상 계정 집합
* `Exercise_logs.jsonl`
  * 임의로 생성된 로그 파일 세트
* `shakespeare.json`
  * 윌리엄 셰익스피어의 전체 작품을 적절하게 필드로 파싱

## `ElasticSearch`
* `$ sudo -i`
* 마스터 노드에 `apt` 업데이트 및 도커 설치
  * `# apt update && apt install docker.io -y`
* 도커 네트워크 생성
  * `# docker network create elastic`
* `ElasticSearch` 설치
  * `# docker run -d --name es01-test --net elastic -p 9200:9200 -p 9300:9300 -e "discovery.type=single-node" elasticsearch:7.14.1`
    * `9300`은 클러스터 구성 시 사용하는 포트
* `KIBANA` 설치
  * `# docker run -d --name kib01-test --net elastic -p 5601:5601 -e "ELASTICSEARCH_HOSTS=http://es01-test:9200" kibana:7.14.1`
    * `5601`은 기존에 정해진 포트
* 주의
  * 엘라스틱서치와 키바나의 버전이 일치해야 함
* 웹 브라우저에서 확인
  * `http://172.30.5.70:5601/app/home` (마스터 노드의 IP)
  * `Explore on my own` 클릭
  * 좌측 상단 메뉴에서 `Management` 탭에 `Dev Tools` 클릭
  * 테스트 `GET` 요청으로 응답 확인

## 데이터 입력과 조회
* 엘라스틱서치 데브툴스 사용
* 간단한 조회 테스트
  * `GET /_cat/indices?v`
    ~~~
    health status index                           uuid                   pri rep docs.count docs.deleted store.size pri.store.size
    green  open   .geoip_databases                EhEE1CTNTq6kZugg5agzFg   1   0         43            0     40.7mb         40.7mb
    green  open   .kibana_task_manager_7.14.1_001 x1_VrfXnRZ-VSZs4kfkVRQ   1   0         14         1693    230.2kb        230.2kb
    green  open   .apm-custom-link                no6kOVIiQ6qeZ5S83Nx9gA   1   0          0            0       208b           208b
    green  open   .apm-agent-configuration        Mg_dvqowTGK6vBHMU4JtEw   1   0          0            0       208b           208b
    green  open   .kibana_7.14.1_001              N8ZMimYjRJehPXTOTplBnw   1   0         27           13      2.1mb          2.1mb
    green  open   .kibana-event-log-7.14.1-000001 Qxws8ow2QH-pvOWzfjGWxA   1   0          1            0      5.6kb          5.6kb
    ~~~
  * `GET /_cat/nodes?v`
    ~~~
    ip         heap.percent ram.percent cpu load_1m load_5m load_15m node.role   master name
    172.18.0.2            8          97  12    0.54    0.63     1.44 cdfhilmrstw *      a8c0177b5a37
    ~~~
* 간단한 삽입 테스트
  * `PUT customer?pretty`
    ~~~json
    {
      "acknowledged" : true,
      "shards_acknowledged" : true,
      "index" : "customer"
    }
    ~~~
* 도큐먼트 삽입
  ~~~
  POST customer/_doc/1
  {
    "name": "John Doe"
  }
  ~~~
  * 맨 뒤에 ID를 지정하지 않으면 자동으로 채번되어 처리
  * 삽입 결과
    ~~~json
    {
      "_index" : "customer",
      "_type" : "_doc",
      "_id" : "1",
      "_version" : 1,
      "result" : "created",
      "_shards" : {
        "total" : 2,
        "successful" : 1,
        "failed" : 0
      },
      "_seq_no" : 0,
      "_primary_term" : 1
    }
    ~~~
* 결과 조회
  * `GET customer/_doc/1`
    ~~~json
    {
      "_index" : "customer",
      "_type" : "_doc",
      "_id" : "1",
      "_version" : 1,
      "_seq_no" : 0,
      "_primary_term" : 1,
      "found" : true,
      "_source" : {
        "name" : "John Doe"
      }
    }
    ~~~
* 도큐먼트 삭제
  * `DELETE customer`
    ~~~
    {
      "acknowledged" : true
    }
    ~~~
* 도큐먼트 수정
  * 테스트 데이터 삽입
    ~~~
    POST books/_doc/1
    {
      "title": "Elasticsearch Guide",
      "author": "Kim",
      "date": "2021-12-27",
      "pages": "500"
    }
    ~~~
  * 삽입 결과
    ~~~json
    {
      "_index" : "books",
      "_type" : "_doc",
      "_id" : "1",
      "_version" : 1,
      "result" : "created",
      "_shards" : {
        "total" : 2,
        "successful" : 1,
        "failed" : 0
      },
      "_seq_no" : 0,
      "_primary_term" : 1
    }
    ~~~
  * 조회
    * `GET books/_mapping`
    ~~~json
    {
      "books" : {
        "mappings" : {
          "properties" : {
            "author" : {
              "type" : "text",
              "fields" : {
                "keyword" : {
                  "type" : "keyword",
                  "ignore_above" : 256
                }
              }
            },
            "date" : {
              "type" : "date"
            },
            "pages" : {
              "type" : "text",
              "fields" : {
                "keyword" : {
                  "type" : "keyword",
                  "ignore_above" : 256
                }
              }
            },
            "title" : {
              "type" : "text",
              "fields" : {
                "keyword" : {
                  "type" : "keyword",
                  "ignore_above" : 256
                }
              }
            }
          }
        }
      }
    }
    ~~~
  * 삭제
    * `DELETE books/_doc/1`
      ~~~json
      {
        "_index" : "books",
        "_type" : "_doc",
        "_id" : "1",
        "_version" : 2,
        "result" : "deleted",
        "_shards" : {
          "total" : 2,
          "successful" : 1,
          "failed" : 0
        },
        "_seq_no" : 1,
        "_primary_term" : 1
      }
      ~~~
    * `_version` 값이 `2`가 됨
      * 다시 삽입 시 3으로 증가
  * `_update` 수정
    ~~~
    POST customer/_doc/1
    {
      "name": "John Doe"
    }
    
    POST customer/_update/1
    {
      "doc" : {
        "category" : "IT",
        "pages" : 50
      }
    }

    POST customer/_update/1
    {
      "doc" : {
        "author" : "K8S"
      }
    }
    ~~~
    * 결과
      ~~~
      {
        "_index" : "customer",
        "_type" : "_doc",
        "_id" : "1",
        "_version" : 7,
        "_seq_no" : 6,
        "_primary_term" : 1,
        "found" : true,
        "_source" : {
          "name" : "John Doe",
          "pages" : 50,
          "category" : "IT",
          "author" : "K8S"
        }
      }
      ~~~
  * `script` 수정
    ~~~
    POST customer/_update/1
    {
      "script": "ctx._source.pages+=50"
    }
    ~~~
    * 결과
      ~~~
      {
        "_index" : "customer",
        "_type" : "_doc",
        "_id" : "1",
        "_version" : 8,
        "_seq_no" : 7,
        "_primary_term" : 1,
        "found" : true,
        "_source" : {
          "name" : "John Doe",
          "pages" : 100,
          "category" : "IT",
          "author" : "K8S"
        }
      }
      ~~~
* 도큐먼트 삭제
  * `script` 삭제 (페이지가 150보다 작은 경우 삭제)
    ~~~
    POST customer/_update/1
    {
      "script": {
        "source": "if(ctx._source.pages <= params.page_cnt) {ctx.op='delete'} else {ctx.op='none'}",
        "params": {
          "page_cnt": 150
        }
      }
    }
    ~~~
    * `GET` 요청 결과
      ~~~
      {
        "_index" : "customer",
        "_type" : "_doc",
        "_id" : "1",
        "found" : false
      }
      ~~~

## 데이터 입력과 조회 연습문제
* `TourCompany`의 고객 관리를 위해 아래 데이터 입력
  ~~~
  DocId /  name  /     phone     / holiday_dest / departure_date
  1      Alfred   010-1234-5678   Disneyland     2017/01/20
  2      Huey     010-2222-4444   Disneyland     2017/01/20
  3      Naomi    010-3333-5555   Hawaii         2017/01/10
  4      Andra    010-6666-7777   Bora Bora      2017/01/11
  5      Paul     010-9999-8888   Hawaii         2017/01/10
  6      Colin    010-5555-4444   Venice         2017/01/16
  ~~~
  * `Index`명은 `tourcompany`로 사용
  * 삽입
    ~~~
    DELETE customer
    PUT customer
    
    POST customer/_doc/1
    {
      "name": "Alfred",
      "phone": "010-1234-5678",
      "holiday_dest": "Disneyland",
      "departure_date": "2017/01/20"
    }

    POST customer/_doc/2
    {
      "name": "Huey",
      "phone": "010-2222-4444",
      "holiday_dest": "Disneyland",
      "departure_date": "2017/01/20"
    }

    POST customer/_doc/3
    {
      "name": "Naomi",
      "phone": "010-3333-5555",
      "holiday_dest": "Hawaii",
      "departure_date": "2017/01/10"
    }

    POST customer/_doc/4
    {
      "name": "Andra",
      "phone": "010-6666-7777",
      "holiday_dest": "Bora Bora",
      "departure_date": "2017/01/11"
    }

    POST customer/_doc/5
    {
      "name": "Paul",
      "phone": "010-9999-8888",
      "holiday_dest": "Hawaii",
      "departure_date": "2017/01/10"
    }

    POST customer/_doc/6
    {
      "name": "Colin",
      "phone": "010-1234-5678",
      "holiday_dest": "Venice",
      "departure_date": "2017/01/16"
    }
    ~~~
* 추가 조건 (해당 과제는 조건절로 처리하지 않아도 됨 - 조건절은 다음 챕터에서 진행)
  * `BoraBora` 여행은 공항테러 사태로 취소 > `BoraBora` 여행자의 명단을 삭제
    * `DELETE customer/_doc/4`
  * `Hawaii` 단체 관람객의 요청으로 출발일이 조정 > `2017/01/10`에 출발하는 `Hawaii`의 출발일을 `2017/01/17`일로 수정
    ~~~
    POST customer/_update/3
    {
      "doc": {
        "departure_date": "2017/01/17"
      }
    }
    
    POST customer/_update/5
    {
      "doc": {
        "departure_date": "2017/01/17"
      }
    }
    ~~~
  * 휴일 여행을 디즈니랜드로 떠나는 사람들의 핸드폰 번호를 조회
    ~~~
    GET customer/_doc/1
    GET customer/_doc/2
    ~~~

## 배치 프로세스
* `json` 데이터를 사용해 대량의 데이터를 일괄 처리
  * 해당 파일이 위치한 경로에서 요청
    ~~~console
    curl -H 'Content-Type: application/x-ndjson' -XPOST 'http://172.30.5.70:9200/bank/_bulk?pretty' --data-binary @accounts.json
    ~~~
  * 확인
    * `GET bank`
      ~~~
      {
        "bank" : {
          "aliases" : { },
          "mappings" : {
            "properties" : {
              "account_number" : {
                "type" : "long"
              },
              "address" : {
                "type" : "text",
                "fields" : {
                  "keyword" : {
                    "type" : "keyword",
                    "ignore_above" : 256
                  }
                }
              },
              "age" : {
                "type" : "long"
              },
              "balance" : {
                "type" : "long"
              },
              "city" : {
                "type" : "text",
                "fields" : {
                  "keyword" : {
                    "type" : "keyword",
                    "ignore_above" : 256
                  }
                }
              },
              "email" : {
                "type" : "text",
                "fields" : {
                  "keyword" : {
                    "type" : "keyword",
                    "ignore_above" : 256
                  }
                }
              },
              "employer" : {
                "type" : "text",
                "fields" : {
                  "keyword" : {
                    "type" : "keyword",
                    "ignore_above" : 256
                  }
                }
              },
              "firstname" : {
                "type" : "text",
                "fields" : {
                  "keyword" : {
                    "type" : "keyword",
                    "ignore_above" : 256
                  }
                }
              },
              "gender" : {
                "type" : "text",
                "fields" : {
                  "keyword" : {
                    "type" : "keyword",
                    "ignore_above" : 256
                  }
                }
              },
              "lastname" : {
                "type" : "text",
                "fields" : {
                  "keyword" : {
                    "type" : "keyword",
                    "ignore_above" : 256
                  }
                }
              },
              "state" : {
                "type" : "text",
                "fields" : {
                  "keyword" : {
                    "type" : "keyword",
                    "ignore_above" : 256
                  }
                }
              }
            }
          },
          "settings" : {
            "index" : {
              "routing" : {
                "allocation" : {
                  "include" : {
                    "_tier_preference" : "data_content"
                  }
                }
              },
              "number_of_shards" : "1",
              "provided_name" : "bank",
              "creation_date" : "1640572973530",
              "number_of_replicas" : "1",
              "uuid" : "aYs8KkspSU6ka3XGKvVBzA",
              "version" : {
                "created" : "7140199"
              }
            }
          }
        }
      }
      ~~~
    * `GET _cat/indices`
      ~~~
      green  open .geoip_databases                EhEE1CTNTq6kZugg5agzFg 1 0   43     0  40.7mb  40.7mb
      yellow open bank                            aYs8KkspSU6ka3XGKvVBzA 1 1 1000     0 372.6kb 372.6kb
      yellow open books                           8oHNIBd5RwO4zH2eRmBVUw 1 1    1     0   5.3kb   5.3kb
      green  open .kibana_task_manager_7.14.1_001 x1_VrfXnRZ-VSZs4kfkVRQ 1 0   14 33025   3.1mb   3.1mb
      green  open .apm-custom-link                no6kOVIiQ6qeZ5S83Nx9gA 1 0    0     0    208b    208b
      green  open .apm-agent-configuration        Mg_dvqowTGK6vBHMU4JtEw 1 0    0     0    208b    208b
      green  open .kibana_7.14.1_001              N8ZMimYjRJehPXTOTplBnw 1 0   52     8   2.1mb   2.1mb
      green  open .kibana-event-log-7.14.1-000001 Qxws8ow2QH-pvOWzfjGWxA 1 0    1     0   5.6kb   5.6kb
      yellow open customer                        OK09R21rRY23ZXYnROi1_g 1 1    6     0  31.2kb  31.2kb
      ~~~

## 검색 API
* 위에서 벌크 삽입한 `bank` 인덱스의 문서를 질의
  ~~~
  # bank 인덱스의 문서 검색
  GET bank/_search?q=*
  GET bank/_search?q=Lynn
  GET bank/_search?q=Pollard AND Lynn
  GET bank/_search?q=firstname:Lynn

  # bank 인덱스에서 특정 _source 필드만 검색
  GET bank/_search?q=firstname:Lynn&_source=firstname,lastname
  GET bank/_search?q=firstname:Lynn&_source=false

  # bank 인덱스에서 특정 필드로 정렬해서 검색
  GET bank/_search?q=*&sort=balance
  GET bank/_search?q=*&sort=balance:desc

  # 원하는 위치에서 원하는 만큼의 데이터 질의
  GET bank/_search?q=*&size=10&from=10
  GET bank/_search?q=*&size=10&from=20
  ~~~
  * 검색 결과 생략

## 검색 API 연습문제
* 데이터 입력과 조회 연습문제에서 입력한 데이터가 모두 날아갔다고 가정
  ~~~
  DocId /  name  /     phone     / holiday_dest / departure_date
  1      Alfred   010-1234-5678   Disneyland     2017/01/20
  2      Huey     010-2222-4444   Disneyland     2017/01/20
  3      Naomi    010-3333-5555   Hawaii         2017/01/10
  4      Andra    010-6666-7777   Bora Bora      2017/01/11
  5      Paul     010-9999-8888   Hawaii         2017/01/10
  6      Colin    010-5555-4444   Venice         2017/01/16
  ~~~
* 삭제 후 다시 삽입
  * `DELETE customer`
  * ~~~
    POST customer/_bulk
    {"index":{"_id":"1"}}
    {"name": "Alfred",  "phone": "010-1234-5678",  "holiday_dest": "Disneyland",  "departure_date": "2017/01/20"}
    {"index":{"_id":"2"}}
    {"name": "Huey",  "phone": "010-2222-4444",  "holiday_dest": "Disneyland",  "departure_date": "2017/01/20"}
    {"index":{"_id":"3"}}
    {"name": "Naomi",  "phone": "010-3333-5555",  "holiday_dest": "Hawaii",  "departure_date": "2017/01/10"}
    {"index":{"_id":"4"}}
    {"name": "Andra",  "phone": "010-6666-7777",  "holiday_dest": "Bora Bora",  "departure_date": "2017/01/11"}
    {"index":{"_id":"5"}}
    {"name": "Paul",  "phone": "010-9999-8888",  "holiday_dest": "Hawaii",  "departure_date": "2017/01/10"}
    {"index":{"_id":"6"}}
    {"name": "Colin",  "phone": "010-1234-5678",  "holiday_dest": "Venice",  "departure_date": "2017/01/16"}
    ~~~
* 이를 해결하기 위해 벌크 데이터를 만들고 API를 사용하여 업로드
* 검색 기능을 수행하는 쿼리 작성
  * `tourcompany` 인덱스에서 `010-3333-5555` 검색
    * `GET customer/_search?q="010-3333-5555"`
      * 더블 쿼텐션을 빼면 검색되지 않음
  * 휴일 여행을 `디즈니랜드`로 떠나는 사람들의 핸드폰 번호 조회 (`phone` 필드만 출력)
    * `GET customer/_search?q=holiday_dest:Disneyland&_source=phone,holiday_dest`
  * `departure date`가 `2017/01/10`과 `2017/01/11`인 사람을 조회하고 이름 순으로 출력 (`name`과 `departure date` 필드만 출력)
    * `POST customer/_search?q=departure_date:"2017/01/10" or departure_date:"2017/01/11"&_source=name,phone,holiday_dest&sort=name.keyword:asc`
      * `name`이 아닌 `name.keyword`로 정렬함을 주의
  * `BoraBora` 여행자의 명단을 삭제
    ~~~
    POST customer/_update_by_query
    {
      "script": {
        "source": "ctx.op='delete'",
        "lang": "painless"
      },
      "query": {
        "match": {
          "holiday_dest": "Bora Bora"
        }
      }
    }
    ~~~
  * `2017/01/10`에 출발하는 `Hawaii`의 출발일을 `2017/01/17`일로 수정
    ~~~
    POST customer/_update_by_query
    {
      "script": {"source": "ctx._source.departure_date='2017/01/17'", "lang": "painless"},
      "query": {
        "bool": {
          "must": [
            {"match": {"departure_date": "2017/01/10"}},
            {"match": {"holiday_dest": "Hawaii"}}
          ]
        }
      }
    }

    GET customer/_search
    ~~~

## KIBANA
* 설치 (이미 위에서 엘라스틱서치 설치 시 함께 설치했기 때문에 따로 설치할 필요 없음)
  * `# apt update && apt install -y docker.io`
  * `# docker network create elastic`
  * `# docker run -d -name es01-test -net elastic -p 9200:9200 -p 9300:9300 -e "discovery.type=single-node" elasticsearch:7.14.1`
  * `# docker run -d -name kib01-test -net elastic -p 5601:5601 -e "ELASTICSEARCH_HOSTS=http://es01-test:9200" kibana:7.14.1`
* `account`(첨부 파일) 데이터 세트는 매핑이 필요하지 않음
* 사전 작업
  ~~~
  DELETE shakespeare
  DELETE logstash-2015.05.18
  DELETE logstash-2015.05.19
  DELETE logstash-2015.05.20
  
  PUT shakespeare
  {
    "mappings" : {
      "properties" : {
        "speaker" : {"type": "keyword" },
        "play_name" : {"type": "keyword" },
        "line_id" : { "type" : "integer" },
        "speech_number" : { "type" : "integer" }
      }
    }
  }

  #18~20까지 세개의 인덱스 구성 필요
  PUT logstash-2015.05.18
  {
    "mappings": {
      "properties": {
        "geo": {
          "properties": {
          "coordinates": { "type": "geo_point" }
          }
        }
      }
    }
  }

  PUT logstash-2015.05.19
  {
    "mappings": {
      "properties": {
        "geo": {
          "properties": {
          "coordinates": { "type": "geo_point" }
          }
        }
      }
    }
  }

  PUT /logstash-2015.05.20
  {
    "mappings": {
      "properties": {
        "geo": {
          "properties": {
          "coordinates": { "type": "geo_point" }
          }
        }
      }
    }
  }
  ~~~
* `CLI`로 업로드 진행
  * `# curl -H 'Content-Type: application/x-ndjson' -XPOST 'http://172.30.5.70:9200/bank/_bulk?pretty' --data-binary @accounts.json`
    * 위에서 이미 삽입했기 때문에 별도의 삭제를 하지 않았다면 실행하지 않아도 됨
  * `# curl -H 'Content-Type: application/x-ndjson' -XPOST 'http://172.30.5.70:9200/_bulk?pretty' --data-binary @shakespeare.json`
  * `# curl -H 'Content-Type: application/x-ndjson' -XPOST 'http://172.30.5.70:9200/_bulk?pretty' --data-binary @Exercise_logs.jsonl`
  * 데이터 삽입 후 조회
    * `GET _cat/indices`
      ~~~
      green  open .kibana_task_manager_7.14.1_001 x1_VrfXnRZ-VSZs4kfkVRQ 1 0     14 67459   5.9mb   5.9mb
      green  open .apm-agent-configuration        Mg_dvqowTGK6vBHMU4JtEw 1 0      0     0    208b    208b
      yellow open logstash-2015.05.20             Fmakf2nFRDSyVy0oAUkASg 1 1   4750     0  12.2mb  12.2mb
      green  open .kibana_7.14.1_001              N8ZMimYjRJehPXTOTplBnw 1 0     60    32   4.2mb   4.2mb
      green  open .geoip_databases                EhEE1CTNTq6kZugg5agzFg 1 0     43     0  40.7mb  40.7mb
      yellow open bank                            aYs8KkspSU6ka3XGKvVBzA 1 1   1000     0 372.7kb 372.7kb
      yellow open books                           8oHNIBd5RwO4zH2eRmBVUw 1 1      1     0   5.3kb   5.3kb
      green  open .apm-custom-link                no6kOVIiQ6qeZ5S83Nx9gA 1 0      0     0    208b    208b
      yellow open shakespeare                     T5rFdOLgTlij6X58eEdLbQ 1 1 111396     0  17.6mb  17.6mb
      yellow open logstash-2015.05.18             0uIVqmhZT0-8pwIx4iI6Pw 1 1   4631     0  11.9mb  11.9mb
      green  open .kibana-event-log-7.14.1-000001 Qxws8ow2QH-pvOWzfjGWxA 1 0      1     0   5.6kb   5.6kb
      yellow open customer                        ohrm0kvXR4C57wm2hnykiA 1 1      6     2  13.5kb  13.5kb
      yellow open logstash-2015.05.19             IuoKqKsTSQSaIezrzLoI_g 1 1   4624     0    12mb    12mb
      ~~~
      * `log-stash` 파일 수는 갱신될 때까지 몇분 소요됨
* 인덱스 패턴 생성
  * 화면 좌측 상단 메뉴 > `Management` > `Stack Management` > `Kibana` > `Index Patterns`
    * [위 인덱스 패턴 페이지](http://172.30.5.70:5601/app/management/kibana/indexPatterns)
  * `create index pattern` 클릭
  * `shakes*` 입력 후 `next step` 클릭하여 패턴 생성
  * 같은 방법으로 `bank*` 패턴 생성
  * `logstash-*` 패턴은 `next step` 클릭 후 설정에서 `Time field` 설정 (`@timestamp`)
* 생성 후 확인
  * 화면 좌측 상단 메뉴 > `Analytics` > `discover`
  * `logstash-*` 패턴은 날짜 입력해야 함 (`2015-05-01` ~ `2015-05-31`)
* `Analytics`에서 주로 사용할 서비스
  * `Discover` (발견, 탐색)
  * `Dashboard` (전시관)
  * `Visualize Library` (그림 렌더링)
* `visualization` 생성
  * `bank*` 패턴
    * `Visualize Library` > `Create new visualization` > `Lens`
    * `Pie` 차트 클릭
    * 좌측 `Filed filters` 메뉴에서 `Available fields` 안에 `balnace` 선택, 우측 `Slice by`로 끌어다 위치 시킴
    * 우측 `Size by`
      * 선택 되어진 항목 삭제
    * 우측 `SliceBy` 안에 `balnace` 선택
      * `Select a function`
        * `Intervals` 선택
      * `Select a field`
        * `balance` 선택
      * `create custom ranges`
        * `Ranges`를 총 6개 선언
          * `0` ~ `1000`
          * `1000` ~ `3000`
          * `3000` ~ `7000`
          * `7000` ~ `15000`
          * `15000` ~ `31000`
          * `31000` ~ `50000`
    * 우측 `SizeBy`
      * `Quick function` > `Count` 선택
    * 우측 `SliceBy` 항목 추가
      * `Top Values`
        * `Select a field` > `age` 선택
        * `Number of value` > `4`
    * 저장
      * 우측 상단에 저장 클릭 (`Save`)
        * `Title`
          * `Pie Example`
        * `Add Dashboard`
          * `None`
  * `shakes*` 패턴
    * `Visualize Library` > `Create new visualization` > `Lens`
    * `Bar vertical` 차트 클릭
    * 좌측에서 `play` 필드 검색, `play_name` 선택, 우측 `Horizontal axis` 끌어다 위치 시킴
      * `Top values of play_name`
    * 좌측에서 `speaker` 필드 검색, `speaker` 선택, 우측 `Vertical axis` 끌어다 위치 시킴
      * `Unique count of speaker`
    * 좌측에서 `speech` 필드 검색, `speech_number` 선택, 우측 `Vertical axis` 끌어다 위치 시킴
      * `Maximum of speech_number`
  * 저장
    * 우측 상단에 저장 클릭 (`Save`)
      * `Title`
        * `Bar Example`
      * `Add Dashboard`
        * `None`
  * `Map`
    * `Visualize Library` > `Create new visualization` > `Maps`
    * `Add layer` > `Cluster and grids` > `Index pattern` > `log-stash*` 후 저장
      * `Map Example`
* `Dashboard` 생성

## 파일 비트를 활용한 아파치 서버 로그 수집
* [다운로드 링크](https://drive.google.com/file/d/1xy4_N4xmLGQMHt59ZMMJjsTA62oYOA7a/view?usp=sharing)
  * `https://drive.google.com/u/0/uc?id=1xy4_N4xmLGQMHt59ZMMJjsTA62oYOA7a&export=download`
* `VM ware`로 위 우분투 실행
  * ID
    * `user01`
  * PW
    * `test1234`
* `$ sudo -i`
* 아파치 설치
  * `$ apt install apache2 -y`
* 파일비트 다운로드, 설치
  * `$ wget https://artifacts.elastic.co/downloads/beats/filebeat-7.15.1-amd64.deb --no-check-certificate`
  * `$ sudo dpkg -i filebeat-7.15.1-amd.deb`
* 접속 정보 입력 (파일 수정)
  * `$ sudo vim /etc/filebeat/filebeat.yml`
  * `output.elasticsearch`를 찾아 `hosts` 위치 값이 정확한지 확인
    * `hosts: ["https://172.30.5.70:9200"]`
      * `https` 프로토콜을 사용하도록 확인
* 파일비트 모듈 설정
  * `apache.yml` 활성화, 필요한 데이터 입력
    * `# cd /etc/filebeat/modules.d`
    * `# cp apache.yml.disabled apache.yml`
    * `# vim apache.yml`
      ~~~yaml
      - module: apache
        access:
          enabled: true
          var.paths: ["/var/log/apache2/access.log*"]
        error:
          enabled: true
          var.paths: ["/var/log/apache2/error.log*"]
      ~~~
  * 재시작
    * `# sudo /etc/init.d/filebeat restart`
    * `# sudo service apache2 restart`
  * 로그 확인
    * `# cd /var/log/apache2`
    * `# curl localhost:80`
    * `# curl 172.30.5.70:9200`
    * `# journalctl -u filebeat # 로그 확인`
