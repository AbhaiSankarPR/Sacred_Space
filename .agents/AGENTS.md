# Project Rules

## API Response Format
All paginated API endpoints in this repository (e.g., `/booking`, `/certificate`, `/events`, etc.) return a wrapped JSON structure containing a `data` list and a `meta` block:

```json
{
  "data": [...],
  "meta": {
    "page": 1,
    "hasMore": true
  }
}
```

Always parse paginated API responses expecting this structure (`data` and `meta` containing `page` and `hasMore`).
