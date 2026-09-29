"""Print per-app CI result and failure annotations for a workflow run. usage: ci_status.py RUN_ID [maxchars]"""
import json, sys, urllib.request
R = sys.argv[1]; N = int(sys.argv[2]) if len(sys.argv) > 2 else 2500
def get(u):
    return json.load(urllib.request.urlopen('https://api.github.com/repos/umesh1912/Hisaab/' + u))
jobs = get(f'actions/runs/{R}/jobs?per_page=50')['jobs']
for j in jobs:
    if not j['name'].startswith('build'): continue
    failed = [s['name'] for s in j['steps'] if s['conclusion'] == 'failure']
    print(f"{j['name']:<22} {j['status']:<11} {j['conclusion']} {failed}")
for j in jobs:
    if j['conclusion'] != 'failure': continue
    print('\n=====', j['name'])
    for a in get(f"check-runs/{j['id']}/annotations"):
        if a['annotation_level'] == 'failure' and 'exit code' not in a['message']:
            print('--', a['message'][:N])
