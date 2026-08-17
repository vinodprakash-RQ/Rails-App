# News crawler

The application periodically imports article metadata and content from:

- OpenAI: `https://openai.com/news/`
- Google DeepMind: `https://deepmind.google/blog/`
- Anthropic: `https://www.anthropic.com/news`

`CrawlNewsJob` runs `NewsCrawler` through Active Job. The crawler discovers same-host article links, fetches each article with bounded timeouts, extracts JSON-LD/Open Graph/HTML fallback fields, and upserts by canonical URL. The unique database index on `news_articles.url` is the final duplicate safeguard.

## Run a crawl

The authenticated API endpoint queues a crawl and returns immediately:

```http
POST /api/v1/news_articles/crawl
Authorization: Bearer <token>
```

For scheduled operation, invoke `CrawlNewsJob.perform_later` from the deployment scheduler. Rails' default async adapter is suitable for development; production should configure a durable Active Job adapter such as Solid Queue or Sidekiq.

## View articles

```http
GET /api/v1/news_articles?page=1&per_page=20&source=openai
GET /api/v1/news_articles/:id
```

The endpoints require authentication and return the stored title, URL, source, publication date, and content. `per_page` is capped at 100.

The crawler intentionally uses a small fixed source allow-list, does not accept arbitrary URLs, limits each source to 50 articles per run, uses request timeouts, and logs individual article failures without aborting the whole crawl. Website markup can change, so selector coverage should be monitored and updated when a source redesigns its news page.
