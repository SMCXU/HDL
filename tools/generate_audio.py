"""Original deterministic chip-synth score and effects; Python standard library only.
No samples or third-party compositions. Re-run from repository root.
"""
import math, random, struct, wave
from pathlib import Path
RATE=22050
OUT=Path(__file__).resolve().parents[1]/'assets/audio'
OUT.mkdir(parents=True,exist_ok=True)
def write(name, samples):
    # Remove DC offset and blend loop boundaries; retain deterministic source.
    if name in ('level','workshop','core','boss','spillway','ascent','warden','redrock','summit','citadel'):
        dc=sum(samples)/len(samples)
        samples=[v-dc for v in samples]
        cross=int(.025*RATE)
        tail=samples[-cross:]
        for i in range(cross):
            blend=i/max(1,cross-1)
            samples[i]=tail[i]*(1-blend)+samples[i]*blend
        samples[-1]=samples[0]
    peak=max(abs(v) for v in samples) or 1
    gain=min(1,.88/peak)
    samples=[math.tanh(v*gain*1.2)/1.2 for v in samples]
    with wave.open(str(OUT/(name+'.wav')),'wb') as f:
        f.setparams((1,2,RATE,0,'NONE','not compressed'))
        f.writeframes(struct.pack('<%dh'%len(samples),*(int(max(-.95,min(.95,x))*32767) for x in samples)))
def hz(m): return 440*2**((m-69)/12)
def add_note(buf,start,duration,note,amp,kind='pulse'):
    start=int(start*RATE); count=int(duration*RATE); freq=hz(note)
    for j in range(count):
        if start+j>=len(buf): break
        t=j/RATE; phase=(t*freq)%1
        waveval=(1 if phase<.25 else -1/3) if kind=='pulse' else (4*abs(phase-.5)-1)
        env=min(1,t/.008)*min(1,(duration-t)/.035)
        buf[start+j]+=waveval*amp*env
# Sixteen 4/4 bars at 120 BPM = 32 seconds. Four original recurring phrases.
melodies=[(76,79,83,81,79,76,74,71),(74,78,81,83,86,83,81,78),(72,76,79,83,81,79,76,74),(74,78,81,78,76,74,71,74)]
for name,bpm in [('level',120),('workshop',128),('core',136),('boss',144),('spillway',116),('ascent',124),('warden',140),('redrock',126),('summit',132),('citadel',142)]:
    beat=60/bpm; duration=64*beat; buf=[0.0]*int(duration*RATE); rng=random.Random(830)
    roots=[52,50,48,50]
    for bar in range(16):
        base=bar*4*beat; root=roots[bar%4]
        melody=melodies[bar%4]
        transpose={'workshop':-5,'core':-12,'spillway':-7,'ascent':-2,'warden':3,'redrock':-3,'summit':2,'citadel':-10}.get(name,0)
        for step,n in enumerate(melody):
            add_note(buf,base+step*beat/2,beat*.4,n+transpose+(12 if name=='boss' and bar%4==3 else 0),.11)
        for step in range(8):
            add_note(buf,base+step*beat/2,beat*.35,root+(12 if step%3==2 else 0),.15,'triangle')
            add_note(buf,base+step*beat/2,beat*.3,root+12+[0,7,12,7][step%4],.045)
        for step in range(8):
            start=int((base+step*beat/2)*RATE)
            for j in range(int(.07*RATE)):
                if start+j<len(buf): buf[start+j]+=rng.uniform(-1,1)*.035*(1-j/(.07*RATE))**3
        for b in range(4):
            start=int((base+b*beat)*RATE)
            for j in range(int(.16*RATE)):
                if start+j>=len(buf): break
                t=j/RATE
                if b%2==0: buf[start+j]+=math.sin(2*math.pi*(70*t+2.3*(1-math.exp(-t*35))))*.3*math.exp(-t*28)
                else: buf[start+j]+=rng.uniform(-1,1)*.13*math.exp(-t*25)
    write(name,buf)
fx={'machine_shot':(.07,1100,180),'laser_shot':(.18,1800,350),'fireball_shot':(.24,240,90),'stone_warning':(.35,320,160),'stone_impact':(.3,130,30),'power_down':(.4,900,70),'arm_break':(.65,180,25),'vent':(.3,180,80),'shot':(.11,920,110),'spread':(.18,650,80),'jump':(.17,240,820),'land':(.09,100,45),'hit':(.18,240,50),'death':(.6,520,35),'enemy_shot':(.14,420,190),'enemy_hit':(.08,950,350),'explosion':(.45,110,25),'pickup':(.32,440,1200),'warning':(.25,600,900),'boss_shot':(.26,200,65),'boss_death':(1.4,160,18),'confirm':(.1,660,1000),'back':(.12,500,280)}
for name,(duration,f0,f1) in fx.items():
    rng=random.Random(name); buf=[]
    noisy=name in ('explosion','boss_death','hit','death','land')
    phase=0
    for i in range(int(duration*RATE)):
        t=i/RATE; u=t/duration; f=f0*(f1/f0)**u; phase+=f/RATE
        tone=(1 if phase%1<.3 else -.43)
        if name in ('shot','spread','machine_shot','enemy_shot','boss_shot'):
            # Body + brief filtered mechanical transient rather than a raw square wave.
            low=math.sin(2*math.pi*(95 if name=='spread' else 155)*t)*math.exp(-t*22)
            transient=rng.uniform(-1,1)*math.exp(-t*65)
            tone=tone*.18+low*.55+transient*.45
        if noisy: tone=tone*.35+rng.uniform(-1,1)*.65
        env=min(1,t/.003)*(1-u)**1.6
        buf.append(tone*.45*env)
    write(name,buf)
for name,notes in [('victory',[72,76,79,84]),('failure',[64,60,55,48])]:
    buf=[0.0]*int(RATE*1.5)
    for i,n in enumerate(notes): add_note(buf,i*.23,.4,n,.25)
    write(name,buf)
print('Generated',len(list(OUT.glob('*.wav'))),'original audio files')
