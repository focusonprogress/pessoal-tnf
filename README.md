# pessoal-tnf

Sistemas para o meu jogo de tiro no Roblox (que usa o **ACS**).

## Sistemas

| Sistema | Status |
|---|---|
| Progressão (XP, níveis, desbloqueios) | ✅ |
| Hotbar de armas (substitui a mochila padrão) | ✅ |
| Tela de escolha de time | ✅ |
| Tags de nível/título (cabeça e chat) | ✅ |
| Eventos de servidor | ✅ |
| Recompensa por cabeça | ✅ |
| Missões diárias | ✅ |
| Recompensa de login diário | ✅ |
| Conquistas | ✅ |
| Câmera de morte (assistir quem te matou) | ✅ |
| Proteção do ACS contra kill all (ACSGuard) | ✅ |

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
| `src/shared/TeamSelect/Config.luau` | `ReplicatedStorage > TeamSelect > Config` | ModuleScript |
| `src/shared/TeamSelect/TeamLookup.luau` | `ReplicatedStorage > TeamSelect > TeamLookup` | ModuleScript |
| — | `ReplicatedStorage > TeamSelectRemotes > ChooseTeam` | **RemoteFunction** |
| `src/server/TeamSelect.server.luau` | `ServerScriptService > TeamSelect` | Script |
| `src/client/TeamSelect.client.luau` | `StarterPlayer > StarterPlayerScripts > TeamSelect` | LocalScript |
| `src/shared/Nametags/Config.luau` | `ReplicatedStorage > Nametags > Config` | ModuleScript |
| `src/client/Nametags.client.luau` | `StarterPlayer > StarterPlayerScripts > Nametags` | LocalScript |
| `src/shared/Economy/Config.luau` | `ReplicatedStorage > Economy > Config` | ModuleScript |
| `src/shared/GameEvents/Config.luau` | `ReplicatedStorage > GameEvents > Config` | ModuleScript |
| `src/shared/Bounty/Config.luau` | `ReplicatedStorage > Bounty > Config` | ModuleScript |
| `src/shared/Missions/Config.luau` | `ReplicatedStorage > Missions > Config` | ModuleScript |
| `src/shared/DailyRewards/Config.luau` | `ReplicatedStorage > DailyRewards > Config` | ModuleScript |
| `src/shared/Achievements/Config.luau` | `ReplicatedStorage > Achievements > Config` | ModuleScript |
| — | `ReplicatedStorage > GameRemotes` (Announce, ClaimDaily, KilledBy) | criados sozinhos pelo servidor |
| `src/server/Gameplay/Remotes.luau` | `ServerScriptService > Gameplay > Remotes` | ModuleScript |
| `src/server/Gameplay/Announcer.luau` | `ServerScriptService > Gameplay > Announcer` | ModuleScript |
| `src/server/Gameplay/Events.luau` | `ServerScriptService > Gameplay > Events` | ModuleScript |
| `src/server/Gameplay/Money.luau` | `ServerScriptService > Gameplay > Money` | ModuleScript |
| `src/server/Gameplay/Bounty.luau` | `ServerScriptService > Gameplay > Bounty` | ModuleScript |
| `src/server/Gameplay/Missions.luau` | `ServerScriptService > Gameplay > Missions` | ModuleScript |
| `src/server/Gameplay/DailyRewards.luau` | `ServerScriptService > Gameplay > DailyRewards` | ModuleScript |
| `src/server/Gameplay/Achievements.luau` | `ServerScriptService > Gameplay > Achievements` | ModuleScript |
| `src/server/Gameplay/DeathCam.luau` | `ServerScriptService > Gameplay > DeathCam` | ModuleScript |
| `src/server/StartGameplay.server.luau` | `ServerScriptService > StartGameplay` | Script |
| `src/client/GameHUD.client.luau` | `StarterPlayer > StarterPlayerScripts > GameHUD` | LocalScript |
| `src/client/BountyMarkers.client.luau` | `StarterPlayer > StarterPlayerScripts > BountyMarkers` | LocalScript |
| `src/client/Missions.client.luau` | `StarterPlayer > StarterPlayerScripts > Missions` | LocalScript |
| `src/client/DailyRewards.client.luau` | `StarterPlayer > StarterPlayerScripts > DailyRewards` | LocalScript |
| `src/client/Achievements.client.luau` | `StarterPlayer > StarterPlayerScripts > Achievements` | LocalScript |
| `src/client/DeathCam.client.luau` | `StarterPlayer > StarterPlayerScripts > DeathCam` | LocalScript |

(`ReplicatedStorage > Progression`, `ServerScriptService > Progression`, `ReplicatedStorage > Hotbar`,
`ReplicatedStorage > TeamSelect`, `ReplicatedStorage > TeamSelectRemotes`, `ReplicatedStorage > Nametags`, `Economy`, `GameEvents`, `Bounty`,
`Missions`, `DailyRewards`, `Achievements`, `GameRemotes` e `ServerScriptService > Gameplay` são **Folders**.)

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

---

## Tela de escolha de time

- Aparece quando o jogador entra e pelo botão **TROCAR TIME** durante a partida
- Se adapta à tela: 4 cards em linha no PC e no celular deitado, grade 2x2 no celular em pé
- O card inteiro é clicável, mostra quantos jogadores tem em cada time e destaca o seu time
- O **servidor** é quem decide a troca: confere se o time existe, tempo de espera entre trocas,
  limite de jogadores e balanceamento (os dois últimos vêm desligados)

Tudo fica em [`src/shared/TeamSelect/Config.luau`](src/shared/TeamSelect/Config.luau):
times, cores, imagens dos avatares, textos e regras.

**Imagens dos avatares:** no menu antigo, clique na ImageLabel do avatar e copie o campo
`Image` em Properties (ex.: `rbxassetid://1234567890`) para o `Image` do time no Config.
Se a imagem já for o card inteiro (com nome e fundo), use `Config.ImageMode = "FullCard"`.

**Nomes dos times:** o `TeamName` precisa ser o nome do Team no serviço **Teams** do Studio.
Se algum não for encontrado, aparece um aviso `[TeamSelect]` no Output.

> Desative a tela de times antiga, senão as duas aparecem.

---

## Tags de nível e título

- **Acima da cabeça:** `Nv 12 · Sargento` na cor do time, com o nome embaixo
  (substitui o nome padrão do Roblox)
- **No chat:** `[Nv 12 · Sargento] Fulano: mensagem`
- Por padrão você **só vê a tag de aliados** e de times neutros (Morador), para não entregar
  a posição de inimigos escondidos. Dá para mudar em `ShowForEnemies`

Configuração em [`src/shared/Nametags/Config.luau`](src/shared/Nametags/Config.luau).

> O Roblox só permite um `TextChatService.OnIncomingMessage` por jogo. Se outro script
> já usa (ex.: tags de VIP), as tags do chat de um dos dois vão parar de aparecer.

---

## Dinheiro

Os sistemas novos pagam no `leaderstats > Dinheiro` que o jogo já tem (quem salva é o sistema
antigo). Nome do valor e formatação (`R$ 15.000`) em
[`src/shared/Economy/Config.luau`](src/shared/Economy/Config.luau).

## Eventos de servidor

A cada 10–15 minutos (com 2+ jogadores) começa um evento de 5 minutos: **XP em dobro**,
**dinheiro em dobro**, **operação policial** (PMERJ/BOPE ganham o dobro), **guerra de facções**
(VERMELHO/AMARELO ganham o dobro) ou **caçada** (recompensas por cabeça valem o triplo).
Aparece um aviso e um contador no topo da tela.

Configuração em [`src/shared/GameEvents/Config.luau`](src/shared/GameEvents/Config.luau).
Para começar um evento por script (ex.: comando de admin):

```lua
local Events = require(game.ServerScriptService.Gameplay.Events)
Events.StartEvent("DoubleXP")
```

## Recompensa por cabeça

Com **5 abates seguidos** sem morrer, a cabeça do jogador fica a prêmio (R$ 1.000, +R$ 500 por
abate, até R$ 20.000). Todo mundo é avisado e vê um marcador **💀 R$ X** em cima dele.
Quem matar leva o dinheiro e XP extra.

Configuração em [`src/shared/Bounty/Config.luau`](src/shared/Bounty/Config.luau).

## Missões diárias

Cada jogador recebe **3 missões por dia** (renovam à meia-noite de Brasília), sorteadas da lista
no Config: abates, assistências, sequência, tempo de jogo, recompensas e abates com tipos de arma.
Botão **MISSÕES** abre o painel com o progresso. Completou, recebe na hora.

Configuração em [`src/shared/Missions/Config.luau`](src/shared/Missions/Config.luau).
Nas missões de arma, os nomes em `Weapons` precisam ser iguais aos nomes das Tools.

## Recompensa de login diário

Uma janela com 7 dias de prêmios que vão aumentando (R$ 500 no dia 1 até R$ 10.000 no dia 7).
Abre sozinha quando tem recompensa para pegar; botão **DIÁRIO** abre de novo. Se pular um dia,
volta pro dia 1. Prêmios em [`src/shared/DailyRewards/Config.luau`](src/shared/DailyRewards/Config.luau).

## Conquistas

Medalhas permanentes (abates, sequências, nível, recompensas, missões, dias seguidos, tempo de
jogo), cada uma com dinheiro e XP. Botão **CONQUISTAS** mostra o progresso. Lista em
[`src/shared/Achievements/Config.luau`](src/shared/Achievements/Config.luau).

## Câmera de morte

Quando você morre, a câmera segue quem te matou até você renascer, com um painel mostrando
o nome dele, a arma e quanta vida ele tinha.

## Proteção do ACS (ACSGuard)

O ACS 2.0.1 confia no que o cliente manda na hora do dano, o que permite **kill all** e dano
infinito. O `ACSGuard` (`ServerScriptService > Security > ACSGuard`) confere cada tiro no
servidor: arma na mão do atirador, status lidos do servidor, distância real, limite de
multiplicador, limite de tiros por segundo e de alvos diferentes por segundo. Quem passa dos
limites tem o tiro ignorado e, depois de 5 advertências, é kickado.

Precisa trocar a função `Damage` no script do servidor do ACS: passo a passo em
[`docs/ACS_PATCH.md`](docs/ACS_PATCH.md).
