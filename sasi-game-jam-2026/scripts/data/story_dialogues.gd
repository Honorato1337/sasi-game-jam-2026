extends RefCounted
## Para editar a história, encontre abaixo a cena que deseja mudar.
## Edite o texto entre aspas em "speaker" (nome) e "text" (fala).
## Em "portrait", use "student" para o Estudante ou "classmate" para o Colega.
## Para adicionar falas, copie uma linha inteira, incluindo a vírgula.
## Mantenha as chaves das cenas e prefira falas curtas para caber na caixa.

const SEQUENCES: Dictionary = {
	"room_1_morning": [
		{"speaker": "Estudante", "portrait": "student", "text": "Espere... eu entrei mesmo no jogo? Até minha mochila virou armadura."},
		{"speaker": "Estudante", "portrait": "student", "text": "Essas sombras lá na frente mal têm forma... parecem o peso da manhã."},
		{"speaker": "Estudante", "portrait": "student", "text": "Antes de avançar, preciso beber água. A garrafa está brilhando ali. [E]"},
	],
	"room_2_afternoon": [
		{"speaker": "Estudante", "portrait": "student", "text": "O laboratório... mais vultos escuros espalhados entre os prazos."},
		{"speaker": "Estudante", "portrait": "student", "text": "Um colega está perto da bancada. Posso pedir apoio. [E]"},
	],
	"classmate_help": [
		{"speaker": "Colega", "portrait": "classmate", "text": "Respira fundo comigo. Você não precisa carregar tudo sozinho."},
		{"speaker": "Colega", "portrait": "classmate", "text": "Eu fico por perto enquanto você recupera o fôlego."},
	],
	"room_3_night": [
		{"speaker": "Estudante", "portrait": "student", "text": "Caiu a noite... mas o dia parece não ter acabado de verdade."},
		{"speaker": "Estudante", "portrait": "student", "text": "Se eu equilibrar Corpo, Mente e Descanso, a porta lá em cima se abre."},
	],
	"room_4_c2_morning": [
		{"speaker": "Estudante", "portrait": "student", "text": "De novo de manhã?! O quarto está igual... só que mais carregado."},
		{"speaker": "Estudante", "portrait": "student", "text": "Espere... essas figuras não são monstros. Esse cabelo ruivo e moletom..."},
	],
	"room_5_c2_afternoon": [
		{"speaker": "Estudante", "portrait": "student", "text": "Outro turno no laboratório. Estou preso nesse ciclo de três tempos."},
		{"speaker": "Estudante", "portrait": "student", "text": "Os vultos estão menos foscos agora. Eles carregam a minha própria mochila."},
	],
	"room_6_c2_night": [
		{"speaker": "Estudante", "portrait": "student", "text": "Outra madrugada sem descanso. Cada falha minha volta para me cobrar."},
		{"speaker": "Estudante", "portrait": "student", "text": "Água, pausa, respiração [R]... ainda dá tempo de quebrar o ciclo."},
	],
	"room_7_c3_morning": [
		{"speaker": "Estudante", "portrait": "student", "text": "Terceira volta... a névoa sumiu. Todas as sombras têm o meu rosto."},
		{"speaker": "Estudante", "portrait": "student", "text": "A exaustão multiplicou a minha própria cobrança por toda parte."},
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
		{"speaker": "Estudante", "portrait": "student", "text": "O controle ainda está nas minhas mãos... tudo isso foi uma alucinação."},
		{"speaker": "Estudante", "portrait": "student", "text": "A falta de cuidado comigo mesmo distorceu meus dias nesses vultos."},
		{"speaker": "Estudante", "portrait": "student", "text": "A culpa por ignorar os sinais era minha — ninguém muda isso por mim."},
		{"speaker": "Estudante", "portrait": "student", "text": "Mas eu entendi a tempo. Agora eu levanto, cuido de mim e mudo a minha rotina."},
	],
}
