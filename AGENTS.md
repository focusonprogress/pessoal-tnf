# AGENTS.md

Instruções para assistentes de IA (Claude, Copilot, Codex...) que trabalham neste repositório.
Tudo que está aqui é lido automaticamente antes de mexerem no código.

## Projeto

Sistemas para um jogo de tiro no Roblox. O jogo usa o **ACS** (Advanced Combat System)
para armas e dano. O ACS **não** fica neste repositório: ele está só no jogo, no Studio.

## Tecnologia

- Linguagem: **Luau** (arquivos `.luau`)
- Sincronização com o Studio: **Rojo** (`default.project.json` define onde cada pasta vai)
- Sufixos dos arquivos: `.server.luau` = Script, `.client.luau` = LocalScript, sem sufixo = ModuleScript

## Estrutura

- `src/shared/` → ReplicatedStorage (servidor e cliente leem; nada secreto aqui)
- `src/server/` → ServerScriptService (só o servidor)
- `src/client/` → StarterPlayerScripts (só o cliente)
- Cada sistema tem um `Config.luau` com todos os números de balanceamento

## Regras

- Comentários e textos para o jogador em **português**
- **Nunca confie no cliente**: XP, níveis e desbloqueios são decididos só no servidor.
  RemoteEvents vão do servidor para o cliente só para mostrar coisas na tela
- Não editar scripts do ACS por aqui. Integrações com o ACS ficam documentadas no README
  (ex.: `KillTracker.Tag`)
- Chamadas de DataStore sempre com `pcall` e novas tentativas
- Ao criar um sistema novo: adicionar no `default.project.json`, na tabela de sistemas
  e na tabela de "copiar e colar" do README
