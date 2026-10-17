"""Compose actual Godot frames and fail if mandatory capture evidence is missing."""
import argparse, hashlib, json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
ROOT=Path(__file__).resolve().parents[2]
FORMS=['reptile','biomass','snake','bird','crab','spider','ape','worm','mole']
GENERIC=['armour','strength','speed','stamina','health','jaw','regen','cocoon','metamorphosis']
PAIRS=['reptile_bird','ape_crab','worm_mole','bird_spider','snake_biomass','ape_spider','reptile_crab','worm_biomass']
p=argparse.ArgumentParser();p.add_argument('--output',default='docs/evolution/polish_evidence');a=p.parse_args()
source=ROOT/'build/polish-captures';out=ROOT/a.output;out.mkdir(parents=True,exist_ok=True)
fontfile=Path('C:/Windows/Fonts/segoeui.ttf')
font=ImageFont.truetype(str(fontfile),18) if fontfile.exists() else ImageFont.load_default(size=18)
expected=[]
for host in FORMS:
    for rank in [0,6,12,18]:
        for angle in range(3):
            expected.extend([f'{host}_e{rank:02}_a{angle}',f'inspect_{host}_e{rank:02}_a{angle}'])
    expected.extend(f'upgrade_{host}_{key}_{tier}' for key in GENERIC for tier in [1,2,3])
expected.extend(f'{prefix}hybrid_{pair}_{stage}' for prefix in ['', 'inspect_'] for pair in PAIRS for stage in range(3))
source_ids=[1,2,6,7,9,11,12,14,15,19,20,22,29,30,36,39,42,43,44,47,49,52,57,58,61,62,72,73,81,84,85,88,90,95,99,100,119,121,122,180,441]
expected.extend(f'source_{n:03}' for n in source_ids)
actions=['action_flight','inspect_action_flight','action_snake_curve','inspect_action_snake_curve','action_spider_wall','inspect_action_spider_wall','action_spider_roof','ui_draft_20_9','ui_lineage_20_9']
actions += [f'action_{host}_dig_{i}' for host in ['worm','mole'] for i in range(3)]+[f'action_{host}_emerge' for host in ['worm','mole']]
expected+=actions
index_path=source/'capture-index.json'
if not index_path.exists(): raise SystemExit('Missing completed capture-run index')
capture_run=json.loads(index_path.read_text())
if set(capture_run['frames'])!=set(expected) or len(capture_run['frames'])!=len(expected):
    raise SystemExit('Completed capture-run index differs from mandatory 565-frame matrix')
missing=[name for name in expected if not (source/(name+'.png')).exists()]
if missing: raise SystemExit('Missing real-engine captures: '+', '.join(missing))
manifest=[]
for name in expected:
    path=source/(name+'.png');im=Image.open(path);im.verify()
    manifest.append(dict(file=path.name,bytes=path.stat().st_size,sha256=hashlib.sha256(path.read_bytes()).hexdigest()))
(out/'capture-manifest.json').write_text(json.dumps(dict(engine=capture_run['engine'],source_sha=capture_run['source_sha'],kind='actual gameplay scene and inspection cameras',count=len(manifest),frames=manifest),indent=2)+'\n')

def sheet(items,columns,name,title):
    w,h=290,345
    canvas=Image.new('RGB',(w*columns,h*((len(items)+columns-1)//columns)+42),'#19353b');d=ImageDraw.Draw(canvas)
    d.text((12,10),title,font=font,fill='#f0dfbc')
    for i,(path,label) in enumerate(items):
        x=(i%columns)*w;y=(i//columns)*h+42
        im=Image.open(path).convert('RGB');im.thumbnail((w-10,h-33))
        canvas.paste(im,(x+(w-im.width)//2,y+28));d.text((x+8,y+3),label,font=font,fill='white')
    canvas.save(out/(name+'.jpg'),quality=86,optimize=True)

def paths(names): return [(source/(stem+'.png'),label) for stem,label in names]
sheet(paths([(f'inspect_{f}_e00_a0',f.title()) for f in FORMS]),3,'nine-forms','Nine biological hosts / actual engine inspection')
sheet(paths([(f'inspect_{f}_e{r:02}_a1',f'{f.title()} E{r}') for f in FORMS for r in [0,6,12,18]]),4,'growth-36','Nine hosts x four physical ranks / side inspection')
sheet(paths([(f'inspect_hybrid_{pair}_{stage}',f'{pair.replace("_"," + ")} / {stage+1}') for pair in PAIRS for stage in range(3)]),3,'hybrids-24','Eight curated routes / acquisition, developing, mature')
for f in FORMS:
    sheet(paths([(f'upgrade_{f}_{key}_{tier}',f'{key} / rank {tier}') for key in GENERIC for tier in [1,2,3]]),3,'upgrades-'+f,f'{f.title()} / nine generic organs x three tiers')
sheet(paths([(f'source_{n:03}',f'Source #{n}') for n in source_ids]),5,'sources-41','41 executable source organs / live anterior views')
sheet(paths([(name,name.replace('action_','').replace('_',' ')) for name in actions if not name.startswith('ui_')]),4,'traversal','Actual physics state / controlled action fixtures')
for name in ['ui_draft_20_9','action_flight','action_snake_curve','action_spider_wall','action_spider_roof']:
    Image.open(source/(name+'.png')).convert('RGB').save(out/(name+'.jpg'),quality=90)
baseline=ROOT/'build/polish-baseline'
if (baseline/'inspect_reptile_e00_a0.png').exists():
    sheet([(directory/f'inspect_{f}_e00_a0.png',f'{f.title()} / {label}') for f in FORMS for directory,label in [(baseline,'baseline 1555b33'),(source,'polish')]],2,'baseline-comparison','Same inspection setup / baseline and polish geometry')
index=['# Actual Godot polish evidence','','These are Godot 4.5 engine frames, not concept art. Raw PNGs, SHA256 manifest and automated coverage CSV are retained with the Actions polish-evidence artifact.','',f'{len(manifest)} required frames: 108 gameplay + 108 inspection growth views, 243 generic tiers, 48 hybrid views, 41 source organs, 17 traversal/UI frames.','','Inspection cameras help assess anatomy; gameplay captures use the live camera. Action fixtures and QA growth do not establish natural progression, phone controls or Android FPS.','','| Evidence | Contact sheet |','|---|---|']
for name,label in [('nine-forms','Nine forms'),('growth-36','Growth 0/6/12/18'),('hybrids-24','Eight hybrid routes'),('sources-41','41 executable sources'),('traversal','Traversal physics states'),('baseline-comparison','Before/after 1555b33')]+[('upgrades-'+f,f.title()+' I/II/III') for f in FORMS]:
    if (out/(name+'.jpg')).exists(): index.append(f'| {label} | [{name}]({name}.jpg) |')
index+=['','[20:9 mutation cards](ui_draft_20_9.jpg) · [Capture manifest](capture-manifest.json)','','Reproduce: Godot 4.5 --path . --rendering-method gl_compatibility --script res://scripts/ci/capture_polish.gd; python scripts/ci/compose_polish_captures.py.']
(out/'README.md').write_text('\n'.join(index)+'\n',encoding='utf-8')
print(f'Verified and composed {len(manifest)} actual-engine frames in {out}')
