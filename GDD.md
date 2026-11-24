# GDD Completo — O Que Mantém de Pé *(Entre Fôlego e Rotina)*

> **Evento:** SASI: Game Jam 2026 (UFAC) — Tema Oficial: **SAÚDE EM JOGO** (*Sinais*, *Equilíbrio* e *Conexões*)

---

## 1. Ficha Técnica & Visão Geral
- **Título provisório:** *O Que Mantém de Pé* *(subtítulo: Entre Fôlego e Rotina)*
- **Gênero / Plataforma:** Ação Top-Down 2D em Arena Única + Gestão de Equilíbrio entre Ondas — Web HTML5 no **itch.io** (e Desktop fallback), Engine **Godot 4.7 (`GL Compatibility`)**.
- **Resolução e Renderização:** Base pixel-perfect **`640x360`** com janela **`1280x720`** (`stretch/mode = "viewport"`, `stretch/aspect = "keep"`, filtro de textura **`Nearest`**).
- **Duração da Demo:** ~3m30s a 4m00s (4 ondas curtas de 45s + telas rápidas do Caderno Retrô entre turnos).
- **Pitch (1 frase):** Controle Seu Antônio, um avô/cuidador tentando manter de pé o Núcleo do Lar e o cuidado com a neta ao longo de 4 turnos intensos, aprendendo a ler os sinais físicos e mentais do próprio corpo (BPM, visão e música), respirar no momento certo e contar com uma rede de apoio antes de entrar em exaustão.

---

## 2. Narrativa, Personagens e Simbolismo de Saúde
- **Protagonista — Seu Antônio (Avô / Cuidador):** Um senhor determinado tentando dar conta da rotina da casa, da própria saúde e do cuidado com a neta Clara após o luto familiar. Visual pixel art 8-bit *chibi* com contornos escuros definidos.
- **O Núcleo do Cuidado e da Estabilidade (`100 HP`):** O cristal/lar no centro da arena que representa tudo o que o avô tenta sustentar de pé (rotina, lar, estabilidade emocional e cuidado). Se o Núcleo chegar a `0 HP`, a sobrecarga vence (*Game Over*).
- **Rede de Apoio (Aliados de Conexão):** Vizinhos, amigos idosos e colegas/estudantes que, quando chamados entre os turnos, posicionam-se ao redor do Núcleo ajudando a repelir pressões e criando uma aura calma que alivia o BPM do protagonista.

### Alinhamento com os Critérios do Edital (100 pts) e Apresentação (27/11 às 11h)
1. **Criatividade e Conceito (25 pts):** Transforma sobrecarga física e emocional em feedback sensorial jogável — o jogador não lê "você está cansado"; ele sente o batimento acelerar, a visão fechar e a música desafinar se ignorar os limites do corpo.
2. **Aderência aos 3 Mundos do Tema (25 pts):**
   - **Mundo 1 — SINAIS:** Monitor de BPM, batimento audível, visão em túnel progressiva, tremor no sprite e desafinação/aceleração da trilha 8-bit.
   - **Mundo 2 — EQUILÍBRIO:** Respiração ativa em tempo real (`R`), Golpe de Clareza e escolhas de autocuidado (*Descansar/Dormir*, *Alimentar & Hidratar*) no Caderno Retrô entre ondas.
   - **Mundo 3 — CONEXÕES:** Opção *Rede de Apoio* que coloca aliados na arena ao lado do Núcleo, demonstrando na mecânica que ninguém precisa sustentar tudo sozinho.
3. **Jogabilidade e UX (25 pts — 1º critério de desempate):** Controles simples e imediatos (`WASD`/Setas + `Espaço`/Clique + `Shift` + `R`), legíveis nos primeiros 10 segundos.
4. **Roteiro da Apresentação Presencial (5º Card):**
   - *Problema de saúde:* Sobrecarga física e emocional de cuidadores e idosos (estresse cardiovascular, fadiga crônica, luto e isolamento).
   - *Público-alvo:* Jovens, adultos e familiares/cuidadores (sensibilização intergeracional sobre autocuidado e rede de apoio).
   - *Contribuição:* Faz o jogador experimentar na prática do controle a diferença entre forçar o corpo até a exaustão versus reconhecer sinais precoces, pausar para respirar e pedir ajuda.

---

## 3. Matemática e Regras Exatas das Mecânicas

### 3.1 Controles e Ações do Protagonista
| Ação | Teclas (`InputMap`) | Parâmetros Exatos | Custo em BPM |
| :--- | :--- | :--- | :--- |
| **Mover (8 direções)** | `WASD` / Setas (`move_*`) | Velocidade base: **`115 px/s`** | `0` (queda passiva **`-6.0 BPM/s`** se sem atacar/dash) |
| **Ataque Base** | `Espaço` / `Clique Esq.` (`attack`) | Dano: **`20`**, Alcance: **`36 px`** (arco frontal), Cooldown: **`0.32s`** | **`+4.5 BPM`** por golpe |
| **Dash** | `Shift` (`dash`) | Velocidade: **`240 px/s`** por **`0.18s`**, Cooldown: **`0.75s`** | **`+9.0 BPM`** por dash |
| **Contato / Golpe Sofrido** | Colisão com inimigo/pulso | Knockback leve no personagem + invulnerabilidade breve (`0.4s`) | **`+14.0 BPM`** *(ou valor do inimigo)* |
| **Respirar (`Equilíbrio`)** | Segurar `R` (`breathe`) | Canalização: **`1.5s`**, caminha a **`40%`** da velocidade (`46 px/s`), fecha o Anel de Fôlego | **`-28.0 BPM/s`** durante a canalização + **`-15.0 BPM`** extras ao completar |
| **Golpe de Clareza** | `Espaço` / `Clique Esq.` (após completar `R`) | Dano: **`55`** (**`110`** contra o Boss), Alcance: **`54 px`**, empurrão em arco amplo | **`0 BPM`** |

### 3.2 Estados de Sinal de BPM (`70.0` a `180.0 BPM`)
| Estado (`SignalLevel`) | Faixa de BPM | Efeitos Visuais, Sonoros e no Controle (*Sinais*) |
| :--- | :--- | :--- |
| **`CALM`** | `70.0 – 119.9` | Visão limpa (`0%` vinheta), música `1.0x` afinada, velocidade `100%`, coração verde/normal. |
| **`WARNING`** | `120.0 – 149.9` | Coração amarelo/laranja pulsando no HUD, vinheta **`25%`**, música **`1.06x`**, batimento cardíaco audível. |
| **`OVERLOAD`** | `150.0 – 179.9` | Coração vermelho rápido, vinheta **`55%`** (visão em túnel), música **`1.12x`** com leve desafinação, tremor no sprite, velocidade **`-15%`**. |
| **`EXHAUSTED`** | `180.0` (teto) | Colapso de **`2.5s`**: velocidade **`45%`**, **sem dash**, ataque lento (`0.65s`), tremor intenso até o BPM recuar para **`135.0 BPM`** *(ou até completar uma Respiração `R`, que limpa a exaustão na hora)*. |

---

## 4. Caderno / Terminal Retrô entre Ondas (3 Escolhas)
Ao final das **Ondas 1, 2 e 3**, abre-se uma janela pixelada retrô 8-bit onde o jogador escolhe **1 cuidado** para o próximo turno:

1. **Descansar / Dormir *(e Remédio em Dia)*:**
   - Reduz em **`-20%`** todo ganho futuro de BPM (acumulável), aumenta recuperação passiva em **`+2.5 BPM/s`** e reseta o BPM atual para **`70.0`**.
2. **Alimentar & Hidratar:**
   - Aumenta velocidade base em **`+15%`**, reduz tempo necessário de respiração (`R`) em **`-0.2s`** *(mínimo `0.9s`)* e restaura **`+25 HP`** do Núcleo.
3. **Conexão / Rede de Apoio:**
   - Adiciona **`+1 Aliado`** ao redor do Núcleo *(máximo 3 aliados)*. Cada aliado emite um pulso de **`15` de dano** + lentidão em área a cada **`1.8s`** e cria uma aura calma de **`-4.0 BPM/s`** quando Seu Antônio está perto do centro.

---

## 5. Bestiário & As 4 Ondas (45s cada)

### 5.1 Inimigos
| Inimigo | HP | Velocidade | Alvo e Comportamento | Observação Tática |
| :--- | :--- | :--- | :--- | :--- |
| **Pressão da Rotina** | `30` | `55 px/s` | Avança direto no Núcleo (`-8 HP` por impacto) | Cai rápido, mas vem em grupo. |
| **Fadiga** | `60` | `35 px/s` | Lenta e pesada; foca no Núcleo (`-14 HP` por impacto) | Cai com **1 único Golpe de Clareza**. |
| **Luto / Culpa** | `25` | `72 px/s` | Persegue o **Avô**, causando **`+16 BPM`** no contato | Pressiona o jogador a se mover ou usar `R` no momento seguro. |
| **Boss da Exaustão / Sobrecarga** | `320` | `24 px/s` | Avança na Onda 4; emite pulso de pressão a cada **`6.0s`** (`+10 BPM` na arena) e ataca o Núcleo | Vulnerável ao **Golpe de Clareza (`110` de dano)**; incentiva respirar e usar Aliados. |

### 5.2 Cronograma das 4 Ondas
| Onda | Turno & Atmosfera | Paleta da Arena | Trilha 8-bit | Composição dos Inimigos |
| :--- | :--- | :--- | :--- | :--- |
| **Onda 1 (45s)** | **Manhã** — *O Despertar da Rotina* | Azul claro / creme alvorada | **Bach** (ritmo estável) | *Pressão da Rotina* (tutorial natural de ataque e respiração). |
| **Onda 2 (45s)** | **Tarde** — *O Peso Acumulado* | Âmbar / laranja quente | **Chopin** (fluida) | *Pressão da Rotina* + *Fadiga*. |
| **Onda 3 (45s)** | **Noite** — *Saudade & Culpa* | Azul-marinho / roxo noturno | **Chopin Noturno** (tensa) | *Pressão da Rotina* + *Fadiga* + *Luto/Culpa*. |
| **Onda 4 (45s+)** | **Madrugada** — *Boss da Exaustão* | Índigo escuro / carmesim | **Tchaikovsky** (dramática) | **Boss da Exaustão** + reforços leves até derrotar o Boss ou zerar o tempo final com o Núcleo de pé. |

---

## 6. Arquitetura de Cenas, Nós e Sinais no Godot 4 (`sasi-game-jam-2026/`)

```text
sasi-game-jam-2026/
├── project.godot                     # 640x360 -> 1280x720, Nearest, Autoloads, InputMap
├── scripts/autoload/
│   ├── game_manager.gd               # Estado global, BPM, SignalLevel, core_hp, wave, hábitos
│   └── audio_manager.gd              # Sintetizador 8-bit (Bach/Chopin/Tchaikovsky) + SFX + reação ao BPM
├── scenes/player/
│   ├── player.tscn                   # CharacterBody2D + Sprite2D + Hitbox + BreathRing
│   └── player.gd                     # Movimento, ataque, dash, respiração (R), Golpe de Clareza
├── scenes/levels/
│   ├── arena.tscn                    # Arena 640x360, Núcleo Central, spawner, marcadores de aliados
│   └── arena.gd                      # Troca de paleta, timer de 45s das 4 ondas, vitória/derrota
├── scenes/enemies/
│   ├── enemy_base.tscn / .gd         # Base reutilizável configurada por tipo (Rotina/Fadiga/Luto/Boss)
│   └── ally_support.tscn / .gd       # Aliado de Conexão ao redor do Núcleo
└── scenes/ui/
    ├── hud.tscn / .gd                # Coração BPM, barra do Núcleo, vinheta de túnel, badge Clareza, timer/onda
    ├── habit_terminal.tscn / .gd     # Caderno/Terminal Retrô entre ondas (3 escolhas de cuidado)
    └── title_end_screens.tscn / .gd  # Tela Inicial (Play + Controles), Vitória e Game Over
```

**Fluxo de Sinais Principais (`GameManager`):**
- `state_changed(new_state)`
- `bpm_changed(new_bpm, signal_level)`
- `core_hp_changed(new_hp, max_hp)`
- `wave_changed(new_wave)`
- `habits_updated(sleep_rank, nutrition_rank, ally_count)`
- `clarity_ready_changed(is_ready)`

---

## 7. Plano de Produção em 6 Etapas

1. **Etapa 1 — Fundação do Projeto (`T-005` + `T-006`):** Configurar `project.godot` (`640x360`, `Nearest`, Autoloads e `InputMap`) e expandir `GameManager` com toda a matemática de BPM, `SignalLevel`, Núcleo e hábitos. *Teste no Godot: projeto abre sem erros no tamanho certo e sinais respondem.*
2. **Etapa 2 — Protagonista & Sensação de Controle (`T-007`):** Implementar `player.tscn/.gd` com movimento, ataque, dash, respiração (`R` por `1.5s`), Golpe de Clareza e estado `EXHAUSTED`. *Teste no Godot: andar, atacar, dar dash e sentir o BPM subir e baixar ao segurar `R`.*
3. **Etapa 3 — Arena, Núcleo, Ondas & Inimigos (`T-008`):** Criar arena 8-bit, Núcleo no centro, paleta por turno, os 4 tipos de inimigos (incluindo Boss) e Aliados de Conexão. *Teste no Godot: jogar as 4 ondas completas com spawn e dano no Núcleo.*
4. **Etapa 4 — HUD de Sinais, Caderno Retrô & Telas (`T-009`):** Criar HUD (coração/BPM, visão em túnel, barra do Núcleo, indicador Golpe de Clareza), janela retrô entre ondas e telas de Início/Vitória/Game Over. *Teste no Godot: loop completo jogável do botão Play até o fim.*
5. **Etapa 5 — Trilha Clássica 8-bit & SFX Reativos (`T-010`):** Implementar gerador chiptune em `AudioManager` com temas de Bach, Chopin e Tchaikovsky reagindo ao BPM + SFX 8-bit de ataque, respiração, acerto e alerta. *Teste no Godot: ouvir a música acelerar/desafinar em sobrecarga e voltar ao normal ao respirar.*
6. **Etapa 6 — Sprites Finais, Juice & Export Web (`T-011`):** Integrar sprites pixel art dedicados (Seu Antônio, Núcleo, inimigos, aliados), *hitstop* / *screen shake* / partículas, atualizar `CREDITS_AND_AI.md` e validar exportação HTML5 no itch.io.
