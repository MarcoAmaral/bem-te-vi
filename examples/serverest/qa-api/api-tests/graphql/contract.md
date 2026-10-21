# Contract: public countries GraphQL API (step 1)

Produced following `.claude/skills/qa-api/SKILL.md`, step 1, for its GraphQL half. Read-only. Dated 2026-10-18.

| Item | Value |
| ---- | ----- |
| Endpoint | `https://countries.trevorblades.com/` (a public, read-only practice API) |
| Contract | The schema returned by the standard introspection query, read with `graphql`'s `buildClientSchema`. Introspection is **enabled** on this public API; that is normal and is not a finding. No separate SDL file is published at a stable URL that was found |
| Deployed version under test | **Not confirmed.** The service exposes no version; the schema is read live on every run, so the contract and the service cannot disagree about which build they describe, but nothing says what build that is |
| Environment | Shared public service. Every request in the specs is a `query`; there is no mutation in the schema that was used, so nothing is created or changed |
| Auth model | None |
| Operations in scope | `country(code: ID!): Country` (nullable), `countries(filter: …): [Country!]!`, `languages(filter: …): [Language!]!` |
| Declared nullability used by the checks | `Country.code`, `name`, `continent`, `languages` are non-null; `capital` and `currency` are nullable. `Continent.code` and `name` are non-null |
| Declared limits | No depth, complexity or rate limit is declared in the schema. None was tested and none is claimed |
