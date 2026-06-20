# Sequência de Sessão — Uso Diário

Referência de comandos para cada momento da sessão.

---

## Abertura obrigatória (toda sessão, nesta ordem)

```
/caveman full
```
Sempre primeiro. Comprime respostas do Claude antes de qualquer token ser gasto.
Com Opus/Sonnet high effort, isso economiza 30–40K tokens só de preamble.

```
/token-optimizer quick
```
Health check em 10 segundos. Detecta CLAUDE.md inchado, skills não usadas, MEMORY.md >200 linhas.
Se mostrar issues → `/token-optimizer` para corrigir.

```
Update the code review graph
```
Primeira vez no projeto: `Build the code review graph for this project`

```
ctx stats
```
Confirma que Context Mode está ativo. Se der erro → `/context-mode:ctx-doctor`

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
/code-review-graph:review-delta
```

### Analisar logs grandes sem poluir contexto

```
ctx_execute("python", `
with open('app.log') as f:
    lines = f.readlines()
errors = [l for l in lines if 'ERROR' in l or 'FATAL' in l]
print(f"Total errors: {len(errors)}")
for e in errors[-20:]:
    print(e.strip())
`)
```

### Rodar testes sem flood de output

```
Run the tests for [módulo]. Show failures only.
```
RTK filtra automaticamente. Reduz de ~2.000 linhas para apenas as falhas.

---

## Monitoramento durante a sessão

**A cada 20–30 minutos:**
```
ctx stats
```

| O que aparece | Significado | Ação |
|---|---|---|
| `Quality: B (74)` | Contexto começando a degradar | `/compact` |
| `Quality: C` ou `D` | Opus/Sonnet objetivamente piores agora | `/compact` imediato |
| `Context fill: >65%` | Zona de degradação real | Summarize → `/compact` |
| Loop detection warning | Claude repetindo abordagem | Reframe explícito (ver abaixo) |

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
/token-optimizer
```
Abre dashboard em `http://localhost:24842/token-optimizer`:
- Custo real da sessão em dólares
- Quality score ao longo do tempo
- Top 5 prompts mais caros
- O que cada ferramenta economizou

---

## Cheat sheet completo

```
ABERTURA
├── /caveman full                          → sempre primeiro
├── /token-optimizer quick                 → checa desperdício estrutural
├── Update the code review graph           → atualiza o mapa do projeto
└── ctx stats                              → confirma Context Mode ativo

DURANTE
├── ctx stats                              → a cada 20 min
├── Check blast radius of <arquivo>        → antes de mexer em qualquer coisa
├── Run tests for <módulo>. Failures only. → testes sem flood de output
└── /code-review-graph:review-delta        → antes de abrir PR

ALERTAS
├── Quality B ou abaixo  → /compact
├── Context >65%         → Summarize + /compact
├── Loop detectado       → Reframe explícito
└── Trocando de modelo   → /compact antes

FIM
└── /token-optimizer     → dashboard com custo real da sessão
```

---

## Por que Opus/Sonnet high effort precisa mais atenção

- Geram mais thinking tokens (invisíveis, mas contam no custo)
- Produzem respostas mais longas por padrão
- Chegam ao limite de contexto mais rápido
- Têm mais a perder numa compactação sem checkpoint

Opus com contexto em 80% está objetivamente pior do que Sonnet com contexto em 30%.
Compactar no momento certo (Quality B, não esperar C ou D) é a decisão de maior impacto.
