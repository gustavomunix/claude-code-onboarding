# Multi-agente — uma superfície, um dono

Leitura do upstream em 2026-10-11. Versões e estado da máquina conferidos em
2026-10-17 (tabela "Versões"). Fontes: `docs/USAGE.md` do code-review-graph
2.3.9, `docs/grok.md` do Token Optimizer 5.13.49, matriz do Context Mode,
README do Caveman v3.2.0 (lido em 2026-10-11; instalado aqui: 4.0.1), e o guia
local do Grok 1.0.62 (`~/.grok/docs/user-guide/`).

O caminho completo continua o Claude Code (`setup/00` a `setup/07`). Este
arquivo diz o que cada ferramenta cobre nos outros agentes, e o que não
empilhar.

RTK, Headroom e JFrog Boost ficam de fora. Os três comprimem saída de comando,
a mesma superfície do proxy do Caveman. Headroom ainda injeta instrução no
contexto.

## Dono de cada superfície

| Superfície | Dono | Por quê |
|---|---|---|
| Saída de terminal e leitura (git, teste, lint, log) | **Proxy do Caveman, módulo `input`** | Comprime o que o agente lê. Só no Claude do WSL. RTK não entra: a faixa é a mesma. |
| Payload bruto (log, CSV, snapshot, JSON de API) | **Context Mode** | Sandbox. O modelo recebe o resumo, o bruto fica no SQLite local. |
| Mapa do código (quem chama o quê) | **code-review-graph** | Um `graph.db` local, servido por MCP. Vale para qualquer cliente MCP. |
| Prosa da resposta | **Caveman, plugin ou skill** | Encurta a resposta. Não mexe em tool output. |
| Auditoria, compactação, custo, dashboard | **Token Optimizer** | Config inchada, skill morta, checkpoint, qualidade, dólar. |

O proxy do Caveman senta na frente da sessão inteira (~33% menos input, número
do upstream, em arquivos de teste com ruído). Aqui só o módulo `input` fica
ligado, só no Claude do WSL: `caveman setup --only input --agents claude`. Os
módulos `output` (a voz já vem do plugin), `routing` (Auto, envia prompts ao
Caveman Cloud), `scripts`, `browse` e `waste-fixes` ficam desligados.

No Claude, o proxy (`input`) e a compressão de bash do Token Optimizer mexem
na mesma saída. Se um comando voltar ilegível, desligue primeiro a compressão
de bash do Token Optimizer, no shell que abre o `claude`:

```bash
export TOKEN_OPTIMIZER_BASH_COMPRESS=0
```

Para fixar, ponha `"TOKEN_OPTIMIZER_BASH_COMPRESS": "0"` no bloco `env` do
`~/.claude/settings.json`.

No Grok não invente um segundo rewriter no mesmo `PreToolUse`.

## Matriz

🟢 hook ou plugin oficial e transparente. 🟡 parcial ou beta. 🔴 sem suporte
no upstream lido. ⚪ não usado nesta máquina.

| | Claude Code | Cursor | Codex | Grok Build | opencode 2.x |
|---|---|---|---|---|---|
| Proxy do Caveman (`input`) | 🟢 só no WSL | ⚪ | ⚪ | ⚪ | ⚪ |
| Context Mode | 🟢 plugin | 🟢 hook JSON | 🟢 hook JSON | 🟡 só MCP | 🟡 só MCP (plugin 1.0.169 é formato 1.x) |
| code-review-graph 2.3.9 | 🟢 `--platform claude-code` | 🟢 `--platform cursor` | 🟢 `--platform codex` | 🟡 sem flag; `.mcp.json` | 🟢 `--platform opencode` |
| Caveman (voz) | 🟢 plugin | 🟢 hook `sessionStart` | 🟢 `$caveman` | 🟡 skills em `~/.grok/skills`; upstream não cita o nome | 🟢 plugin `./plugins/caveman` |
| Token Optimizer | 🟢 plugin | 🟢 `install.sh --cursor` | 🟢 `docs/codex.md` | 🟡 `install.sh --grok`, beta; não instalado aqui | 🟡 `install.sh --opencode`, sem doc própria; não instalado aqui |

Codex não está instalado nesta máquina. A coluna vem só do upstream.

## RTK (não usado)

O RTK fica de fora (`AGENTS.md`). O proxy do Caveman (`input`) comprime a
mesma saída no Claude. Não rode `rtk` em nenhum agente desta máquina. Dois
rewriters no mesmo `PreToolUse` brigam pela mesma saída.

## code-review-graph — como funciona no Cursor

Upstream **2.3.9**. Nesta máquina o pipx já está em **2.3.9**, no Linux e no
Windows. Python 3.10+.

Flags: `codex`, `claude-code` (ou `claude`), `cursor`, `windsurf`, `zed`,
`continue`, `opencode`, `antigravity`, `gemini-cli`, `qwen`, `kiro`, `qoder`,
`copilot`, `copilot-cli`, `codebuddy`, `hermes`, `all`. Não existe `grok`.

O mecanismo é o mesmo em todo cliente. Tree-sitter lê o repo, grava nós
(função, classe, import) e arestas (chamada, herança, teste) num SQLite
local. Na hora da pergunta o agente chama o MCP e recebe o blast radius: quem
chama, quem depende, qual teste cobre. Ele lê esse conjunto, não a árvore
inteira. Hook, pre-commit ou `watch` reindexam só o arquivo cujo SHA-256
mudou.

No Cursor, rode só o MCP:

```bash
code-review-graph install --platform cursor --no-hooks --no-instructions
code-review-graph build
```

Com as duas flags, o install grava `.cursor/mcp.json` e garante
`.code-review-graph/` no `.gitignore`. Sem elas, ele também:

- faz append em `AGENTS.md`;
- cria `.cursorrules`;
- põe hooks em `~/.cursor/hooks.json`, que vale para todo projeto.

Sem TTY, a pergunta antes de injetar instrução aceita sozinha. O `--dry-run`
mostra o MCP e os arquivos de instrução, mas não lista os hooks.

Nos outros clientes:

- `--platform claude-code` cria `.mcp.json`, `CLAUDE.md`, `.claude/settings.json`, skills em `.claude/skills` e o hook git `pre-commit`.
- `--platform codex` grava o MCP em `~/.codex/config.toml` (global), faz append em `AGENTS.md`, põe hooks do Codex e o `pre-commit`.
- Skills nativas vão para Claude Code, Gemini CLI, CodeBuddy, Hermes e Qoder.

Por isso, no Cursor:

1. Rode os dois comandos na raiz do git.
2. Reinicie o Cursor para ele ler `.cursor/mcp.json`.
3. Peça o blast radius em linguagem normal. Não há slash command do grafo no Cursor.
4. Mantenha o grafo com `code-review-graph update`, ou deixe `code-review-graph watch` num terminal. Sem isso o mapa envelhece, porque ninguém reindexa no save.

`install` sem `--platform` vale `all`. Ele configura toda ferramenta detectada
e injeta instrução em todos os arquivos de regra. Não use aqui. `--dry-run`
mostra o que seria escrito. `--no-hooks`, `--no-skills` e `--no-instructions`
pulam essas partes. `-y` aceita a injeção sem perguntar.

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

Voz: plugin no Claude, skill ou plugin nos outros agentes. Proxy: só o módulo
`input`, só no Claude do WSL (veja o topo).

Nesta máquina o instalador amplo do Caveman 4.0.1 já deixou a voz no Cursor
(hook `sessionStart`), no opencode (`./plugins/caveman`) e no Grok (skills em
`~/.grok/skills/` e bloco no `~/.grok/AGENTS.md`). Não instale o skill avulso
por cima: duplica o 4.0.1. No Grok, com o compat do Claude ligado, o `/caveman`
colide com `/user:caveman`. Com o compat desligado (seção abaixo), não colide.

Em máquina nova, instale só no agente que precisa. Exemplo no Cursor:
`npx -y github:JuliusBrussee/caveman#v4.0.1 -- --only cursor` (no npm 12,
com `--allow-git=root`).

Codex: `$caveman` se `/caveman` não disparar. O README v3.2.0 cita Claude,
Codex, Gemini, Cursor, Windsurf, Cline, Copilot e "30+". Não nomeia Grok.
`stop caveman` desliga.

## Grok e o compat do Claude

O Grok 1.0.62 importa o `~/.claude` por padrão:

- hooks do `~/.claude/settings.json`;
- plugins do `~/.claude/plugins/installed_plugins.json`;
- MCP do `~/.claude.json`;
- o `~/.claude/CLAUDE.md`;
- as skills de `~/.claude/skills/`.

Aqui isso fazia o Grok rodar o `caveman-proxy native-hook`, o `caveman
shrink-hook`, os plugins Token Optimizer e Context Mode, e o MCP `caveman`.
O `CLAUDE.md` global entrava junto com `~/.grok/rules/estilo-codigo.md`.

Configurado em 2026-10-17, em `~/.grok/config.toml`. O `[compat.claude]` está
confirmado. O `[plugins] disabled` ainda não (ver pendência abaixo):

```toml
[compat.claude]
skills = false
rules = false
agents = false
mcps = false
hooks = false

[plugins]
disabled = ["caveman", "token-optimizer", "context-mode"]
```

O Grok fica com:

- skills do Caveman em `~/.grok/skills/`;
- bloco do Caveman no `~/.grok/AGENTS.md`;
- MCP `context-mode` no `config.toml`;
- `~/.grok/rules/estilo-codigo.md`.

Confira:

```bash
grok inspect
grok inspect --json
```

Hooks, MCP, skills e `CLAUDE.md` vindos do `~/.claude` devem sair com
`compatibilityStatus: disabled`. No TUI, `/plugins` lista os plugins e
`/hooks` lista os hooks. No `/hooks`, Space desliga o hook selecionado.

Ainda em aberto: o `grok inspect` lista os três plugins do Claude como
`enabled`, e dois hooks de plugin (`token-optimizer`, `context-mode`). A doc
aceita nome simples ou ID (`<scope>/<hash>/<name>`) em `[plugins] disabled`.
Não está confirmado que o nome simples pega plugin importado do Claude: o
`grok plugin list` diz que não há plugin instalado. Até confirmar, desligue os
dois hooks no `/hooks`, ou confira numa sessão curta que eles não disparam.

O compat do Cursor segue ligado (padrão). Os hooks de `~/.cursor/hooks.json`
aparecem em Hook Load Errors no `grok inspect`: o Grok ainda não lê a resposta
de hook do Cursor, então eles não rodam.

Num repo em `/mnt/*` (DrvFs), o `grok inspect` lista `AGENTS.md` e
`Agents.md`. É o mesmo arquivo: o Grok não percebe que o DrvFs ignora a caixa
e carrega o texto duas vezes. Mantenha o `AGENTS.md` curto.

## Token Optimizer no Grok

v5.13.49, `docs/grok.md`. Contrato testado contra o fonte do Grok, sem sessão
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

Nesta máquina o adapter não está instalado: `~/.grok/hooks/` não existe. O
matcher do `PreToolUse` dele é `Bash`. O guia local aliasa `Bash` para
`run_terminal_command`, então o hook enxerga o shell do Grok. O `--probe`
prova que o processo sai 0. Não prova que o Grok aplica o `updatedInput` que
o adapter devolve. Isso continua na lista ao vivo deles.

Dois detalhes do contrato, ainda sem sessão real observada:

- `updatedInput` no guia do Grok vai dentro de `hookSpecificOutput`.
- Custo ausente significa desconhecido, não zero.

Se alguém instalar depois, mantenha o compat do Claude desligado (seção
anterior). Com ele ligado, os hooks do plugin Claude e os do adapter rodam em
dobro.

Install, manual, nesta ordem:

1. Clone e rode o `grok-doctor`. Ele confere o Grok antes de gravar nada.
2. Confira com `grok inspect` que o compat do Claude segue desligado.
3. Rode o `install.sh --grok`.
4. Rode o `grok-doctor --probe`. Ele só testa o hook já gravado em
   `~/.grok/hooks/token-optimizer.json`. Antes do install, acusa
   `no grok hook entry installed`.
5. Probe falhou: `grok-uninstall`.

```bash
git clone --depth 1 https://github.com/alexgreensh/token-optimizer.git
cd token-optimizer
TOKEN_OPTIMIZER_RUNTIME=grok python3 skills/token-optimizer/scripts/measure.py grok-doctor
bash install.sh --grok
TOKEN_OPTIMIZER_RUNTIME=grok python3 skills/token-optimizer/scripts/measure.py grok-doctor --probe
```

Plugin Claude já instalado? O módulo vem junto, na pasta da versão mais nova
do cache:

```bash
TO=$(ls -d ~/.claude/plugins/cache/alexgreensh-token-optimizer/token-optimizer/*/ | sort -V | tail -1)
TOKEN_OPTIMIZER_RUNTIME=grok python3 "${TO}skills/token-optimizer/scripts/measure.py" grok-doctor
TOKEN_OPTIMIZER_RUNTIME=grok python3 "${TO}skills/token-optimizer/scripts/measure.py" grok-install
TOKEN_OPTIMIZER_RUNTIME=grok python3 "${TO}skills/token-optimizer/scripts/measure.py" grok-doctor --probe
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

Conferido em 2026-10-17.

| Ferramenta | Nesta máquina (Ubuntu 26.04 no WSL2 + Windows) | Upstream |
|---|---|---|
| RTK | não usado (o proxy do Caveman ocupa a faixa) | v1.0.1 (2026-10-14) |
| code-review-graph | 2.3.9 via pipx, no Linux e no Windows | v2.3.9 (2026-09-18) |
| Context Mode | 1.0.169: plugin no Claude do WSL e do Windows, bin global `context-mode` nos dois lados | 1.0.169 (npm) |
| Caveman | 4.0.1: plugin no Claude, CLI e proxy `input` no WSL, hook no Cursor dos dois lados, plugin no opencode, skills no Grok | v4.0.1 (2026-10-13) |
| Token Optimizer | plugin Claude 5.13.49; adapter do Grok não instalado | v5.13.49 (2026-10-16) |
| Grok Build | 1.0.62, compat do Claude desligado | — |
| opencode | 2.0.32 | — |
| Cursor CLI | `cursor-agent` 2026.10.16 Linux em `~/.local/bin`; Windows pelo Scoop | — |
| npm | 12 no WSL, 11 no Windows | — |

O bin do Context Mode responde a `context-mode doctor`. `--version` não imprime
número. O doctor, rodado de um shell com variável do Zed, pode dizer que a
plataforma é Zed. Isso é detecção do ambiente, não o install.

## Install curto por agente

Claude: `setup/01` e `setup/02`.

Cursor:

```bash
npm install -g context-mode
pipx upgrade code-review-graph
code-review-graph install --platform cursor --no-hooks --no-instructions
code-review-graph build
```

Depois, ligue o Context Mode no `~/.cursor` (tabela de "Context Mode nos
outros agentes"). Caveman: nesta máquina já está no Cursor; em máquina nova,
veja a seção "Caveman". Token Optimizer, na pasta do clone:
`bash install.sh --cursor`. Reinicie o Cursor.

Codex (não instalado nesta máquina):

```bash
npm install -g context-mode
code-review-graph install --platform codex --no-hooks --no-instructions
code-review-graph build
```

Caveman: `$caveman`. Marketplace:
`codex plugin marketplace add alexgreensh/token-optimizer`.

opencode: já configurado. Veja "Grok, Cursor e opencode nesta máquina".

Grok: Caveman já em `~/.grok/skills/`. Grafo pelo `.mcp.json` (seção abaixo).
Context Mode só como MCP, e só se o modelo for mandado para `ctx_execute`.
Token Optimizer não instalado. Se instalar, siga a ordem de "Token Optimizer
no Grok" e só confie nele depois que o `grok-doctor --probe` passar.

## Grok e o grafo, sem flag própria

O Grok lê o `.mcp.json` da raiz do projeto (pasta confiável). Esse arquivo não
depende do `[compat.claude] mcps`. Ele só deixa de ser lido se você aceitou ou
dispensou o prompt de importação do Claude no Grok.

Para o grafo entrar só por esse arquivo:

```bash
code-review-graph install --platform claude-code --no-hooks --no-skills --no-instructions
code-review-graph build
```

Sem as flags, o `--platform claude-code` também cria `CLAUDE.md`,
`.claude/settings.json`, as skills e o hook git `pre-commit`. Confira com
`grok inspect`: ele mostra cada MCP carregado e a origem.

Grok também lê `AGENTS.md` e `CLAUDE.md` da raiz do repo. Os dois entram se os
dois existirem. O `agents = false` do compat só corta o `~/.claude/` e o
`.claude/CLAUDE*.md`. Não copie o mesmo texto para os dois arquivos.

## Abertura por agente

Claude: `setup/04-sessao.md`.

Cursor, no chat: `/caveman`. Codex: `$caveman`. No terminal do projeto:
`code-review-graph update` (ou `build` na primeira vez) e `context-mode doctor`.

Grok, no chat: `/caveman`. Com `[compat.claude] skills = true`, ele colide
com o plugin do Claude: use `/user:caveman`. Blast radius pelo MCP antes de ler o repo. Payload
grande via `ctx_execute` ou `ctx_search`. Custo, só se o adapter foi
instalado e o probe passou:

```bash
TOKEN_OPTIMIZER_RUNTIME=grok python3 ~/.grok/token-optimizer/plugin/skills/token-optimizer/scripts/measure.py grok-summary
```

Use o caminho que `grok-doctor` imprimir. Não chute se o probe falhou.

## Empilhar, medir e desativar o que quebrar

Stack completo no Claude: plugin do Caveman, proxy do Caveman (`input`),
Context Mode, Token Optimizer. No `PreToolUse` rodam juntos:

- `caveman-proxy native-hook` (proxy, em todo tool);
- `caveman shrink-hook` (CLI do Caveman);
- hooks do Context Mode (`Bash`, `Read`, `Grep`, `WebFetch`, `Agent`, `mcp__`);
- hooks do Token Optimizer (`Bash`, `Read`, `Agent|Task`, `mcp__.*`);
- o hook `prompt` de `Write|Edit` (`setup/07`).

Por isso a falha típica é saída truncada, ilegível ou vazia, não erro explícito.

O setup do proxy também grava, e vale lembrar ao depurar:

- `ANTHROPIC_BASE_URL=http://127.0.0.1:8787/w/claude` no `env` do `~/.claude/settings.json`;
- o MCP `caveman` no `~/.claude.json`;
- hooks `native-hook` em quase todo evento.

Há ainda um hook `SessionStart` do Context Mode,
`~/.claude/hooks/context-mode-cache-heal.mjs`. Ele conserta o caminho do
plugin no cache depois de auto-update.

Sinais de quebra:

- Comando devolve resumo demais (`git diff`, teste sem o detalhe necessário).
- O agente relê o mesmo arquivo ou repete o mesmo comando.
- Erra por falta de contexto que antes não faltava.
- Falha de conexão de MCP ou hook.

Diagnóstico:

```bash
caveman status
caveman doctor
```

No chat: `/context-mode:ctx-doctor` e `/token-optimizer:quick`.

Desativar, do menos ao mais custoso:

| Ordem | Peça | Como |
|---|---|---|
| 1 | Compressão de bash do Token Optimizer | `export TOKEN_OPTIMIZER_BASH_COMPRESS=0`, ou no `env` do `settings.json` |
| 2 | Context Mode | `/plugin disable context-mode@context-mode` |
| 3 | Proxy do Caveman | `caveman off input`, ou restaurar o backup de `~/.claude/settings.json` e `~/.claude.json` |
| 4 | Token Optimizer inteiro | `/plugin disable token-optimizer@alexgreensh-token-optimizer` |

O plugin do Caveman fica por último: só muda a voz, não mexe em saída de
ferramenta. Sem o compressor de bash, o Token Optimizer ainda audita (CLAUDE.md
inchado, skills mortas, MCPs ociosos), faz checkpoint de compactação e mostra
custo.

Medir antes de concluir que algo ajudou:

1. Linha de base: 3 ou 4 tarefas típicas com tudo desligado. Anote custo, tokens
   e tempo.
2. Ligue uma peça por vez e repita as mesmas tarefas.
3. Compare com `/caveman-stats`, `/context-mode:ctx-stats` e
   `/token-optimizer:quick`. Olhe custo total, tempo e qualidade, não só a
   contagem de tokens.

Overhead de regras e hooks sem retorno é o risco real de manter tudo ligado.
Os números percentuais dos upstreams são deles, não medições deste guia.

## Grok, Cursor e opencode nesta máquina

O instalador amplo do Caveman já deixou a voz nos três. O proxy (`input`) fica
só no Claude do WSL. O `caveman status` sugere `caveman enable opencode`: não
rode.

| Agente | Já instalado | Recomendado | Evitar |
|---|---|---|---|
| Grok 1.0.62 | Caveman: skills em `~/.grok/skills/` e bloco no `~/.grok/AGENTS.md`. MCP `context-mode` no `config.toml`. Regra `~/.grok/rules/estilo-codigo.md`. Compat do Claude desligado. Adapter do Token Optimizer: não. | Grafo via `.mcp.json`, conferido no `grok inspect`. | Proxy. Religar o compat do Claude. Usar o Token Optimizer sem o `grok-doctor --probe` passar. |
| Cursor (`cursor-agent`) | Caveman (hook `sessionStart`) e Context Mode (hooks + MCP), no WSL e no Windows. Ver "Windows e WSL" abaixo. | Grafo: `code-review-graph install --platform cursor --no-hooks --no-instructions`, por projeto. | Proxy. RTK. |
| opencode 2.0.32 | Caveman: plugin `./plugins/caveman` (`server.js`, formato 2.x) na chave `plugins`. Context Mode só MCP (`mcp.servers.context-mode`; o log mostra `tools=11`). `instructions` com `estilo-codigo.md`. | Manter. Voltar ao plugin do Context Mode quando sair a versão para a 2.x. | `caveman enable opencode`: o proxy fica só no Claude. |

Regras que valem para os três:

- Uma superfície, um dono. Não repita no agente o que o Claude já faz.
- Cada agente tem o seu próprio `AGENTS.md`. Não copie texto entre eles.
- Rode `caveman status` e confira o que cada agente carrega antes de empilhar.
- Meça cada agente à parte (seção anterior), porque o custo e o contexto não são
  comparáveis entre eles.

## Context Mode nos outros agentes

Aplicado nesta máquina. No Claude vem pelo plugin e não precisa do bin global.
Nos demais, a doc do upstream exige `npm install -g context-mode`.

```bash
npm install -g context-mode
context-mode doctor
```

O npm 12 (o do WSL) bloqueia os scripts de instalação do `better-sqlite3`.
Aqui o `doctor` passou sem eles (FTS5 ok). Se o FTS5 falhar, o pacote vai no
fim do comando:

```bash
npm install -g context-mode --allow-scripts=context-mode,better-sqlite3
```

| Agente | Config | Observação |
|---|---|---|
| Cursor | `~/.cursor/mcp.json` com `"context-mode": {"command": "context-mode"}`, e em `~/.cursor/hooks.json` os hooks `preToolUse`, `postToolUse` e `stop` (`context-mode hook cursor ...`) | Mesclar com os hooks que já existem (o do Caveman em `sessionStart`). O Cursor do Windows usa os mesmos dois arquivos em `C:\Users\<você>\.cursor`. |
| opencode 2.x | Só MCP: `opencode mcp add --global context-mode -- context-mode` (grava `mcp.servers.context-mode`). Os plugins ficam na chave `plugins`; `plugin` é a chave antiga da 1.x | O Context Mode 1.0.169 exporta `{ id, server }`, o formato da 1.x. A 2.x exige `{ id, setup }` e recusa o plugin com `Plugin must export a default definition with an id and an effect or setup function`. Sem o plugin não há roteamento automático, só as ferramentas `ctx_*`. Volte ao plugin quando o upstream publicar a versão para a 2.x. |
| Grok | `grok mcp add context-mode context-mode` | Só MCP, sem hooks. Confira com `grok inspect` (origem `config.toml`) e `grok mcp doctor`. |
| Zed | `context_servers` em `%APPDATA%\Zed\settings.json` (lado Windows), com `"command": "context-mode"` | Exige o `npm install -g` também no Windows (PowerShell). Sem ele, use `wsl.exe -e <node do WSL> <start.mjs>`. Sem hooks. |

Zed lê o `settings.json` do Windows, mesmo com o projeto no WSL. O arquivo é
JSONC: preserve os comentários ao editar. Os agentes `claude-acp` e `cursor` do
Zed usam a config própria de cada um, não o `context_servers`.

Sem hooks (Grok, Zed) o agente só usa as ferramentas `ctx_*` se for instruído.
O upstream traz um `AGENTS.md` de roteamento em `configs/` do pacote. Ele manda
quase tudo para `ctx_execute` e só vale onde as ferramentas existem. Não o cole
no `AGENTS.md` deste repo: o Grok o carregaria.

Fazer backup antes de editar `hooks.json`, `opencode.jsonc`, `config.toml` do
Grok e o `settings.json` do Zed. Verificar em cada agente: a ferramenta
`ctx_stats` no chat (no Claude, `/context-mode:ctx-stats`), ou o painel de
MCP. Reinicie o agente depois de editar.

## Windows e WSL: cada um no seu quadrado

Claude Code e Cursor têm uma casa em cada lado. Nenhum lê a config do outro.

| Agente | WSL | Windows |
|---|---|---|
| Claude Code | `~/.claude` | `C:\Users\<você>\.claude` |
| Cursor | `~/.cursor` | `C:\Users\<você>\.cursor` |
| Caveman (modo padrão) | `~/.config/caveman/config.json` | `%APPDATA%\caveman\config.json` |

### Armadilha do shim do Scoop

O PATH do WSL termina com as pastas do Windows. Sem um `cursor-agent` Linux, o
shell acha `/mnt/c/Users/<você>/scoop/shims/cursor-agent`, que chama o
`cmd.exe`. Esse binário é o do Windows e lê `C:\Users\<você>\.cursor`, não
`~/.cursor`. O shim `agent` do Scoop também é o Cursor do Windows, não o Grok.
O mesmo vale para `claude` e `grok` se faltarem no Linux. Confira com
`type -a`: o primeiro resultado deve estar em `~/.local/bin`, `~/.grok/bin` ou
`/usr/bin`.

### Cursor no WSL

```bash
ls -la ~/.local/bin/agent
curl https://cursor.com/install -fsS | bash
type -a cursor-agent
cursor-agent login
```

O instalador apaga e recria `~/.local/bin/agent` e `~/.local/bin/cursor-agent`.
O instalador do Grok também usa `~/.local/bin/agent` (link para
`~/.grok/bin/agent`). Se o `ls` mostrou esse link, refaça-o depois e chame o
Cursor sempre por `cursor-agent`:

```bash
ln -sfn ~/.grok/bin/agent ~/.local/bin/agent
```

O `ln` só devolve o `agent` ao Grok. Os hooks e o MCP de `~/.cursor` (Caveman +
Context Mode) valem quando roda o `cursor-agent` Linux. Quem decide é o PATH:
`type -a cursor-agent` tem de mostrar `~/.local/bin/cursor-agent` antes do
shim do Scoop.

### Cursor no Windows

No PowerShell. Faça backup de `C:\Users\<você>\.cursor` antes.

```powershell
npm install -g context-mode
npx -y github:JuliusBrussee/caveman#v4.0.1 -- --only cursor
```

O npm do Windows aqui é o 11. Só no npm 12 ou mais novo acrescente
`--allow-git=root` ao `npx`. O instalador grava o hook do Caveman com o Node
do Windows. Depois, mescle no `hooks.json` os hooks do Context Mode
(`preToolUse`, `postToolUse`, `stop`, os mesmos do WSL) e crie o `mcp.json`
com `"context-mode": {"command": "context-mode"}`. Nenhum caminho desses
arquivos pode apontar para `/home/...`.

### Claude Code no Windows

Os plugins são por casa. No Claude do Windows, rode os mesmos comandos de
`setup/01` e `setup/02` (`/plugin marketplace add ...`, `/plugin install ...`).
O modo padrão do Caveman fica em `%APPDATA%\caveman\config.json`, com
`{"defaultMode": "caveman"}`. O proxy `input` fica só no Claude do WSL.

### PATH duplicado no `~/.bashrc`

Cada shell aninhado relê o `~/.bashrc`. Um `export PATH="$HOME/.local/bin:$PATH"`
solto repete a pasta a cada nível. Use uma guarda:

```bash
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) export PATH="$HOME/.local/bin:$PATH" ;; esac
```

O bloco `# >>> grok installer >>>` vem do instalador oficial do Grok
(`https://x.ai/cli/install.sh`). Ele faz o mesmo `export` sem guarda, então
`~/.grok/bin` se repete a cada nível de shell. É só cosmético. Não edite o
bloco: o instalador o reescreve a cada reinstalação.
