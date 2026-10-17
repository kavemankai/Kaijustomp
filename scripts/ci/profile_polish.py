"""Run the rendered route and sample process-tree RSS; no Android claims."""
import argparse,json,subprocess,time
from pathlib import Path
import psutil
p=argparse.ArgumentParser();p.add_argument('--godot',required=True);p.add_argument('--project',default='.');p.add_argument('--seconds',type=float,default=900);p.add_argument('--output',required=True);a=p.parse_args()
project=Path(a.project).resolve();out=Path(a.output);out.parent.mkdir(parents=True,exist_ok=True)
log=out.with_suffix('.log')
peak=0
with log.open('w',encoding='utf-8') as f:
    proc=subprocess.Popen([str(Path(a.godot).resolve()),'--path',str(project),'--rendering-method','gl_compatibility','--script','res://scripts/ci/profile_polish.gd','--',f'--seconds={a.seconds}'],stdout=f,stderr=subprocess.STDOUT)
    while proc.poll() is None:
        try:
            tree=psutil.Process(proc.pid);rss=sum(x.memory_info().rss for x in [tree,*tree.children(recursive=True)] if x.is_running());peak=max(peak,rss)
        except psutil.Error: pass
        time.sleep(.2)
    if proc.returncode: raise SystemExit(proc.returncode)
text=log.read_text()
if 'SCRIPT ERROR' in text or '\nERROR:' in text: raise SystemExit('Engine errors in '+str(log))
report=json.loads((project/'build/polish-evidence/profile.json').read_text());report['peak_process_tree_rss_bytes']=peak
report['limitations']+=' RSS sampled every 200ms across Godot console/game processes; driver allocations and brief spikes may differ.'
out.write_text(json.dumps(report,indent=2)+'\n');print(out,report['frame_ms'], 'peak_RSS_MiB',round(peak/1048576,1))
