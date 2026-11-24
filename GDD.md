# GDD Completo — Três Turnos *(Manhã, Tarde e Noite)*

> **Evento:** SASI: Game Jam 2026 (UFAC) — Tema Oficial: **SAÚDE EM JOGO** (*Sinais*, *Equilíbrio* e *Conexões*)

---

## 1. Visão Geral
- **Título:** *Três Turnos*
- **Gênero / Plataforma:** Ação & Aventura Top-Down 2D em 3 Salas estilo *Zelda: Link's Awakening* — Web HTML5 no **itch.io** (e Desktop fallback), Engine **Godot 4.7 (`GL Compatibility`)**.
- **Resolução e Nitidez:** Base **`640x360`** com janela **`1280x720`** usando `stretch/mode = "canvas_items"` + `snap_2d_transforms_to_pixel = true` + filtro de textura **`Nearest`** (sprites pixel art 32-bit crocantes e textos HD sem embaçamento).
- **Duração & Ritmo:** Jogo completo com progressão de 3 Salas interligadas por portas físicas, diálogos curtos adaptáveis, estações de cuidado interativas, Colega NPC aliado e Boss do Burnout em 2 fases (~4–6 minutos de jornada completa).
- **Pitch (1 frase):** Controle um estudante universitário que enxerga os desafios acadêmicos como monstros de RPG ao longo de 3 salas (*Manhã, Tarde e Noite*), precisando ler os sinais reais de **Corpo**, **Mente** e **Descanso**, equilibrar seus hábitos e contar com um colega antes de sucumbir ao Boss do Burnout.

---

## 2. Protagonista, História & Direção Audiovisual
- **Protagonista — Estudante Universitário (inspirado no Stark de *Frieren*):**
  - Jovem universitário de cabelo ruivo com raízes pretas bem marcadas, casaco/moletom preto, mochila nas costas e **espada de RPG** na imaginação acadêmica.
- **Direção Visual 32-bit:**
  - Cenários top-down 2.5D em tons **médios-escuros confortáveis** (nunca claros/chapados), ricos em textura (madeira, ladrilhos sombreados, estantes, lâmpadas, tapetes, portas RPG), com iluminação aditiva e partículas ambientais.
  - Interface em estilo **Janelas Retrô 8-bit/32-bit** (`retro_window.gd`).
- **Direção Sonora 8-bit Clássica:**
  - **Sala 1 (Manhã):** **Bach** 8-bit (ritmo matinal vivo).
  - **Sala 2 (Tarde):** **Chopin** 8-bit (pressão e melancolia crescente).
  - **Sala 3 (Noite):** **Tchaikovsky** 8-bit (clímax dramático contra o Burnout).
  - A música reage em tempo real ao pilar da **Mente** (acelera + vibrato quando ansioso/sobrecarregado e toca batimento cardíaco).
- **História Adaptável (`scripts/data/story_dialogues.gd`):**
  - Todos os diálogos ficam centralizados em um único arquivo GDScript editável e comentado em português, com caixa de diálogo retrô, retrato pixel art animado e efeito *typewriter* pulável (`ESC`).

---

## 3. Os 3 Pilares de Equilíbrio & Seus Sinais (Mecânica Central)

Cada sala gira em torno dos **3 Pilares (`0.0 – 100.0`)** + **Vida do Estudante (`100 HP`)**:

| Pilar | O que representa | Como cai | **Sinal no Controle (O Jurado SENTE)** | Como Equilibrar |
| :--- | :--- | :--- | :--- | :--- |
| **CORPO** | Alimentação e hidratação | Inicia baixo na Manhã (`35%`), desgaste gradual/golpes de *Procrastinação* | **Abaixo de `40%`:** alcance da espada cai de **`40 px` para `24 px`**, dano cai (`24 → 14`) e velocidade cai **`-25%`**. | Apertar **`E`** na **Estação de Água/Lanche** (`+45`) ou pegar **Gotas d'Água** dropadas. |
| **MENTE** | Foco e calma emocional | Drenado por *Autocobrança*, *Prazo* e ataques do *Burnout* | **`25%–49%` (`ANXIOUS`):** vinheta `25%`, música `1.06x` + heartbeat.<br>**`< 25%` (`OVERLOAD`):** vinheta `55%`, música `1.12x` + desafinação, tremor na tela/sprite. | Segurar **`R` (Respirar por `1.5s`)** (`+35 Mente` + carrega **Golpe de Foco**) ou apoio do **Colega NPC (`E`)**. |
| **DESCANSO** | Energia e fôlego | Cada golpe de espada (**`-10`**) e dash (**`-16`**) consome energia | **Zerar (`0%`):** estudante entra em **Exaustão Ofegante por `2.0s`** (não ataca nem dá dash, velocidade `55%`, gotas de suor e tremor). | Pausar ataques (`+22/s` após `0.45s` sem atacar/dash), usar **Canto de Pausa (`E`)** ou respirar **`R`**. |

### Controles Completos
- `WASD` / Setas: Mover (`122 px/s` base)
- `Espaço` / `Clique Esq.`: Golpe de Espada (`24` dano, `40 px`, custo `-10` Descanso) ou **Golpe de Foco/Clareza** (`65` dano / `120` no Boss, `60 px`, custo `0`, ativa após completar `R`)
- `Shift`: Dash (`245 px/s` por `0.18s`, custo `-16` Descanso, invulnerabilidade breve)
- Segurar `R`: Respirar fundo (`1.5s`, recupera Mente + Descanso e carrega **Golpe de Foco**)
- `E`: Interagir com **Estações de Cuidado**, **Colega NPC** ou **Pilares** da Sala 3
- `Esc` / `P`: Pausar (ou pular diálogo com `Esc`)

---

## 4. Estrutura das 3 Salas (Manhã → Tarde → Noite)

### Sala 1 — MANHÃ (*O Despertar & A Correria*) — Trilha: **Bach 8-bit**
- **Cenário:** Quarto e corredor universitário ao amanhecer (`room_morning.png`).
- **Foco Pedagógico & Gameplay:** O estudante acorda com **Corpo = `35%`** (espada curta e passo lento logo no início para o jurado sentir na prática o **Sinal do Corpo**).
- **Desafios:** *Procrastinação* (slime preguiçoso que salta e cria poça de lentidão) e *Prazo* (diabrete rápido).
- **Condição para abrir a Porta Norte:** Derrotar os inimigos da sala **E** equilibrar o **Corpo (`>= 50%`)** na Estação de Água/Lanche (`[E]`).

### Sala 2 — TARDE (*O Laboratório & A Pressão*) — Trilha: **Chopin 8-bit**
- **Cenário:** Laboratório de informática / biblioteca com bancadas táticas que criam cobertura (`room_afternoon.png`).
- **Foco:** Entra a **Autocobrança** (espectro que drena a Mente à distância, fechando a visão e acelerando a música).
- **Conexões (Mundo 3):** O jogador encontra o **Colega Universitário NPC** na sala; ao apertar **`E`**, o Colega se junta à luta lançando pulsos calmantes (`18` dano + lentidão nos inimigos + regenera `+3.5 Mente/s` quando o estudante está por perto).
- **Condição para abrir a Porta Norte:** Derrotar os inimigos da sala **E** manter **Corpo e Mente `>= 45%`**.

### Sala 3 — NOITE (*Madrugada vs. A Sombra do Burnout*) — Trilha: **Tchaikovsky 8-bit**
- **Cenário:** Quarto/mente na madrugada (`room_night.png`) com **3 Pilares físicos** posicionados no salão (**CORPO**, **MENTE** e **DESCANSO**).
- **Boss — A Sombra do Burnout (`380 HP`, 2 Fases):**
  - Alterna entre **disparos telegrafados de estresse** (que o jogador esquiva com Dash ou corta com o **Golpe de Foco**) e **dreno direto de um dos 3 Pilares** a cada `7s` (`5.5s` na Fase 2 abaixo de 50% HP) com aviso visual na tela!
  - Se um Pilar físico cair abaixo de `40%`, o sinal dele pesa no jogador; correr até o Pilar piscando e apertar **`E`** reacende-o imediatamente (`+40`), enquanto segurar **`R`** prepara o **Golpe de Foco (`120` de dano no Boss!)**.
- **Vitória:** Derrotar a Sombra do Burnout com os pilares de pé abre o Amanhecer + diálogo final + tela de Vitória!

---

## 5. Alinhamento com os 4 Critérios do Edital (100 pts) & Apresentação (27/11 às 11h)
- *Problema de saúde:* Esgotamento acadêmico (*burnout*), negligência alimentar/hídrica, ansiedade e exaustão física em estudantes universitários.
- *Público-alvo:* Estudantes universitários e jovens adultos.
- *Contribuição:* Faz o jogador sentir no próprio controle o impacto da má alimentação (alcance/força), ansiedade (visão/música) e falta de pausas (exaustão ofegante), provando que autocuidado e pedir apoio a colegas são parte da vitória.
