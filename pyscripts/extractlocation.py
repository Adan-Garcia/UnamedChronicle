
import json
import sys

def build_hierarchy(json_path):
    with open(json_path, encoding='utf-8') as f:
        data = json.load(f)
    mp = data['map']

    # Extract lists, skipping placeholders
    empires_list = mp['states']
    sectors_list = [p for p in mp['provinces'] if isinstance(p, dict)]
    towns_list = [b for b in mp['burgs'] if 'cell' in b ]
    cell2prov_str = mp['cellprovinces']  # keys are strings, values are sector IDs (ints)
    empire_names = []
    # Build empire map
    empire_map = {
        s['i']: {
            'id': s['i'],
            'name': s.get('name', s.get('name')),
            'x': s['pole'][0],
            'y': s['pole'][1],
            'area': s['area'],
            'neighbors':s['neighbors'],
            'urban':s['urban'],
            'rural':s['rural'],
            'diplomacy':s['diplomacy'],
            'sectors': []
        }
        for s in empires_list if 'pole' in s
    }

    # Build sector map
    sector_map = {
        p['i']: {
            'id': p['i'],
            'name': p.get('name', p.get('name')),
            'x': p['pole'][0],
            'y': p['pole'][1],
            'towns': []
        }
        for p in sectors_list
    }

    # Attach sectors to empires
    for s in empires_list:
        sid = s['i']
        for pid in s.get('provinces', []):
            if pid in sector_map:
                empire_map[sid]['sectors'].append(sector_map[pid])
    for s in empires_list:
       empire_names.append(s['name'])


    # Attach towns to sectors via cell -> sector mapping
    for t in towns_list:
        # settlement cell index -> sector id
        prov_id = cell2prov_str.get(str(t['cell']))
        if prov_id in sector_map:
            sector_map[prov_id]['towns'].append({
                'id': t['i'],
                'name': t['name'],
                'x': t['x'],
                'y': t['y'],
                'capital': t['capital'],
                'culture': t['culture'],
                'population': t['population']

            })

    # Return final hierarchy as a list
    main = {
        'Empires' : list(empire_map.values()),
        'EmpireList' : empire_names
    }
    
    return main

if __name__ == '__main__':
    

    hierarchy = build_hierarchy('Tigyia Minimal 2025-05-01-10-00.json ')
   
    with open('heirarchy.json', 'w') as f:
        f.write(json.dumps(hierarchy, indent=2))
