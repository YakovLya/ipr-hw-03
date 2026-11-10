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