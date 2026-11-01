# pessoal-tnf

Sistemas para o meu jogo de tiro no Roblox (que usa o **ACS**).

## Sistemas

| Sistema | Status |
|---|---|
| Progressão (XP, níveis, desbloqueios) | ✅ |
| Hotbar de armas (substitui a mochila padrão) | ✅ |

---

## Como sincronizar com o Roblox Studio (Rojo)

O código fica em arquivos `.luau` neste repositório. O [Rojo](https://rojo.space) leva o código para o Studio:

1. Instale o Rojo: https://rojo.space/docs/v7/getting-started/installation/
   (o jeito mais fácil é a extensão **Rojo** do VS Code, que já instala tudo)
2. Instale o plugin do Rojo no Roblox Studio (o mesmo link explica como)
3. Na pasta do projeto, rode:
   ```bash
   rojo serve
   ```
4. No Studio, abra o seu jogo, clique no plugin do Rojo e depois em **Connect**

> ⚠️ **Faça um backup do seu jogo antes da primeira conexão** (File → Save to File).
> O Rojo só mexe nas pastas listadas no `default.project.json` (os sistemas novos),
> então o ACS e o resto do jogo ficam como estão. Mesmo assim, ter um backup é sempre bom.

**Sem Rojo?** Também funciona copiando e colando: crie no Studio os mesmos objetos
da tabela abaixo e cole o conteúdo de cada arquivo.

| Arquivo | Onde fica no Studio | Tipo |
|---|---|---|
| `src/shared/Progression/Config.luau` | `ReplicatedStorage > Progression > Config` | ModuleScript |
| `src/shared/Progression/LevelMath.luau` | `ReplicatedStorage > Progression > LevelMath` | ModuleScript |
| — | `ReplicatedStorage > ProgressionRemotes > XPGained` | RemoteEvent |
| — | `ReplicatedStorage > ProgressionRemotes > LevelUp` | RemoteEvent |
| `src/server/Progression/PlayerData.luau` | `ServerScriptService > Progression > PlayerData` | ModuleScript |
| `src/server/Progression/ProgressionService.luau` | `ServerScriptService > Progression > ProgressionService` | ModuleScript |
| `src/server/Progression/KillTracker.luau` | `ServerScriptService > Progression > KillTracker` | ModuleScript |
| `src/server/StartProgression.server.luau` | `ServerScriptService > StartProgression` | Script |
| `src/client/ProgressionHUD.client.luau` | `StarterPlayer > StarterPlayerScripts > ProgressionHUD` | LocalScript |
| `src/shared/Hotbar/Config.luau` | `ReplicatedStorage > Hotbar > Config` | ModuleScript |
| `src/client/Hotbar.client.luau` | `StarterPlayer > StarterPlayerScripts > Hotbar` | LocalScript |

(`ReplicatedStorage > Progression`, `ServerScriptService > Progression` e `ReplicatedStorage > Hotbar` são **Folders**.)

---

## Sistema de progressão

### O que ele faz

- **XP por abate**, **assistência** (deu dano nos últimos 10s) e **sequência de abates** (3, 5, 10, 15 seguidos)
- **XP por tempo de jogo**
- **Níveis** de 1 a 100 com curva configurável
- **Títulos e desbloqueios** por nível (ex.: AK-47 no nível 10)
- **Multiplicador de XP** global (eventos) e por jogador (gamepass)
- **Salva tudo** no DataStore: nível, XP, abates, mortes, assistências e melhor sequência
- **HUD**: barra de XP, avisos de `+100 XP Abate` e banner de "Subiu de nível!"
- Nível aparece na **tabela de jogadores** (leaderstats)

### Configurando

Tudo fica em [`src/shared/Progression/Config.luau`](src/shared/Progression/Config.luau):
XP de cada ação, curva de níveis, recompensas, desbloqueios, multiplicador, etc.

### Como os abates são detectados (importante para o ACS!)

O `KillTracker` usa a tag **`creator`**: um `ObjectValue` dentro do `Humanoid` de quem
levou o tiro, apontando para o `Player` que atirou. Esse é o padrão do Roblox.

**Teste se a sua versão do ACS cria essa tag:**

1. Em `Config.luau`, coloque `Config.Debug = true`
2. No Studio, vá em **Test → Clients and Servers**, com 2 jogadores, e um mata o outro
3. Olhe o Output do servidor:
   - `Fulano matou Ciclano` → ✅ funciona, não precisa fazer nada
   - `Ciclano morreu sem tag "creator"` → ❌ precisa de um ajuste no ACS (abaixo)

**Se precisar do ajuste:** no script do ACS que aplica dano **no servidor**, logo depois
da linha que tira vida do Humanoid, adicione:

```lua
local KillTracker = require(game.ServerScriptService.Progression.KillTracker)
KillTracker.Tag(humanoidAtingido, jogadorQueAtirou)
```

(Troque `humanoidAtingido` e `jogadorQueAtirou` pelos nomes das variáveis que o ACS usa ali.)

### Usando em outros scripts (servidor)

```lua
local ProgressionService = require(game.ServerScriptService.Progression.ProgressionService)

-- Dar XP (ex.: o time venceu a partida)
ProgressionService.AddXP(player, 250, "MatchWin")

-- Bloquear arma por nível (ex.: na loja ou no armário de armas do ACS)
if ProgressionService.HasUnlocked(player, "AK-47") then
	-- entrega a arma
else
	local nivel = ProgressionService.GetUnlockLevel("AK-47")
	-- avisa: "Desbloqueia no nível " .. nivel
end

-- Fazer algo quando alguém sobe de nível
ProgressionService.LevelUp:Connect(function(player, level, reward)
	print(player.Name, "chegou no nível", level)
end)

-- XP em dobro para um jogador (ex.: gamepass)
player:SetAttribute("XPMultiplier", 2)
```

Também dá para ler direto do jogador (inclusive no cliente):
`player:GetAttribute("Level")`, `"XP"`, `"XPToNext"` e `"Title"`.

### Testando no Studio

Para salvar dados no Studio, ative **Game Settings → Security → Enable Studio Access to API Services**.
Sem isso, o sistema funciona com dados temporários e mostra um aviso no Output.

---

## Hotbar de armas

Substitui a mochila padrão do Roblox por uma hotbar no mesmo estilo da barra de XP.

- Teclas **1 a 9** equipam e desequipam (no celular, é só tocar no espaço)
- A arma equipada fica destacada em amarelo
- Mostra o ícone da arma quando a Tool tem `TextureId`; sem ícone, mostra o nome
- Diminui sozinha em telas pequenas (celular)
- A barra de XP fica automaticamente logo acima dela

Tamanho, cores, teclas e se mostra espaços vazios ficam em
[`src/shared/Hotbar/Config.luau`](src/shared/Hotbar/Config.luau).

> Se o jogo tinha outra hotbar feita antes, **apague ou desative** a antiga,
> senão as duas aparecem uma em cima da outra.
