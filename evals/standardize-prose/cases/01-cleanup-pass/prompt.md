Standardize the prose in this spec. No fixture file exists — the doc is given inline below; work from the text under the fence and propose edits to it:

````markdown
---
title: Slug cache
status: draft
---

# Slug cache design

The slug cache module is a component that stores slug-to-id lookups. The module
keeps an in-memory map so lookups are fast.

## Requirements

- [ ] The cache component must reject unknown slugs
- The lookup result will be discarded after 24 hours
- It should be noted that several error paths exist in the module, and the
  handling of the errors that occur in those paths where the error is not
  recoverable by the caller of the lookup operation must be considered in
  a way that is appropriate for a component of this kind
- When the slug is not present in the cache element, the value is discarded

## Tasks

- [ ] Create the cache table
- [ ] Wire up the loader

Risk: high — executable-code

```python
def lookup(slug):
    return cache.get(slug)
```

## Acceptance

The component verifies the slug before the cache returns the identifier.
````