"""Reproducible sculpted hero source. Run with Blender 3.6+ --background --python.

Coordinates in the design helpers are Godot metres, +Y up, -Z forward.
Cross-section lofts form continuous body/limb surfaces; palette is vertex colour.
Editable .blend masters stay outside Godot's import tree; checked-in GLBs ship.
"""
import bpy, math, os, json
from mathutils import Vector

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, 'assets', 'creature')
os.makedirs(OUT, exist_ok=True)
PAL = {'body':'238B83','light':'59BEA5','deep':'173E48','belly':'F2D69D',
       'coral':'ED8457','gold':'FFCD65','white':'FFF7D8','mouth':'472B49'}
def rgb(key):
    h = PAL.get(key,key)
    # Godot Compatibility uses sRGB vertex palette values for this material.
    return tuple(int(h[i:i+2],16)/255 for i in (0,2,4))+(1,)
def B(p): return (p[0],-p[2],p[1])

def build(upright):
    bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
    verts=[]; faces=[]; colors=[]; weights=[]
    anchors={'Root':(0,0,0),'Torso':(0,0,0),'Head':(0,1.13,-1.22),'Jaw':(0,.68,-2.17)}
    for i,(x,z) in enumerate([(-.78,-.87),(-.78,.94),(.78,-.87),(.78,.94)]):
        s=-1 if x<0 else 1
        anchors['Leg%d'%i]=(x,1,z)
        anchors['Knee%d'%i]=(x+s*.10,.45,z)
        anchors['Paw%d'%i]=(x+s*.17,.03,z-.19)
    for i in range(3): anchors['Tail%d'%i]=(0,.98-i*.13,1.24+i*.91)
    def v(p,c,w):
        verts.append(B(p)); colors.append(rgb(c)); weights.append(w); return len(verts)-1
    def loft(rings,n=16):
        # Each cross-section: centre, radius along X/Y, vertex-weight map.
        start=len(verts)
        for center,rx,ry,w in rings:
            for j in range(n):
                a=2*math.pi*j/n; sn=math.sin(a)
                c='belly' if sn<-.42 else ('deep' if sn>.92 else ('light' if -.42<=sn<.18 else 'body'))
                v((center[0]+math.cos(a)*rx,center[1]+sn*ry,center[2]),c,w)
        for k in range(len(rings)-1):
            for j in range(n):
                a=start+k*n+j;b=start+k*n+(j+1)%n
                faces.append((a,b,b+n,a+n))
        faces.append(tuple(start+j for j in reversed(range(n))))
        faces.append(tuple(start+(len(rings)-1)*n+j for j in range(n)))
    def ellipsoid(name,center,radii,color,bone,segments=12,rings=6):
        start=len(verts)
        for k in range(rings+1):
            t=math.pi*k/rings
            for j in range(segments):
                a=2*math.pi*j/segments
                v(tuple(center[q]+radii[q]*[math.sin(t)*math.cos(a),math.cos(t),math.sin(t)*math.sin(a)][q] for q in range(3)),color,{bone:1})
        for k in range(rings):
            for j in range(segments):
                a=start+k*segments+j;b=start+k*segments+(j+1)%segments
                faces.append((a,b,b+segments,a+segments))
    def fin(center,length,height,width,bone,color='coral'):
        x,y,z=center; start=len(verts)
        for p in [(x-width,y,z-length/2),(x+width,y,z-length/2),(x+width*.6,y,z+length/2),(x-width*.6,y,z+length/2),(x,y+height,z+length*.27)]: v(p,color,{bone:1})
        for f in [(0,1,4),(1,2,4),(2,3,4),(3,0,4),(0,3,2,1)]: faces.append(tuple(start+i for i in f))
    # Continuous torso, neck and wedge-shaped muzzle; weight the hip transition.
    torso=[(1.65,1.00,.27,.25),(1.26,1.04,.57,.42),(.72,1.08,.77,.49),
           (0,1.12,.83,.52),(-.72,1.16,.76,.49),(-1.16,1.20,.55,.37),
           (-1.47,1.26,.56,.35),(-1.85,1.23,.68,.36),(-2.22,1.10,.61,.27),
           (-2.72,1.02,.49,.22),(-2.94,1.02,.35,.17)]
    rs=[]
    for z,y,rx,ry in torso:
        if z> .7: w={'Root':min(1,(z-.7)/.8),'Torso':1-min(1,(z-.7)/.8)}
        elif z< -1.16: w={'Head':min(1,(-z-1.16)/.45),'Torso':1-min(1,(-z-1.16)/.45)}
        else: w={'Torso':1}
        if upright and z>-.9: rx*=1.19;ry*=1.13
        rs.append(((0,y,z),rx,ry,w))
    loft(rs,20)
    for k,z in enumerate([-1.04,-.60,-.15,.32,.79,1.16]):
        fin((0,1.57 if k<4 else 1.47,z),.46,.40 if k<4 else .28,.085,'Torso' if k<4 else 'Root')
    # Brow is an angular overhang; eyes point sideways and slightly forward.
    for s in [-1,1]:
        ellipsoid('socket',(s*.55,1.43,-1.86),(.18,.18,.24),'deep','Head')
        ellipsoid('eye',(s*.67,1.46,-1.95),(.075,.115,.14),'gold','Head')
        ellipsoid('pupil',(s*.726,1.47,-1.99),(.026,.083,.045),'deep','Head',8,4)
        ellipsoid('glint',(s*.745,1.51,-2.025),(.014,.022,.025),'white','Head',8,4)
        ellipsoid('brow',(s*.53,1.51,-1.88),(.23,.13,.29),'body','Head')
        ellipsoid('nostril',(s*.29,1.12,-2.84),(.075,.035,.055),'deep','Head',8,4)
    ellipsoid('jaw',(0,.73,-2.43),(.49,.14,.49),'belly','Jaw',16,6)
    ellipsoid('mouth',(0,.85,-2.44),(.43,.035,.43),'mouth','Jaw',16,4)
    for s in [-1,1]:
        for j in range(3): fin((s*.42,.85,-2.14-j*.22),.12,.14,.045,'Jaw','white')
    # Continuous bent limbs with blended elbow weights; feet stay articulated.
    for i,(x,z) in enumerate([(-.78,-.87),(-.78,.94),(.78,-.87),(.78,.94)]):
        s=-1 if x<0 else 1; hind=i%2==1
        bulk=1.32 if upright and hind else (0.87 if upright else 1)
        start=len(verts); n=12
        sections=[(1.07,.02,.29),(.83,.075,.32),(.55,.10,.24),(.35,.14,.17),(.14,.17,.16)]
        for k,(y,ox,r) in enumerate(sections):
            w={'Leg%d'%i:1} if k<2 else ({'Leg%d'%i:.35,'Knee%d'%i:.65} if k==2 else {'Knee%d'%i:1})
            for j in range(n):
                a=math.tau*j/n
                v((x+s*ox+math.cos(a)*r*bulk,y,z+math.sin(a)*r*.82-.03*k),'light' if j>6 else 'body',w)
        for k in range(4):
            for j in range(n):
                a=start+k*n+j;b=start+k*n+(j+1)%n;faces.append((a,a+n,b+n,b))
        faces.append(tuple(start+j for j in range(n)))
        faces.append(tuple(start+4*n+j for j in reversed(range(n))))
        ellipsoid('foot',(x+s*.17,.13,z-.23),(.29,.12,.36),'deep','Paw%d'%i,12,4)
        for j in range(3):
            # Flattened tapered claws, pointing forward.
            cx=x+s*.17+(j-1)*.19;start=len(verts)
            for p in [(cx-.065,.16,z-.43),(cx+.065,.16,z-.43),(cx+.045,.07,z-.43),(cx-.045,.07,z-.43),(cx,.085,z-.72)]:v(p,'white',{'Paw%d'%i:1})
            for f in [(0,1,4),(1,2,4),(2,3,4),(3,0,4)]: faces.append(tuple(start+a for a in f))
    tail=[]
    for k in range(13):
        z=1.26+k*.25; t=k/12; f=min(2,(z-1.24)/.91)
        lo=int(f);hi=min(2,lo+1);frac=f-lo
        w={'Tail%d'%lo:1-frac}
        if hi!=lo:w['Tail%d'%hi]=frac
        tail.append(((0,.98-.42*t,z),max(.025,.45*(1-t)**.8),max(.025,.32*(1-t)),w))
    loft(tail,12)
    for k in range(4):fin((0,1.23-k*.13,1.6+k*.52),.30,.22-k*.035,.055,'Tail%d'%min(2,k))
    mesh=bpy.data.meshes.new('SculptedSurface');mesh.from_pydata(verts,[],faces);mesh.update()
    obj=bpy.data.objects.new('SculptedHero',mesh);bpy.context.collection.objects.link(obj)
    attr=mesh.color_attributes.new(name='Palette',type='FLOAT_COLOR',domain='CORNER')
    for poly in mesh.polygons:
        poly.use_smooth=True
        for li in poly.loop_indices:attr.data[li].color=colors[mesh.loops[li].vertex_index]
    mat=bpy.data.materials.new('SatinPalette');mat.use_nodes=True
    bs=mat.node_tree.nodes.get('Principled BSDF');bs.inputs['Roughness'].default_value=.76
    vc=mat.node_tree.nodes.new('ShaderNodeVertexColor');vc.layer_name='Palette';mat.node_tree.links.new(vc.outputs['Color'],bs.inputs['Base Color']);obj.data.materials.append(mat)
    arm=bpy.data.armatures.new('CoastalCreatureRig');rig=bpy.data.objects.new('CreatureRig',arm);bpy.context.collection.objects.link(rig)
    bpy.context.view_layer.objects.active=rig;rig.select_set(True);bpy.ops.object.mode_set(mode='EDIT')
    for name,p in anchors.items():
        bone=arm.edit_bones.new(name);bone.head=B(p);bone.tail=B((p[0],p[1]+.3,p[2]))
    bpy.ops.object.mode_set(mode='OBJECT')
    for name in anchors:
        group=obj.vertex_groups.new(name=name)
        for i,w in enumerate(weights):
            if w.get(name,0)>0:group.add([i],w[name],'REPLACE')
    mod=obj.modifiers.new('Skin','ARMATURE');mod.object=rig;obj.parent=rig
    # Recalculate winding consistently, preserving deliberately smooth normals.
    bpy.context.view_layer.objects.active=obj;rig.select_set(False);obj.select_set(True)
    bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.mesh.normals_make_consistent(inside=False);bpy.ops.object.mode_set(mode='OBJECT')
    name='upright' if upright else 'quadruped'
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(os.path.dirname(__file__),name+'.blend'))
    bpy.ops.export_scene.gltf(filepath=os.path.join(OUT,name+'.glb'),export_format='GLB',export_yup=True,export_animations=False,export_skins=True)
    mesh.calc_loop_triangles()
    return {'form':name,'triangles':len(mesh.loop_triangles),'bones':len(anchors),'materials':len(mesh.materials),'vertices':len(verts)}

reports=[build(False),build(True)]
with open(os.path.join(OUT,'asset_budget.json'),'w') as f:json.dump(reports,f,indent=2)
print('CREATURE EXPORT COMPLETE',reports)
