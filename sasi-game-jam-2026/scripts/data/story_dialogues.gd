extends RefCounted
## Para editar a história, encontre abaixo a cena que deseja mudar.
## Edite o texto entre aspas em "speaker" (nome) e "text" (fala).
## Em "portrait", use "student" para o Estudante ou "classmate" para o Colega.
## Para adicionar falas, copie uma linha inteira, incluindo a vírgula.
## Mantenha as chaves das cenas e prefira falas curtas para caber na caixa.

const SEQUENCES: Dictionary = {
	"room_1_morning": [
		{"speaker": "Estudante", "portrait": "student", "text": "Espere... eu entrei mesmo no jogo? Até minha mochila virou armadura."},
		{"speaker": "Estudante", "portrait": "student", "text": "Mas o cansaço veio comigo: mal comecei e o corpo já pesa demais."},
		{"speaker": "Estudante", "portrait": "student", "text": "Antes de encarar a sala, preciso beber água. A garrafa está ali. [E]"},
	],
	"room_2_afternoon": [
		{"speaker": "Estudante", "portrait": "student", "text": "Esse lugar parece o laboratório... prazos e cobranças por todo lado."},
		{"speaker": "Estudante", "portrait": "student", "text": "Um colega está perto da bancada. Posso pedir apoio. [E]"},
	],
	"classmate_help": [
		{"speaker": "Colega", "portrait": "classmate", "text": "Respira um pouco. Você não precisa carregar tudo sozinho."},
		{"speaker": "Colega", "portrait": "classmate", "text": "Vamos por partes. Eu fico com você enquanto a gente abre caminho."},
	],
	"room_3_night": [
		{"speaker": "Estudante", "portrait": "student", "text": "Madrugada... a Sombra do Burnout quer apagar os meus três pilares."},
		{"speaker": "Estudante", "portrait": "student", "text": "Corpo, Mente e Descanso. Se um cair, eu reacendo e respiro [R]."},
	],
	"victory": [
		{"speaker": "Estudante", "portrait": "student", "text": "O controle ainda está na minha mão... eu estava alucinando de tanto cansaço."},
		{"speaker": "Estudante", "portrait": "student", "text": "Os monstros não eram reais, mas os sinais do meu corpo eram verdadeiros."},
		{"speaker": "Estudante", "portrait": "student", "text": "Para viver, preciso fazer aqui fora: comer, beber água, descansar e dormir."},
	],
}
