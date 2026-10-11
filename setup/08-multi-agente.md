# Multi-agente — uma superfície, um dono

Leitura do upstream em 2026-10-11. Fontes: README `develop` do RTK,
`docs/USAGE.md` do code-review-graph 2.3.9, `docs/grok.md` do Token Optimizer
v5.13.37, matriz do Context Mode, README do Caveman v3.2.0, e o guia de hooks
desta máquina (`~/.grok/docs/user-guide/10-hooks.md`).

O caminho completo continua o Claude Code (`setup/00` a `setup/07`). Este
arquivo diz o que cada ferramenta cobre nos outros agentes, e o que não
empilhar.

Headroom e JFrog Boost ficam de fora. Os dois comprimem saída de comando, a
mesma superfície do RTK. Headroom ainda injeta instrução no contexto.

## Dono de cada superfície

| Superfície | Dono | Por quê |
|---|---|---|
| Saída de terminal (git, teste, lint, log) | **RTK** | Hook reescreve o comando antes de rodar. Especialista dessa faixa. |
| Payload bruto (log, CSV, snapshot, JSON de API) | **Context Mode** | Sandbox. O modelo recebe o resumo, o bruto fica no SQLite local. |
| Mapa do código (quem chama o quê) | **code-review-graph** | Um `graph.db` local, servido por MCP. Vale para qualquer cliente MCP. |
| Prosa da resposta | **Caveman, só o skill** | Encurta a resposta. Não mexe em tool output. |
| Auditoria, compactação, custo, dashboard | **Token Optimizer** | Config inchada, skill morta, checkpoint, qualidade, dólar. |

O proxy do Caveman (`caveman setup --install`, `caveman claude`) é outra pilha.
Ele senta na frente da sessão inteira (~33% menos input, número do README
v3.2.0). Não ligue esse proxy em cima de RTK + Context Mode + Token Optimizer.

No Claude, RTK (antes) e Token Optimizer (depois, no output já capturado)
podem coexistir. Se um comando voltar ilegível, desligue só a compressão de
bash do Token Optimizer e deixe o RTK:

```bash
TOKEN_OPTIMIZER_BASH_COMPRESS=0
```

No Grok não existe hook de RTK. Não invente um segundo rewriter no mesmo
`PreToolUse`.

## Matriz

🟢 hook ou plugin oficial e transparente. 🟡 parcial ou beta. 🔴 sem suporte
no upstream lido hoje.

| | Claude Code | Cursor | Codex | Grok Build |
|---|---|---|---|---|
| RTK | 🟢 `rtk init -g` | 🟢 `rtk init -g --agent cursor` | 🟢 no `develop`: hook + `AGENTS.md` | 🔴 ausente na lista de 18 |
| Context Mode | 🟢 plugin | 🟢 hook JSON | 🟢 hook JSON | 🟡 MCP sim, linha oficial não |
| code-review-graph 2.3.9 | 🟢 `--platform claude-code` | 🟢 `--platform cursor` (só MCP) | 🟢 `--platform codex` | 🟡 sem flag; MCP importado |
| Caveman skill | 🟢 plugin | 🟢 `npx skills add` | 🟢 `$caveman` | 🟡 skill carrega; upstream não cita o nome |
| Token Optimizer | 🟢 plugin | 🟢 `install.sh --cursor` | 🟢 `docs/codex.md` | 🟡 `install.sh --grok`, beta sem prova ao vivo |

## RTK — o que o README `develop` lista

18 ferramentas. Cada uma reescreve comando de shell para o equivalente `rtk`
quando o agente deixa interceptar. Grok não está na tabela.

| Ferramenta | Install | Método |
|---|---|---|
| Claude Code | `rtk init -g` | PreToolUse, binário nativo |
| GitHub Copilot (VS Code) | `rtk init -g --copilot` | PreToolUse, rewrite transparente |
| GitHub Copilot CLI | `rtk init -g --copilot` | PreToolUse, nega e sugere (limite do CLI) |
| Cursor | `rtk init -g --agent cursor` | `preToolUse` em `hooks.json` |
| Gemini CLI | `rtk init -g --gemini` | `BeforeTool` |
| Codex | `rtk init -g --codex` | `PreToolUse` (`updatedInput`) + `AGENTS.md` |
| Windsurf | `rtk init -g --agent windsurf` | `.windsurfrules` (projeto) |
| Cline / Roo Code | `rtk init --agent cline` | `.clinerules` (projeto) |
| OpenCode | `rtk init -g --opencode` | plugin TS |
| OpenClaw | plugin no repo `openclaw/` | plugin TS |
| Pi | `rtk init -g --agent pi` | extensão TS |
| Oh My Pi | `rtk init -g --agent omp` | extensão TS, compartilhada com Pi |
| Hermes | `rtk init --agent hermes` | plugin Python |
| Mistral Vibe | `rtk init -g --agent vibe` | `pre_tool` em `hooks.toml` |
| Kilo Code | `rtk init --agent kilocode` | arquivo de regra |
| Google Antigravity | `rtk init -g --agent antigravity` | plugin em `~/.gemini` ou no projeto |
| Kimi | `rtk init --agent kimi` | `AGENTS.md` |
| Factory Droid | `rtk init -g --agent droid` | PreToolUse, matcher `Execute` |
| Trae | `rtk init -g --agent trae` | PreToolUse, matcher `RunCommand` |

O hook só pega chamada de shell. `Read`, `Grep` e `Glob` nativos do Claude não
passam por ele. Windsurf, Cline, Kilo e Kimi não reescrevem sozinhos: o modelo
tem que prefixar `rtk`.

Nesta máquina o binário em `~/.local/bin/rtk` é **0.51.0**. `rtk init --help`
já mostra `--codex` como hook (`hooks.json`) mais `AGENTS.md`. O backup do
0.44.2 ficou em `~/.local/bin/rtk.0.44.2.bak`.

Como o filtro funciona, em qualquer agente com hook: o modelo pede `git status`,
o hook troca para `rtk git status`, o shell devolve o texto já filtrado
(ruído fora, linhas iguais agrupadas, repetição contada). O cache de prompt
não quebra: o filtro roda uma vez por comando e o resultado entra no histórico
normal.

## code-review-graph — como funciona no Cursor

Upstream **2.3.9**. Nesta máquina o pipx já está em **2.3.9**. Python 3.10+.

Flags: `codex`, `claude-code`, `cursor`, `windsurf`, `zed`, `continue`,
`opencode`, `antigravity`, `gemini-cli`, `qwen`, `kiro`, `qoder`, `copilot`,
`copilot-cli`, `codebuddy`, `hermes`. Não existe `grok`.

O mecanismo é o mesmo em todo cliente. Tree-sitter lê o repo, grava nós
(função, classe, import) e arestas (chamada, herança, teste) num SQLite
local. Na hora da pergunta o agente chama o MCP e recebe o blast radius: quem
chama, quem depende, qual teste cobre. Ele lê esse conjunto, não a árvore
inteira. Hook, pre-commit ou `watch` reindexam só o arquivo cujo SHA-256
mudou.

No Cursor o install é mais estreito que no Claude:

```bash
code-review-graph install --platform cursor
code-review-graph build
```

O que isso grava: `.cursor/mcp.json`. Não grava skill, não grava hook de
sessão, não grava pre-commit. Pre-commit o upstream limita a Codex, Claude
Code e Qoder. Skills nativas vão para Claude Code, Gemini CLI, CodeBuddy,
Hermes e Qoder.

Por isso, no Cursor:

1. Rode os dois comandos na raiz do git.
2. Reinicie o Cursor para ele ler `.cursor/mcp.json`.
3. Peça o blast radius em linguagem normal. Não há `/code-review-graph:review-delta` no Cursor.
4. Mantenha o grafo com `code-review-graph update`, ou deixe `code-review-graph watch` num terminal. Sem isso o mapa envelhece, porque ninguém reindexa no save.

`install` sem `--platform` detecta as ferramentas presentes e configura cada
uma. `--dry-run` mostra o que seria escrito. `--no-hooks`, `--no-skills` e
`--no-instructions` pulam essas partes.

Desinstalar tira só o que o CRG escreveu. Outros MCP, hooks e comentários
JSONC ficam.

```bash
code-review-graph uninstall --dry-run
code-review-graph uninstall --keep-user-configs --repo .
```

## Context Mode

17 clientes no `docs/platform-support.md`. Três jeitos: JSON no stdin/stdout
(Claude, Cursor, Codex, Copilot, Gemini, Kimi, Kiro, Qwen, Antigravity CLI),
plugin TypeScript (OpenCode, Kilo, OpenClaw), ou só MCP (Antigravity app, Zed,
Pi, OMP). Grok não está na lista.

Fora do plugin Claude, o bin global é obrigatório:

```bash
npm install -g context-mode
```

O corte de ~98% depende do hook que manda o output grande para o sandbox.
Sem hook, o modelo precisa escolher `ctx_execute` / `ctx_search`, e o próprio
README fala em ~60%.

## Caveman

Use o skill, não o proxy.

```bash
npx skills add JuliusBrussee/caveman -g
```

Claude também aceita o plugin (`setup/01`). Codex: `$caveman` se `/caveman`
não disparar. O README v3.2.0 cita Claude, Codex, Gemini, Cursor, Windsurf,
Cline, Copilot e "30+". Não nomeia Grok. Nesta máquina o skill já está em
`~/.grok/skills/`. `stop caveman` desliga.

## Token Optimizer no Grok

v5.13.37, `docs/grok.md`. Contrato testado contra o fonte do Grok, sem sessão
ao vivo do autor.

O que o adapter faz:

- Custo e tokens saem do próprio Grok (`sessions/.../updates.jsonl`, campo
  `costUsdTicks`). Não usa tabela de preço do Claude.
- `PreToolUse` pode reescrever input (compressão de bash).
- `PostToolUse` pode mandar `additionalContext` (nudge).
- Fail-open. Não emite deny.

O que não faz, e o guia local confirma:

- `SessionStart` ignora stdout. Sem restore de continuidade na abertura.
- `UserPromptSubmit` descarta o stdout de um hook que deixa o prompt passar.
  Sem nudge de qualidade por prompt.

Nesta máquina o install já rodou. `grok-doctor` ficou 0 fail, 1 warn (ledger
`observed-events.jsonl` vazio até uma sessão real). `grok-doctor --probe`
disparou 5/5 com exit 0. O matcher do `PreToolUse` é `Bash`. O guia local
aliasa `Bash` para `run_terminal_command`, então o hook enxerga o shell do
Grok. O probe prova que o processo sai 0. Não prova que o Grok aplica o
`updatedInput` que o adapter devolve. Isso continua na lista ao vivo deles.

Dois detalhes do contrato, ainda sem sessão real observada:

- `updatedInput` no guia do Grok vai dentro de `hookSpecificOutput`.
- Custo ausente significa desconhecido, não zero.

Install, manual, depois do probe:

```bash
git clone --depth 1 https://github.com/alexgreensh/token-optimizer.git
cd token-optimizer
bash install.sh --grok
TOKEN_OPTIMIZER_RUNTIME=grok python3 skills/token-optimizer/scripts/measure.py grok-doctor
TOKEN_OPTIMIZER_RUNTIME=grok python3 skills/token-optimizer/scripts/measure.py grok-doctor --probe
```

Plugin Claude já instalado? O módulo vem junto:

```bash
TOKEN_OPTIMIZER_RUNTIME=grok python3 ~/.claude/skills/token-optimizer/scripts/measure.py grok-install
```

Isso grava só `~/.grok/hooks/token-optimizer.json` e
`~/.grok/token-optimizer/plugin/`. Não aponte o install com `GROK_HOME`.
Se precisar de outro diretório: `TOKEN_OPTIMIZER_GROK_HOME`.

Não espere `/token-optimizer`, barra de qualidade, nem checkpoint na abertura.
Comandos reais: `grok-summary`, `grok-rollup`. Desinstalar: `grok-uninstall`
(não apaga a sessão do Grok).

`route` e os detectores Opus/Haiku do coach são do Claude. No Grok o número
certo é o `costUsdTicks` do host. Não rode `inject-routing` num `CLAUDE.md`
que o Grok também carrega.

## Versões nesta máquina vs upstream

| Ferramenta | Nesta máquina (Fedora 44) | Upstream |
|---|---|---|
| RTK | 0.51.0 em `~/.local/bin/rtk` | v0.51.0 (2026-10-02) |
| code-review-graph | 2.3.9 via pipx | 2.3.9, com `hermes` |
| Context Mode | plugin Claude + bin global `context-mode` (nvm Node 24) | v1.0.169 (2026-06-29) |
| Caveman | plugin Claude + `~/.grok/skills/` | v3.2.0 (2026-10-08) |
| Token Optimizer | plugin Claude 5.13.37 + hooks em `~/.grok/hooks/token-optimizer.json` | v5.13.37 (2026-10-10) |

O bin do Context Mode responde a `context-mode doctor`. `--version` não imprime
número. O doctor, rodado de um shell com variável do Zed, pode dizer que a
plataforma é Zed. Isso é detecção do ambiente, não o install.

## Install curto por agente

Claude: `setup/01` e `setup/02`.

Cursor:

```bash
rtk init -g --agent cursor
npm install -g context-mode
pip install -U code-review-graph
code-review-graph install --platform cursor
code-review-graph build
npx skills add JuliusBrussee/caveman -g
```

Token Optimizer, na pasta do clone: `bash install.sh --cursor`. Reinicie o Cursor.

Codex, depois de confirmar o hook no `rtk init --help`:

```bash
rtk init -g --codex
npm install -g context-mode
code-review-graph install --platform codex
code-review-graph build
npx skills add JuliusBrussee/caveman -g
```

Marketplace: `codex plugin marketplace add alexgreensh/token-optimizer`.

Grok: Caveman skill e MCP do grafo (veja abaixo). Context Mode só se o modelo
for mandado para `ctx_execute`. Token Optimizer só depois do `grok-doctor --probe`.

## Grok e o grafo, sem flag própria

Grok lê `.mcp.json` e, com compat ligada (padrão), o MCP do Claude e do
Cursor. `code-review-graph install --platform claude-code` numa repo já
entrega o `.mcp.json` que o Grok importa. Confira com `grok mcp list`.

Grok também lê `AGENTS.md` e `CLAUDE.md`. Os dois entram juntos se os dois
existirem. Não copie o mesmo texto para os dois arquivos.

## Abertura por agente

Claude: `setup/04-sessao.md`.

Cursor ou Codex, no chat: `/caveman`. No terminal do projeto:
`code-review-graph update` (ou `build` na primeira vez) e `context-mode doctor`.

Grok, no chat: `/caveman`. Blast radius pelo MCP antes de ler o repo. Payload
grande via `ctx_execute` ou `ctx_search`. Custo, se o probe passou:

```bash
TOKEN_OPTIMIZER_RUNTIME=grok python3 ~/.grok/token-optimizer/plugin/skills/token-optimizer/scripts/measure.py grok-summary
```

Use o caminho que `grok-doctor` imprimir. Não chute se o probe falhou.
