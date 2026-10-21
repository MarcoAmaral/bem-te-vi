// playwright/contract/contract.ts
// Loads the OpenAPI document once and answers one question: which errors does this body have
// against the schema declared for this operation and status? It returns the errors and never
// asserts: the spec decides what a non-empty list means.
import Ajv from "ajv";

type Json = Record<string, any>;

export class Contract {
  private readonly ajv = new Ajv({ strict: false, allErrors: true });

  private constructor(readonly document: Json) {}

  static async load(url: string): Promise<Contract> {
    const response = await fetch(url);
    if (!response.ok) throw new Error(`Cannot load the contract from ${url}: ${response.status}`);
    return new Contract(await response.json());
  }

  get version(): string {
    return `${this.document.openapi} / API ${this.document.info.version}`;
  }

  /** Follows a `$ref` to a reusable response, if the node is one. */
  private resolve(node: Json): Json {
    if (!node?.$ref) return node;
    const [, ...path] = (node.$ref as string).split("/");
    return path.reduce((current: Json, key) => current[key], this.document);
  }

  /** The schema declared for a response, or undefined when the contract declares none. */
  responseSchema(path: string, method: string, status: number): Json | undefined {
    const declared = this.document.paths[path]?.[method]?.responses?.[String(status)];
    if (declared === undefined) return undefined;
    return this.resolve(declared).content?.["application/json"]?.schema;
  }

  /** The statuses the contract declares for an operation. */
  declaredStatuses(path: string, method: string): string[] {
    return Object.keys(this.document.paths[path]?.[method]?.responses ?? {});
  }

  /** The schema declared for a request body. */
  requestSchema(path: string, method: string): Json | undefined {
    const body = this.resolve(this.document.paths[path]?.[method]?.requestBody ?? {});
    return body.content?.["application/json"]?.schema;
  }

  /** Errors of `body` against `schema`; the root keeps `components` so `$ref`s resolve. */
  errors(schema: Json | undefined, body: unknown): string[] {
    if (schema === undefined) return ["the contract declares no schema for this"];
    const validate = this.ajv.compile({ ...schema, components: this.document.components });
    if (validate(body)) return [];
    return (validate.errors ?? []).map((e) => `${e.instancePath || "(body)"} ${e.message}`);
  }

  responseErrors(path: string, method: string, status: number, body: unknown): string[] {
    return this.errors(this.responseSchema(path, method, status), body);
  }
}
