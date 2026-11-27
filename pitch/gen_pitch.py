from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.dml.color import RGBColor
from pptx.enum.shapes import MSO_SHAPE
from pptx.enum.text import PP_ALIGN, MSO_ANCHOR
from PIL import Image
import os, hashlib
S = r"C:\Users\maria\Desktop\GAMEJAMSASI\sasi-game-jam-2026\assets\sprites"
VIDEO = r"C:\Users\maria\.gemini\antigravity\brain\eb5457d1-01b5-417c-9b6a-54daae48aa9f\.user_uploaded\media_1795657013052_d08deaf8.mp4"
POSTER = r"C:\Users\maria\Desktop\GAMEJAMSASI\pitch\poster.png"
INTRO_GIF = r"C:\Users\maria\Desktop\GAMEJAMSASI\pitch\intro_cutscene.gif"
FONT = "Pixelify Sans"
def C(h): return RGBColor.from_string(h.upper())
INK=C("181322"); CREAM=C("FAF0DD"); MUTED=C("C9C5DF"); FRAME=C("8F7AA6"); BL=C("D8BE92"); BD=C("4A3C5C")
TITLE=C("372C48"); BODY=C("241C31"); MINT=C("81E6C0"); GOLD=C("F4BA72")
CORPO=C("81E6C0"); MENTE=C("7FC8FF"); DESC=C("C9A0FF"); RED=C("FF7B7B")
prs=Presentation(); prs.slide_width=Inches(13.333); prs.slide_height=Inches(7.5)
blank=prs.slide_layouts[6]
TMP=os.environ["TEMP"]
def up(name, box=None, factor=1, dark=0, size=None):
    im=Image.open(os.path.join(S,name)).convert("RGBA")
    if box: im=im.crop(box)
    im=im.resize((im.width*factor, im.height*factor), Image.NEAREST)
    if dark:
        im=Image.alpha_composite(im, Image.new("RGBA", im.size, (14,10,24,int(255*dark))))
    key=hashlib.md5(repr((name,box,factor,dark)).encode()).hexdigest()
    out=os.path.join(TMP,f"p_{key}.png"); im.save(out); return out
def rect(s,x,y,w,h,fill=BODY,line=None,lw=0):
    r=s.shapes.add_shape(MSO_SHAPE.RECTANGLE,Inches(x),Inches(y),Inches(w),Inches(h))
    if fill is None: r.fill.background()
    else: r.fill.solid(); r.fill.fore_color.rgb=fill
    if line is None: r.line.fill.background()
    else: r.line.color.rgb=line; r.line.width=Pt(lw)
    r.shadow.inherit=False; return r
def text(s,x,y,w,h,t,size=22,color=CREAM,bold=False,align=PP_ALIGN.LEFT,anchor=MSO_ANCHOR.TOP,sp=6):
    tb=s.shapes.add_textbox(Inches(x),Inches(y),Inches(w),Inches(h)); tf=tb.text_frame; tf.word_wrap=True; tf.vertical_anchor=anchor
    tf.margin_left=tf.margin_right=Inches(0.05); tf.margin_top=tf.margin_bottom=Inches(0.02)
    for i,l in enumerate(t if isinstance(t,list) else [t]):
        p=tf.paragraphs[0] if i==0 else tf.add_paragraph(); p.alignment=align; p.space_after=Pt(sp)
        r=p.add_run(); r.text=l; r.font.size=Pt(size); r.font.color.rgb=color; r.font.bold=(bold and size>=24); r.font.name=FONT
    return tb
def pic(s,path,x,y,w=None,h=None):
    return s.shapes.add_picture(path,Inches(x),Inches(y),Inches(w) if w else None,Inches(h) if h else None)
def window(s,x,y,w,h,title,accent=GOLD,body=BODY,tbh=0.5):
    rect(s,x+0.1,y+0.1,w,h,fill=INK)                       # hard shadow
    rect(s,x,y,w,h,fill=INK)                                # outer ink
    rect(s,x+0.05,y+0.05,w-0.1,h-0.1,fill=FRAME)            # frame
    rect(s,x+0.1,y+0.1,w-0.2,h-0.2,fill=BL)                 # bevel light
    rect(s,x+0.14,y+0.14,w-0.24,h-0.24,fill=BD)             # bevel dark
    rect(s,x+0.14,y+0.14,w-0.28,h-0.28,fill=body)
    rect(s,x+0.14,y+0.14,w-0.28,tbh,fill=TITLE)
    rect(s,x+0.14,y+0.14+tbh-0.04,w-0.28,0.04,fill=BD)
    rect(s,x+0.3,y+0.14+tbh/2-0.07,0.14,0.14,fill=accent)
    text(s,x+0.55,y+0.14,w-1.6,tbh,title.upper(),16,CREAM,True,anchor=MSO_ANCHOR.MIDDLE)
    for i in range(3): rect(s,x+w-0.7+i*0.18,y+0.14+tbh/2-0.06,0.12,0.12,fill=[GOLD,MINT,RED][i])
    return (x+0.3,y+0.14+tbh+0.15,w-0.6,h-0.28-tbh-0.3)
def bar(s,x,y,w,label,pct,col):
    text(s,x,y-0.05,2.2,0.4,label,16,col,True)
    rect(s,x+2.1,y,w-2.1,0.32,fill=INK,line=FRAME,lw=2)
    n=10
    for i in range(n):
        if i<round(n*pct): rect(s,x+2.16+i*((w-2.22)/n),y+0.05,(w-2.22)/n-0.05,0.22,fill=col)
def bg(s,name,dark=0.82):
    pic(s,up(name,factor=2,dark=dark),0,0,13.333,7.5)
def slide(num,title,notes,room="room_c3_night.png",icon=None):
    s=prs.slides.add_slide(blank); s.background.fill.solid(); s.background.fill.fore_color.rgb=INK
    bg(s,room)
    # header plate
    rect(s,0.6,0.35,0.0001,0.0001)
    window(s,0.5,0.3,8.2,1.0,f"fase {num:02d} / 08",GOLD,TITLE,tbh=0.0001) if False else None
    rect(s,0.6,0.4,0.9,0.9,fill=INK); rect(s,0.65,0.45,0.8,0.8,fill=GOLD)
    text(s,0.65,0.45,0.8,0.8,f"{num:02d}",30,INK,True,PP_ALIGN.CENTER,MSO_ANCHOR.MIDDLE)
    rect(s,1.6,0.4,0.0001,0.0001)
    text(s,1.7,0.42,10,0.9,title,38,CREAM,True,anchor=MSO_ANCHOR.MIDDLE)
    rect(s,0.6,1.4,12.1,0.06,fill=GOLD); rect(s,0.6,1.46,12.1,0.04,fill=BD)
    s.notes_slide.notes_text_frame.text=notes
    return s
def sprite(s,name,box,factor,x,y,w):
    pic(s,up(name,box=box,factor=factor),x,y,w=w)

# 01 CAPA
s=prs.slides.add_slide(blank); s.background.fill.solid(); s.background.fill.fore_color.rgb=INK
pic(s,up("title_bg.png",factor=3,dark=0.35),0,0,13.333,7.5)
pic(s,up("game_logo.png",box=(0,0,260,96),factor=4),3.67,1.5,w=6.0)
sprite(s,"student_sheet.png",(0,0,32,32),8,5.8,3.7,1.7)
text(s,0,5.5,13.333,0.6,"MANHÃ  ·  TARDE  ·  NOITE",28,GOLD,True,PP_ALIGN.CENTER)
text(s,0,6.05,13.333,0.5,"Um jogo sobre ler os sinais do próprio corpo",20,CREAM,False,PP_ALIGN.CENTER)
rect(s,0,6.85,13.333,0.65,fill=INK); rect(s,0,6.85,13.333,0.05,fill=GOLD)
text(s,0.5,6.95,12.3,0.5,"SASI: GAME JAM 2026 · UFAC  |  Luiz Fernando · Ana Souza · Jackeline Jansen Medeiros · Ri Maciel",14,MUTED,False,PP_ALIGN.CENTER)
s.notes_slide.notes_text_frame.text="[0:00-0:15] Boa tarde! Somos a equipe de Três Turnos. Em 5 minutos vamos mostrar um jogo em que a gente não luta contra monstros... luta contra a rotina de quem estuda."

# 02 A HISTÓRIA
s=slide(2,"A HISTÓRIA","[0:15-0:50] A história começa na rotina real: três semanas de despertador cedo, ônibus lotado e madrugadas acumulando cansaço. No limite às 2h40 da manhã, o estudante liga o videogame para tentar desligar a mente — e é puxado para dentro da tela. Os monstros da alucinação vão perdendo a fumaça e revelando o próprio rosto dele: o inimigo final é o Burnout.","room_night.png")
x,y,w,h=window(s,0.6,1.75,5.05,5.35,"do cansaço ao jogo",GOLD)
beats=[
("1. ROTINA SEM FIM",CORPO,"Despertador cedo, busão lotado, aulas e madrugadas em claro acumulam exaustão a cada semana."),
("2. FUGA PELA TELA",MENTE,"No limite às 2h40, o estudante liga o videogame para desligar a mente — e é puxado para dentro da TV."),
("3. O VERDADEIRO INIMIGO",RED,"A névoa das sombras baixa a cada ciclo e revela o próprio rosto dele: a luta é contra o Burnout."),
]
for i,(bt,bc,bd) in enumerate(beats):
    by=y+0.05+i*1.40
    text(s,x,by,w,0.36,bt,16,bc,True)
    text(s,x,by+0.36,w,0.95,bd,14,CREAM,sp=2)
rx,ry,rw,rh=window(s,5.9,1.75,6.85,5.35,"cutscene inicial · abertura",MINT,INK)
pic(s,INTRO_GIF,rx,ry,w=6.25,h=3.516)
text(s,rx,ry+3.65,rw,0.60,"Semana 1 → Semana 3 (Exaustão) → Poema 'Cansaço' → Entrada na TV",13,GOLD,False,PP_ALIGN.CENTER,MSO_ANCHOR.MIDDLE)

# 03 O JOGO
s=slide(3,"O JOGO EM POUCAS PALAVRAS","[0:50-1:20] São 3 salas: Manhã, Tarde e Noite. O jogador controla 3 pilares: Corpo, Mente e Descanso. Se negligenciar, o próprio controle fica pior.","room_morning.png")
x,y,w,h=window(s,0.6,1.75,6.9,5.45,"missão",GOLD)
text(s,x,y,w,1.4,"Ação e aventura top-down em 3 salas. Você é um estudante que enfrenta a rotina como se fosse um RPG.",18,CREAM)
bar(s,x,y+1.45,w,"CORPO",0.35,CORPO); text(s,x,y+1.8,w,0.4,"água e alimentação",13,MUTED)
bar(s,x,y+2.35,w,"MENTE",0.7,MENTE); text(s,x,y+2.7,w,0.4,"foco e calma",13,MUTED)
bar(s,x,y+3.25,w,"DESCANSO",0.5,DESC); text(s,x,y+3.6,w,0.4,"fôlego e pausas",13,MUTED)
text(s,x,y+4.1,w,0.5,"META: chegar ao amanhecer sem colapsar.",17,GOLD,True)
for i,(n,l,c) in enumerate([("room_morning.png","MANHÃ",GOLD),("room_c2_afternoon.png","TARDE",MENTE),("room_c3_night.png","NOITE",DESC)]):
    yy=1.75+i*1.8
    window(s,7.9,yy,4.8,1.6,l,c,tbh=0.38)
    pic(s,up(n,factor=1),8.15,yy+0.62,w=1.75,h=0.9) if False else pic(s,up(n,factor=1),8.2,yy+0.62,w=1.9)
    text(s,10.2,yy+0.6,2.4,0.95,{"MANHÃ":["Corpo baixo = espada curta","Beber água [E]"],"TARDE":["Colega aliado [E]","Respirar [R]: Golpe de Foco"],"NOITE":["Boss drena os pilares","Reacendê-los [E]"]}[l],13,c,sp=2)

# 04 VIDEO
s=slide(4,"GAMEPLAY","[1:20-1:50] Deixe o vídeo rodar SEM falar por cima, ou comente só: 'aqui o Corpo está baixo e a espada encurtou'. Plano B: abrir o jogo no itch.io em outra aba.","room_c2_night.png" if os.path.exists(os.path.join(S,"room_c2_night.png")) else "room_c3_night.png")
x,y,w,h=window(s,2.2,1.6,8.9,5.7,"gameplay · 30s",GOLD,INK)
vw=w; vh=w*9/16
mv=s.shapes.add_movie(VIDEO,Inches(x),Inches(y),Inches(vw),Inches(vh),poster_frame_image=POSTER,mime_type="video/mp4")
sprite(s,"student_sheet.png",(0,0,32,32),6,0.45,5.4,1.4)

# 05 ESPECIAL
s=slide(5,"O QUE TEM DE ESPECIAL","[1:50-2:40] Aqui está o diferencial. Primeiro: você SENTE a saúde no controle. Com o Corpo baixo, a espada encurta e o passo fica lento. Ansioso, a música acelera, a tela escurece e o coração bate. Sem Descanso, o personagem fica ofegante. Segundo: cuidar de si é mecânica de vitória, não pausa. Terceiro: você não vence sozinho, o colega ajuda. E no final, o jogo devolve um espelho da sua jornada.","room_c3_morning.png")
cards=[("SINAIS QUE VOCÊ SENTE",CORPO,"Corpo baixo: espada curta e passo lento.\nMente baixa: tela escura e música acelerada.\nSem fôlego: exaustão ofegante.",("stations_sheet.png",(0,0,48,48))),
("CUIDAR É JOGAR",MENTE,"Beber água, respirar [R] e descansar [E] carregam o Golpe de Foco. Autocuidado é a arma mais forte.",("care_core_sheet.png",(0,0,48,56))),
("NINGUÉM VENCE SOZINHO",DESC,"Na Tarde, o Colega entra na luta e recupera a sua Mente. Pedir ajuda é parte da vitória.",("classmate_sheet.png",(0,0,32,32))),
("ESPELHO DA JORNADA",GOLD,"No final, um perfil mostra como você cuidou (ou não) de si ao longo do jogo.",("seu_antonio_sheet.png",(0,0,32,32)))]
for i,(hd,c,b,(sp,bx)) in enumerate(cards):
    cx=0.6+(i%2)*6.15; cy=1.75+(i//2)*2.65
    x,y,w,h=window(s,cx,cy,5.9,2.45,hd,c,tbh=0.42)
    text(s,x,y,w-1.3,h,b.split("\n"),16,CREAM,sp=4)
    pic(s,up(sp,box=bx,factor=4),cx+4.55,cy+0.85,w=1.1)

# 06 TEMA
s=slide(6,"SAÚDE EM JOGO","[2:40-3:20] O tema pedia Sinais, Equilíbrio e Conexões. Sinais: o corpo avisa e o jogo traduz em controle. Equilíbrio: três pilares que se alternam, o Boss drena um deles. Conexões: o colega na luta e o Seu Antônio. O público é universitário: burnout, falta de água, ansiedade e exaustão são reais na nossa rotina.","room_c2_afternoon.png")
cols=[("SINAIS",CORPO,"O corpo avisa. O jogo traduz cada aviso em sensação no controle, não só em barras de status.","stations_sheet.png",(0,0,48,48)),
("EQUILÍBRIO",MENTE,"Corpo, Mente e Descanso. O Boss drena um pilar por vez: só vence quem cuida de todos.","boss_burnout_sheet.png",(0,0,80,80)),
("CONEXÕES",DESC,"Colega e Seu Antônio. Apoio social como mecânica: a ajuda de outras pessoas muda o resultado.","classmate_sheet.png",(0,0,32,32))]
for i,(hd,c,b,sp,bx) in enumerate(cols):
    cx=0.6+i*4.1
    x,y,w,h=window(s,cx,1.75,3.9,4.3,hd,c,tbh=0.45)
    pic(s,up(sp,box=bx,factor=4),cx+1.2,y+0.05,h=1.5)
    text(s,x,y+1.7,w,2.2,b,17,CREAM)
rect(s,0.6,6.3,12.1,0.8,fill=INK,line=GOLD,lw=2)
text(s,0.7,6.3,11.9,0.8,"PÚBLICO: universitários  ·  PROBLEMA: burnout, ansiedade, descuido com água e descanso",17,GOLD,True,PP_ALIGN.CENTER,MSO_ANCHOR.MIDDLE)

# 07 CRONOGRAMA
s=slide(7,"CRONOGRAMA","[3:20-3:50] Fizemos tudo em 4 dias de jam. Já está jogável no navegador no itch.io e com versões para Windows, Linux e macOS. Depois da jam, vamos ouvir os jogadores, ajustar o equilíbrio e talvez expandir com mais salas.","room_c3_afternoon.png")
rect(s,0.9,3.7,11.5,0.18,fill=INK); rect(s,0.9,3.74,11.5,0.1,fill=BL)
ev=[("23/11","Início da jam\nConceito e GDD",GOLD),("24/11","Primeira jogatina\nSalas 1 a 3",CORPO),("25/11","Arte, trilha 8-bit\ne polimento",MENTE),("26/11","Versão final\nno itch.io",DESC),("DEPOIS","Feedback e\nnovas salas",RED)]
for i,(d,t,c) in enumerate(ev):
    x=1.0+i*2.4
    rect(s,x+0.62,3.5,0.6,0.6,fill=INK); rect(s,x+0.68,3.56,0.48,0.48,fill=c)
    window(s,x-0.1,1.75,2.1,1.35,d,c,tbh=0.4) if False else None
    text(s,x-0.1,2.7,2.1,0.6,d,26,c,True,PP_ALIGN.CENTER)
    window(s,x-0.05,4.4,2.1,1.5,"",c,tbh=0.2)
    text(s,x+0.05,4.8,1.9,0.9,t.split("\n"),14,CREAM,False,PP_ALIGN.CENTER,sp=2)
rect(s,1.6,6.3,10.1,0.8,fill=INK,line=GOLD,lw=2)
text(s,1.6,6.3,10.1,0.8,"JOGÁVEL AGORA: Web (HTML5) · Windows · Linux · macOS",20,GOLD,True,PP_ALIGN.CENTER,MSO_ANCHOR.MIDDLE)

# 08 EQUIPE
s=slide(8,"EQUIPE","[3:50-4:25] Apresente cada pessoa em UMA frase: nome e o que fez. Luiz programou, Ana criou o roteiro, o design e a arte, Jackeline escreveu o roteiro, Ri desenhou e fez o som.","room_morning.png")
team=[("Luiz Fernando","Programador",CORPO),("Ana Souza","Roteiro, Game Design e Artista",GOLD),("Jackeline Jansen Medeiros","Roteiro",DESC),("Ri Maciel","Designer e Sonoplasta",MENTE)]
for i,(n,r,c) in enumerate(team):
    cx=0.6+(i%2)*6.15; cy=1.75+(i//2)*2.6
    x,y,w,h=window(s,cx,cy,5.9,2.4,f"jogador {i+1}",c,tbh=0.42)
    pic(s,up("student_sheet.png",box=(0,0,32,32),factor=4),cx+0.35,y+0.2,h=1.4) if False else sprite(s,["student_sheet.png","classmate_sheet.png","classmate_sheet.png","student_sheet.png"][i],[(0,0,32,32),(0,0,32,32),(32,0,64,32),(32,0,64,32)][i],4,cx+0.35,y+0.15,1.3)
    text(s,cx+1.8,y+0.1,4.0,1.0,n,22,CREAM,True)
    text(s,cx+1.8,y+1.15,4.0,0.8,r,17,c,True)
text(s,0.6,6.95,12.1,0.4,"Universidade Federal do Acre (UFAC) · SASI 2026",13,MUTED,False,PP_ALIGN.CENTER)

# 08 FECHAMENTO
s=prs.slides.add_slide(blank); s.background.fill.solid(); s.background.fill.fore_color.rgb=INK
pic(s,up("cutscene_happy_sunset.png",factor=8,dark=0.7),0,0,13.333,7.5)
x,y,w,h=window(s,1.4,0.6,10.5,2.9,"o tempo · mário quintana",GOLD,BODY,tbh=0.45)
text(s,x,y+0.1,w,2.0,["“Quando se vê, passaram 60 anos!","Agora, é tarde demais para ser reprovado…”"],28,CREAM,True,PP_ALIGN.CENTER,sp=8)
rect(s,1.4,3.7,10.5,0.7,fill=INK); rect(s,1.4,3.7,10.5,0.04,fill=GOLD)
text(s,0,3.78,13.333,0.8,"TRÊS TURNOS: cuide de você antes que o dia acabe.",26,GOLD,True,PP_ALIGN.CENTER)
x,y,w,h=window(s,2.2,4.6,8.9,2.3,"fim de jogo · obrigado!",MINT,BODY,tbh=0.42)
text(s,x,y+0.05,w,1.6,["JOGUE AGORA: louishonorato1337.itch.io/tres-turnos","CÓDIGO: github.com/Honorato1337/sasi-game-jam-2026","PERGUNTAS?"],18,CREAM,False,PP_ALIGN.CENTER,sp=6)
sprite(s,"student_sheet.png",(0,0,32,32),6,0.5,5.2,1.5); sprite(s,"seu_antonio_sheet.png",(0,0,32,32),6,11.3,5.2,1.5)
s.notes_slide.notes_text_frame.text="[4:25-5:00] Feche com o poema (leia a frase em voz alta) e a mensagem: o jogo termina com o personagem aceitando a rotina, mas cuidando de si. Deixe o link na tela e abra para perguntas."
prs.save("Pitch_Tres_Turnos.pptx"); print("ok")





