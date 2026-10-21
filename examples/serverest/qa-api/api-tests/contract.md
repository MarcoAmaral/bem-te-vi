# Contract: ServeRest cart and login (step 1)

Produced following `.claude/skills/qa-api/SKILL.md`, step 1. Read-only. Dated 2026-10-18.

| Item | Value |
| ---- | ----- |
| Contract | OpenAPI 3.0.0 document, `https://serverest.dev/swagger.json` (the "Swagger" page of the API) |
| Fetched | 2026-10-18, HTTP 200, `application/json`; `info.version` 3.2.2; SHA-256 of the copy read for this file `bc95150fbf9c3138dafc6f87ca05f43b70699481229865f00a1a36f722fe8c02` (the specs fetch their own copy on every run) |
| Deployed version under test | **Not confirmed independently.** ServeRest exposes no version route that was found and no deployment record is public. The only version signal is the document's own `info.version`, 3.2.2, so "the schema describes the build under test" is an assumption, stated here and not verified |
| Environment | The public instance `https://serverest.dev`: shared, unversioned, used by other people. A practice API with no production data |
| Auth model | `POST /login` with `email` and `password` returns an `authorization` value (`Bearer <jwt>`) that is sent unchanged in the `Authorization` header. The document marks `POST /carrinhos` and the two `DELETE` cart routes with `ApiKeyAuth`; `GET /carrinhos` and `GET /carrinhos/{_id}` declare no `security` |
| Scope | `POST /login`; `GET /carrinhos`; `POST /carrinhos`; `GET /carrinhos/{_id}`; `DELETE /carrinhos/concluir-compra`; `DELETE /carrinhos/cancelar-compra`. The same slice as `../../qa-static/review.md`, `../../qa-agentic/` and `../../qa-automate/`, so one story runs through four outputs |
| Declared statuses | `/login`: 200, 401. `GET /carrinhos`: 200. `POST /carrinhos`: 201, 400, 401. `GET /carrinhos/{_id}`: 200, 400. Both `DELETE` routes: 200, 401 |
| Declared constraints | The schemas carry types only. **No `required`, no `additionalProperties`, no `minimum`, no `enum`** anywhere in the slice. That limits what a schema check can find (see `conformance.md`, "What the schema cannot catch") |

The user and product routes were used only for set-up and clean-up, and are not under test.

## GraphQL

A second contract, for the GraphQL half of the skill: [`graphql/contract.md`](graphql/contract.md).
