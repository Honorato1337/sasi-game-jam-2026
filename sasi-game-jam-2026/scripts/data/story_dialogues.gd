extends RefCounted
## Para editar a história, encontre abaixo a cena que deseja mudar.
## Edite o texto entre aspas em "speaker" (nome) e "text" (fala).
## Em "portrait", use "student" para o Estudante ou "classmate" para o Colega.
## Para adicionar falas, copie uma linha inteira, incluindo a vírgula.
## Mantenha as chaves das cenas e prefira falas curtas para caber na caixa.

const SEQUENCES: Dictionary = {
	"room_1_morning": [
		{"speaker": "Estudante", "portrait": "student", "text": "Espere... eu entrei mesmo no jogo? Até minha mochila virou armadura."},
		{"speaker": "Estudante", "portrait": "student", "text": "Esses vultos são completamente pretos... só o peso escuro da manhã."},
		{"speaker": "Estudante", "portrait": "student", "text": "Antes de enfrentar tudo, preciso beber água. A garrafa está brilhando ali. [E]"},
	],
	"room_2_afternoon": [
		{"speaker": "Estudante", "portrait": "student", "text": "O laboratório de tarde... ainda mais vultos negros espalhados entre os prazos."},
		{"speaker": "Estudante", "portrait": "student", "text": "Um colega está perto da bancada. Posso pedir apoio antes que aperte. [E]"},
	],
	"classmate_help": [
		{"speaker": "Colega", "portrait": "classmate", "text": "Respira fundo comigo. Você não precisa carregar tudo sozinho."},
		{"speaker": "Colega", "portrait": "classmate", "text": "Eu fico por perto enquanto você recupera o fôlego."},
	],
	"room_3_night": [
		{"speaker": "Estudante", "portrait": "student", "text": "Caiu a noite... e mais sombras cercam o apartamento. O dia não acaba."},
		{"speaker": "Estudante", "portrait": "student", "text": "Se eu equilibrar Corpo, Mente e Descanso, a porta lá em cima se abre."},
	],
	"room_4_c2_morning": [
		{"speaker": "Estudante", "portrait": "student", "text": "De novo de manhã?! A neblina começou a ceder em volta das sombras..."},
		{"speaker": "Estudante", "portrait": "student", "text": "Espere... não são monstros. Esse cabelo ruivo e essa mochila..."},
	],
	"room_5_c2_afternoon": [
		{"speaker": "Estudante", "portrait": "student", "text": "Outro turno no laboratório. Estou preso nesse ciclo de três tempos."},
		{"speaker": "Estudante", "portrait": "student", "text": "Os vultos estão menos foscos agora. Eles carregam a minha própria exaustão."},
	],
	"room_6_c2_night": [
		{"speaker": "Estudante", "portrait": "student", "text": "Outra madrugada sem descanso. Cada descuido meu se multiplica na sala."},
		{"speaker": "Estudante", "portrait": "student", "text": "Água, pausa, respiração [R]... ainda dá tempo de quebrar esse ciclo."},
	],
	"room_7_c3_morning": [
		{"speaker": "Estudante", "portrait": "student", "text": "Terceira volta... a escuridão sumiu. Todas as sombras têm o meu rosto."},
		{"speaker": "Estudante", "portrait": "student", "text": "A negligência multiplicou a minha própria cobrança por todo o quarto."},
	],
	"room_8_c3_afternoon": [
		{"speaker": "Estudante", "portrait": "student", "text": "Última tarde desse ciclo. Não quero continuar fugindo de mim mesmo."},
		{"speaker": "Estudante", "portrait": "student", "text": "Cuidar do corpo e da mente não é perder tempo — é continuar vivo."},
	],
	"room_9_c3_night": [
		{"speaker": "Estudante", "portrait": "student", "text": "Essa silhueta gigante sou eu... destruído por cada dia sem cuidado."},
		{"speaker": "Estudante", "portrait": "student", "text": "Corpo, Mente e Descanso. Se eu me equilibrar e respirar [R], encerro isso."},
	],
	"victory": [
		{"speaker": "Estudante", "portrait": "student", "text": "O gigante se desfaz em luz... esse tempo todo eu estava lutando contra mim mesmo."},
		{"speaker": "Estudante", "portrait": "student", "text": "A tela da TV começa a me puxar de volta para o meu quarto..."},
	],
}
