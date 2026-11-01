# Proteção do ACS 2.0.1 (ACSGuard)

O ACS 2.0.1 confia no que o cliente manda na hora do dano. Isso permite **kill all**
e dano infinito. O `ACSGuard` refaz as contas no servidor antes de aplicar o dano.

> Faça um **backup** do jogo antes (File → Save to File).

## Jeito mais fácil: trocar o script inteiro

O arquivo [`docs/ACS_Server_protegido.luau`](ACS_Server_protegido.luau) é o script do servidor
do ACS 2.0.1 **completo**, já com as mudanças dos passos 2 e 3 abaixo. Então:

1. Faça o **passo 1** (criar o `ACSGuard`)
2. Abra o script do servidor do ACS, apague tudo e cole o conteúdo de `ACS_Server_protegido.luau`
3. Pule para o **passo 4** (testar)

> Só serve se o seu script do servidor do ACS for igual ao original 2.0.1 deste jogo. Se você
> mexeu nele depois, prefira fazer os passos 2 e 3 manualmente.

## 1. Criar o ACSGuard

Em **ServerScriptService**, crie uma **Folder** chamada `Security` e, dentro dela, um
**ModuleScript** chamado `ACSGuard` com o código de
[`src/server/Security/ACSGuard.luau`](../src/server/Security/ACSGuard.luau).

## 2. Trocar a função `Damage` no script do servidor do ACS

No script do servidor do ACS, encontre o bloco que começa em:

```lua
local function Damage(SKP_0, SKP_1, SKP_2, SKP_3, SKP_4, SKP_5, SKP_6, SKP_7, SKP_8, SKP_9)
```

e termina em:

```lua
Evt.Damage.OnServerInvoke = Damage
```

Selecione **esse bloco inteiro** (incluindo as duas linhas acima) e substitua por:

```lua
--// ACSGuard: confere cada tiro no servidor (ver docs/ACS_PATCH.md no repositório)
local ACSGuardModule = game:GetService("ServerScriptService"):FindFirstChild("Security")
ACSGuardModule = ACSGuardModule and ACSGuardModule:FindFirstChild("ACSGuard")
local ACSGuard = ACSGuardModule and require(ACSGuardModule)
if not ACSGuard then
	warn("[ACSGuard] NÃO ENCONTRADO em ServerScriptService > Security > ACSGuard. As armas NÃO vão dar dano até isso ser corrigido!")
end

local function Damage(SKP_0, SKP_1, SKP_2, SKP_3, SKP_4, SKP_5, SKP_6, SKP_7, SKP_8, SKP_9)
	if not SKP_0 or not SKP_0.Character then return; end;
	if not SKP_0.Character:FindFirstChild("Humanoid") or SKP_0.Character.Humanoid.Health <= 0 then return; end;

	if SKP_9 ~= (ACS_0.."-"..SKP_0.UserId) then
		SKP_0:kick("Exploit Protocol")
		warn(SKP_0.Name.." - Potential Exploiter! Case 0-B: Wrong Permission Code")
		table.insert(_G.TempBannedPlayers, SKP_0)
		return;
	end

	-- Dano em si mesmo (queda, etc.): só pode tirar vida, nunca dar.
	if SKP_7 then
		SKP_0.Character.Humanoid:TakeDamage(math.max(tonumber(SKP_8) or 0, 0))
		return;
	end

	if not SKP_1 then
		SKP_0:kick("Exploit Protocol")
		warn(SKP_0.Name.." - Potential Exploiter! Case 1: Tried To Access Damage Event")
		table.insert(_G.TempBannedPlayers, SKP_0)
		return;
	end

	if not ACSGuard then return; end;

	-- Confere arma, alvo, distância, velocidade de tiro e quantidade de alvos.
	local Settings, Mods, Distance, HitType = ACSGuard.ValidateHit(SKP_0, SKP_1, SKP_2, SKP_4, SKP_6)
	if not Settings then return; end;

	-- Checagem original do ACS (status da arma alterados = kick).
	if type(SKP_5) == "table" then
		local ok, valid = pcall(secureSettings, SKP_0, SKP_1, SKP_5)
		if not ok or not valid then return; end;
	end

	-- Usa os status do SERVIDOR e a distância calculada pelo servidor.
	CalculateDMG(SKP_0, SKP_2, Distance, HitType, Settings, Mods)
end

Evt.Damage.OnServerInvoke = Damage
```

## 3. Consertar o ban temporário

Mais embaixo, dentro de `plr.PlayerAdded:Connect(function(player)`, troque:

```lua
		if v == player.Name then
```

por:

```lua
		if v == player.Name or (typeof(v) == "Instance" and v.UserId == player.UserId) then
```

(Antes o ban nunca funcionava: a lista guarda o jogador, mas comparava com o nome.)

## 4. Testar

1. **Commit** no script do ACS (se usar Team Create) e aperte **Play**
2. Atire em alguém (Test → Clients and Servers com 2 jogadores): o dano tem que funcionar normal
3. Teste **todas as armas**, principalmente escopetas, snipers e **granadas**
4. No Output, busque `ACSGuard`. Se aparecer advertência para jogador normal, me mande a
   mensagem: dá para ajustar os limites em `ACSGuard.Config`

## Limites (ajustáveis em `ACSGuard.Config`)

| Configuração | Padrão | O que faz |
|---|---|---|
| `MaxRange` | 3000 | Distância máxima de um tiro (studs) |
| `MaxDamageMod` | 1.5 | Maior multiplicador de dano aceito |
| `RateTolerance` | 1.5 | Aceita até 1.5x a cadência da arma |
| `MaxTargetsPerSecond` | 4 | Alvos diferentes por segundo (+ balas por tiro nas escopetas) |
| `StrikesToKick` | 5 | Advertências até o kick (somem depois de 30s) |
