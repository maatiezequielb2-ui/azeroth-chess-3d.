"""Hand-authored forms for the approved Warcraft chess miniature designs.
This module creates mesh volumes, never image planes or downloaded meshes.
"""
def author_footman(g):
    g['rig']()
    loft,plate,curve,ell,rod,box=(g[k] for k in ['loft','plate','curve','ell','rod','bevelbox'])
    # Long articulated legs and narrow waist rather than a round toy silhouette.
    for side in [-1,1]:
        bone='LeftLeg' if side<0 else 'RightLeg';x=side*.115
        loft('Mail thigh',[(x,0,.35,.068,.07),(x,0,.46,.081,.086),(x,0,.61,.087,.091)],'mail',bone,n=16)
        loft('Forged calf shell',[(x,0,.17,.055,.052),(x,0,.27,.067,.062),(x,0,.36,.072,.065)],'plate',bone,n=12)
        loft('Brown leather boot',[(x,-.045,.122,.079,.13),(x,-.045,.17,.078,.13),(x,-.015,.225,.057,.060)],'leather',bone,n=16)
        plate('Blue pointed knee',[(x-.075,-.073,.37),(x,-.104,.421),(x+.075,-.073,.37),(x+.064,-.085,.335),(x,-.112,.30),(x-.064,-.085,.335)],'blue',bone,.020)
        curve('Knee bright raised frame',[(x-.075,-.087,.37),(x,-.118,.421),(x+.075,-.087,.37),(x+.064,-.099,.335),(x,-.126,.30),(x-.064,-.099,.335),(x-.075,-.087,.37)],.007,'silver',bone)
        plate('Pointed blue greave inset',[(x-.060,-.066,.305),(x+.060,-.066,.305),(x+.038,-.074,.182),(x,-.091,.15),(x-.038,-.074,.182)],'blue',bone,.012)
        curve('Greave brass inlay',[(x-.048,-.084,.285),(x,-.108,.303),(x+.048,-.084,.285),(x,-.109,.168),(x-.048,-.084,.285)],.004,'gold',bone)
        plate('Layered thigh plate',[(x-.075,-.080,.56),(x+.074,-.080,.56),(x+.068,-.09,.455),(x,-.11,.415),(x-.068,-.09,.455)],'plate',bone,.020)
        curve('Thigh raised V rim',[(x-.075,-.103,.47),(x,-.131,.415),(x+.075,-.103,.47)],.006,'silver',bone)
    loft('Chainmail torso',[(0,0,.55,.145,.10),(0,0,.73,.158,.115),(0,0,.91,.196,.125),(0,0,1.02,.137,.095)],'mail','Body',n=24)
    # Metal cuirass composed of solid curved, tapered overlapping plates.
    loft('Formed torso cuirass',[(0,0,.64,.151,.11),(0,0,.76,.172,.13),(0,0,.91,.202,.143),(0,0,1.01,.121,.098)],'plate','Body',n=24)
    for z,w in [(.735,.160),(.813,.180),(.895,.19)]:
        pts=[(-w,-.057,z+.04),(-w*.73,-.127,z+.025),(0,-.163,z-.046),(w*.73,-.127,z+.025),(w,-.057,z+.04)]
        plate('Overlapping cuirass chevron',pts+[(w,-.05,z+.086),(0,-.16,z+.015),(-w,-.05,z+.086)],'steel','Body',.015)
        curve('Cuirass bright chevron edge',[(x,y-.014,zv) for x,y,zv in pts],.007,'silver','Body')
    loft('High chainmail collar',[(0,0,1.0,.095,.075),(0,0,1.09,.094,.077)],'mail','Head',n=20)
    for side in [-1,1]:
        bone='LeftArm' if side<0 else 'RightArm';x=side*.28
        loft('Chainmail sleeve',[(side*.308,-.01,.57,.058,.065),(side*.3,0,.72,.069,.071),(side*.255,0,.91,.075,.087)],'mail',bone,n=16)
        loft('Blue plate vambrace',[(side*.313,-.018,.58,.059,.065),(side*.303,-.005,.69,.069,.075),(side*.296,0,.73,.063,.070)],'blue',bone,n=12)
        curve('Vambrace silver spine',[(side*.311,-.088,.59),(side*.302,-.090,.69),(side*.296,-.080,.735)],.009,'silver',bone)
        ell('Leather gloved palm',(side*.315,-.038,.55),(.045,.038,.052),'leather',bone)
        for d in range(4):
            rod('Armoured glove fingers',(side*.315-.021+d*.014,-.059,.55),(side*.315-.021+d*.014,-.070,.50),.007,'leather',bone)
        # Closed shell with swept ridges, no holes through exposed shoulders.
        loft('Monumental pauldron shell',[(side*.255,0,.89,.14,.11),(side*.255,0,.965,.16,.137),(side*.235,0,1.047,.103,.082)],'plate','Body',n=20)
        for k in range(3):
            z=.925-k*.050;outer=side*(.39+k*.008)
            coords=[(side*.13,-.035,z+.060),(side*.235,-.143,z+.05),(outer,-.081,z),(outer,.072,z-.008),(side*.255,.13,z+.03),(side*.14,.055,z+.06)]
            plate('Solid overlapping pauldron lames',coords,'plate','Body',.022)
            curve('Lame silver edge',[(side*.13,-.05,z+.06),(side*.235,-.16,z+.05),(outer,-.096,z),(outer,.072,z-.008)],.006,'silver','Body')
        for k in range(3):
            x=side*(.185+k*.065)
            plate('Raised forged pauldron fin',[(x,-.133,.984),(x,-.035,1.09-k*.023),(x,.065,1.025),(x,.065,.985)],'steel','Body',.009)
            curve('Pauldron fin bevel',[(x,-.14,.984),(x,-.035,1.09-k*.023),(x,.065,1.025)],.004,'silver','Body')
        plate('Folded hip blue tabard',[(side*.055,-.117,.63),(side*.164,-.092,.63),(side*.214,-.067,.403),(side*.106,-.105,.45)],'blue','Body',.009)
        curve('Tabard gold edge',[(side*.067,-.13,.62),(side*.10,-.128,.52),(side*.116,-.12,.455)],.0035,'gold','Body')
    loft('Leather waist belt',[(0,0,.604,.166,.122),(0,0,.642,.165,.122)],'leather','Body',n=24)
    # Greathelm custom polygon cross-sections. Entire face is closed metal.
    loft('Pointed closed greathelm',[(0,0,1.09,.075,.079),(0,0,1.15,.104,.095),(0,0,1.27,.102,.083),(0,0,1.345,.060,.053),(0,0,1.38,.009,.010)],'plate','Head',n=12)
    for side in [-1,1]:
        pts=[(side*.020,-.101,1.108),(side*.089,-.079,1.154),(side*.089,-.079,1.26),(side*.053,-.088,1.323),(side*.019,-.099,1.31)]
        plate('Closed blue visor half',pts,'blue','Head',.010)
        curve('Greathelm gold outline',[(x,y-.01,z) for x,y,z in pts+[pts[0]]],.0045,'gold','Head')
        curve('Greathelm dark vertical sight',[(side*.013,-.12,1.29),(side*.017,-.119,1.17)],.004,'black','Head')
    curve('Sharp helmet center spine',[(0,-.020,1.377),(0,-.107,1.30),(0,-.117,1.09)],.006,'gold','Head')
    loft('Blue plume brass socket',[(0,0,1.365,.027,.028),(0,0,1.412,.030,.030)],'gold','Head')
    for k in range(17):
        x=(k-8)*.005
        curve('Individual horsehair plume',[(x,.004,1.408),(x*1.5,.02,1.51),(x*1.2,.04,1.635-abs(k-8)*.009)],.008,'blue','Head')
    # Sculpted heraldic lion head and mane on belt and curved shield.
    def lion(x,y,z,size,bone):
        for k in range(10):
            a=k*6.283185/10
            import math
            rod('Lion mane ray',(x+math.cos(a)*size*.55,y,z+math.sin(a)*size*.55),(x+math.cos(a)*size,y,z+math.sin(a)*size),size*.16,'gold',bone,end=size*.08)
        ell('Lion heraldic muzzle',(x,y-.01,z),(size*.47,.012,size*.60),'gold',bone,seg=12,rings=8)
        for side in [-1,1]:
            ell('Lion inset eye',(x+side*size*.19,y-.023,z+size*.16),(size*.085,.003,size*.08),'black',bone)
        ell('Lion raised nose',(x,y-.027,z-size*.09),(size*.15,.006,size*.12),'gold',bone)
    for scale,material,y in [(1,'gold',-.14),(.83,'blue',-.155)]:
        plate('Lion belt badge',[(x*scale,y,.586+(z-.586)*scale) for x,z in [(-.089,.64),(.089,.64),(.069,.55),(0,.50),(-.069,.55)]],material,'Body',.008)
    lion(0,-.171,.579,.037,'Body')
    # Right-hand sword points down as in the approved concept, not up beside head.
    x=.335;y=-.10
    rod('Sword leather grip',(x,y,.515),(x,y,.61),.021,'leather','RightArm')
    ell('Sword pommel',(x,y,.62),(.03,.023,.027),'gold','RightArm')
    curve('Sword ornate crossguard',[(x-.10,y,.51),(x-.06,y,.485),(x,y,.50),(x+.06,y,.485),(x+.10,y,.51)],.012,'gold','RightArm')
    plate('Sharp long downturned blade',[(x-.027,y,.485),(x-.025,y,.17),(x+.025,y,.17),(x+.027,y,.485)],'steel','RightArm',.016)
    curve('Blade sharp central fuller',[(x,y-.018,.48),(x,y-.018,.15)],.004,'silver','RightArm')
    plate('Sword pointed tip',[(x-.025,y,.17),(x,y,.11),(x+.025,y,.17)],'silver','RightArm',.015)
    # Curved full-height lion shield: seven rows of actual bowed metal geometry.
    vertices=[]
    for z,w in [(.28,.015),(.36,.07),(.50,.115),(.67,.13),(.83,.14)]:
        for t in [-1,-.5,0,.5,1]:vertices.append((-.32+t*w,-.145-.065*(1-t*t),z))
    mesh=g['bpy'].data.meshes.new('Curved lion shield shell')
    faces=[]
    for row in range(4):
        for col in range(4):
            i=row*5+col;faces.append((i,i+1,i+6,i+5))
    mesh.from_pydata(vertices,[],faces);mesh.update()
    o=g['bpy'].data.objects.new('Bowed blue shield',mesh);g['bpy'].context.collection.objects.link(o)
    g['finish'](o,'Bowed blue shield','blue','LeftArm')
    for side in [-1,1]:
        curve('Shield substantial steel frame',[(-.32+side*w,-.156,z) for z,w in [(.28,.015),(.36,.07),(.50,.115),(.67,.13),(.83,.14)]],.014,'silver','LeftArm')
    curve('Shield crown steel frame',[(-.46,-.156,.83),(-.32,-.223,.86),(-.18,-.156,.83)],.014,'silver','LeftArm')
    lion(-.32,-.235,.63,.068,'LeftArm')

def author_face(g,orc=False,elf=False,arthas=False):
    loft,ell,rod,curve=(g[k] for k in ['loft','ell','rod','curve'])
    mat='orc' if orc else ('undead' if elf or arthas else 'skin')
    w=.134 if orc else .090
    loft('Sculpted angular face',[(0,.004,1.075,w*.47,.055),(0,-.004,1.11,w*.85,.071),(0,0,1.16,w,.081),(0,.007,1.215,w*.94,.076),(0,.010,1.265,w*.84,.068),(0,.013,1.302,w*.40,.040)],mat,'Head',n=24)
    for side in [-1,1]:
        curve('Stern brow ridge',[(side*.015,-.083,1.226),(side*.047,-.089,1.232),(side*.076,-.069,1.225)],.008,mat,'Head')
        ell('Almond eye',(side*.043,-.082,1.213),(.017,.007,.008),'ice' if arthas else ('red' if elf else 'bone'),'Head',seg=12,rings=6)
        ell('Eye pupil',(side*.043,-.089,1.213),(.005,.003,.006),'black','Head',seg=8,rings=4)
        curve('Lower eyelid',[(side*.025,-.088,1.207),(side*.043,-.09,1.202),(side*.061,-.08,1.207)],.003,mat,'Head')
        if elf:
            rod('Long elven ear',(side*.087,.003,1.20),(side*.196,.024,1.29),.026,mat,'Head',end=.002)
        else:ell('Anatomical ear',(side*w*.98,.01,1.20),(.019,.015,.034),mat,'Head')
    loft('Sculpted nose',[(0,-.095,1.155,.017,.019),(0,-.115,1.172,.022 if orc else .018,.017),(0,-.093,1.207,.010,.011),(0,-.078,1.228,.010,.008)],mat,'Head',n=10)
    curve('Neutral closed mouth',[(-.035,-.081,1.130),(0,-.087,1.132),(.035,-.081,1.130)],.0028,'leather','Head')
    if orc:
        for side in [-1,1]:curve('Long lower jaw tusk',[(side*.064,-.083,1.106),(side*.077,-.122,1.145),(side*.079,-.119,1.188)],.013,'bone','Head')


def enrich_character(g,kind):
    plate,curve,rod,ell,loft=(g[k] for k in ['plate','curve','rod','ell','loft'])
    if kind=='footman':return
    orc=kind in ['grunt','thrall']
    # Repeated forged detail is geometry, so highlights move correctly when rotated.
    if kind in ['arthas','thrall']:
        trim='gold' if orc else 'silver'
        for side in [-1,1]:
            for k in range(3):
                z=.92-k*.045
                pts=[(side*.145,-.08,z+.065),(side*.255,-.145,z+.07),(side*.40,-.08,z),(side*.37,.08,z-.025),(side*.20,.12,z+.045)]
                plate('Hero overlapping shoulder plate',pts,'iron','Body',.022)
                curve('Hero forged shoulder border',[(x,y-.014,zv) for x,y,zv in pts[:3]],.009,trim,'Body')
            for k in range(4):
                z=.69+k*.055
                curve('Etched royal chest flourish',[(side*.052,-.155,z),(side*.095,-.16,z+.024),(side*.146,-.137,z+.015)],.0035,trim,'Body')
            bone='LeftLeg' if side<0 else 'RightLeg';x=side*.13
            plate('Hero pointed shin armour',[(x-.075,-.085,.34),(x,-.11,.39),(x+.075,-.085,.34),(x+.05,-.10,.18),(x,-.123,.143),(x-.05,-.10,.18)],'iron',bone,.022)
            curve('Hero shin raised trim',[(x-.075,-.10,.34),(x,-.13,.39),(x+.075,-.10,.34),(x,-.143,.143),(x-.075,-.10,.34)],.007,trim,bone)
    if kind=='grunt':
        for side in [-1,1]:
            ell('Broad muscular pectoral',(side*.09,-.10,.856),(.108,.051,.092),'orc','Body',seg=20,rings=12)
            for k in range(3):ell('Abdominal muscle',(side*.037,-.116,.735-k*.05),(.045,.023,.037),'orc','Body',seg=12,rings=8)
            # Sparse fur spikes along boots and shoulder, with irregular silhouette.
            for k in range(10):
                x=side*.13+(k%5-2)*.029;y=-.067+(k//5)*.061
                rod('Boot fur tuft',(x,y,.28),(x+.008,y-.017,.34+(k%3)*.013),.015,'leather','LeftLeg' if side<0 else 'RightLeg',end=.001)
            for k in range(3):
                z=.90-k*.044
                pts=[(side*.16,-.078,z+.06),(side*.255,-.148,z+.065),(side*.40,-.065,z),(side*.37,.079,z-.015),(side*.20,.10,z+.04)]
                plate('Red grunt shoulder plates',pts,'red','Body',.02)
                curve('Grunt shoulder metal rim',[(x,y-.012,zv) for x,y,zv in pts[:3]],.009,'steel','Body')
            for k in range(5):ell('Leather harness iron rivet',(side*(.06+k*.019),-.16,.70+k*.04),(.007,.005,.007),'silver','Body',seg=8,rings=4)
    if kind in ['jaina','sylvanas']:
        trim='gold' if kind=='jaina' else 'silver'
        for side in [-1,1]:
            for k in range(4):
                z=.64+k*.061
                curve('Mage or ranger chest embroidery',[(side*.03,-.132,z),(side*.07,-.148,z+.02),(side*.11,-.126,z+.016)],.003,trim,'Body')
            for k in range(3):
                z=.915-k*.036
                plate('Fitted heroine shoulder lames',[(side*.16,-.06,z+.03),(side*.25,-.113,z+.038),(side*.34,-.04,z-.02),(side*.30,.08,z-.02),(side*.19,.08,z+.025)],'blue' if kind=='jaina' else 'purple','Body',.012)
                curve('Heroine shoulder fine edge',[(side*.16,-.071,z+.03),(side*.25,-.124,z+.038),(side*.34,-.05,z-.02)],.005,trim,'Body')
        if kind=='jaina':
            for side in [-1,1]:
                for k in range(4):
                    z=.24+k*.09
                    curve('Gold robe embroidered scroll',[(side*.07,-.202+(.24-z)*.17,z),(side*.12,-.189+(.24-z)*.17,z+.03),(side*.09,-.20+(.24-z)*.17,z+.055)],.003,'gold','Body')
        else:
            for side in [-1,1]:
                bone='LeftLeg' if side<0 else 'RightLeg';x=side*.13
                curve('Ranger greave silver edge',[(x-.056,-.115,.35),(x,-.14,.39),(x+.056,-.115,.35),(x,-.144,.15)],.006,'silver',bone)


def enrich_tower(g,orc):
    box,plate,rod,curve=(g[k] for k in ['bevelbox','plate','rod','curve'])
    if not orc:
        # Tall blue-roofed Warcraft watch turret rather than a plain chess rook.
        box('Roof upper timber platform',(0,0,1.12),(.46,.42,.04),'wood',radius=.005)
        for side in [-1,1]:
            for y in [-.17,.17]:rod('Tower lookout roof post',(side*.19,y,1.10),(side*.19,y,1.37),.022,'wood',n=8)
        for row in range(5):
            z=1.35+row*.035;w=.30-row*.046
            for side in [-1,1]:
                plate('Individual blue roof course',[(side*w,-w,z),(side*w,w,z),(side*(w-.061),w-.061,z+.045),(side*(w-.061),-w+.061,z+.045)],'blue',thickness=.012)
                curve('Roof shingle seam',[(side*w,-w,z),(side*w,w,z)],.005,'steel')
        rod('Roof finial',(0,0,1.49),(0,0,1.58),.013,'gold',end=.001)
        for row in range(5):
            for col in range(4):
                x=-.18+col*.12+(row%2)*.03
                if x<.23:box('Individual masonry face',(x,-.227,.23+row*.155),(.111,.018,.14),'stone',radius=.007)
    else:
        for side in [-1,1]:
            for z in [.35,.62,.92]:
                curve('Timber rope binding',[(side*.22,-.23,z),(side*.25,-.19,z+.03),(side*.23,-.15,z),(side*.20,-.19,z-.025),(side*.22,-.23,z)],.008,'leather')
        for k in range(4):rod('Watchtower narrow ladder rung',(-.08,-.245,.22+k*.15),(.08,-.245,.22+k*.15),.012,'wood',n=8)

def author_frostmourne(g,at=(.33,-.12,.5),frost=False,bone='RightArm',length=.64):
    if not frost:return g['ordinary_sword'](at,frost,bone,length)
    x,y,z=at;rod,plate,curve,ell=(g[k] for k in ['rod','plate','curve','ell'])
    rod('Frostmourne wrapped grip',(x,y,z-.12),(x,y,z+.05),.023,'leather',bone)
    for k in range(7):curve('Runeblade grip spiral',[(x-.024,y,z-.10+k*.02),(x,y-.026,z-.09+k*.02),(x+.024,y,z-.08+k*.02)],.003,'silver',bone)
    ell('Frostmourne skull pommel',(x,y,z-.13),(.032,.025,.04),'silver',bone)
    outline=[(x-.045,y,z+.11),(x-.058,y,z+.24),(x-.040,y,z+.31),(x-.052,y,z+.42),(x-.036,y,z+.48),(x-.045,y,z+length*.74),(x-.034,y,z+length*.85),(x,y,z+length)]
    outline += [(2*x-xx,yy,zz) for xx,yy,zz in reversed(outline[:-1])]
    plate('Jagged Frostmourne runeblade',outline,'plate',bone,.023)
    for side in [-1,1]:
        curve('Frostmourne sharpened silver bevel',[(x+side*.038,y-.017,z+.16),(x+side*.047,y-.017,z+.24),(x+side*.034,y-.017,z+.31),(x+side*.044,y-.017,z+.42),(x+side*.029,y-.017,z+length*.80),(x,y-.017,z+length)],.006,'silver',bone)
        curve('Horned demonic crossguard',[(x,y,z+.09),(x+side*.085,y,z+.08),(x+side*.13,y,z+.15),(x+side*.11,y,z+.24)],.015,'steel',bone)
        rod('Guard dagger spike',(x+side*.095,y,z+.085),(x+side*.17,y,z+.02),.018,'steel',bone,end=.001)
    g['skull']((x,y-.029,z+.105),.041,bone)
    for k in range(7):
        zz=z+.27+k*(length-.32)/7
        curve('Frostmourne blue engraved rune',[(x-.014,y-.019,zz),(x+.012,y-.019,zz+.015),(x-.005,y-.019,zz+.028)],.0028,'ice',bone)


def enrich_creature(g,kind):
    ell,rod,curve=(g[k] for k in ['ell','rod','curve'])
    if kind=='hippogryph':
        ell('Equine muscular hindquarters',(0,.18,.54),(.145,.18,.18),'leather')
        for side in [-1,1]:
            rod('Hippogryph horse rear leg',(side*.10,.19,.46),(side*.13,.24,.21),.036,'leather')
            ell('Hippogryph rear hoof',(side*.13,.20,.17),(.047,.055,.041),'black')
        for k in range(10):
            curve('Hippogryph neck feather',[((k%3-1)*.033,-.22,1.025-k*.017),((k%3-1)*.04,-.23,.98-k*.017),((k%3-1)*.05,-.15,.91-k*.017)],.010,'feather')
    else:
        for side in [-1,1]:
            rod('Gargoyle hunched arm',(side*.11,-.06,.73),(side*.22,-.18,.54),.044,'stone')
            for digit in [-1,0,1]:rod('Gargoyle hand claw',(side*.22+digit*.018,-.18,.54),(side*.25+digit*.023,-.24,.45),.01,'iron',end=.001)
        curve('Gargoyle back spine',[(0,.14,.42),(0,.21,.62),(0,.15,.83)],.014,'iron')
