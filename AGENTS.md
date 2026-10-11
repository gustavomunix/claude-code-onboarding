# AGENTS.md

Guia de onboarding. Não é um app. Não gere `CLAUDE.md` de projeto aqui.

Mapa multi-agente: `setup/08-multi-agente.md`. Caminho completo do Claude Code:
`setup/00-checklist.md`.

Uma superfície, um dono:

- Terminal: RTK, só no agente que tem hook. Grok não tem.
- Payload bruto: Context Mode.
- Mapa do código: code-review-graph, um `graph.db`.
- Prosa: skill do Caveman. Sem o proxy (`caveman setup`).
- Auditoria e custo: Token Optimizer. No Grok, só depois do `grok-doctor --probe`.

Não instale binário, hook ou plugin sem pedido explícito. Não duplique este
arquivo num `CLAUDE.md`: o Grok carrega os dois.

Comentário no código do repositório é público. Vale para qualquer autor e
qualquer agente. Não adicionar comentário novo (`//`, `/* */`, `#`) a menos
que o pedido peça. Comentário que já existe fica.
