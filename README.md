# ИПР ДЗ 03 (docker)

Ляхович Яков Александрович, БПМИ 263

## На 4 балла

написал простейший Dockerfile, собрал и запустил контейнер

Для сборки
```
docker build -t ipr-hw3 .  
```

для запуска контейнера
```
docker run -d --name ipr-333 -p 127.0.0.1:8080:8000 ipr-hw3
```

название образа – `ipr-hw3`

название контейнера - `ipr-333`

логи прикладываю

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

- добавил .env.example (у меня локально также просто .env), в нем настройки окружения, большая часть из readme приложения

- добавил compose.yaml . В нем задал постоянный volume для контейнера. Теперь между запусками не теряются значения

Запускаем 

```
docker compose up -d 
# первый раз надо docker compose up -d --build
```

пару раз делает запрос на увеличение счетчика

```
curl -X POST http://localhost:8080/increment
curl -X POST http://localhost:8080/increment
curl -X POST http://localhost:8080/increment
```

Останавливаем контейнер

```
docker compose down
```

Снова запускаем из смотрим значение 

```
curl http://localhost:8080
```
