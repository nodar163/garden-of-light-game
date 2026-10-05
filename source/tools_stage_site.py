"""Stage only public game files and a reproducible source snapshot for GitHub."""
from pathlib import Path
import shutil

root = Path(__file__).parent
target = root/'github-pages-site'
assert (target/'.git').is_dir(), 'Expected the existing GitHub Pages checkout'
for item in (root/'web-site'/'dist').iterdir():
    if item.is_file() and not item.name.endswith('.import'):
        shutil.copy2(item, target/item.name)
source = target/'source'
source.mkdir(exist_ok=True)
for folder, patterns in {'scripts':['*.gd','*.uid'], 'levels':['*.json'], 'match_levels':['*.json'],
                         'tests':['*.gd','*.uid'], 'assets':['*.svg','*.wav','*.png'],
                         'docs':['*.md','*.csv']}.items():
    (source/folder).mkdir(exist_ok=True)
    for pattern in patterns:
        for item in (root/folder).glob(pattern):
            shutil.copy2(item, source/folder/item.name)
for name in ['project.godot','main.tscn','export_presets.cfg','README.md','tools.ps1',
             'tools_build_assets.py','tools_more_levels.py','tools_expansion.py','tools_web.py','tools_nature_audio.py','tools_garden_music.py']:
    shutil.copy2(root/name,source/name)
(source/'.gitignore').write_text('.godot/\n.tools/\nartifacts/\nandroid/\nweb-site/\n*.import\n*.keystore\n*.jks\n.env\nexport_credentials.cfg\n',encoding='utf-8')
(source/'docs'/'.gdignore').write_text('',encoding='utf-8')
(target/'.gitignore').write_text('*.import\n.gdignore\n',encoding='utf-8')
print('Staged public build and allowlisted source files. No credentials or tools copied.')
