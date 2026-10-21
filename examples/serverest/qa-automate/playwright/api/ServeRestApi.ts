// playwright/api/ServeRestApi.ts
// Thin client over Playwright's APIRequestContext. Actions only: no assertions here.
import { APIRequestContext, APIResponse } from "@playwright/test";

export interface CartItem {
  idProduto: string;
  // Typed loosely on purpose: TC-CART-030 sends a JSON string.
  quantidade: unknown;
}

export class ServeRestApi {
  constructor(private readonly request: APIRequestContext) {}

  private authHeaders(token?: string): Record<string, string> {
    return token === undefined ? {} : { Authorization: token };
  }

  createUser(data: {
    nome: string;
    email: string;
    password: string;
    administrador: "true" | "false";
  }): Promise<APIResponse> {
    return this.request.post("/usuarios", { data });
  }

  deleteUser(id: string): Promise<APIResponse> {
    return this.request.delete(`/usuarios/${id}`);
  }

  login(email: string, password: string): Promise<APIResponse> {
    return this.request.post("/login", { data: { email, password } });
  }

  createProduct(
    token: string,
    data: { nome: string; preco: number; descricao: string; quantidade: number },
  ): Promise<APIResponse> {
    return this.request.post("/produtos", {
      data,
      headers: this.authHeaders(token),
    });
  }

  getProduct(id: string): Promise<APIResponse> {
    return this.request.get(`/produtos/${id}`);
  }

  deleteProduct(token: string, id: string): Promise<APIResponse> {
    return this.request.delete(`/produtos/${id}`, {
      headers: this.authHeaders(token),
    });
  }

  createCart(token: string | undefined, produtos: CartItem[]): Promise<APIResponse> {
    return this.request.post("/carrinhos", {
      data: { produtos },
      headers: this.authHeaders(token),
    });
  }

  getCart(id: string): Promise<APIResponse> {
    return this.request.get(`/carrinhos/${id}`);
  }

  listCartsOfUser(idUsuario: string): Promise<APIResponse> {
    return this.request.get("/carrinhos", { params: { idUsuario } });
  }

  cancelPurchase(token: string): Promise<APIResponse> {
    return this.request.delete("/carrinhos/cancelar-compra", {
      headers: this.authHeaders(token),
    });
  }
}
