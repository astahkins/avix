# Avix Server

Простой FastAPI-сервер для хранения и ретрансляции сообщений обычных чатов Avix.

## Запуск

```bash
cd server
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
python main.py
```

По умолчанию сервер запускается на:

```text
http://0.0.0.0:8000
```

Проверка доступности:

```bash
curl http://127.0.0.1:8000/ping
```

Ответ:

```json
{"status":"ok"}
```

## API

### POST /send

Сохраняет сообщение.

```json
{
  "chatId": "chat-1",
  "senderPublicKey": "public-key",
  "text": "Hello",
  "timestamp": "2026-06-06T21:00:00",
  "isSecret": false
}
```

### GET /messages/{chat_id}

Возвращает сообщения чата.

Параметры:

- `limit` - количество сообщений, по умолчанию `50`
- `offset` - смещение, по умолчанию `0`
- `before_timestamp` - вернуть сообщения до указанного времени

Пример:

```bash
curl "http://127.0.0.1:8000/messages/chat-1?limit=50&offset=0"
```

### GET /ping

Возвращает:

```json
{"status":"ok"}
```
