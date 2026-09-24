The design for a slug-caching feature is approved (spec: cache slug→id lookups
in a Postgres table `slug_cache`, TTL 24h, invalidated on rename). Write the
implementation plan for this feature.