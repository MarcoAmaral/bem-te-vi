# Example: `/qa-agentic` on one ServeRest user story

The pipeline writes three files into one ticket folder, committed exactly as produced:

```text
cart-no-duplicate-product/
├── requirements.md   # stage 1, qa-groomer: 14 atomic requirements
├── checklist.md      # stage 2, qa-designer: technique, checks, priority, suite, level per requirement
└── testcases.md      # stage 3, qa-writer: 33 test cases, TC-CART-001 to TC-CART-033
```

The `evidence/` folder from the command's layout is not present because this run captured no screenshots or recordings.

## Prompt

```text
/qa-agentic As a customer, I can't add the same product to my cart twice. Target: ServeRest, API docs https://serverest.dev, front https://front.serverest.dev. Write the ticket folder to examples/serverest/qa-agentic/cart-no-duplicate-product/
```

## Run details

| Item | Value |
| ---- | ----- |
| Date | 2026-10-08 |
| Package version | 2.9.0 (before the rename to Bem-te-vi) |
| Files followed | `.claude/commands/qa-agentic.md`, `.claude/agents/qa-groomer.md`, `qa-designer.md`, `qa-writer.md`, `.claude/rules/context-discovery.md`, `.claude/rules/testing-guidelines.md` |
| Model | An AI coding assistant following the command files (Claude Sonnet 5.5, `claude-sonnet-5-5`) playing all three stages |
| Target | ServeRest API documentation (OpenAPI 3.0.0, version 3.2.2) and the live API at `https://serverest.dev` |

## ServeRest's Portuguese

ServeRest answers in Portuguese. Its messages, paths and field names are quoted verbatim in this
example, because the tests compare against what the real server returns. English glosses:

- `/carrinhos`: carts; `concluir-compra`: complete purchase; `cancelar-compra`: cancel purchase
- `produtos`: products; `idProduto`: product ID; `idProdutosDuplicados`: duplicated product IDs
- `quantidade`: quantity; `quantidadeTotal`: total quantity; `precoTotal`: total price
- "Não é permitido possuir produto duplicado": a duplicate product is not allowed
- "Não é permitido ter mais de 1 carrinho": having more than 1 cart is not allowed
- "Não foi encontrado carrinho para esse usuário": no cart was found for this user

## Honest limits

- **The three stages were not separate subagents.** The command tells the director to dispatch `qa-groomer`, `qa-designer` and `qa-writer` through the Task tool. This run did not: one assistant wrote the three files in order, using only the previous file for stages 2 and 3. That removes the isolation the Traceability Rule is built on, and the assistant already knew the documentation when it wrote stages 2 and 3. Three details that were not in the previous stage's file (an exact message, a status text and a token validity period) slipped into `checklist.md` and were removed before the file was committed. The writer stage was meant to run on a smaller model; here it ran on the same one. Treat this folder as a faithful example of the output **format**, not as proof of the traceability property.
- **The story had to be adapted.** The API has no operation to add a product to an existing cart: a user may own one cart and there is no update route. "Twice" can therefore happen only inside one `POST /carrinhos` request, and a second request is rejected as "more than 1 cart". `requirements.md` says so in its context notes and covers both readings (requirements 1 to 7 for the duplicate inside one request, 8 to 12 for the second cart; the context notes in `requirements.md` say "1-6" and "7-9", a numbering slip left in the output). That reading is the assistant's assumption, not the story author's.
- **Requirement 3 and requirement 14 rest on live behaviour.** `idProdutosDuplicados` is not in the written documentation; it was seen in a live response. Requirement 14 (a string `quantidade` is rejected) states what the schema declares. The live API accepts the string and returns `quantidadeTotal: "02"`, so the matching test case, TC-CART-030, fails today.
- **The test-case file fails the package's own format hook.** `.claude/hooks/validate-tc-format.sh testcases.md` reports errors: the frontmatter lacks `tracker_issues`, `cdt`, `implementation_pack` and `spec`, and every case lacks the `Issue`, `Manual Env` and `Note` rows. The writer agent's output contract (`ado_user_stories`, `ADO Story`, no `Note`) was followed exactly, and it does not match what the hook requires. This is a defect in the package at version 2.9.0, found by this run. The file was left as the writer contract produces it.
  *Update, 2026-10-08:* reproduced and fixed in the package (PR #107). The `qa-writer` contract and the
  `/qa` quick reference described an older format than the hook enforces; both now match, and a CI
  check runs the hook on every format description. This output stays unedited as the evidence.
- **Fields the pipeline cannot fill honestly.** `ado_user_stories` is empty and `ADO Story` says "N/A - no tracker". `Automation Score` reads "HIGH (not scored)": no scoring method exists in the files the writer reads, and no number was invented. `risk_level: MEDIUM` is a judgement.
- **No negative-control or mutation check of the 33 cases.** Their expected results come from the document and from single live calls on 2026-10-08. The 16 cases automated in `../qa-automate/` were run; the other 17 were not.
- **Lines added for the linter.** `checklist.md` starts with `<!-- markdownlint-disable MD022 MD032 -->` because the qa-designer output shape puts a list directly under each heading, and `testcases.md` has `<!-- markdownlint-disable MD060 -->` after its frontmatter for table column style. Nothing else was edited. The CLI used in CI does not read a nested `examples/.markdownlint.jsonc`, so inline comments were used instead of a config file.
- **One case is a manual charter** (TC-CART-033, exploratory) and is tagged `@manual-only`.
