# AGENTS.md

Guia de onboarding. Não é um app. Não gere `CLAUDE.md` de projeto aqui.

Mapa multi-agente: `setup/08-multi-agente.md`. Caminho completo do Claude Code:
`setup/00-checklist.md`.

Uma superfície, um dono:

- Terminal e leitura: proxy do Caveman, só o módulo `input`, só no Claude (WSL e
  Windows). RTK fica de fora: comprime a mesma saída. Só entra se o proxy não
  rodar na máquina.
- Payload bruto: Context Mode.
- Mapa do código: code-review-graph, um `graph.db`.
- Prosa: plugin do Caveman. No proxy, o módulo `output` fica desligado.
- Auditoria e custo: Token Optimizer. No Grok, só depois do `grok-doctor --probe`.

Não instale binário, hook ou plugin sem pedido explícito. Não duplique este
arquivo num `CLAUDE.md`: o Grok carrega os dois.

Comentário no código do repositório é público. Vale para qualquer autor e
qualquer agente. Não adicionar comentário novo (`//`, `/* */`, `#`) a menos
que o pedido peça. Comentário que já existe fica.
