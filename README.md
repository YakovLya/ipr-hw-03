# ИПР ДЗ 03 (docker)

Ляхович Яков Александрович, БПМИ 263

## На 4 балла

Написал простейший Dockerfile, собрал и запустил контейнер

Для сборки
```
docker build -t ipr-hw3 .  
```

Для запуска контейнера
```
docker run -d --name ipr-333 -p 127.0.0.1:8080:8000 ipr-hw3
```

Название образа – `ipr-hw3`

Название контейнера - `ipr-333`

Логи прикладываю

```
2026-11-10 21:57:00,036 listening port=8000 storage=sqlite
2026-11-10 21:57:03,919 http 172.17.0.1 "GET / HTTP/1.1" 200 -
2026-11-10 21:57:04,511 http 172.17.0.1 "GET / HTTP/1.1" 200 -
2026-11-10 22:00:49,105 http 172.17.0.1 "GET / HTTP/1.1" 200 -
2026-11-10 22:00:53,631 http 172.17.0.1 "POST /increment HTTP/1.1" 200 -
2026-11-10 22:00:55,086 http 172.17.0.1 "POST /increment HTTP/1.1" 200 -
2026-11-10 22:00:55,649 http 172.17.0.1 "POST /increment HTTP/1.1" 200 -
2026-11-10 22:00:56,154 http 172.17.0.1 "POST /increment HTTP/1.1" 200 -
2026-11-10 22:00:58,994 http 172.17.0.1 "GET / HTTP/1.1" 200 -
2026-11-10 22:01:09,513 http 172.17.0.1 "GET /healthz HTTP/1.1" 200 -
2026-11-10 22:01:12,473 http 172.17.0.1 "GET /readyz HTTP/1.1" 200 -
2026-11-10 22:01:16,553 http 172.17.0.1 "GET /aboba_not_found HTTP/1.1" 404 -
2026-11-10 22:01:19,537 http 172.17.0.1 "GET / HTTP/1.1" 200 -
2026-11-10 22:01:23,167 http 172.17.0.1 "POST /increment HTTP/1.1" 200 -
```

## На 6 баллов

- Добавил .env.example (у меня локально также просто .env), в нем настройки окружения, большая часть из readme приложения

- Добавил compose.yaml . В нем задал постоянный volume для контейнера. Теперь между запусками не теряются значения

Запускаем 

```
docker compose up -d 
# первый раз надо docker compose up -d --build
```

Несколько раз делаем запрос на увеличение счетчика

```
curl -X POST http://localhost:8080/increment
curl -X POST http://localhost:8080/increment
curl -X POST http://localhost:8080/increment
```

Видим после последнего запроса

```
{"greeting": "Hello, Docker!", "count": 4, "hostname": "3194abc164a3", "storage": "sqlite"}
```

Останавливаем контейнер

```
docker compose down
```

Снова запускаем контейнер по команде выше и смотрим значение 

```
curl http://localhost:8080
```

Видим ответ

```
{"greeting": "Hello, Docker!", "count": 4, "hostname": "ec3ed64b739b", "storage": "sqlite"}
```

Счетчик не изменился, что и требовалось показать

## На 8 баллов

- Изменил .env (и .env.example очевидно), теперь `STORAGE=redis`

- В compose.yaml добавил описание для контейнера redis'а. В приложение прокинул REDIS_URL и поменял volume на редисный

- Настроил healthcheck для обоих контейнеров. Для redis стандартно. Для приложения сначала хотел через curl, потом оказалось, что curl нету в образе, поэтому через питон сделал

(Запускаем и останавливаем как в разделе на 6 баллов)

Проверка что данные не теряются при остановке:
1) Запускаем
2) Смотрим, что healthcheck работают (через `docker compose ps`)
```
NAME                IMAGE              COMMAND                  SERVICE   CREATED          STATUS                    PORTS
ipr-hw-03-app-1     ipr-hw-03-app      "python app.py"          app       13 seconds ago   Up 12 seconds (healthy)   127.0.0.1:8080->8000/tcp
ipr-hw-03-redis-1   redis:7.4-alpine   "docker-entrypoint.s…"   redis     13 seconds ago   Up 12 seconds (healthy)   6379/tcp
```
3) Несколько раз увеличиваем счетчик через `/increment`
4) Останавлиавем оба контейнера
5) Смотрим заново счетчик, все сохранилось

Проверка что при остановке redis приложение не останавливается и корректно отдает ошибки:
1) Запускаем 
2) Останавливаем именно redis
```
docker compose stop redis
```

3) проверяем `GET /healthz`
```
curl -i  http://localhost:8080/healthz
HTTP/1.0 200 OK
...
```

4) проверяем `GET /readyz`
```
curl -i  http://localhost:8080/readyz 
HTTP/1.0 503 Service Unavailable
...
```

5) проверяем `POST /increment`
```
curl -X POST -i  http://localhost:8080/increment
HTTP/1.0 503 Service Unavailable
...
```

6) Обратно подключаем redis
```
docker compose start redis
```

7) Опять проверяем, например `POST /increment`
```
curl -X POST -i  http://localhost:8080/increment
HTTP/1.0 200 OK
Server: BaseHTTP/0.6 Python/3.13.18
Date: Thu, 12 Nov 2026 22:48:47 GMT
Content-Type: application/json; charset=utf-8
Content-Length: 90
Cache-Control: no-store

{"greeting": "Hello, Docker!", "count": 4, "hostname": "89b4b2b6ef9f", "storage": "redis"}%
```

Все работает как и должно! И счетчик не обнулился

Хотел приложить логи контейнера redis и контейнера app, но в первом просто куча логов redis, без особого смысла. А у app очень много вызовов /readyz в логах от частых healthcheck'ов

## На 10 баллов

- Добавил ограничения в compose.yaml

- Написал scripts/check.sh для автопроверок

Для начала проверим, что ограничения применяются
```
docker compose exec app id
# должно быть uid=10001 gid=10001 groups=10001

docker inspect --format 'Readonly={{.HostConfig.ReadonlyRootfs}} Memory={{.HostConfig.Memory}} NanoCpus={{.HostConfig.NanoCpus}}' "$(docker compose ps -q app)"
# должно быть Readonly=true Memory=268435456 NanoCpus=1000000000
```

Для запуска автопроверки
```
# выполнять из корня репозитория
# при необходимости предварительно
# chmod +x ./scripts/check.sh
./scripts/check.sh
```

Если нужен сразу .log отчет
```
./scripts/check.sh | tee scripts/check-42.log
```

Два успешных запуска прогнал:
- [Первый запуск](scripts/check-01.log)
- [Второй запуск](scripts/check-02.log)

## Outro. Фидбек

На этом всё. Прикольное задание. Для пет проектов обычно брал стандартные шаблоны/слопил. Тут сам гуглил и писал, дольше, но интересно (больше не хочется)

Писать скрипт автопроверки оч приятно было. Эх даже жаль, что курс ограничивается лишь поверхностным применением знаний и не будет заданий чтобы поднимать через кубер систему контейнеров и строить утойчивую систему с умными деградациями