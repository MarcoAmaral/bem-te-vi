# Example: `/qa-static` on the ServeRest cart documentation

The output is [`review.md`](review.md), committed exactly as produced.

## Prompt

```text
/qa-static review the ServeRest cart documentation: the "Carrinhos" section of https://serverest.dev/swagger.json (POST /carrinhos, GET /carrinhos, GET /carrinhos/{_id}, DELETE /carrinhos/concluir-compra, DELETE /carrinhos/cancelar-compra), with the token rule from POST /login
```

## Run details

| Item | Value |
| ---- | ----- |
| Date | 2026-10-08 |
| Package version | 2.9.0 (before the rename to Bem-te-vi) |
| Command file followed | `.claude/commands/qa-static.md` |
| Model | An AI coding assistant following the command file (Claude Sonnet 5.5, `claude-sonnet-5-5`) |
| Target | ServeRest API documentation, OpenAPI 3.0.0, API version 3.2.2, plus the live API at `https://serverest.dev` |

## ServeRest's Portuguese

ServeRest answers in Portuguese. Its messages, paths and field names are quoted verbatim in this
example, because the tests compare against what the real server returns. English glosses:

- `/carrinhos`: carts; `concluir-compra`: complete purchase; `cancelar-compra`: cancel purchase
- `produtos`: products; `idProduto`: product ID; `idProdutosDuplicados`: duplicated product IDs
- `quantidade`: quantity; `quantidadeTotal`: total quantity; `precoTotal`: total price
- "Não é permitido possuir produto duplicado": a duplicate product is not allowed
- "Não é permitido ter mais de 1 carrinho": having more than 1 cart is not allowed
- "Não foi encontrado carrinho para esse usuário": no cart was found for this user
- "Produto não encontrado": product not found
- "Produto não possui quantidade suficiente": the product does not have enough stock
- "Carrinho não encontrado": cart not found
- "Registro excluído com sucesso": record deleted successfully ("Estoque dos produtos
  reabastecido": product stock restocked)
- "Os carrinhos retornados são únicos por usuário": the carts returned are unique per user
- `precoUnitario`: unit price; `quantidadeEstoque`: quantity in stock; "usuário": user

## Honest limits

- **Not a pure static review.** The command says "without executing anything". The document alone gave only some of the findings, so the assistant also called the live API (throwaway users, products and carts, deleted afterwards) to check what the document says. Findings that rest on a call are marked `live:` in the output. SR-001 (schema says object, API requires an array), SR-005 (string `quantidade` accepted), SR-006 to SR-008 and SR-012 depend on those calls. Strictly, that is dynamic testing used as context discovery.
- **The package was not installed.** The assistant read the command file from the package source and followed it. It was not launched through an installed slash command.
- **Single date, single observation.** Each `live:` claim was seen once on 2026-10-08. ServeRest is a public, changing service and may behave differently later.
- **Roles are mostly empty.** Only reviewer and scribe were played. Author, manager, review leader and moderator were absent, so no finding has an agreed status; every one is an anomaly or question for the ServeRest maintainer. The verdict "exit criteria not met" is the reviewer's, not a team decision.
- **Severities are judgement.** For example SR-004 (no way to change a cart) is graded Major because it decides what "add to cart" means; a maintainer could reasonably call it by design. The counts in the Verdict section were checked by hand against the table.
- **Scope was chosen, not given.** The assistant picked the cart section. Users, products and login were reviewed only where the cart depends on them. A copy-paste error seen outside scope (the `PUT /produtos/{_id}` description mentions "usuário") was not reported.
- **One line added for the linter.** `review.md` starts with `<!-- markdownlint-disable MD060 -->` (table column style) so the repository's markdownlint passes. The rest of the file is as written. The CLI used in CI does not read a nested `examples/.markdownlint.jsonc`, so an inline comment was used instead of a config file.
- **No other fixes needed from a human to the output.** The file is committed as written. A human reviewer should still re-check SR-005 and SR-012 before reporting them upstream.
