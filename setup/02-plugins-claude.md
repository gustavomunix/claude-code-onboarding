# Plugins do Claude Code — Instalação Interativa

Estes plugins só podem ser instalados via slash command dentro de uma sessão Claude Code.
Cole cada bloco no chat, um de cada vez.

---

## Token Optimizer

O mais completo: audit estrutural, compactação inteligente com checkpoint, dashboard de custo.
Cobre os três tipos de desperdício: estrutural (CLAUDE.md inchado, skills mortas), runtime (re-leituras, output verboso) e comportamental (cache expirando, loops).

**Instalar:**
```
/plugin marketplace add alexgreensh/token-optimizer
/plugin install token-optimizer@alexgreensh-token-optimizer
```

**Habilitar auto-update:**
```
/plugin → aba Marketplaces → selecione alexgreensh-token-optimizer → Enable auto-update
```

**Audit inicial:**
```
/token-optimizer
```

**Verificar:**
```
/token-optimizer quick
```
Deve retornar algo como: `Context fill: 4%  Quality: S (94)`

O plugin não cobre Grok. O adapter é `bash install.sh --grok`, beta, e não
devolve `/token-optimizer` nem checkpoint na abertura. Passos e limites:
`setup/08-multi-agente.md`.

---

## Context Mode

Mantém dados brutos (snapshots Playwright, responses de API, logs, CSVs) fora do contexto via sandbox.
Também salva estado em SQLite — quando o Claude compacta, retoma de onde parou.

**Instalar:**
```
/plugin marketplace add mksglu/context-mode
/plugin install context-mode@context-mode
```

**Verificar:**
```
/context-mode:ctx-doctor
```
Todos os itens devem mostrar `[x]`.

**Verificar no chat (forma curta):**
```
ctx doctor
ctx stats
```

---

## Economia esperada com ambos ativos

| Cenário | Bruto | Com plugins | Economia |
|---|---|---|---|
| Snapshot Playwright | 56 KB | 299 B | 99% |
| 20 issues GitHub | 59 KB | 1,1 KB | 98% |
| Log de acesso (500 req) | 45 KB | 155 B | 100% |
| CLAUDE.md com skills mortas | +4.200 tokens por sessão | 0 | 100% |
| Compactação sem checkpoint | perde 60-70% do contexto | preservado | — |

---

## Comandos do Token Optimizer

| Comando | O que faz |
|---|---|
| `/token-optimizer` | Audit completo com 6 agentes paralelos |
| `/token-optimizer quick` | Health check em 10 segundos |
| `/token-coach` | Análise de 30 dias + plano de melhoria |
| `python3 measure.py doctor` | Diagnóstico: hooks, componentes, versões |
| `python3 measure.py memory-review` | Audit do MEMORY.md (linha 200 é o limite) |
| `python3 measure.py savings` | Economia acumulada em dólares |

## Comandos do Context Mode

| Comando | O que faz |
|---|---|
| `ctx stats` | Economia por ferramenta, tokens consumidos |
| `ctx doctor` | Diagnóstico completo |
| `ctx index` | Indexar arquivo/diretório |
| `ctx search` | Buscar conteúdo indexado |
| `/context-mode:ctx-insight` | Dashboard de analytics no browser |
