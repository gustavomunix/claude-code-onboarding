# Ferramentas Globais — Instalação

Instale uma vez. Ficam disponíveis em todos os projetos.

---

## Windows: Scoop primeiro

No Windows, tudo deste guia vem pelo Scoop. Instale no PowerShell, sem admin:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
```

Depois, o Git (traz o Git Bash, que a ferramenta Bash do Claude usa) e o
Claude Code:

```powershell
scoop install git claude-code
claude --version
```

---

## Node e pnpm

Node 22.13 ou mais novo (o proxy do Caveman exige; os hooks dos plugins
chamam `node`). Com nvm:

```bash
curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
. "$HOME/.nvm/nvm.sh"
nvm install 24 && nvm alias default 24
corepack enable && corepack prepare pnpm@latest --activate
```

Verificar:
```bash
node -v && pnpm -v
```

Node 25 em diante não traz o corepack. Nesse caso: `npm install -g corepack`.

Windows (PowerShell + Scoop). O Scoop instala o pnpm direto, sem corepack:
```powershell
scoop install nodejs pnpm
node -v; pnpm -v
```

O `npm install -g` do Node do Scoop grava em
`~\scoop\persist\nodejs\bin`, que fica no PATH.

---

## Caveman

Encurta as respostas do Claude. Não afeta o raciocínio, só o texto final.
A economia medida é modesta: a JetBrains mediu ~8,5% de output em 86 tarefas
reais, sem perda de qualidade. O upstream anuncia mais. As regras custam ~1.160
tokens de input, então em tarefa curta o ganho pode ser nulo. Meça com e sem.

Instale só o plugin, dentro do chat:
```
/plugin marketplace add JuliusBrussee/caveman
/plugin install caveman@caveman
/reload-plugins
```

Ou, no terminal, o mesmo plugin:
```bash
claude plugin marketplace add JuliusBrussee/caveman && claude plugin install caveman@caveman
```

Não rode `npx @caveman-ai/cli@latest` nem o `install.sh` sem `--only`: instalam em todos os
agentes da máquina (opencode, Cursor, Grok), com hooks e regras globais.
O CLI `@caveman-ai/cli` entra só no proxy abaixo, com `--only input`.
O plugin e a skill não enviam nada. A exceção é `/caveman-compress`, que envia
o arquivo comprimido ao provedor do modelo.

Para fixar o modo em todas as sessões, crie `~/.config/caveman/config.json`
(no Windows, `%APPDATA%\caveman\config.json`):
```json
{"defaultMode": "caveman"}
```

### Proxy do Caveman, só o módulo `input` (opcional)

Comprime o que o agente lê (logs, testes, JSON). Precisa do Node 22.13+.
Só no Claude, no WSL e no Windows. Os binários vêm prontos para Linux, macOS e
Windows (amd64 e arm64). Não ligue em outro agente.

RTK não é usado: o proxy do Caveman (`input`) comprime a mesma saída. RTK é
fallback só se o proxy não rodar na máquina.

```bash
npm install -g @caveman-ai/cli
caveman telemetry off
caveman setup --dry-run --only input --agents claude
caveman setup --yes --only input --agents claude
```

O setup aponta `ANTHROPIC_BASE_URL` para `http://127.0.0.1:8787/w/claude` no
`~/.claude/settings.json`, instala hooks em vários eventos e registra um MCP.
Faça backup de `~/.claude/settings.json` e `~/.claude.json` antes. Se o proxy
estiver parado, o Claude Code não conecta: `caveman status` e `caveman doctor`.
Vale só na sessão seguinte.

Windows (PowerShell). Os mesmos comandos, com backup antes:
```powershell
Copy-Item "$env:USERPROFILE\.claude\settings.json", "$env:USERPROFILE\.claude.json" "$env:USERPROFILE\Desktop\"
npm install -g @caveman-ai/cli
caveman telemetry off
caveman setup --dry-run --only input --agents claude
caveman setup --yes --only input --agents claude
```

Se o setup acusar `caveman-mcp pre-versioned lacks current mcp_recovery
capability`, rode `caveman setup --install` e repita o `--yes`. O `--install`
também baixa o `caveman-browse` (~34 MB).

No Windows, os binários ficam em `~\.caveman\bin`. Não há serviço nem tarefa
agendada: o hook `SessionStart` do Claude sobe o `caveman-proxy`. Para ver se
está no ar:
```powershell
Get-NetTCPConnection -LocalPort 8787 -State Listen
```

Verificar:
```bash
caveman status
caveman doctor
```

`claude` em `input` deve mostrar `wired`, e o doctor, `healthy`.

---

## code-review-graph

Constrói um mapa estrutural do código (AST + dependências). O Claude consulta o grafo e lê só os arquivos relevantes. Redução: de 951K tokens para ~2K por consulta em projetos grandes.

Prefira o `pipx` (instalação isolada):

```bash
pipx install code-review-graph
```

Ubuntu 24.04+ e WSL: o Python do sistema bloqueia `pip install` global e pode
vir sem `pip`, `venv` e `pipx`. Instale antes (pede `sudo`, num terminal com TTY;
o `!` do Claude Code não serve):

```bash
sudo apt install -y python3-pip python3-venv pipx
sudo apt install -y jq
pipx install code-review-graph
```

Sem a senha, pelo PowerShell: `wsl -u root -- apt install -y python3-pip python3-venv pipx jq`.
O `jq` é usado nas verificações do `setup/07-estilo-codigo.md`.

Windows (PowerShell + Scoop):
```powershell
scoop install python pipx jq
pipx ensurepath
pipx install code-review-graph
```

O `pipx` instala em `~\.local\bin`. Abra um terminal novo depois do
`ensurepath`.

WSL: o PATH inclui as pastas do Windows (`/mnt/c/...`) no fim. Se o Linux ainda
não tem `pipx`, o shell cai no `pipx` do Windows e instala lá, não no Linux.
Confira com `type -a pipx`: o primeiro deve ser `/usr/bin/pipx`. Cada lado
(Windows e WSL) tem a sua cópia do code-review-graph. Projetos abertos pelo
Claude no WSL usam a do Linux.

Verificar:
```bash
code-review-graph --version
```

> Suporta: Python, JS/TS, Go, Rust, Java, C/C++, C#, Ruby, Kotlin, Swift, PHP, Scala, Jupyter.

---

## Verificação conjunta

```bash
caveman status
code-review-graph --version && echo "CRG ok"
```

Windows (PowerShell):
```powershell
caveman status
code-review-graph --version; if ($?) { "CRG ok" }
```

`caveman status` só se instalou o proxy.

Dentro do Claude Code:
```
/caveman
```

---

## Outros agentes

O install acima é o do Claude. Comandos, o que o Cursor recebe do grafo, e o
adapter Grok do Token Optimizer: `setup/08-multi-agente.md`.
