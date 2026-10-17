# Sequência de Sessão — Uso Diário

Referência de comandos para cada momento da sessão no Claude Code.
Os slash commands abaixo são dos plugins do Claude Code.
A abertura de Cursor, Codex e Grok está em `setup/08-multi-agente.md`.

---

## Abertura (toda sessão, nesta ordem)

O Caveman já entra no modo padrão pelo hook, no início da sessão. Não precisa
de comando. Se você desligou, reative:
```
/caveman
```
Outros modos: `/ultracave` e `/megacave`. Desligar: `/caveman off`.

```
/token-optimizer:quick
```
Health check em 10 segundos. Mostra o overhead de contexto, o Quality score e
os três maiores ofensores. Se mostrar issues → `/token-optimizer` para corrigir.

```
Update the code review graph
```
Primeira vez no projeto: `Build the code review graph for this project`

```
/context-mode:ctx-stats
```
Confirma que o Context Mode está ativo. Se der erro → `/context-mode:ctx-doctor`

---

## Contextos de trabalho

### Implementar feature nova

```
Before we start: check the blast radius of the files we'll likely touch.
The feature is [descreva em 1 linha]. What are the key files and their dependencies?
```

### Debugar bug em produção

```
Debug mode. Here's the error: [cole o stack trace].
Don't read the whole codebase. Use the graph to find only the relevant files.
```

### Code review / preparar PR

```
/review-changes
```
Skill que o `code-review-graph install` cria no projeto.

### Analisar logs grandes sem poluir contexto

Peça a ferramenta `ctx_execute_file` com `path: "app.log"` e
`language: "python"`. O arquivo chega no código como `FILE_CONTENT`:

```python
lines = FILE_CONTENT.splitlines()
errors = [l for l in lines if 'ERROR' in l or 'FATAL' in l]
print(f"Total errors: {len(errors)}")
for e in errors[-20:]:
    print(e.strip())
```

Não use `ctx_execute` com `open('app.log')`: o código roda numa pasta
temporária e o caminho relativo falha.

### Rodar testes sem flood de output

```
Run the tests for [módulo]. Show failures only.
```
O pedido já corta a saída para as falhas. No Claude do WSL, o proxy do
Caveman (módulo `input`) comprime a saída de terminal.

---

## Monitoramento durante a sessão

**A cada 20–30 minutos:**
```
/token-optimizer:quick
```

| O que aparece | Significado | Ação |
|---|---|---|
| `Quality: B (74)` | Contexto começando a degradar | `/compact` |
| `Quality: C` ou `D` | Opus/Sonnet objetivamente piores agora | `/compact` imediato |
| `Context fill: >65%` | Zona de degradação real | Summarize → `/compact` |
| Loop detection warning | Claude repetindo abordagem | Reframe explícito (ver abaixo) |

Quality e Context fill vêm do `/token-optimizer:quick`. O
`/context-mode:ctx-stats` mostra quanto o Context Mode economizou por
ferramenta.

---

## Como compactar corretamente

**1. Salvar estado antes:**
```
Summarize current state: files changed, decisions made, what's pending, any blockers.
```

**2. Compactar:**
```
/compact
```
O Smart Compaction do Token Optimizer salva checkpoint — arquivos editados, decisões, erros resolvidos.

**3. Confirmar retomada:**
```
What's the current state? What are we working on?
```

---

## Quebrar loops

Se o Claude estiver tentando a mesma coisa repetidas vezes:

```
Stop. This approach isn't working. New direction: [descreva diferente].
Ignore what we tried before and start fresh from here.
```

---

## Trocar de modelo sem desperdiçar

Trocar de modelo **invalida o cache do prompt** — na próxima mensagem, todo o contexto é re-enviado sem cache.

Antes de trocar:
```
/compact
```
Depois troque. O contexto pós-compactação é menor, o re-send custa menos.

---

## Fim de sessão

```
/token-optimizer:token-dashboard
```
Abre o dashboard como arquivo HTML: uso de contexto, Quality score, histórico
de sessões e economia.

A URL `http://localhost:24842/token-optimizer` só funciona depois de rodar
`measure.py setup-daemon`, que sobe o servidor local.

---

## Cheat sheet completo

```
ABERTURA
├── (hook)                                 → Caveman já ativo; /caveman reativa
├── /token-optimizer:quick                 → checa desperdício estrutural
├── Update the code review graph           → atualiza o mapa do projeto
└── /context-mode:ctx-stats                → confirma Context Mode ativo

DURANTE
├── /token-optimizer:quick                 → a cada 20 min
├── Check blast radius of <arquivo>        → antes de mexer em qualquer coisa
├── Run tests for <módulo>. Failures only. → testes sem flood de output
└── /review-changes                        → antes de abrir PR

ALERTAS
├── Quality B ou abaixo  → /compact
├── Context >65%         → Summarize + /compact
├── Loop detectado       → Reframe explícito
└── Trocando de modelo   → /compact antes

FIM
└── /token-optimizer:token-dashboard → dashboard da sessão
```

---

## Por que Opus/Sonnet high effort precisa mais atenção

- Geram mais thinking tokens (invisíveis, mas contam no custo)
- Produzem respostas mais longas por padrão
- Chegam ao limite de contexto mais rápido
- Têm mais a perder numa compactação sem checkpoint

Contexto cheio piora qualquer modelo, inclusive o Opus.
Compactar no momento certo (Quality B, não esperar C ou D) é a decisão de maior impacto.
