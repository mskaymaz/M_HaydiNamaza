import json
import re

# Orijinal dosyayı oku
with open('fikih.json', 'r', encoding='utf-8') as f:
    content = f.read()

# Tüm array bloklarını bul
array_blocks = re.findall(r'\[.*?\]', content, re.DOTALL)

all_objects = []
for block in array_blocks:
    try:
        obj_list = json.loads(block)
        all_objects.extend(obj_list)
    except json.JSONDecodeError as e:
        print(f"Hata: {block[:200]}... - {e}")

# Tüm objeleri tek array'e çevir
final_json = json.dumps(all_objects, ensure_ascii=False, indent=2)

# Yeni dosyaya yaz
with open('fikih_fixed.json', 'w', encoding='utf-8') as f:
    f.write(final_json)

print(f"Toplam {len(all_objects)} kayıt işlendi.")