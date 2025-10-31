#!/usr/bin/env python3
import os
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
POSTS_DIR = ROOT / '_posts'
OUT_DIR = ROOT / 'content' / 'posts'
OUT_DIR.mkdir(parents=True, exist_ok=True)

md_file_re = re.compile(r'(?P<date>\d{4}-\d{2}-\d{2})-(?P<slug>.+)\.(md|markdown)$')

def process_file(p):
    m = md_file_re.match(p.name)
    if not m:
        print(f"Skipping non-post file: {p.name}")
        return
    date = m.group('date')
    slug = m.group('slug')
    out_name = slug + '.md'
    out_path = OUT_DIR / out_name

    text = p.read_text(encoding='utf-8')
    # Find YAML front matter
    if text.startswith('---'):
        parts = text.split('\n')
        # find end of front matter
        try:
            end_index = parts.index('---', 1)
        except ValueError:
            end_index = None
        if end_index:
            fm = '\n'.join(parts[1:end_index])
            rest = '\n'.join(parts[end_index+1:])
            if re.search(r'^date:\s*', fm, flags=re.MULTILINE):
                # already has date
                new_fm = fm
            else:
                new_fm = f'date: {date}\n' + fm
            new_text = '---\n' + new_fm + '\n---\n\n' + rest.strip() + '\n'
        else:
            # malformed front matter, create one
            body = text
            new_text = f'---\n' + f'date: {date}\n' + '---\n\n' + body
    else:
        # No front matter, create one
        body = text
        new_text = f'---\n' + f'date: {date}\n' + '---\n\n' + body

    out_path.write_text(new_text, encoding='utf-8')
    print(f'Wrote {out_path}')


def main():
    if not POSTS_DIR.exists():
        print('No _posts directory found; nothing to do.')
        return
    for p in POSTS_DIR.iterdir():
        if p.suffix.lower() in ('.md', '.markdown'):
            process_file(p)

if __name__ == '__main__':
    main()
