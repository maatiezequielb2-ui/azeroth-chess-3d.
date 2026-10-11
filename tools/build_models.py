"""Original Warcraft-inspired chess sculptures, authored in Blender.

Run: blender --background --python tools/build_models.py -- [--preview]
No Blizzard game data, external meshes, or reference photographs are embedded.
"""
import bpy
import math
import sys
import json
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/models'
OUT.mkdir(parents=True, exist_ok=True)
PALETTE = {
    'steel': ('596675', .72, .38), 'silver': ('949da5', .72, .30),
    'iron': ('384049', .5, .60), 'blue': ('183354', .0, .75),
    'red': ('713c3d', .0, .82), 'gold': ('a08a59', .45, .50),
    'leather': ('49372e', .0, .88), 'skin': ('c8a38c', .0, .8),
    'orc': ('536f45', .0, .80), 'bone': ('c6bc9b', .0, .80),
    'black': ('26282a', .0, .85), 'hair': ('b8b5a6', .0, .82),
    'white': ('b8b9b0', .0, .86), 'purple': ('4c3e59', .0, .82),
    'undead': ('8197a2', .0, .82), 'ice': ('7dabbf', .2, .45),
    'stone': ('606873', .0, .9), 'wood': ('645044', .0, .92),
    'mail': ('282d34', .5, .70), 'plate': ('293342', .72, .37),
    'feather': ('5c6c77', .0, .85), 'green': ('718958', .0, .68),
}
MATS = {}
OBJS = []
BIND = {}
RIG = None
STATS = {}


def material(name):
    if name in MATS:
        return MATS[name]
    color, metal, rough = PALETTE[name]
    rgb = [int(color[i:i+2], 16)/255 for i in (0,2,4)]
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    p = m.node_tree.nodes.get('Principled BSDF')
    p.inputs['Metallic'].default_value = metal
    p.inputs['Roughness'].default_value = rough
    # Small embedded paint texture: controlled variation, no neon emission.
    # Surface paint comes from our own generated, approved-style Footman image.
    # This is a small tiled material patch, not a projected character billboard.
    source_path=ROOT/'design/footman-material-reference.png'
    patches={'plate':(430,490,495,560),'steel':(460,454,540,485),'silver':(360,410,425,432),
             'blue':(436,908,496,978),'gold':(528,700,552,742),'mail':(260,573,302,625),
             'leather':(396,1384,456,1420)}
    size=256
    img = bpy.data.images.new(name+'_paint', width=size, height=size)
    pixels = []
    if source_path.exists() and name in patches:
        import numpy as np
        src=bpy.data.images.load(str(source_path),check_existing=True)
        sw,sh=src.size;arr=np.array(src.pixels[:]).reshape(sh,sw,4)
        x0,y0,x1,y1=patches[name]
        for y in range(size):
            for x in range(size):
                xx=x0+int(x/size*(x1-x0));yy=sh-1-(y0+int(y/size*(y1-y0)))
                sample=arr[yy,xx,:3]
                luma=float(sum(sample)/3)
                f=.85+.40*luma
                pixels.extend([min(1,c*f) for c in rgb]+[1])
    else:
        for y in range(size):
            for x in range(size):
                grain=math.sin(x*12.9898+y*78.233)*.055
                f=1+grain+math.sin(y*.19+x*.07)*.04
                pixels.extend([min(1,c*f) for c in rgb]+[1])
    img.pixels = pixels
    img.pack()
    tex = m.node_tree.nodes.new('ShaderNodeTexImage')
    tex.image = img
    m.node_tree.links.new(tex.outputs['Color'], p.inputs['Base Color'])
    MATS[name] = m
    return m


def finish(o, name, mat, bone='Root'):
    o.name = name
    o.data.materials.append(material(mat))
    for poly in o.data.polygons:
        poly.use_smooth = True
    OBJS.append(o)
    BIND[o.name] = bone
    return o


def ell(name, loc, scale, mat, bone='Root', seg=16, rings=10):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=seg, ring_count=rings, location=loc)
    o = bpy.context.object
    o.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return finish(o,name,mat,bone)


def loft(name, rings, mat, bone='Root', n=16):
    # Each ring: center x/y/z and elliptical cross section rx/ry.
    verts = []
    for x,y,z,rx,ry in rings:
        verts.extend([(x+rx*math.cos(i*math.tau/n),y+ry*math.sin(i*math.tau/n),z) for i in range(n)])
    faces = []
    for r in range(len(rings)-1):
        for i in range(n):
            j = (i+1)%n
            faces.append((r*n+i,r*n+j,(r+1)*n+j,(r+1)*n+i))
    faces.extend([tuple(reversed(range(n))),tuple((len(rings)-1)*n+i for i in range(n))])
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(verts,[],faces)
    mesh.update()
    o = bpy.data.objects.new(name,mesh)
    bpy.context.collection.objects.link(o)
    return finish(o,name,mat,bone)


def rod(name,a,b,r,mat,bone='Root',end=None,n=10):
    d = Vector(b)-Vector(a)
    bpy.ops.mesh.primitive_cone_add(vertices=n, radius1=r, radius2=r if end is None else end, depth=d.length, location=(Vector(a)+Vector(b))/2)
    o = bpy.context.object
    o.rotation_euler = d.to_track_quat('Z','Y').to_euler()
    return finish(o,name,mat,bone)


def curve(name, points, r, mat, bone='Root'):
    d = bpy.data.curves.new(name,'CURVE')
    d.dimensions = '3D'
    d.bevel_depth = r
    d.bevel_resolution = 1
    d.resolution_u = 6
    sp = d.splines.new('BEZIER')
    sp.bezier_points.add(len(points)-1)
    for p, co in zip(sp.bezier_points,points):
        p.co=co
        p.handle_left_type='VECTOR' if any(t in name.lower() for t in ['frame','outline','edge','chevron','border','spine','rim','bevel']) else 'AUTO'
        p.handle_right_type=p.handle_left_type
    o = bpy.data.objects.new(name,d)
    bpy.context.collection.objects.link(o)
    bpy.context.view_layer.objects.active=o
    o.select_set(True)
    bpy.ops.object.convert(target='MESH')
    o.select_set(False)
    return finish(o,name,mat,bone)


def plate(name, coords, mat, bone='Root', thickness=.014):
    mesh=bpy.data.meshes.new(name)
    mesh.from_pydata(coords,[],[tuple(range(len(coords)))])
    mesh.update()
    o=bpy.data.objects.new(name,mesh)
    bpy.context.collection.objects.link(o)
    o=finish(o,name,mat,bone)
    bpy.context.view_layer.objects.active=o
    mod=o.modifiers.new('Forged thickness','SOLIDIFY')
    mod.thickness=thickness
    bpy.ops.object.modifier_apply(modifier=mod.name)
    bevel=o.modifiers.new('Forged edges','BEVEL')
    bevel.width=.006
    bevel.segments=2
    bpy.ops.object.modifier_apply(modifier=bevel.name)
    return o


def bevelbox(name, loc, scale, mat, bone='Root', radius=.02):
    bpy.ops.mesh.primitive_cube_add(size=1,location=loc)
    o=bpy.context.object
    o.scale=scale
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    mod=o.modifiers.new('Rounded forged edges','BEVEL')
    mod.width=radius
    mod.segments=3
    bpy.ops.object.modifier_apply(modifier=mod.name)
    return finish(o,name,mat,bone)


def base(faction):
    loft('Carved chess plinth',[(0,0,.0,.36,.36),(0,0,.025,.39,.39),(0,0,.06,.39,.39),(0,0,.09,.35,.35),(0,0,.115,.34,.34)],'iron',n=32)
    loft('Faction inlay',[(0,0,.06,.392,.392),(0,0,.074,.392,.392)],'blue' if faction=='alliance' else 'red',n=32)
    loft('Fine brass rim',[(0,0,.09,.356,.356),(0,0,.099,.356,.356)],'gold',n=32)


def skull(loc,size=.08,bone='Root'):
    x,y,z=loc
    ell('Skull',loc,(size,size*.55,size*1.1),'bone',bone)
    for side in [-1,1]:
        ell('Skull eye socket',(x+side*size*.35,y-size*.5,z+size*.1),(size*.22,.012,size*.23),'black',bone)
    for side in [-1,0,1]:
        rod('Skull teeth',(x+side*size*.25,y-size*.4,z-size*.5),(x+side*size*.25,y-size*.4,z-size*.85),size*.10,'bone',bone)


def face(orc=False,elf=False,arthas=False):
    flesh='orc' if orc else ('undead' if elf else 'skin')
    wide=.14 if orc else .103
    ell('Sculpted cranium',(0,0,1.19),(wide,.104,.14),flesh,'Head')
    ell('Jaw',(0,-.025,1.125),(wide*.89,.102,.075),flesh,'Head')
    ell('Nose bridge',(0,-.100,1.19),(.025,.035,.045),flesh,'Head')
    ell('Nose tip',(0,-.129,1.166),(.029,.018,.021),flesh,'Head')
    for side in [-1,1]:
        ell('Cheekbone',(side*wide*.65,-.085,1.16),(.037,.035,.039),flesh,'Head')
        ell('Eye recess',(side*.048,-.102,1.208),(.031,.015,.021),'iron','Head')
        ell('Eye',(side*.048,-.116,1.207),(.014,.009,.009),'black' if not elf else 'red','Head')
        rod('Brow',(side*.025,-.114,1.231),(side*.077,-.091,1.228),.012,flesh,'Head')
        if elf:
            rod('Elven ear',(side*.095,0,1.205),(side*.22,.015,1.30),.040,flesh,'Head',end=.002)
        else:
            ell('Ear',(side*wide,0,1.19),(.032,.025,.048),flesh,'Head')
        if orc:
            curve('Lower tusk',[(side*.063,-.112,1.105),(side*.080,-.146,1.125),(side*.086,-.147,1.17)],.015,'bone','Head')
    curve('Mouth',[(-.048,-.113,1.125),(0,-.126,1.128),(.048,-.113,1.125)],.005,'black','Head')


def rig():
    global RIG
    arm=bpy.data.armatures.new('Character skeleton')
    RIG=bpy.data.objects.new('Rig',arm)
    bpy.context.collection.objects.link(RIG)
    bpy.context.view_layer.objects.active=RIG
    RIG.select_set(True)
    bpy.ops.object.mode_set(mode='EDIT')
    bones={
        'Root':((0,0,.1),(0,0,.38),None),
        'Body':((0,0,.57),(0,0,1.02),'Root'),
        'Head':((0,0,1.03),(0,0,1.32),'Body'),
        'LeftLeg':((-.13,0,.59),(-.13,0,.30),'Body'),
        'RightLeg':((.13,0,.59),(.13,0,.30),'Body'),
        'LeftArm':((-.255,0,.91),(-.315,-.03,.61),'Body'),
        'RightArm':((.255,0,.91),(.315,-.03,.61),'Body'),
    }
    for name,(head,tail,parent) in bones.items():
        bone=arm.edit_bones.new(name)
        bone.head=head
        bone.tail=tail
        if parent:bone.parent=arm.edit_bones[parent]
    bpy.ops.object.mode_set(mode='OBJECT')
    RIG.select_set(False)


def body(orc=False,robe=False):
    rig()
    flesh='orc' if orc else 'skin'
    for side in [-1,1]:
        bone='LeftLeg' if side==-1 else 'RightLeg'
        ell('Thigh',(side*.13,0,.48),(.105,.11,.19),'leather',bone)
        ell('Calf',(side*.13,0,.27),(.078,.085,.13),'iron',bone)
        ell('Boot',(side*.13,-.046,.16),(.089,.155,.065),'leather',bone)
        ell('Knee plate',(side*.13,-.080,.36),(.082,.035,.095),'steel',bone)
        rod('Shin ridge',(side*.13,-.085,.19),(side*.13,-.085,.30),.018,'silver',bone)
    breadth=.235 if orc else .18
    loft('Anatomical torso',[(0,0,.55,.145,.104),(0,0,.66,.155,.11),(0,0,.83,breadth,.13),(0,0,.94,breadth*.76,.105),(0,0,1.015,.095,.09)],flesh if orc else 'iron','Body')
    ell('Neck',(0,0,1.025),(.071,.065,.072),flesh,'Head')
    for side in [-1,1]:
        bone='LeftArm' if side==-1 else 'RightArm'
        ell('Deltoid',(side*.255,0,.89),(.112,.115,.117),flesh,bone)
        ell('Bicep',(side*.29,-.01,.77),(.08,.078,.13),flesh,bone)
        ell('Forearm',(side*.32,-.035,.65),(.066,.073,.105),flesh,bone)
        ell('Bracer',(side*.325,-.035,.65),(.073,.08,.09),'leather' if orc else 'steel',bone)
        ell('Hand',(side*.32,-.07,.54),(.065,.047,.070),flesh,bone)
        for digit in range(4):
            rod('Finger',(side*.32-.025+digit*.017,-.10,.55),(side*.32-.025+digit*.017,-.105,.49),.008,flesh,bone)
    loft('Broad belt',[(0,0,.57,.166,.122),(0,0,.625,.174,.126)],'leather','Body')
    bevelbox('Belt buckle',(0,-.126,.601),(.078,.018,.05),'gold','Body',.007)
    if robe:
        loft('Fitted flowing robe',[(0,0,.15,.245,.20),(0,0,.33,.22,.17),(0,0,.56,.16,.12),(0,0,.72,.15,.113),(0,0,.86,.19,.123)],'blue','Body',n=24)
        for side in [-1,1]:
            plate('White robe panels',[(side*.04,-.20,.17),(side*.17,-.17,.17),(side*.075,-.13,.71),(side*.023,-.13,.71)],'white','Body')
            curve('Gold robe edging',[(side*.04,-.208,.17),(side*.04,-.168,.42),(side*.023,-.136,.71)],.008,'gold','Body')


def shoulders(orc=False,royal=False):
    for side in [-1,1]:
        ell('Curved pauldron',(side*.255,0,.946),(.155,.135,.12),'iron' if orc else 'steel','Body')
        curve('Pauldron raised rim',[(side*.14,-.07,.95),(side*.25,-.139,.943),(side*.385,-.06,.925)],.012,'gold' if royal else 'silver','Body')
        if orc or royal:
            for k in range(3):
                rod('Armour spike',(side*(.20+k*.060),.012,.997),(side*(.22+k*.07),.018,1.14-k*.023),.026,'bone' if orc else 'silver','Body',end=.001)
        else:
            for k in range(3):
                ell('Pauldron rivet',(side*(.18+k*.070),-.113,.94),(.009,.008,.009),'gold','Body')


def cloak(mat='blue',hood=False):
    # Curved cloth surface with folds instead of a flat rectangular block.
    verts=[]
    faces=[]
    for row in range(9):
        t=row/8
        z=.97-t*.76
        width=.12+t*.13
        for col in range(13):
            u=col/12*2-1
            y=.10+.075*t+.018*math.cos(u*math.pi*5)*t
            verts.append((u*width,y,z-.024*math.sin(u*math.pi*3)**2*t))
    for row in range(8):
        for col in range(12):
            i=row*13+col
            faces.append((i,i+1,i+14,i+13))
    mesh=bpy.data.meshes.new('Folded cloak')
    mesh.from_pydata(verts,[],faces)
    mesh.update()
    o=bpy.data.objects.new('Folded cloak',mesh)
    bpy.context.collection.objects.link(o)
    finish(o,'Folded cloak',mat,'Body')
    mod=o.modifiers.new('Cloth thickness','SOLIDIFY');mod.thickness=.009
    bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=mod.name)


def sword(at=(.33,-.12,.5),frost=False,bone='RightArm',length=.64):
    x,y,z=at
    rod('Leather sword grip',(x,y,z-.10),(x,y,z+.06),.026,'leather',bone)
    ell('Pommel',(x,y,z-.105),(.036,.026,.032),'gold',bone)
    curve('Swept crossguard',[(x-.15,y,z+.10),(x-.08,y,z+.075),(x,y,z+.09),(x+.08,y,z+.075),(x+.15,y,z+.10)],.022,'silver' if frost else 'gold',bone)
    plate('Forged blade',[(x-.048,y,z+.105),(x-.047,y,z+length*.82),(x,y,z+length),(x+.047,y,z+length*.82),(x+.048,y,z+.105)],'steel',bone,.025)
    curve('Blade fuller',[(x,y-.019,z+.16),(x,y-.019,z+length*.83)],.006,'ice' if frost else 'iron',bone)
    if frost:
        skull((x,y-.028,z+.11),.038,bone)
        for k in range(5):
            zz=z+.24+k*.064
            curve('Etched icy rune',[(x-.016,y-.020,zz),(x+.012,y-.020,zz+.016),(x-.009,y-.020,zz+.030)],.003,'ice',bone)
        for side in [-1,1]:
            curve('Frostmourne horn',[(x+side*.065,y,z+.11),(x+side*.11,y,z+.18),(x+side*.08,y,z+.24)],.012,'silver',bone)


def shield():
    coords=[(-.12,-.16,.84),(-.12,-.19,.68),(-.31,-.23,.41),(-.50,-.19,.68),(-.50,-.16,.84)]
    plate('Kite shield steel',coords,'silver','LeftArm',.036)
    c=Vector((-.31,-.207,.69))
    plate('Shield blue field',[tuple(c+(Vector(p)-c)*.85+Vector((0,-.02,0))) for p in coords],'blue','LeftArm')
    curve('Shield heraldic lion spine',[(-.31,-.239,.50),(-.31,-.239,.72),(-.28,-.239,.79)],.020,'gold','LeftArm')
    for side in [-1,1]:
        curve('Lion heraldry',[(-.31,-.240,.69),(-.31+side*.078,-.240,.75),(-.31+side*.055,-.240,.80)],.014,'gold','LeftArm')
        curve('Lion claw',[(-.31,-.240,.60),(-.31+side*.063,-.240,.58)],.013,'gold','LeftArm')


def axe():
    x=.335;y=-.12
    rod('Axe haft',(x,y,.34),(x,y,1.15),.026,'wood','RightArm')
    for z in [.47,.51,.55]:
        loft('Axe grip wrapping',[(x,y,z,.03,.03),(x,y,z+.018,.03,.03)],'leather','RightArm',n=10)
    for side in [-1,1]:
        plate('Crescent axe blade',[(x+side*.025,y,1.05),(x+side*.11,y,1.13),(x+side*.22,y,1.09),(x+side*.235,y,.95),(x+side*.15,y,.88),(x+side*.025,y,.98)],'steel','RightArm',.035)
        curve('Axe sharpened edge',[(x+side*.22,y-.025,1.09),(x+side*.235,y-.025,.95),(x+side*.15,y-.025,.88)],.009,'silver','RightArm')
    bevelbox('Axe head binding',(x,y,1.01),(.075,.067,.09),'iron','RightArm',.01)


def hair(long=False,braids=False):
    ell('Hair crown',(0,.012,1.30),(.117,.098,.065),'black' if braids else 'hair','Head')
    for side in [-1,1]:
        if braids:
            for k in range(7):
                ell('Braided hair',(side*.115,.013,1.23-k*.038),(.030,.036,.027),'black','Head')
            loft('Braid band',[(side*.115,.013,1.015,.032,.036),(side*.115,.013,1.035,.032,.036)],'gold','Head')
        elif long:
            for k in range(4):
                curve('Flowing hair strand',[(side*(.067+k*.019),.021,1.31),(side*(.096+k*.018),.049,1.17),(side*(.11+k*.015),.052,.99)],.016,'hair','Head')


def humanoid(kind):
    if kind == 'footman':
        author_footman(globals());return
    orc=kind in ['grunt','thrall']
    body(orc,kind=='jaina')
    if kind != 'footman':
        face(orc,kind=='sylvanas',kind=='arthas')
    if kind=='footman':
        # Match the supplied Warcraft III Footman reference: dark plate,
        # pointed full-face helmet, towering plume, layered broad shoulders.
        for o in OBJS:
            if any(t in o.name for t in ['Deltoid','Bicep','Forearm','Thigh','Anatomical torso']):
                o.data.materials.clear();o.data.materials.append(material('mail'))
        for o in OBJS:
            if any(t in o.name for t in ['Hand','Finger','Neck']):
                o.data.materials.clear();o.data.materials.append(material('leather' if 'Neck' not in o.name else 'mail'))
        loft('Pointed closed greathelm',[(0,0,1.085,.080,.09),(0,0,1.13,.125,.12),(0,0,1.26,.12,.105),(0,0,1.35,.068,.065),(0,0,1.39,.015,.021)],'plate','Head',n=12)
        for side in [-1,1]:
            plate('Long blue visor panel',[(side*.022,-.126,1.105),(side*.104,-.104,1.16),(side*.076,-.107,1.29),(side*.02,-.115,1.32)],'blue','Head')
            curve('Visor brass outline',[(side*.022,-.136,1.105),(side*.104,-.114,1.16),(side*.076,-.117,1.29),(side*.02,-.125,1.32)],.007,'gold','Head')
            bevelbox('Vertical black sight slit',(side*.012,-.137,1.23),(.012,.009,.15),'black','Head',.002)
        curve('Helmet central brass ridge',[(0,-.105,1.39),(0,-.128,1.32),(0,-.143,1.13)],.009,'gold','Head')
        loft('Plume brass socket',[(0,0,1.36,.041,.04),(0,0,1.41,.041,.04)],'gold','Head')
        for k in range(9):
            x=(k-4)*.014
            curve('Tall blue horsehair plume',[(x,.018,1.40),(x*1.4,.025,1.53),(x*.8,.052,1.65-abs(k-4)*.014)],.018,'blue','Head')
        loft('Dark forged cuirass',[(0,-.012,.65,.168,.125),(0,-.02,.78,.205,.145),(0,-.012,.91,.204,.135),(0,0,1.01,.105,.093)],'plate','Body',n=12)
        for z in [.73,.80,.87]:
            curve('Overlapping chest chevron',[(-.18,-.105,z+.04),(0,-.177,z-.036),(.18,-.105,z+.04)],.011,'silver','Body')
        for side in [-1,1]:
            for k in range(3):
                x=side*(.235+k*.024);z=.91-k*.055
                plate('Layered angular shoulder plates',[(side*.135,-.075,z+.09),(x,-.18,z+.075),(side*(.405+k*.016),-.12,z),(side*(.39+k*.016),.065,z-.03),(side*.17,.105,z+.075)],'plate','Body',.025)
                curve('Shoulder swept bright rim',[(side*.135,-.085,z+.09),(x,-.19,z+.075),(side*(.405+k*.016),-.13,z)],.009,'silver','Body')
            for k in range(3):
                curve('Raised shoulder ribs',[(side*(.20+k*.055),-.13,.95),(side*(.22+k*.060),-.04,1.08),(side*(.23+k*.055),.07,.99)],.015,'steel','Body')
            leg='LeftLeg' if side==-1 else 'RightLeg'
            plate('Pointed blue greave',[(side*.13-.07,-.091,.32),(side*.13+.07,-.091,.32),(side*.13+.055,-.102,.19),(side*.13,-.125,.14),(side*.13-.055,-.102,.19)],'blue',leg)
            curve('Greave silver border',[(side*.13-.07,-.106,.32),(side*.13,-.127,.35),(side*.13+.07,-.106,.32),(side*.13,-.141,.14),(side*.13-.07,-.106,.32)],.009,'steel',leg)
            plate('Blue folded hip cloth',[(side*.06,-.13,.59),(side*.17,-.12,.60),(side*.22,-.09,.40),(side*.10,-.12,.44)],'blue','Body')
        plate('Brass lion belt escutcheon',[(-.11,-.146,.64),(.11,-.146,.64),(.082,-.153,.53),(0,-.166,.48),(-.082,-.153,.53)],'gold','Body')
        plate('Blue belt escutcheon',[(-.087,-.16,.626),(.087,-.16,.626),(.061,-.167,.54),(0,-.18,.507),(-.061,-.167,.54)],'blue','Body')
        skull((0,-.184,.574),.037,'Body')
        shield();sword()
    elif kind=='grunt':
        shoulders(True)
        hair(braids=True)
        # Exposed green chest with crossed leather harness.
        for side in [-1,1]:
            curve('Chest harness',[(side*.16,-.13,.93),(side*.04,-.145,.74),(-side*.13,-.13,.60)],.021,'leather','Body')
        for k in range(9):
            angle=k*math.tau/9
            plate('Leather kilt strip',[(math.cos(angle)*.17,math.sin(angle)*.13,.59),(math.cos(angle+.5)*.17,math.sin(angle+.5)*.13,.59),(math.cos(angle+.5)*.19,math.sin(angle+.5)*.14,.38),(math.cos(angle)*.19,math.sin(angle)*.14,.40)],'red' if k%3==0 else 'leather','Body')
        axe()
    elif kind=='arthas':
        shoulders(False,True);hair(long=True);cloak('black')
        loft('Death knight breastplate',[(0,0,.64,.17,.12),(0,0,.83,.206,.148),(0,0,.94,.156,.13)],'iron','Body')
        skull((0,-.157,.81),.055,'Body')
        for side in [-1,1]:
            curve('Armour filigree',[(side*.06,-.155,.65),(side*.15,-.156,.77),(side*.08,-.142,.91)],.012,'silver','Body')
            skull((side*.27,-.118,.95),.047,'Body')
        for side in [-1,1]:
            plate('Death knight flared hip armour',[(side*.10,-.10,.63),(side*.20,-.11,.62),(side*.26,-.10,.37),(side*.12,-.12,.41)],'plate','Body')
            curve('Royal greave metal trim',[(side*.13-.055,-.10,.29),(side*.13,-.13,.36),(side*.13+.055,-.10,.29)],.009,'silver','LeftLeg' if side==-1 else 'RightLeg')
        sword((.34,-.13,.44),True,length=.89)
    elif kind=='thrall':
        shoulders(True,True);hair(braids=True);cloak('black')
        loft('Black plate chest',[(0,0,.64,.18,.12),(0,0,.86,.232,.145),(0,0,.94,.174,.12)],'iron','Body')
        skull((0,-.164,.81),.06,'Body')
        for side in [-1,1]:
            curve('Gold chest edging',[(side*.04,-.149,.67),(side*.18,-.159,.82),(side*.10,-.134,.94)],.014,'gold','Body')
        rod('Doomhammer handle',(.34,-.12,.37),(.34,-.12,1.10),.033,'wood','RightArm')
        bevelbox('Doomhammer head',(.34,-.12,1.09),(.31,.16,.20),'iron','RightArm',.026)
        for xx in [.205,.475]:bevelbox('Hammer iron binding',(xx,-.12,1.09),(.03,.18,.22),'silver','RightArm',.009)
        curve('Doomhammer rune',[(.31,-.207,1.04),(.35,-.207,1.12),(.38,-.207,1.055)],.009,'gold','RightArm')
    elif kind=='jaina':
        hair(long=True);cloak('white')
        for side in [-1,1]:
            ell('Mage shoulder cloth',(side*.235,0,.935),(.102,.095,.075),'white','Body')
            curve('Gold collar',[(side*.025,-.089,1.003),(side*.13,-.13,.91)],.009,'gold','Body')
        rod('Archmage staff',(.33,-.11,.16),(.33,-.11,1.36),.020,'gold','RightArm')
        for side in [-1,1]:curve('Staff crystal cradle',[(.33,-.11,1.21),(.33+side*.075,-.11,1.31),(.33+side*.056,-.11,1.43)],.011,'silver','RightArm')
        ell('Ice staff crystal',(.33,-.11,1.38),(.053,.045,.082),'ice','RightArm',seg=8,rings=4)
        ell('Belt sapphire',(0,-.14,.62),(.026,.012,.031),'ice','Body')
    elif kind=='sylvanas':
        cloak('purple');hair(long=True)
        loft('Ranger cuirass',[(0,0,.64,.14,.11),(0,0,.81,.175,.13),(0,0,.91,.153,.11)],'purple','Body')
        for side in [-1,1]:
            plate('Ranger angular leg armour',[(side*.13-.07,-.10,.38),(side*.13+.07,-.10,.38),(side*.13+.05,-.10,.18),(side*.13,-.13,.13),(side*.13-.05,-.10,.18)],'purple','LeftLeg' if side==-1 else 'RightLeg')
        # Hood composed of a shell around the visible face.
        for side in [-1,1]:
            curve('Hood edge',[(side*.13,.0,1.12),(side*.14,-.01,1.29),(side*.08,-.025,1.37),(0,-.045,1.39)],.025,'purple','Head')
            plate('Hood cloth',[(side*.13,.02,1.10),(side*.15,.04,1.30),(0,.07,1.39),(0,.11,1.13)],'purple','Head')
            ell('Ranger pauldron',(side*.25,0,.94),(.11,.10,.075),'silver','Body')
            rod('Pauldron horn',(side*.25,0,.98),(side*.34,0,1.10),.025,'silver','Body',end=.001)
            curve('Cuirass edging',[(side*.05,-.123,.65),(side*.14,-.134,.82),(side*.06,-.112,.91)],.009,'silver','Body')
        curve('Recurve bow',[(-.34,-.17,.19),(-.48,-.19,.37),(-.38,-.19,.58),(-.35,-.19,.71),(-.48,-.19,.98),(-.35,-.17,1.24)],.021,'iron','LeftArm')
        rod('Bowstring',(-.34,-.17,.19),(-.35,-.17,1.24),.003,'bone','LeftArm')
        for z in [.38,.99]:ell('Bow jewel',(-.47,-.19,z),(.026,.028,.04),'red','LeftArm')
        rod('Quiver',(.13,.17,.61),(.13,.17,1.07),.055,'leather','Body')
        for k in range(3):rod('Arrow',(.10+k*.025,.17,.73),(.10+k*.025,.17,1.17),.005,'wood','Body')


def wing(name,side,dragon=False):
    bone='Root'
    # Ribbed silhouette with tapered individual feathers or web membranes.
    shoulder=(side*.10,.07,.70)
    elbow=(side*.36,.10,1.12)
    tip=(side*.49,.05,1.38)
    rod(name+' leading bone',shoulder,elbow,.035,'stone' if dragon else 'feather')
    rod(name+' wingtip',elbow,tip,.024,'stone' if dragon else 'feather',end=.005)
    if dragon:
        for k in range(4):
            end=(side*(.49-k*.095),.11,.54+k*.05)
            rod('Membrane finger',elbow,end,.011,'iron',end=.002)
            plate('Bat wing membrane',[elbow,end,(side*(.40-k*.09),.08,.58+k*.05)],'purple',thickness=.006)
    else:
        for k in range(9):
            start=(side*(.18+k*.032),.09,.87+k*.039)
            end=(side*(.37+k*.017),.08,.56+k*.068)
            rod('Flight feather',start,end,.025,'bone' if k%3==0 else 'feather',end=.004,n=8)


def creature(kind):
    dragon=kind=='gargoyle'
    color='stone' if dragon else 'leather'
    ell('Creature torso',(0,0,.57),(.15,.24,.21),color)
    ell('Arched neck',(0,-.16,.79),(.09,.11,.23),color)
    ell('Creature head',(0,-.20,1.02),(.11,.12,.10),color)
    for side in [-1,1]:
        ell('Bright eye',(side*.070,-.285,1.055),(.019,.010,.015),'green' if dragon else 'gold')
        rod('Leg',(side*.10,.09,.46),(side*.15,-.015,.23),.040,color)
        for digit in [-1,0,1]:rod('Talon',(side*.15,-.02,.23),(side*.15+digit*.03,-.10,.15),.014,'bone',end=.001)
        wing('Wing',side,dragon)
        if dragon:
            curve('Gargoyle horn',[(side*.06,-.14,1.085),(side*.12,-.09,1.20),(side*.085,-.11,1.29)],.019,'iron')
        else:
            curve('Hippogryph antler',[(side*.07,-.14,1.08),(side*.12,-.11,1.26),(side*.15,-.15,1.35)],.018,'bone')
            rod('Antler tine',(side*.12,-.11,1.24),(side*.22,-.13,1.27),.012,'bone',end=.001)
    if dragon:
        ell('Snout',(0,-.295,.99),(.060,.074,.04),'stone')
        for side in [-1,1]:rod('Fang',(side*.04,-.34,.99),(side*.038,-.345,.95),.010,'bone',end=.001)
    else:
        rod('Eagle beak',(0,-.27,1.015),(0,-.42,.95),.051,'gold',end=.005)
    curve('Tail',[(0,.15,.52),(0,.30,.54),(0,.34,.72),(0,.28,.86)],.025,color)


def weapon(kind):
    if kind=='frostmourne':
        loft('Frozen sword pedestal',[(0,0,.12,.20,.18),(0,0,.25,.15,.13),(0,0,.33,.07,.09)],'ice',n=7)
        sword((0,0,.42),True,'Root',1.02)
    else:
        rod('Glaive display spine',(0,.02,.13),(0,.02,.85),.025,'iron')
        for side in [-1,1]:
            # Crescent silhouette, positioned diagonally as the two glaives.
            c=[]
            for k in range(13):
                a=-1.3+k/12*2.6
                c.append((side*(.04+.35*math.sin(a)),0,.78+.37*math.cos(a)))
            for k in reversed(range(13)):
                a=-1.3+k/12*2.6
                c.append((side*(.04+.28*math.sin(a)),0,.78+.24*math.cos(a)))
            plate('Azzinoth crescent blade',c,'steel',thickness=.024)
            curve('Green glaive inlay',[(side*(.04+.31*math.sin(a)),-.016,.78+.30*math.cos(a)) for a in [-1.15,-.7,0,.7,1.15]],.010,'green')
            skull((side*.06,-.037,.81),.044)
        rod('Glaive grip',(-.12,-.01,.78),(.12,-.01,.78),.025,'leather')


def tower(orc=False):
    if orc:
        for side in [-1,1]:
            for y in [-.19,.19]:rod('Timber tower support',(side*.23,y,.12),(side*.19,y,.98),.045,'wood',n=8)
        for z in [.30,.58,.87]:
            for y in [-.19,.19]:rod('Timber crossbeam',(-.23,y,z),(.23,y,z+.13),.025,'wood',n=8)
        bevelbox('Watch platform',(0,0,.99),(.54,.48,.08),'wood')
        for side in [-1,1]:
            for y in [-.22,.22]:rod('Tower spike',(side*.26,y,.97),(side*.31,y,1.31),.04,'bone',end=.001)
        loft('Orc red canopy',[(0,0,1.09,.35,.30),(0,0,1.26,.24,.21),(0,0,1.44,.015,.015)],'red',n=8)
        for side in [-1,1]:curve('Roof horn',[(side*.25,0,1.16),(side*.32,0,1.30),(side*.34,0,1.41)],.022,'bone')
        skull((0,-.275,1.105),.055)
    else:
        bevelbox('Stone keep shaft',(0,0,.59),(.48,.44,.93),'stone',radius=.012)
        for z in [.27,.46,.65,.84]:
            bevelbox('Stone course',(0,0,z),(.497,.457,.017),'iron',radius=.004)
        for z in [.40,.77]:
            for x in [-.25,.25]:rod('Mortar vertical seam',(x,-.225,z-.12),(x,-.225,z+.04),.006,'iron')
        bevelbox('Crenellation ledge',(0,0,1.04),(.57,.53,.11),'silver')
        for x in [-.23,0,.23]:
            for y in [-.22,.22]:bevelbox('Battlement',(x,y,1.15),(.13,.13,.16),'stone',radius=.010)
        for x in [-.23,.23]:bevelbox('Side battlement',(x,0,1.15),(.13,.13,.16),'stone',radius=.010)
        for z in [.55,.85]:
            bevelbox('Arrow slit',(0,-.226,z),(.040,.012,.105),'black',radius=.014)
        plate('Alliance tower banner',[(-.10,-.242,.93),(.10,-.242,.93),(.10,-.242,.67),(0,-.242,.60),(-.10,-.242,.67)],'blue')
        rod('Banner gold mark',(0,-.260,.69),(0,-.260,.88),.013,'gold')


def join_meshes():
    bpy.ops.object.select_all(action='DESELECT')
    for o in OBJS:
        if RIG:
            bone=BIND[o.name]
            vg=o.vertex_groups.new(name=bone)
            vg.add(list(range(len(o.data.vertices))),1,'REPLACE')
        o.select_set(True)
    bpy.context.view_layer.objects.active=OBJS[0]
    bpy.ops.object.join()
    mesh=bpy.context.object
    mesh.name='CharacterMesh'
    if CURRENT in KINDS[1:6]:
        def proportions(z):
            if z<.12:return z
            if z<.60:return .12+(z-.12)*1.25
            if z<1.06:return z+.12
            return 1.18+(z-1.06)*.82
        for v in mesh.data.vertices:
            co=mesh.matrix_world@v.co;co.z=proportions(co.z);v.co=mesh.matrix_world.inverted()@co
        bpy.context.view_layer.objects.active=RIG;bpy.ops.object.mode_set(mode='EDIT')
        for b in RIG.data.edit_bones:b.head.z=proportions(b.head.z);b.tail.z=proportions(b.tail.z)
        bpy.ops.object.mode_set(mode='OBJECT');bpy.context.view_layer.objects.active=mesh
    # UVs are authored once per generated model; textures remain embedded.
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=1.15,island_margin=.015)
    bpy.ops.object.mode_set(mode='OBJECT')
    if RIG:
        mod=mesh.modifiers.new('Character skin','ARMATURE');mod.object=RIG
        mesh.parent=RIG
    STATS[CURRENT]={'vertices':len(mesh.data.vertices),'triangles':sum(len(p.vertices)-2 for p in mesh.data.polygons),'rigged':bool(RIG)}
    return mesh


def animations():
    if not RIG:return
    RIG.animation_data_create()
    def action(name,length,loop=False):
        a=bpy.data.actions.new(name)
        RIG.animation_data.action=a
        for bone in RIG.pose.bones:
            bone.rotation_mode='XYZ';bone.rotation_euler=(0,0,0)
        if name=='walk':
            for f in range(0,25,3):
                phase=f/24*math.tau
                for limb in ['LeftLeg','RightLeg','LeftArm','RightArm']:
                    b=RIG.pose.bones[limb]
                    amp=.32 if 'Leg' in limb else .20
                    b.rotation_euler.x=math.sin(phase)*amp*(1 if limb.startswith('Left') else -1)
                    b.keyframe_insert('rotation_euler',frame=f)
        elif name=='attack':
            for f,rx in [(0,0),(8,-.60),(14,1.40),(25,0)]:
                b=RIG.pose.bones['RightArm'];b.rotation_euler.x=rx;b.keyframe_insert('rotation_euler',frame=f)
        else:
            for b in RIG.pose.bones:b.keyframe_insert('rotation_euler',frame=0);b.keyframe_insert('rotation_euler',frame=1)
        track=RIG.animation_data.nla_tracks.new();track.name=name
        strip=track.strips.new(name,0,a)
        RIG.animation_data.action=None
        for b in RIG.pose.bones:b.rotation_euler=(0,0,0)
        return a
    action('walk',24,True);action('attack',25);action('idle',1)


def preview(mesh):
    # Render each sculpture under a neutral studio light for visual inspection.
    scene=bpy.context.scene
    scene.render.engine='CYCLES';scene.cycles.samples=64;scene.cycles.use_denoising=False
    scene.render.resolution_x=540;scene.render.resolution_y=720;scene.render.resolution_percentage=100
    scene.world.color=(.18,.18,.18)
    scene.view_settings.view_transform='AgX'
    bpy.ops.object.camera_add(location=(1.1,-5.0,2.0))
    cam=bpy.context.object;cam.rotation_euler=(Vector((0,0,.75))-cam.location).to_track_quat('-Z','Y').to_euler()
    cam.data.type='ORTHO';cam.data.ortho_scale=1.95;scene.camera=cam
    for loc,energy,size in [((2,-3,4),180,4),((-3,-1,2),100,3),((0,2,3),140,3)]:
        bpy.ops.object.light_add(type='AREA',location=loc)
        o=bpy.context.object;o.data.energy=energy;o.data.shape='DISK';o.data.size=size
        o.rotation_euler=(Vector((0,0,.7))-o.location).to_track_quat('-Z','Y').to_euler()
    bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,-.006))
    plane=bpy.context.object;plane.data.materials.append(material('iron'))
    scene.render.filepath=str(OUT/(CURRENT+'-preview.png'))
    bpy.ops.render.render(write_still=True)


exec((ROOT/'tools/sculpt_detail.py').read_text(),globals())
face=lambda orc=False,elf=False,arthas=False:author_face(globals(),orc,elf,arthas)
ordinary_sword=sword
sword=lambda at=(.33,-.12,.5),frost=False,bone='RightArm',length=.64:author_frostmourne(globals(),at,frost,bone,length)

KINDS=['footman','grunt','arthas','thrall','jaina','sylvanas','hippogryph','gargoyle','frostmourne','warglaives','human_tower','orc_tower']
selected=sys.argv[sys.argv.index('--only')+1] if '--only' in sys.argv else None
for CURRENT in KINDS:
    if selected and CURRENT != selected:continue
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
    OBJS=[];BIND={};RIG=None
    base('alliance' if CURRENT in ['footman','arthas','jaina','hippogryph','frostmourne','human_tower'] else 'horde')
    if CURRENT in KINDS[:6]:
        humanoid(CURRENT);enrich_character(globals(),CURRENT)
    elif CURRENT in ['hippogryph','gargoyle']:
        creature(CURRENT);enrich_creature(globals(),CURRENT)
    elif CURRENT in ['frostmourne','warglaives']:weapon(CURRENT)
    else:
        tower(CURRENT=='orc_tower');enrich_tower(globals(),CURRENT=='orc_tower')
    mesh=join_meshes();animations()
    bpy.ops.object.select_all(action='DESELECT');mesh.select_set(True)
    if RIG:RIG.select_set(True)
    bpy.context.scene.render.fps=50
    bpy.ops.export_scene.gltf(filepath=str(OUT/(CURRENT+'.glb')),export_format='GLB',use_selection=True,export_animations=True,export_animation_mode='NLA_TRACKS',export_force_sampling=True,export_frame_range=False,export_nla_strips=True,export_materials='EXPORT',export_yup=True)
    if '--preview' in sys.argv and True:preview(mesh)
(OUT/'model_stats.json').write_text(json.dumps(STATS,indent=2))
print('MODEL_BUILD_COMPLETE',json.dumps(STATS))
