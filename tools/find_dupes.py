import os, re, sys

src = 'c:/Users/mikew/source/repos/Achaea/LEVI-Achaea/src_new'
delete = '--delete' in sys.argv

seen = {}  # key -> list of (path, content)
dupes_to_remove = []
code_differs = []

for root, dirs, files in os.walk(src):
    for f in sorted(files):
        if not f.endswith('.lua'):
            continue
        path = os.path.join(root, f)
        try:
            with open(path, 'r', encoding='utf-8') as fh:
                content = fh.read()
        except:
            continue

        # Extract name from YAML header
        m = re.search(r"name:\s*['\"]?(.*?)['\"]?\s*\n", content)
        if not m:
            continue
        name = m.group(1).strip()

        # Extract hierarchy
        h = re.findall(r'^- (.+)$', content, re.MULTILINE)
        hierarchy = '|'.join(h)

        # Extract code (after YAML header)
        code_match = re.search(r'\]\]--\s*\n(.*)', content, re.DOTALL)
        code = code_match.group(1).strip() if code_match else ''

        key = f'{name}|||{hierarchy}'
        if key not in seen:
            seen[key] = [(path, code)]
        else:
            # Check if code matches
            existing_code = seen[key][-1][1]
            if code == existing_code:
                # Same code — mark earlier one for removal, keep latest
                dupes_to_remove.append(seen[key][-1][0] if path > seen[key][-1][0] else path)
                if path > seen[key][-1][0]:
                    seen[key].append((path, code))
            else:
                code_differs.append((name, hierarchy, seen[key][-1][0], path))

print(f'Exact duplicates (same name + hierarchy + code): {len(dupes_to_remove)}')
if code_differs:
    print(f'\nSame name + hierarchy but DIFFERENT code: {len(code_differs)}')
    for name, hier, p1, p2 in code_differs[:20]:
        print(f'  {name}')
        print(f'    {os.path.basename(p1)} vs {os.path.basename(p2)}')

if delete and dupes_to_remove:
    print(f'\nDeleting {len(dupes_to_remove)} duplicate files...')
    for p in dupes_to_remove:
        os.remove(p)
        print(f'  Deleted: ...{p[-60:]}')
    print(f'\nDone. Removed {len(dupes_to_remove)} files.')
elif dupes_to_remove:
    print(f'\nRun with --delete to remove them.')
    # Show first 10
    for p in dupes_to_remove[:10]:
        print(f'  Would remove: ...{p[-60:]}')
    if len(dupes_to_remove) > 10:
        print(f'  ... and {len(dupes_to_remove) - 10} more')
