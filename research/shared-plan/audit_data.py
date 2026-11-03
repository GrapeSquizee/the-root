import json
from pathlib import Path
from collections import Counter
import openpyxl

root = Path(__file__).resolve().parents[2]
d = json.loads((root/'docs/THE_ROOT_Vertical_Slice_DevData_v0.2.json').read_text(encoding='utf-8'))
w = openpyxl.load_workbook(root/'docs/THE_ROOT_Vertical_Slice_DevData_v0.2.xlsx', data_only=False)
def rows(name):
    values=list(w[name].values)
    return [dict(zip(values[3],v)) for v in values[4:] if v[0] is not None]
errors=[]
comparisons=0
def eq(label,a,b):
    global comparisons
    comparisons+=1
    if a!=b: errors.append({'check':label,'json':a,'xlsx_or_expected':b})
entities={e['entity_id']:e for e in d['entities']}
cats={c['category_id']:c for c in rows('Categories_Canon')}
for e in d['entities']:
    eq(e['entity_id']+' path length',len(e['path']),e['max_depth'])
    eq(e['entity_id']+' step length',len(e['steps']),e['max_depth'])
    eq(e['entity_id']+' bonus',e['complete_bonus'],{4:80,5:100,6:120}[e['max_depth']]+10*(e['difficulty']-1))
    for i,s in enumerate(e['steps']):
        label=f"{e['entity_id']}/D{i+1}"
        eq(label+' depth',s['depth'],i+1)
        eq(label+' path',s['correct_category_id'],e['path'][i])
        eq(label+' parent',s['parent_category_id'],e['path'][i-1] if i else 'root')
        eq(label+' final',s['is_final'],i==e['max_depth']-1)
        for key in ['parent_category_id','correct_category_id','distractor_category_id']:
            eq(label+' ref '+key,s[key] in cats,True)
        eq(label+' distinct',s['correct_category_id']!=s['distractor_category_id'],True)
for r in rows('Answer_Key_30'):
    e=entities[r['entity_id']]
    for k in ['name_ko','name_en','scientific_name','difficulty','max_depth','complete_bonus','observe_hint','design_role','source_url']:
        eq(r['entity_id']+'/'+k,e[k],r[k])
    for c in [1,2]:
        for k,sk in [('position','pos'),('start_depth','start_depth')]:
            eq(r['entity_id']+f'/cycle{c}/{k}',e[f'cycle{c}'][k],r[f'cycle{c}_{sk}'])
for r in rows('Question_Steps'):
    s=entities[r['entity_id']]['steps'][r['depth']-1]
    for jk,xk in [('parent_category_id','parent_category'),('correct_category_id','correct_category'),('distractor_category_id','distractor_category'),('base_score','base_score'),('is_final','is_final')]:
        eq(f"{r['entity_id']}/{r['depth']}/{jk}",s[jk],r[xk])
for c in [1,2]:
    rr=rows(f'Cycle_{c}')
    eq(f'cycle{c} sequence',d[f'cycle{c}'],[r['entity_id'] for r in rr])
    for r in rr:
        e=entities[r['entity_id']]
        eq(f"cycle{c}/{r['entity_id']}/start",e[f'cycle{c}']['start_depth'],r['start_depth'])
        eq(f"cycle{c}/{r['entity_id']}/valid",1<=r['start_depth']<=e['max_depth'],True)
for r in rows('HardMode_Attributes'):
    attrs={a['attribute_id']:a['value'] for a in entities[r['entity_id']]['hardmode_attributes']}
    eq(r['entity_id']+'/'+r['attribute_id'],attrs.get(r['attribute_id']),r['expected_value'])
items={i['item_id']:i for i in d['items']}
for r in rows('Items'):
    it=items[r['item_id']]; effect=it['effects'][r['level']]
    for k in ['effect_key','effect_value']:
        eq(f"{r['item_id']}/+{r['level']}/{k}",effect[k],r[k])
    for k in ['base_shop_price','mastery_event','mastery_required']:
        eq(r['item_id']+'/'+k,it[k],r[k])
for r in rows('Materials'):
    mat=next(m for m in d['materials'] if m['material_id']==r['material_id'])
    for k in mat: eq(r['material_id']+'/'+k,mat[k],r[k])
for r in rows('Upgrade_Costs'):
    u=d['upgrade_costs'][r['from_level']]
    for k in u: eq('upgrade/'+str(r['from_level'])+'/'+k,u[k],r[k])
for r in rows('Shop_Prices'):
    if r['level']<=4:
        eq(f"price/{r['item_id']}/{r['level']}",round(items[r['item_id']]['base_shop_price']*d['shop']['shop_price_level_multipliers'][str(r['level'])]),r['shop_price'])
eq('general level probability',sum(d['shop']['later_shop_equipment_level_probabilities'].values()),100)
eq('first level probability',sum(d['shop']['first_shop']['guaranteed_level_probabilities'].values()),100)
for s in d['shop']['slot_archetypes']: eq('slot probability '+str(s['slot']),sum(s[k] for k in ['equipment_pct','material_pct','unknown_fragment_pct']),100)
for c in rows('Categories_Canon'):
    if c['parent_id']: eq('category parent/'+c['category_id'],c['parent_id'] in cats,True)
missing_siblings=[]
for e in d['entities']:
    for s in e['steps']:
        if cats[s['distractor_category_id']]['parent_id']!=s['parent_category_id']:
            missing_siblings.append([e['entity_id'],s['depth'],s['parent_category_id'],s['distractor_category_id'],cats[s['distractor_category_id']]['parent_id']])
result={'sheets':{s.title:[s.max_row,s.max_column] for s in w},'entities':len(entities),'steps':sum(len(e['steps']) for e in d['entities']),'attributes':sum(len(e['hardmode_attributes']) for e in d['entities']),'categories':len(cats),'comparisons':comparisons,'mismatches':errors,'non_sibling_distractors':missing_siblings,'balance':rows('Balance'),'prices':rows('Shop_Prices'),'zero_effect_items':[{'item':i['item_id'],'effect':i['effects'][0]} for i in d['items']],'observe_allowed_counts':dict(Counter(r['observe_allowed'] for r in rows('Question_Steps')))}
(root/'research/shared-plan/data_audit.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps({k:v for k,v in result.items() if k not in ['sheets','prices']},ensure_ascii=False,indent=2))
