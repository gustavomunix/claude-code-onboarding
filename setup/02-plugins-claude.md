# Plugins do Claude Code — Instalação Interativa

Instale pelo chat, com slash command, ou pelo terminal, com `claude plugin ...`
(mesma sintaxe do Caveman no `setup/01-ferramentas-globais.md`).
No chat, cole cada bloco, um de cada vez.

---

## Token Optimizer

O mais completo: audit estrutural, compactação inteligente com checkpoint, dashboard de custo.
Cobre os três tipos de desperdício: estrutural (CLAUDE.md inchado, skills mortas), runtime (re-leituras, output verboso) e comportamental (cache expirando, loops).

**Instalar:**
```
/plugin marketplace add alexgreensh/token-optimizer
/plugin install token-optimizer@alexgreensh-token-optimizer
```

**Audit inicial:**
```
/token-optimizer
```

**Verificar:**
```
/token-optimizer:quick
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
Os itens devem mostrar `[OK]`. `[WARN]` é aviso; `[FAIL]` precisa de correção.

**Economia da sessão:**
```
/context-mode:ctx-stats
```

---

## Auto-update

Vem desligado por padrão. Ligue nos três marketplaces: `caveman`,
`alexgreensh-token-optimizer` e `context-mode`.

```
/plugin → aba Marketplaces → selecione o marketplace → Enable auto-update
```

Repita em cada Claude (WSL e Windows).

Conferir no Windows (PowerShell):
```powershell
(Get-Content "$env:USERPROFILE\.claude\plugins\known_marketplaces.json" -Raw | ConvertFrom-Json).PSObject.Properties | ForEach-Object { "$($_.Name) autoUpdate=$($_.Value.autoUpdate)" }
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
| `/token-optimizer:quick` | Health check em 10 segundos |
| `/token-optimizer:token-coach` | Análise de 30 dias + plano de melhoria |
| `python3 "$M" doctor` | Diagnóstico: hooks, componentes, versões |
| `python3 "$M" memory-review` | Audit do MEMORY.md (linha 200 é o limite) |
| `python3 "$M" savings` | Economia acumulada em dólares |

`$M` é o `measure.py` da versão mais nova no cache do plugin:

```bash
M=$(ls -d ~/.claude/plugins/cache/alexgreensh-token-optimizer/token-optimizer/*/ | sort -V | tail -1)skills/token-optimizer/scripts/measure.py
python3 "$M" doctor
```

Windows (PowerShell):
```powershell
$v = Get-ChildItem "$env:USERPROFILE\.claude\plugins\cache\alexgreensh-token-optimizer\token-optimizer" -Directory | Sort-Object { try { [version]$_.Name } catch { [version]'0.0' } } | Select-Object -Last 1
$M = Join-Path $v.FullName 'skills\token-optimizer\scripts\measure.py'
python $M doctor
```

## Comandos do Context Mode

| Comando | O que faz |
|---|---|
| `/context-mode:ctx-stats` | Economia por ferramenta, tokens consumidos |
| `/context-mode:ctx-doctor` | Diagnóstico completo |
| `/context-mode:ctx-index` | Indexar arquivo/diretório |
| `/context-mode:ctx-search` | Buscar conteúdo indexado |
| `/context-mode:ctx-insight` | Dashboard de analytics no browser |

---

## Statusline combinada (Caveman + Token Optimizer)

O Claude aceita um só `statusLine`. O Token Optimizer mostra contexto e
qualidade; o Caveman mostra o selo `[CAVEMAN]` com o modo ativo. Um script
junta os dois: lê o JSON do stdin uma vez, passa para cada um e põe o selo no
início da primeira linha.

Crie `~/.claude/statusline-combo.sh`:

```bash
#!/bin/bash
input=$(cat)
plugins="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/plugins"
to_script="$plugins/marketplaces/alexgreensh-token-optimizer/skills/token-optimizer/scripts/statusline.js"
cave_dir=$(ls -d "$plugins"/cache/caveman/caveman/*/ 2>/dev/null | sort -V | tail -1)
cave_script="${cave_dir}src/hooks/caveman-statusline.sh"

cave=""
[ -f "$cave_script" ] && cave=$(printf '%s' "$input" | bash "$cave_script" 2>/dev/null)
to=""
[ -f "$to_script" ] && to=$(printf '%s' "$input" | node "$to_script" 2>/dev/null)

if [ -n "$cave" ] && [ -n "$to" ]; then
  printf '%s %s' "$cave" "$to"
else
  printf '%s%s' "$cave" "$to"
fi
```

O `sort -V` pega a versão mais nova do cache do Caveman, então o script
sobrevive a update do plugin. Se um dos dois sumir, o outro aparece sozinho.

```bash
chmod +x ~/.claude/statusline-combo.sh
echo '{}' | ~/.claude/statusline-combo.sh
```

No `~/.claude/settings.json` (backup antes):

```json
"statusLine": { "type": "command", "command": "bash ~/.claude/statusline-combo.sh" }
```

Vale na sessão seguinte.

### Windows (PowerShell)

O `.sh` não roda no Claude do Windows. O equivalente chama o
`caveman-statusline.ps1` do plugin. Crie `~\.claude\statusline-combo.ps1`:

```powershell
$ErrorActionPreference = 'SilentlyContinue'
$utf8NoBom = New-Object Text.UTF8Encoding $false
[Console]::InputEncoding = $utf8NoBom
[Console]::OutputEncoding = $utf8NoBom
$OutputEncoding = $utf8NoBom
$inputJson = [Console]::In.ReadToEnd().TrimStart([char]0xFEFF)
$claudeDir = if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $HOME '.claude' }
$plugins = Join-Path $claudeDir 'plugins'
$toScript = Join-Path $plugins 'marketplaces\alexgreensh-token-optimizer\skills\token-optimizer\scripts\statusline.js'
$caveDir = Get-ChildItem (Join-Path $plugins 'cache\caveman\caveman') -Directory |
    Sort-Object { try { [version]$_.Name } catch { [version]'0.0' } } |
    Select-Object -Last 1
$caveScript = if ($caveDir) { Join-Path $caveDir.FullName 'src\hooks\caveman-statusline.ps1' }

$cave = ''
if ($caveScript -and (Test-Path $caveScript)) {
    $cave = ($inputJson | powershell -NoProfile -ExecutionPolicy Bypass -File $caveScript 2>$null) -join "`n"
}
$to = ''
if (Test-Path $toScript) {
    $to = ($inputJson | node $toScript 2>$null) -join "`n"
}

if ($cave -and $to) {
    [Console]::Out.Write("$cave $to")
} else {
    [Console]::Out.Write("$cave$to")
}
```

O `Sort-Object` por `[version]` faz o papel do `sort -V`. As linhas de
encoding não são opcionais: no PowerShell 5.1, o pipe para o `node` leva um
BOM UTF-8, o `JSON.parse` do Token Optimizer falha e a parte dele some calada.

Testar (pelo `cmd`, que não põe BOM):
```powershell
cmd /c "echo {} | powershell -NoProfile -ExecutionPolicy Bypass -File %USERPROFILE%\.claude\statusline-combo.ps1"
```

No `~\.claude\settings.json` (backup antes; troque `<você>`):

```json
"statusLine": { "type": "command", "command": "powershell -NoProfile -ExecutionPolicy Bypass -File C:/Users/<você>/.claude/statusline-combo.ps1" }
```

Use `/` no caminho. O Claude do Windows roda o `statusLine` pelo Git Bash, que
come as `\` sem aspas: `C:\Users\...` vira `C:Users...` e a barra fica vazia.

Cada execução leva ~0,6 s (dois processos novos).

---

## Solução de problemas

`node: not found` nos hooks, ou o MCP do Context Mode não conecta: os hooks dos
plugins chamam `node` sem caminho absoluto. O Claude precisa abrir com o Node no
PATH. Com nvm, abra o Claude num terminal que carregue o `~/.bashrc`. Se o
launcher não carrega o shell (atalho, IDE), crie um symlink em `~/.local/bin`:

```bash
ln -sf "$(. ~/.nvm/nvm.sh && nvm which default)" ~/.local/bin/node
```

Trocou a versão do Node? Refaça o symlink.

No Windows com Scoop, o `node` vem de `~\scoop\apps\nodejs\current` e o Scoop
põe essa pasta no PATH do usuário. Se o hook não acha o `node`, confira com
`Get-Command node` num terminal novo. Não aponte hooks para uma versão fixa:
use o caminho `current`.

MCP em "falha recente, retenta em 15 min": rode `/mcp` e reconecte
`context-mode`. Depois, `/context-mode:ctx-doctor`.

`npm install -g context-mode` não é necessário no Claude: a doc do upstream
(`docs/platform-support.md`) exige o bin global em todas as plataformas
**exceto** a instalação pelo plugin do Claude Code. Ele só vale para Cursor,
opencode, Codex, Grok e os demais (`setup/08-multi-agente.md`).
