"""Original Redrock Falls authored geometry. No external game coordinates/assets."""
from pathlib import Path
R=Path(__file__).resolve().parents[1]
def vec(p):return 'Vector2(%s,%s)'%tuple(p)
def rect(r):return 'Rect2(%s)'%','.join(map(str,r))
def packed(p):return 'PackedVector2Array('+','.join(str(v) for xy in p for v in xy)+')'
legs=[(180,2),(500,4),(260,3),(620,4),(380,3),(620,3),(350,3),(650,3),(410,3),(730,4),(410,4),(650,3),(380,3),(560,2)]
x,y=300,435;route=[];plats=[];turns=[]
for end,n in legs:
 start=x
 for j in range(n):
  x=round(start+(end-start)*(j+1)/n,2);y-=60;route.append((x,y))
 turns.append(len(route)-1)
moving=[17,32]
for i,(x,y) in enumerate(route):
 if i not in moving:plats.append((x-84,y,168,16))
 if i in turns and i not in moving:plats.append((max(80,min(640,x-120)),y,240,16))
 # Irregular catch ledges covering nearby route, with a thin readable top.
 if i%4==3 and i not in moving:
  near=route[max(0,i-2):min(len(route),i+3)]
  l=max(80,min(p[0] for p in near)-95);r=min(880,max(p[0] for p in near)+95)
  width=min(340,r-l);l=max(80,min(880-width,x-width/2));plats.append((l,y,width,16))
# Fixed waiting/recovery surfaces under both ferries.
for i in moving:
 px,py=route[i-1];plats.append((max(80,px-130),py,260,16))
# Short alternate upper paths: same six rises, offset 80 pixels; never a maze.
branches=[]
for a,b in [(6,9),(29,33)]:
 pts=[route[a-1]]
 for i in range(a,b):
  px,py=route[i];alt=max(164,min(796,px+(90 if a==6 else -90)))
  plats.append((alt-84,py,168,16));pts.append((alt,py))
 pts.append(route[b]);branches.append(pts)
cps=[route[13],route[27],route[-1]]
for px,py in cps:plats.append((max(80,min(560,px-160)),py,320,18))
# Enemy supports stay away from the main landing corridor.
enc=[]
for n,i in enumerate([4,7,10,12,21,24,27,30,35,38,41]):
 px,py=route[i];ex=800 if px<480 else 160;plats.append((ex-65,py-60,130,16))
 points=[(ex,py-60)];types=[1 if n%3==1 else 0]
 if n in [5,7,8,9]:points.append((max(150,min(810,px-100)),py-160));types.append(2)
 enc.append('{"id":"R%02d","trigger":%s,"positions":[%s],"types":[%s]}'%(n,rect((80,py-25,800,105)),','.join(vec(p) for p in points),','.join(map(str,types))))
# Rocks fall away from checkpoint/catch centers. Source determines visible warning column.
rocks=[]
for n,i in enumerate([7,34]):
 px,py=route[i];rocks.append('{"id":"rock%d","area":%s,"warning":1.1,"speed":240.0,"cooldown":2.2}'%(n,rect((max(100,min(800,px-135)),py-210,48,200))))
haz=[]
for n,i in enumerate([23,25]):
 px,py=route[i];hx=max(100,min(800,px+120));plats.append((hx-25,py,160,16))
 haz.append('{"id":"fire%d","kind":"vent","source":"","area":%s,"warning":1.0,"active":0.7,"cooldown":1.8}'%(n,rect((hx,py-65,50,65))))
plats.extend([(110,y-60,190,16),(660,y-60,190,16)])
sections=['峡口入侵','碎岩瀑道','浮岩渡口','灼流残桥','夹击断崖','峰顶突击']
s='[gd_resource type="Resource" load_steps=9 format=3]\n[ext_resource type="Script" path="res://scripts/level/level_spec.gd" id="1"]\n[ext_resource type="Script" path="res://scripts/level/encounter_spec.gd" id="2"]\n'
for i,title in enumerate(sections):s+='[sub_resource type="Resource" id="S%d"]\nscript=ExtResource("2")\ntitle="%s"\n'%(i,title)
s+='[resource]\nscript=ExtResource("1")\nid="redrock"\ntitle="赤岩瀑布 · 断崖要塞"\nlength=960.0\nground=435.0\nvertical=true\nplay_left=80.0\nplay_right=880.0\nworld_top=-2700.0\nspawn=Vector2(300,435)\nboss_checkpoint='+vec(cps[-1])+'\nboss_left=80.0\nboss_position='+vec((480,y-210))+'\nboss_trigger_zone='+rect((150,y-35,650,48))+'\n'
s+='sectors=Array[Resource](['+','.join('SubResource("S%d")'%i for i in range(6))+'])\nheight_ends=PackedFloat32Array(360,840,1320,1680,2280,2641)\nmusic_tracks=PackedStringArray("redrock","redrock","summit","summit","summit","redrock","citadel")\n'
s+='floor_rects=Array[Rect2](['+rect((200,435,560,100))+','+rect((80,y,800,80))+'])\nextra_platforms=Array[Rect2](['+','.join(rect(p) for p in plats)+'])\n'
s+='climb_route='+packed(route)+'\ncheckpoint_points='+packed(cps)+'\ncheckpoint_ids=PackedStringArray("rock_merge","bridge_exit","summit")\npickup_points='+packed([(route[i][0],route[i][1]-30) for i in [5,27,42]])+'\n'
s+='encounter_data=Array[Dictionary](['+','.join(enc)+'])\nhazard_data=Array[Dictionary](['+','.join(haz)+'])\nrock_data=Array[Dictionary](['+','.join(rocks)+'])\n'
s+='moving_data=Array[Dictionary](['+','.join('{"id":"ferry%d","center":%s,"width":168.0,"amplitude":64.0,"speed":52.0,"route_index":%d}'%(n,vec(route[i]),i) for n,i in enumerate(moving))+'])\n'
s+='branch_routes=Array[PackedVector2Array](['+','.join(packed(b) for b in branches)+'])\n'
items=[("rock_m1",5,"machine"),("rock_f1",21,"fireball"),("rock_r1",27,"rapid"),("rock_l1",35,"laser")]
s+='pickup_data=Array[Dictionary](['+','.join('{"id":"%s","pos":%s,"kind":"%s"}'%(id,vec((route[i][0],route[i][1]-30)),kind) for id,i,kind in items)+'])\n'
s+='boss_supply='+vec((cps[-1][0]+50,cps[-1][1]-25))+'\n'
(R/'resources/levels/redrock.tres').write_text(s)
print('Redrock',len(route),'rises; net',435-y,'2 ferries; 2 branches',cps)
