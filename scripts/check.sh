#!/bin/bash

set -euo pipefail

TEST_NAME="ipr-hw-03-check-$(date +%s)"
export HOST_PORT=18080
URL="http://localhost:$HOST_PORT"

cleanup() {
    result=$?
    echo "  Начал очистку"


    if [ "$result" -ne 0 ]; then
        echo "  Ошибка во время выполнения: " >&2
    fi

    docker compose -p "$TEST_NAME" down -v --timeout 10 || result=1

    exit "$result"
}

trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

echo "  Поднимаю compose"

docker compose -p "$TEST_NAME" up --build --wait --wait-timeout 60

echo "  [ ] - Проверка начального состояния – начало"

COUNT=$(
    curl -fsS --max-time 5 "$URL/" |
    docker compose -p "$TEST_NAME" exec -T app \
        python -c 'import json, sys; print(json.load(sys.stdin)["count"])'
)

if [ "$COUNT" != "0" ]; then
    echo "  [-] - Проверка начального состояния – не пройдено"
    echo "  Изначально COUNT не ноль" >&2
    exit 1
fi

echo "  [+] - Проверка начального состояния – пройдено"

echo "  [ ] - Проверка счётчика – начало"

N=5

for ((i=0; i<N; i++)); do
    curl -fsS --max-time 5 \
        -X POST "$URL/increment" > /dev/null
done

COUNT=$(
    curl -fsS --max-time 5 "$URL/" |
    docker compose -p "$TEST_NAME" exec -T app \
        python -c 'import json, sys; print(json.load(sys.stdin)["count"])'
)

if [ "$COUNT" != "$N" ]; then
    echo "  [-] - Проверка счётчика – не пройдено"
    echo "  Число счётчика не совпало с ожидаемым, ожидалось $N, но COUNT=$COUNT" >&2
    exit 1
fi

echo "  [+] - Проверка счётчика – пройдено"

echo "  [ ] - Проверка перезапуска – начало"

docker compose -p "$TEST_NAME" up --no-deps --force-recreate --wait --wait-timeout 60 app

COUNT=$(
    curl -fsS --max-time 5 "$URL/" |
    docker compose -p "$TEST_NAME" exec -T app \
        python -c 'import json, sys; print(json.load(sys.stdin)["count"])'
)

if [ "$COUNT" != "$N" ]; then
    echo "  [-] - Проверка перезапуска – не пройдено"
    echo "  Число счётчика не совпало с ожидаемым, ожидалось $N, но COUNT=$COUNT" >&2
    exit 1
fi

echo "  [+] - Проверка перезапуска – пройдено"

echo "  [ ] - Проверка отключения Redis – начало"

docker compose -p "$TEST_NAME" stop --timeout 10 redis

echo "  [ ][ ] – проверяю GET /healthz"

STATUS=$(
    curl -sS --connect-timeout 2 --max-time 5 \
        -o /dev/null -w '%{http_code}' \
        -X GET "$URL/healthz"
)

if [ "$STATUS" != "200" ]; then
    echo "  [-] - Проверка отключения Redis – не пройдено"
    echo "  GET /healthz вернул не 200, а $STATUS" >&2
    exit 1
fi

echo "  [ ][+] – GET /healthz -> 200"

echo "  [ ][ ] – проверяю GET /readyz"

STATUS=$(
    curl -sS --connect-timeout 2 --max-time 5 \
        -o /dev/null -w '%{http_code}' \
        -X GET "$URL/readyz"
)

if [ "$STATUS" != "503" ]; then
    echo "  [-] - Проверка отключения Redis – не пройдено"
    echo "  GET /readyz вернул не 503, а $STATUS" >&2
    exit 1
fi

echo "  [ ][+] – GET /readyz -> 503"

echo "  [ ][ ] – проверяю POST /increment"

STATUS=$(
    curl -sS --connect-timeout 2 --max-time 5 \
        -o /dev/null -w '%{http_code}' \
        -X POST "$URL/increment"
)

if [ "$STATUS" != "503" ]; then
    echo "  [-] - Проверка отключения Redis – не пройдено"
    echo "  POST /increment вернул не 503, а $STATUS" >&2
    exit 1
fi

echo "  [ ][+] – POST /increment -> 503"

echo "  [+] - Проверка отключения Redis – пройдено"

echo "  [ ] - Проверка восстановления Redis – начало"

docker compose -p "$TEST_NAME" start --wait --wait-timeout 60 redis

COUNT=$(
    curl -fsS --max-time 5 "$URL/" |
    docker compose -p "$TEST_NAME" exec -T app \
        python -c 'import json, sys; print(json.load(sys.stdin)["count"])'
)

if [ "$COUNT" != "$N" ]; then
    echo "  [-] - Проверка восстановления Redis – не пройдено"
    echo "  Число счётчика не совпало с ожидаемым, ожидалось $N, но COUNT=$COUNT" >&2
    exit 1
fi

COUNT=$(
    curl -fsS --max-time 5 -X POST "$URL/increment" |
    docker compose -p "$TEST_NAME" exec -T app \
        python -c 'import json, sys; print(json.load(sys.stdin)["count"])'
)

if [ "$COUNT" != "$((N + 1))" ]; then
    echo "  [-] - Проверка восстановления Redis – не пройдено"
    echo "  Число счётчика не совпало с ожидаемым, ожидалось $N, но COUNT=$COUNT" >&2
    exit 1
fi

echo "  [+] - Проверка восстановления Redis – пройдено"


echo "  [ ] - Проверка резервной копии – начало"

mkdir -p backups
BACKUP="$PWD/backups/$TEST_NAME.tar"

docker compose -p "$TEST_NAME" stop --timeout 10 app redis

docker compose -p "$TEST_NAME" run --rm --no-deps -T --user 0:0 --entrypoint tar redis -C /data -cpf - . > "$BACKUP"

test -s "$BACKUP"

echo "  [+] - Проверка резервной копии – пройдено"