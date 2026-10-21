// GraphQL checks against the public, read-only API https://countries.trevorblades.com/
// Every request is a query: nothing is created, so there is nothing to clean up.
import { test, expect } from "@playwright/test";
import {
  buildClientSchema,
  getIntrospectionQuery,
  GraphQLSchema,
  parse,
  validate,
} from "graphql";

const ENDPOINT = process.env.GRAPHQL_URL || "https://countries.trevorblades.com/";

let schema: GraphQLSchema;

async function post(request: any, query: string) {
  return request.post(ENDPOINT, { data: { query } });
}

test.beforeAll(async ({ playwright }) => {
  const request = await playwright.request.newContext();
  const response = await request.post(ENDPOINT, { data: { query: getIntrospectionQuery() } });
  schema = buildClientSchema((await response.json()).data);
  await request.dispose();
});

test.describe("Countries GraphQL contract @graphql", () => {
  // API-GQL-01
  test("a valid query returns 200, no errors array and the declared fields @smoke @api @p0 @graphql", async ({
    request,
  }) => {
    // Arrange
    const query = `{ country(code: "BR") { name capital currency languages { code name } } }`;
    const invalid = validate(schema, parse(query));

    // Act
    const response = await post(request, query);
    const body = await response.json();

    // Assert
    expect(invalid, "the query is valid against the SDL").toEqual([]);
    expect(response.status()).toBe(200);
    expect(body.errors).toBeUndefined();
    expect(body.data.country.name).toBe("Brazil");
    expect(body.data.country.languages).toEqual([{ code: "pt", name: "Portuguese" }]);
  });

  // API-GQL-02
  test("an unknown code returns 200 with a null country and no errors @regression @api @p1 @graphql", async ({
    request,
  }) => {
    // Act
    const response = await post(request, `{ country(code: "ZZ") { name } }`);
    const body = await response.json();

    // Assert: the SDL declares `country` nullable, so null is the contract, not a failure
    expect(response.status()).toBe(200);
    expect(body.errors).toBeUndefined();
    expect(body.data).toEqual({ country: null });
  });

  // API-GQL-03
  test("a query for an undeclared field returns an errors array, not data @regression @api @p1 @graphql", async ({
    request,
  }) => {
    // Act
    const response = await post(request, `{ country(code: "BR") { name nope } }`);
    const body = await response.json();

    // Assert: a status-only check passes here, so assert the body
    expect(response.status()).toBe(200);
    expect(body.data).toBeUndefined();
    expect(body.errors[0].extensions.code).toBe("GRAPHQL_VALIDATION_FAILED");
    expect(body.errors[0].message).toContain('Cannot query field "nope"');
  });

  // API-GQL-04
  test("a failing non-null list nulls the whole data and names the path @regression @api @p2 @graphql", async ({
    request,
  }) => {
    // Act: a regular expression that does not compile makes the server fail at `languages`
    const response = await post(request, `{ languages(filter: { code: { regex: "(" } }) { code } }`);
    const body = await response.json();

    // Assert: `languages: [Language!]!` cannot be null, so the error propagates to `data`
    expect(response.status()).toBe(200);
    expect(body.data).toBeNull();
    expect(body.errors[0].path).toEqual(["languages"]);
    expect(body.errors[0].extensions.code).toBe("INTERNAL_SERVER_ERROR");
  });

  // API-GQL-05
  test("no non-null field is null in the full country list @regression @api @p2 @graphql", async ({
    request,
  }) => {
    // Arrange
    const query = `{ countries { code name continent { code name } languages { code name } } }`;
    const invalid = validate(schema, parse(query));

    // Act
    const response = await post(request, query);
    const body = await response.json();
    const nulls = body.data.countries.filter(
      (c: any) =>
        c.code === null ||
        c.name === null ||
        c.continent === null ||
        c.continent.name === null ||
        c.languages === null ||
        c.languages.some((l: any) => l === null || l.code === null || l.name === null),
    );

    // Assert
    expect(invalid).toEqual([]);
    expect(body.errors).toBeUndefined();
    expect(body.data.countries.length).toBeGreaterThan(200);
    expect(nulls).toEqual([]);
  });

  // API-GQL-06
  test("a request that is not valid GraphQL syntax is answered with 400 @regression @api @p2 @graphql", async ({
    request,
  }) => {
    // Act
    const response = await post(request, `{ country(code: "BR" { name } }`);
    const body = await response.json();

    // Assert: unlike a validation error (API-GQL-03), a syntax error is not answered with 200
    expect(response.status()).toBe(400);
    expect(body.errors).toHaveLength(1);
  });
});
