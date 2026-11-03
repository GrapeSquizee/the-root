import { readFileSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const dataDir = join(dirname(fileURLToPath(import.meta.url)), '..', 'data');
const fantasy = JSON.parse(readFileSync(join(dataDir, 'fantasy.json'), 'utf8'));

function familiar(id, name, english, note, clues, steps) {
  return {
    entity_id: id,
    name_ko: name,
    name_en: english,
    scientific_name: '익숙한 세계의 표본',
    max_depth: steps.length,
    start_depth: 1,
    complete_bonus: 30,
    field_note: note,
    quick_clues: clues,
    path: steps.map(([correct]) => correct),
    steps: steps.map(([correct, distractor], index) => ({
      correct_category_id: correct,
      distractor_category_id: distractor,
      base_score: 10 + index * 10,
      is_final: index === steps.length - 1,
    })),
  };
}

const dog = familiar('dog', '강아지', 'Dog',
  '밥을 먹고 잠을 자며, 상처가 나면 스스로 아문다. 사람을 따라 뛰어다닌다.',
  ['밥을 먹고 자라며 상처가 스스로 아문다.', '밥그릇의 먹이를 먹고 몸을 유지한다.'],
  [['living', 'crafted'], ['hunter', 'light_feeder']]);
const cat = familiar('cat', '고양이', 'Cat',
  '털로 덮인 몸을 스스로 움직인다. 어미 곁에서 어린 새끼가 젖을 먹는다.',
  ['먹고 자라며 몸을 스스로 움직인다.', '어미의 몸에서 자란 새끼가 태어난다.'],
  [['living', 'crafted'], ['live_bearing', 'egg_bearing']]);
const water = familiar('water', '물', 'Water',
  '잔에 담긴 투명한 액체. 스스로 자라거나 먹지 않으며, 그릇의 모양을 따라 흐른다.',
  ['스스로 먹거나 자라지 않는다.', '손에 담으면 흘러내리고 공간을 차지한다.'],
  [['non_living', 'living'], ['matter', 'crafted']]);
const platypus = familiar('platypus', '오리너구리', 'Platypus',
  '털이 있고 물속에서 먹이를 찾는다. 포유류처럼 젖을 먹이지만, 둥지에는 알을 남긴다.',
  ['스스로 자라고 상처를 회복한다.', '물속의 작은 동물을 잡아먹는다.', '어미가 둥지에 알을 낳는다.'],
  [['living', 'crafted'], ['hunter', 'light_feeder'], ['egg_bearing', 'live_bearing']]);

const unknown = Object.fromEntries(fantasy.entities.map(entity => [entity.entity_id, {
  ...entity,
  collectible: true,
}]));
const order = [dog, cat, water, unknown.moss_hart, unknown.ember_moth,
  unknown.glass_fox, platypus, unknown.echo_eel, unknown.mirror_hare,
  unknown.time_snail];
const data = {
  mode_id: 'descent',
  categories: {
    ...fantasy.categories,
    non_living: '살아 있지 않은 것',
    matter: '손에 닿는 물질',
  },
  plain_explanations: {
    ...fantasy.plain_explanations,
    non_living: '먹거나 자라지 않고 스스로 상처를 회복하지 않는다.',
    matter: '공간을 차지하고 담는 그릇에 따라 모양이 달라질 수 있다.',
  },
  entities: order,
};
writeFileSync(join(dataDir, 'descent.json'), JSON.stringify(data, null, 2) + '\n');
