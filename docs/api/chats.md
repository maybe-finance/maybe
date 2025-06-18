# Chat API Documentation

The Chat API allows external applications to interact with Maybe's AI chat functionality.

## Authentication

All chat endpoints require authentication via OAuth2 or API keys. The chat endpoints also require the user to have AI features enabled (`ai_enabled: true`).

## Endpoints

### List Chats
```
GET /api/v1/chats
```

**Required Scope:** `read`

**Response:**
```json
{
  "chats": [
    {
      "id": "uuid",
      "title": "Chat title",
      "last_message_at": "2024-01-01T00:00:00Z",
      "message_count": 5,
      "error": null,
      "created_at": "2024-01-01T00:00:00Z",
      "updated_at": "2024-01-01T00:00:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "per_page": 20,
    "total_count": 50,
    "total_pages": 3
  }
}
```

### Get Chat
```
GET /api/v1/chats/:id
```

**Required Scope:** `read`

**Response:**
```json
{
  "id": "uuid",
  "title": "Chat title",
  "error": null,
  "created_at": "2024-01-01T00:00:00Z",
  "updated_at": "2024-01-01T00:00:00Z",
  "messages": [
    {
      "id": "uuid",
      "type": "user_message",
      "role": "user",
      "content": "Hello AI",
      "created_at": "2024-01-01T00:00:00Z",
      "updated_at": "2024-01-01T00:00:00Z"
    },
    {
      "id": "uuid",
      "type": "assistant_message",
      "role": "assistant",
      "content": "Hello! How can I help you?",
      "model": "gpt-4",
      "created_at": "2024-01-01T00:00:00Z",
      "updated_at": "2024-01-01T00:00:00Z",
      "tool_calls": []
    }
  ],
  "pagination": {
    "page": 1,
    "per_page": 50,
    "total_count": 2,
    "total_pages": 1
  }
}
```

### Create Chat
```
POST /api/v1/chats
```

**Required Scope:** `write`

**Request Body:**
```json
{
  "title": "Optional chat title",
  "message": "Initial message to AI",
  "model": "gpt-4" // optional, defaults to gpt-4
}
```

**Response:** Same as Get Chat endpoint

### Update Chat
```
PATCH /api/v1/chats/:id
```

**Required Scope:** `write`

**Request Body:**
```json
{
  "title": "New chat title"
}
```

**Response:** Same as Get Chat endpoint

### Delete Chat
```
DELETE /api/v1/chats/:id
```

**Required Scope:** `write`

**Response:** 204 No Content

### Create Message
```
POST /api/v1/chats/:chat_id/messages
```

**Required Scope:** `write`

**Request Body:**
```json
{
  "content": "User message",
  "model": "gpt-4" // optional, defaults to gpt-4
}
```

**Response:**
```json
{
  "id": "uuid",
  "chat_id": "uuid",
  "type": "user_message",
  "role": "user",
  "content": "User message",
  "created_at": "2024-01-01T00:00:00Z",
  "updated_at": "2024-01-01T00:00:00Z",
  "ai_response_status": "pending",
  "ai_response_message": "AI response is being generated"
}
```

### Retry Last Message
```
POST /api/v1/chats/:chat_id/messages/retry
```

**Required Scope:** `write`

Retries the last assistant message in the chat.

**Response:**
```json
{
  "message": "Retry initiated",
  "message_id": "uuid"
}
```

## AI Response Handling

AI responses are processed asynchronously. When you create a message or chat with an initial message, the API returns immediately with the user message. The AI response is generated in the background.

### Checking for AI Responses

Currently, you need to poll the chat endpoint to check for new AI responses. Look for new messages with `type: "assistant_message"`.

### Available AI Models

- `gpt-4` (default)
- `gpt-4-turbo`
- `gpt-3.5-turbo`

### Tool Calls

The AI assistant can make tool calls to access user financial data. These appear in the `tool_calls` array of assistant messages:

```json
{
  "tool_calls": [
    {
      "id": "uuid",
      "function_name": "get_accounts",
      "function_arguments": {},
      "function_result": { ... },
      "created_at": "2024-01-01T00:00:00Z"
    }
  ]
}
```

## Error Handling

All endpoints return standard error responses:

```json
{
  "error": "error_code",
  "message": "Human readable error message",
  "details": ["Additional error details"] // optional
}
```

Common error codes:
- `unauthorized` - Invalid or missing authentication
- `forbidden` - Insufficient permissions or AI not enabled
- `not_found` - Resource not found
- `unprocessable_entity` - Invalid request data
- `rate_limit_exceeded` - Too many requests

## Rate Limits

Chat API endpoints are subject to the standard API rate limits based on your API key tier.