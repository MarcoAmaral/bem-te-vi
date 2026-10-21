# Conformance: public countries GraphQL API (step 3)

Produced following `.claude/skills/qa-api/SKILL.md`, steps 2 and 3 in one pass, by running `../../playwright/tests/countries-graphql.api.spec.ts` on 2026-10-18. Output: [`../../run-output.txt`](../../run-output.txt) (the last six cases). All six passed. Every query that is meant to be valid was first validated against the introspected schema with `graphql`'s `validate`.

| Case | What it checks | Source | Observed |
| ---- | -------------- | ------ | -------- |
| API-GQL-01 | A valid query: HTTP 200, no `errors` key, the declared fields | SDL | As expected |
| API-GQL-02 | An unknown `code`: `data.country` is `null`, no `errors` | `country` is nullable in the SDL | HTTP 200, `{"data":{"country":null}}` |
| API-GQL-03 | A query for an undeclared field | The skill's rule that status alone proves nothing | HTTP **200** with `errors[0].extensions.code` `GRAPHQL_VALIDATION_FAILED` and no `data`: a status-only assertion passes here |
| API-GQL-04 | A server failure inside a non-null list | Non-null propagation (`languages` is `[Language!]!`) | HTTP 200, `data` is `null`, `errors[0].path` is `["languages"]`, code `INTERNAL_SERVER_ERROR` |
| API-GQL-05 | No non-null field is `null` across all countries | Nullability from the SDL | None was null in the full list (over 200 countries) |
| API-GQL-06 | A request with a GraphQL syntax error | HTTP behaviour | HTTP **400** with an `errors` array (the message is the gateway's: it mentions batch and persisted-query requests) |

## What this shows about the skill's rules

- **Errors with HTTP 200 is the common case, not the rule.** A validation error (API-GQL-03), a server error (API-GQL-04) and a null result (API-GQL-02) all arrive with 200. A request that is not parseable GraphQL (API-GQL-06) was answered 400 here, by what looks like a gateway in front of the server. The skill therefore says "usually 200" and tells the tester to record what the service does.
- API-GQL-04 needs a malformed regular expression to make the server fail. That is one bounded, non-destructive request, but it provokes a server error on a service other people use; it ran once per run.
- The trigger for API-GQL-04 is incidental: a fix on the server (validating the regular expression and returning a normal error) would make that case fail for a good reason. It documents behaviour seen on 2026-10-18, not a promise.

## Not exercised

Mutations (the schema in use has none), subscriptions, depth and cost limits (none declared), partial `data` alongside `errors` on a nullable field (no trigger was found without writing unbounded queries), and authentication.
