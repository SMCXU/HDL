"""Original one-screen-wide spillway climb. Editable source for the authored Godot resource."""
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def v(x,y):return f'Vector2({x},{y})'
def rect(x,y,w,h):return f'Rect2({x},{y},{w},{h})'
def packed(points):return 'PackedVector2Array('+','.join(str(n) for p in points for n in p)+')'
# Alternating 2..4-jump runs; the route must reverse rather than keep going right.
legs=[(180,2),(540,4),(270,3),(630,4),(360,3),(720,4),(450,3),(810,4),(450,4),(720,3),(360,4),(630,3),(270,4),(540,3),(180,4),(360,2)]
route=[];platforms=[];x=300;y=435;turns=[]
for end,count in legs:
 start=x
 for j in range(count):
  x=round(start+(end-start)*(j+1)/count,2)
  y-=40 if (len(route)+1)%9==0 else 60
  route.append((x,y));platforms.append((x-84,y,168,18))
 turns.append(len(route)-1)
# Wide, visibly thin rescue supports cover the adjacent three-jump corridor.
for i,point in enumerate(route):
 if (i+1)%3==0:
  near=route[max(0,i-2):min(len(route),i+4)]
  left=max(80,min(p[0] for p in near)-100);right=min(880,max(p[0] for p in near)+100)
  platforms.append((left,point[1],right-left,16))
 elif i in turns:platforms.append((max(80,min(point[0]-132,616)),point[1],264,18))
# Checkpoint slabs: coordinates can move left while their ordinal moves forward.
cp_indices=[18,37,53]
cps=[route[i] for i in cp_indices]
for px,py in cps:platforms.append((max(80,min(px-160,560)),py,320,18))
floors=[(200,435,560,105),(80,y,800,70)]
sections=[('坝底支架',480),('泄洪水幕',1080),('中层维护台',1560),('交叉火力层',2160),('供能支架层',2640),('主闸上行层',3121)]
# Eleven bounded encounters, keyed by world-space activation rectangles.
encounters=[]
for n,i in enumerate([4,8,12,16,21,26,30,34,40,44,49]):
 px,py=route[i];side=1 if px<480 else -1
 enemy_x=805 if px<480 else 155
 points=[(enemy_x,py-60)]
 types=[1 if n%3==1 else 0]
 # Put a real support below fixed enemies; offset away from the landing corridor.
 platforms.append((enemy_x-60,py-60,120,18))
 if n>=3:points.append((max(120,min(840,px-side*140)),py-160));types.append(2)
 encounters.append('{"id":"V%02d","trigger":%s,"positions":[%s],"types":[%s],"condition":"exit_reached"}'%(n,rect(80,py-35,800,115),','.join(v(*p) for p in points),','.join(map(str,types))))
# Optional on-route relay and power nodes; they NEVER seal the climb or boss.
targets=[('relay',route[5][0]+70,route[5][1],6),('node_a',route[39][0]+65,route[39][1],8),('node_b',route[44][0]-65,route[44][1],8)]
target_data=['{"id":"%s","pos":%s,"max_hp":%d,"optional":true}'%(id,v(px,py),hp) for id,px,py,hp in targets]
hazards=[]
for id,kind,i,offset,source in [('vent_a','vent',10,-125,''),('vent_b','vent',28,125,''),('grid_a','electric',40,130,'node_a'),('grid_b','electric',45,-130,'node_b')]:
 px,py=route[i];hx=max(90,min(810,px+offset));height=72 if kind=='vent' else 14
 platforms.append((max(80,hx-20),py,150,18))
 hazards.append('{"id":"%s","kind":"%s","area":%s,"source":"%s","warning":%s,"active":%s,"cooldown":%s}'%(id,kind,rect(hx,py-height,60 if kind=='vent' else 70,height),source,.9 if kind=='vent' else .8,.75 if kind=='vent' else .65,1.6 if kind=='vent' else 1.8))
s='[gd_resource type="Resource" load_steps=9 format=3]\n[ext_resource type="Script" path="res://scripts/level/level_spec.gd" id="1"]\n[ext_resource type="Script" path="res://scripts/level/encounter_spec.gd" id="2"]\n'
for i,(title,height) in enumerate(sections):s+='[sub_resource type="Resource" id="S%d"]\nscript=ExtResource("2")\ntitle="%s"\n'%(i,title)
s+='''[resource]
script=ExtResource("1")
id="spillway"
title="暴雨水坝 · 纵向突入"
length=960.0
ground=435.0
vertical=true
play_left=80.0
play_right=880.0
world_top=-3160.0
spawn=Vector2(300,435)
boss_checkpoint='''+v(*cps[-1])+'''
boss_trigger=0.0
boss_left=80.0
boss_position='''+v(720,y-255)+'''
boss_trigger_zone='''+rect(140,y-35,470,48)+'''
gate_x=960.0
sectors=Array[Resource](['''+','.join('SubResource("S%d")'%i for i in range(6))+'''])
height_ends=PackedFloat32Array(480,1080,1560,2160,2640,3121)
music_tracks=PackedStringArray("spillway","ascent","ascent","ascent","spillway","spillway","warden")
'''
s+='floor_rects=Array[Rect2](['+','.join(rect(*r) for r in floors)+'])\n'
s+='extra_platforms=Array[Rect2](['+','.join(rect(*r) for r in platforms)+'])\n'
s+='climb_route='+packed(route)+'\ncheckpoint_points='+packed(cps)+'\ncheckpoint_ids=PackedStringArray("maintenance","power","summit")\n'
pickups=[(route[i][0],route[i][1]-30) for i in [5,19,38,51]]
s+='pickup_points='+packed(pickups)+'\nencounter_data=Array[Dictionary](['+','.join(encounters)+'])\n'
s+='target_data=Array[Dictionary](['+','.join(target_data)+'])\nhazard_data=Array[Dictionary](['+','.join(hazards)+'])\n'
items=[("spill_s1",5,"spread"),("spill_f1",19,"fireball"),("spill_r1",30,"rapid"),("spill_l1",38,"laser")]
s+='pickup_data=Array[Dictionary](['+','.join('{"id":"%s","pos":%s,"kind":"%s"}'%(id,v(route[i][0],route[i][1]-30),kind) for id,i,kind in items)+'])\n'
s+='boss_supply='+v(cps[-1][0]-60,cps[-1][1]-25)+'\n'
(ROOT/'resources/levels/spillway.tres').write_text(s)
print('Vertical spillway:',len(route),'rises, height',435-y,'width 960; checkpoints',cps)
