"""Goblin Forge balance sandbox: reproduces the initial design values in docs/prd.

Every number here is an initial design value (initial tuning, not final).
The PRD tables are generated from this file. When you change a value here,
rerun it and update the PRD.

    python tools/balance_sim.py weapons   # weapon stats for the forge worked examples
    python tools/balance_sim.py matrix    # per-hit damage vs each enemy trait
    python tools/balance_sim.py stages    # stages 1-20: recommended build vs counter-pick build
    python tools/balance_sim.py economy   # first 20 stages: resource path and farm time
    python tools/balance_sim.py safeguards # tutorial subsidy and all acceleration sources
    python tools/balance_sim.py all
"""
import math
import random
import sys

# ----------------------------------------------------------------------------
# Facilities (levels 1-10)
# ----------------------------------------------------------------------------
ANVIL_BUDGET = {1: 6, 2: 7, 3: 8, 4: 9, 5: 10, 6: 11, 7: 12, 8: 13, 9: 14, 10: 14}
FURNACE_MD = {1: 10, 2: 12, 3: 14, 4: 17, 5: 20, 6: 24, 7: 28, 8: 33, 9: 39, 10: 46}
FURNACE_METAL = {1: "Copper", 2: "Copper", 3: "Copper", 4: "Iron", 5: "Iron", 6: "Iron",
                 7: "Steel", 8: "Steel", 9: "Steel", 10: "Moonsilver"}
FURNACE_ORE = {1: 6, 2: 8, 3: 10, 4: 15, 5: 18, 6: 22, 7: 32, 8: 38, 9: 45, 10: 65}
BARRACKS_HP = {1: 100, 2: 118, 3: 139, 4: 164, 5: 194, 6: 229, 7: 270, 8: 319, 9: 376, 10: 444}

# Coin cost to reach each level (filled from upgrade_cost() in the economy section). Key = target level.
UPGRADE_COST = {
    "anvil":    {2: 40, 3: 90, 4: 220, 5: 480, 6: 1000, 7: 2000, 8: 3900, 9: 7400, 10: 13500},
    "furnace":  {2: 60, 3: 120, 4: 300, 5: 600, 6: 1200, 7: 2400, 8: 4500, 9: 8200, 10: 15000},
    "barracks": {2: 50, 3: 100, 4: 240, 5: 500, 6: 1000, 7: 1900, 8: 3600, 9: 6800, 10: 12500},
}
# Stage clear that unlocks a facility level (metal tiers and the Great form budget).
UPGRADE_GATE = {("furnace", 4): 5, ("furnace", 7): 10, ("furnace", 10): 20,
                ("anvil", 3): 6}

# ----------------------------------------------------------------------------
# Forge rules
# ----------------------------------------------------------------------------
BLADE_CAP, HILT_CAP, RUNE_CAP = 12, 6, 5
HILT_STEP = 0.07           # each Hilt point cuts the attack interval by 7% of the form base
BLADE_STEP = 0.10          # each Blade point adds 10% damage
TEMPER_STEP = 0.01         # each Perfect strike adds 1% damage, capped at 10
TEMPER_CAP = 10
FORMS = {
    #          blade pts   per-hit mult  base interval(s)  arc(deg)  range(u)  max targets
    "Needle": dict(lo=0, hi=3,  mult=1.00, base=1.00, arc=0,   rng=1.6, maxt=1),
    "Broad":  dict(lo=4, hi=7,  mult=0.90, base=1.35, arc=150, rng=2.0, maxt=6),
    "Great":  dict(lo=8, hi=12, mult=1.40, base=2.30, arc=360, rng=2.4, maxt=10),
}
RUNE_CHAIN_RANGE = 3.0
SPARK_RATIO = 0.6          # bolt on the primary target + up to 2 chained targets, 60% of H each;
                           # armor applies, Guard does not block it (a bolt removes 1 pip AND deals damage)
EMBER_RATIO = 1.5          # burn deals 150% of H over 3 s (3 ticks), ignores armor; does not stack, refreshes
FROST_BONUS = 0.3          # the triggering hit deals +30% H
FROST_SLOW = 0.65          # chilled: enemy attack and move speed x0.65 for 3.5 s
FROST_TIME = 3.5
MIN_DMG_RATIO = 0.2        # armor can never cut a hit below 20% of its raw damage


def rhu(x):
    """Round half up (the PRD rounding rule; Python's round() is banker's rounding)."""
    return int(math.floor(x + 0.5))


def form_of(bp):
    for name, f in FORMS.items():
        if f["lo"] <= bp <= f["hi"]:
            return name
    raise ValueError(bp)


def weapon(md, bp, hp, rp=0, rune=None, temper=0):
    """Weapon stats delivered from the forge."""
    assert 0 <= bp <= BLADE_CAP and 0 <= hp <= HILT_CAP and 0 <= rp <= RUNE_CAP
    assert (rp == 0) == (rune is None)
    form = form_of(bp)
    f = FORMS[form]
    h = rhu(md * (1 + BLADE_STEP * bp) * f["mult"] * (1 + TEMPER_STEP * min(temper, TEMPER_CAP)))
    interval = round(f["base"] * (1 - HILT_STEP * hp), 2)
    windup = round(min(0.6, max(0.15, 0.35 * interval)), 2)
    every = (6 - rp) if rp else None
    return dict(form=form, H=h, I=interval, W=windup, arc=f["arc"], rng=f["rng"],
                maxt=f["maxt"], rune=rune, every=every, bp=bp, hp=hp, rp=rp,
                temper=temper, md=md, label=f"{form} B{bp}/H{hp}/R{rp}{(' ' + rune) if rune else ''}")


def hit_after_armor(raw, armor):
    return max(raw - armor, math.ceil(raw * MIN_DMG_RATIO))


# ----------------------------------------------------------------------------
# Enemies. Base values are at stage 1; HP/armor/damage scale by stage.
# ----------------------------------------------------------------------------
HP_GROWTH, DMG_GROWTH = 1.085, 1.03
ARMOR_GROWTH = 1.065   # tracks the furnace damage curve so armor keeps the same meaning
MAX_ATTACKERS = 6   # melee ring: at most 6 enemies hit the hero at once, the rest queue behind

ENEMIES = {
    "mushling":  dict(hp=14, armor=0, guard=0, regen=0,   dmg=3,  atk=1.5, spd=1.1, r=0.35),
    "sprite":    dict(hp=16, armor=0, guard=3, regen=1.5, dmg=3,  atk=1.6, spd=1.6, r=0.30),
    "shellback": dict(hp=60, armor=7, guard=0, regen=0,   dmg=7,  atk=2.4, spd=0.7, r=0.50),
    # Bosses: values are already scaled for the stage they first appear on.
    "queen":       dict(hp=300,  armor=0,  guard=0, regen=0,   dmg=5,  atk=2.2, spd=0.8, r=0.9,
                        summon=("mushling", 3, 8.0)),
    "ironhide":    dict(hp=500,  armor=20, guard=0, regen=0,   dmg=6,  atk=2.5, spd=0.8, r=1.0,
                        slam=(12.0, 1.5, 24)),
    "thornwarden": dict(hp=750,  armor=0,  guard=6, regen=1.2, dmg=6,  atk=2.0, spd=0.8, r=0.9,
                        summon=("sprite", 2, 15.0)),
    "warden_elite": dict(hp=850, armor=26, guard=4, regen=1.2, dmg=8, atk=2.2, spd=0.8, r=1.0,
                         summon=("sprite", 2, 14.0), slam=(14.0, 1.5, 30)),
}
BOSS_STAGE = {"queen": 5, "ironhide": 10, "thornwarden": 15, "warden_elite": 20}


def enemy_stats(kind, stage):
    e = dict(ENEMIES[kind])
    if kind in BOSS_STAGE:
        k = 1.0  # authored for its own stage
    else:
        k = HP_GROWTH ** (stage - 1)
    d = 1.0 if kind in BOSS_STAGE else DMG_GROWTH ** (stage - 1)
    ka = 1.0 if kind in BOSS_STAGE else ARMOR_GROWTH ** (stage - 1)
    e["hp"] = rhu(e["hp"] * k)
    e["armor"] = rhu(e["armor"] * ka)
    e["dmg"] = rhu(e["dmg"] * d)
    e["kind"] = kind
    return e


# Stage layout: list of waves; each wave = list of (kind, count, side).
# side: L=left edge, R=right edge, T=top edge, A=around (all sides)
STAGES = {
    1:  [[("mushling", 2, "R")], [("mushling", 3, "A")], [("mushling", 3, "A")]],
    2:  [[("mushling", 3, "A")], [("mushling", 4, "A")], [("mushling", 4, "A")]],
    3:  [[("mushling", 3, "A")], [("mushling", 5, "L"), ("mushling", 5, "R")], [("mushling", 5, "A")]],
    4:  [[("mushling", 4, "A")], [("sprite", 2, "T")], [("mushling", 3, "A"), ("sprite", 2, "T")]],
    5:  [[("mushling", 4, "A")], [("sprite", 2, "T"), ("mushling", 3, "A")], [("queen", 1, "T")]],
    6:  [[("mushling", 4, "A")], [("shellback", 1, "R"), ("mushling", 3, "L")], [("shellback", 2, "A")]],
    7:  [[("shellback", 2, "A")], [("mushling", 7, "A")], [("shellback", 1, "R"), ("mushling", 4, "A")]],
    8:  [[("sprite", 3, "A")], [("shellback", 1, "R"), ("sprite", 2, "T")], [("mushling", 8, "A")]],
    9:  [[("mushling", 7, "A")], [("shellback", 2, "A")], [("sprite", 3, "A"), ("shellback", 1, "R")]],
    10: [[("shellback", 2, "A"), ("mushling", 3, "A")], [("sprite", 3, "A")], [("ironhide", 1, "T")]],
    11: [[("sprite", 4, "A")], [("mushling", 8, "A")], [("sprite", 3, "A"), ("mushling", 4, "A")]],
    12: [[("sprite", 4, "A")], [("shellback", 2, "A")], [("sprite", 3, "A"), ("shellback", 1, "T")]],
    13: [[("mushling", 9, "A")], [("sprite", 4, "A")], [("mushling", 5, "A"), ("sprite", 3, "A")]],
    14: [[("shellback", 3, "A")], [("sprite", 4, "A")], [("shellback", 2, "A"), ("sprite", 2, "A")]],
    15: [[("sprite", 4, "A")], [("mushling", 8, "A")], [("thornwarden", 1, "T")]],
    16: [[("shellback", 3, "A")], [("mushling", 10, "A")], [("shellback", 2, "A"), ("mushling", 4, "A")]],
    17: [[("sprite", 4, "A")], [("shellback", 3, "A")], [("sprite", 3, "A"), ("shellback", 1, "A")]],
    18: [[("mushling", 10, "A")], [("shellback", 4, "A")], [("mushling", 6, "A"), ("shellback", 2, "A")]],
    19: [[("sprite", 4, "A")], [("mushling", 8, "A"), ("sprite", 2, "T")], [("shellback", 2, "A"), ("sprite", 2, "A")]],
    20: [[("shellback", 3, "A"), ("mushling", 5, "A")], [("sprite", 5, "A")], [("warden_elite", 1, "T")]],
}
TIME_LIMIT = {"normal": 90.0, "boss": 120.0}   # boss limit counts from the boss wave
SPAWN_GAP = 0.35   # seconds between spawns inside a wave
WAVE_GAP = 1.0     # seconds between waves
WAVE_HEAL = 0.20   # hero heals 20% of max HP at each wave break
SPAWN_DIST = 6.5
HERO_R = 0.5
ENEMY_REACH = 0.25
DT = 0.05


def side_angle(rng, side):
    centre = {"R": 0, "T": 90, "L": 180}.get(side)
    if centre is None:
        return rng.uniform(0, 360)
    return centre + rng.uniform(-35, 35)


class Unit:
    def __init__(self, stats, ang):
        self.__dict__.update(stats)
        self.max_hp = self.hp
        self.max_guard = self.guard
        a = math.radians(ang)
        self.x, self.y = SPAWN_DIST * math.cos(a), SPAWN_DIST * math.sin(a)
        self.atk_t = None
        self.regen_t = self.regen
        self.last_hit = -99.0
        self.burns = []        # [remaining_ticks, per_tick, next_tick_time]
        self.chill = 0.0
        self.summon_t = stats.get("summon", (None, 0, 0))[2]
        self.slam_t = stats.get("slam", (0, 0, 0))[0]
        self.telegraph = None

    def dist(self):
        return math.hypot(self.x, self.y)

    def edge(self):
        return self.dist() - self.r - HERO_R


def simulate(stage, wpn, hero_hp, seed=7, verbose=False):
    """wpn: one weapon dict, or a list with one weapon per wave (swap at wave breaks)."""
    plan = wpn if isinstance(wpn, list) else None
    rng = random.Random(seed * 1000 + stage)
    waves = STAGES[stage]
    is_boss = any(k in BOSS_STAGE for w in waves for k, _, _ in w)
    limit = TIME_LIMIT["boss" if is_boss else "normal"]
    hp = hero_hp
    t = 0.0
    log = dict(blocked_by_guard=0, armor_absorbed=0, dealt=0, burn=0, hits=0, swings=0,
               max_engaged=0, taken=0, triggers=0)
    alive = []
    charge = 0
    state, timer, aim = "ready", 0.0, None
    boss_t0 = None
    for wi, wave in enumerate(waves):
        if plan:
            wpn = plan[wi]
            charge = 0   # swapping resets rune charge
        if any(k in BOSS_STAGE for k, _, _ in wave):
            hp, boss_t0 = hero_hp, t   # Boss gate: hero is restored to full HP before the boss wave
        elif wi > 0:
            hp = min(hero_hp, hp + round(hero_hp * WAVE_HEAL))
        queue = []
        for kind, n, side in wave:
            queue += [(kind, side)] * n
        rng.shuffle(queue)
        spawn_t = 0.0
        while queue or alive:
            # spawn
            spawn_t -= DT
            if queue and spawn_t <= 0:
                kind, side = queue.pop()
                alive.append(Unit(enemy_stats(kind, stage), side_angle(rng, side)))
                spawn_t = SPAWN_GAP
            # enemies act
            engaged = 0
            for e in alive:
                slow = FROST_SLOW if e.chill > t else 1.0
                if e.edge() > ENEMY_REACH:
                    step = e.spd * slow * DT
                    d = e.dist()
                    e.x -= e.x / d * step
                    e.y -= e.y / d * step
                elif engaged >= MAX_ATTACKERS and e.atk_t is None:
                    pass  # waits behind the melee ring, still inside weapon reach
                else:
                    engaged += 1
                    if e.atk_t is None:
                        e.atk_t = e.atk * 0.5
                    e.atk_t -= DT * slow
                    if e.atk_t <= 0:
                        hp -= e.dmg
                        log["taken"] += e.dmg
                        e.atk_t = e.atk
                # Guard regen: after `regen` seconds without being hit, +1 pip every `regen` seconds.
                if e.max_guard and e.guard < e.max_guard and t - e.last_hit >= e.regen:
                    e.regen_t -= DT
                    if e.regen_t <= 0:
                        e.guard += 1
                        e.regen_t = e.regen
                if "summon" in e.__dict__ and e.summon:
                    e.summon_t -= DT * slow
                    if e.summon_t <= 0:
                        kind, n, every = e.summon
                        boss_ang = math.degrees(math.atan2(e.y, e.x))
                        for _ in range(n):   # summons pop out right next to the boss
                            u = Unit(enemy_stats(kind, stage), boss_ang + rng.uniform(-25, 25))
                            k = (e.dist() + 0.8) / SPAWN_DIST
                            u.x, u.y = u.x * k, u.y * k
                            alive.append(u)
                        e.summon_t = every
                if "slam" in e.__dict__ and e.slam:
                    every, tele, dmg = e.slam
                    if e.telegraph is None:
                        e.slam_t -= DT * slow
                        if e.slam_t <= 0:
                            e.telegraph = tele
                    else:
                        e.telegraph -= DT
                        if e.telegraph <= 0:
                            hp -= dmg
                            log["taken"] += dmg
                            e.telegraph, e.slam_t = None, every
                # burn ticks (not hits: ignore armor and guard, never trigger runes)
                for b in e.burns:
                    if t >= b[2]:
                        e.hp -= b[1]
                        log["burn"] += b[1]
                        b[0] -= 1
                        b[2] += 1.0
                e.burns = [b for b in e.burns if b[0] > 0]
            log["max_engaged"] = max(log["max_engaged"], engaged)
            # hero acts
            in_range = [e for e in alive if e.edge() <= wpn["rng"]]
            if state == "ready" and in_range:
                prim = min(in_range, key=lambda e: e.edge())
                aim = math.atan2(prim.y, prim.x)
                state, timer = "windup", wpn["W"]
            elif state == "windup":
                timer -= DT
                if timer <= 0:
                    charge = resolve(wpn, alive, aim, charge, log, t)
                    state, timer = "recover", wpn["I"] - wpn["W"]
            elif state == "recover":
                timer -= DT
                if timer <= 0:
                    state = "ready"
            alive = [e for e in alive if e.hp > 0]
            t += DT
            if hp <= 0:
                return dict(win=False, t=round(t, 1), hp=0, wave=wi + 1, left=len(alive) + len(queue), log=log)
            if (boss_t0 is None and t >= TIME_LIMIT["normal"]) or (boss_t0 is not None and t - boss_t0 >= limit):
                return dict(win=False, t=round(t, 1), hp=max(hp, 0), wave=wi + 1, left=len(alive) + len(queue),
                            log=log, timeout=True)
        t += WAVE_GAP
    return dict(win=True, t=round(t, 1), hp=hp, wave=len(waves), left=0, log=log,
                boss_t=round(t - WAVE_GAP - boss_t0, 1) if boss_t0 is not None else None)


def resolve(wpn, alive, aim, charge, log, t):
    in_range = [e for e in alive if e.edge() <= wpn["rng"] and e.hp > 0]
    if not in_range:
        return charge  # whiff: target died or left during windup
    if wpn["form"] == "Needle":
        targets = [min(in_range, key=lambda e: e.edge())]
    elif wpn["form"] == "Broad":
        half = math.radians(wpn["arc"] / 2)
        def diff(e):
            a = math.atan2(e.y, e.x) - aim
            return abs((a + math.pi) % (2 * math.pi) - math.pi)
        targets = sorted([e for e in in_range if diff(e) <= half], key=lambda e: e.edge())[:wpn["maxt"]]
        if not targets:
            targets = [min(in_range, key=lambda e: e.edge())]
    else:
        targets = sorted(in_range, key=lambda e: e.edge())[:wpn["maxt"]]
    log["swings"] += 1
    trigger = False
    if wpn["rune"]:
        charge += 1
        if charge >= wpn["every"]:
            trigger, charge = True, 0
            log["triggers"] += 1
    raw = wpn["H"] * (1 + FROST_BONUS if trigger and wpn["rune"] == "Frost" else 1)
    damaged = []
    for e in targets:
        if apply_hit(e, raw, log, t):
            damaged.append(e)
    if trigger and damaged:
        if wpn["rune"] == "Ember":
            per_tick = math.ceil(wpn["H"] * EMBER_RATIO / 3)
            for e in damaged:
                if not e.burns or e.burns[0][1] <= per_tick:
                    e.burns = [[3, per_tick, t + 1.0]]
        elif wpn["rune"] == "Frost":
            for e in damaged:
                e.chill = t + FROST_TIME
    if trigger and wpn["rune"] == "Spark":
        # Spark triggers on any connecting swing, even a fully blocked one.
        src = targets[0]
        others = sorted([e for e in alive if e is not src and e.hp > 0 and
                         math.hypot(e.x - src.x, e.y - src.y) <= RUNE_CHAIN_RANGE],
                        key=lambda e: math.hypot(e.x - src.x, e.y - src.y))[:2]
        for e in [src] + others:
            if e.hp > 0:
                apply_hit(e, wpn["H"] * SPARK_RATIO, log, t, pierce=True)
    return charge


def apply_hit(e, raw, log, t=0.0, pierce=False):
    log["hits"] += 1
    e.last_hit = t
    e.regen_t = 0.0   # first pip returns exactly `regen` s after the last hit
    if e.guard > 0:
        e.guard -= 1
        log["blocked_by_guard"] += 1
        if not pierce:
            return False
    dmg = hit_after_armor(rhu(raw), e.armor)
    log["armor_absorbed"] += rhu(raw) - dmg
    log["dealt"] += dmg
    e.hp -= dmg
    return True


# ----------------------------------------------------------------------------
# Expected player state per stage (design target, not a requirement)
# ----------------------------------------------------------------------------
# stage: (anvil, furnace, barracks, rune stones available)
EXPECTED = {
    1: (1, 1, 1, ()), 2: (1, 1, 1, ()), 3: (2, 1, 1, ()), 4: (2, 2, 1, ()),
    5: (2, 2, 1, ()), 6: (2, 2, 2, ("Ember",)), 7: (3, 2, 2, ("Ember",)),
    8: (4, 4, 3, ("Ember",)), 9: (4, 5, 3, ("Ember",)), 10: (5, 5, 4, ("Ember",)),
    11: (5, 5, 4, ("Ember", "Frost")), 12: (5, 6, 5, ("Ember", "Frost")),
    13: (6, 6, 5, ("Ember", "Frost", "Spark")), 14: (6, 6, 5, ("Ember", "Frost", "Spark")),
    15: (6, 7, 6, ("Ember", "Frost", "Spark")), 16: (7, 7, 6, ("Ember", "Frost", "Spark")),
    17: (7, 7, 6, ("Ember", "Frost", "Spark")), 18: (7, 8, 7, ("Ember", "Frost", "Spark")),
    19: (8, 8, 7, ("Ember", "Frost", "Spark")), 20: (8, 8, 8, ("Ember", "Frost", "Spark")),
}
TEMPER_BASELINE = 3   # balance assumes an average of 3 Perfect strikes


def builds_for(budget, md, runes, temper=TEMPER_BASELINE):
    """Representative allocations for one budget: no-rune and with-rune versions of each form."""
    out = []
    def add(bp, hp, rp=0, rune=None):
        if bp + hp + rp > budget or hp > HILT_CAP or rp > RUNE_CAP or bp > BLADE_CAP:
            return
        out.append(weapon(md, bp, hp, rp, rune, min(temper, bp + hp + rp)))
    # Needle: 3 blade, rest into hilt, then rune
    add(min(3, budget), min(HILT_CAP, budget - min(3, budget)))
    for r in runes:
        rest = budget - 3
        hp = min(HILT_CAP, max(0, rest - 3))
        add(3, hp, min(RUNE_CAP, rest - hp), r)
    # Broad: 4 blade + hilt, rest blade
    if budget >= 4:
        hp = min(HILT_CAP, budget - 4)
        add(min(7, budget - hp), hp)
        for r in runes:
            rp = min(RUNE_CAP, max(1, (budget - 4) // 2))
            hp = min(HILT_CAP, budget - 4 - rp)
            add(min(7, budget - hp - rp), hp, rp, r)
    # Great: 8 blade + hilt
    if budget >= 8:
        hp = min(HILT_CAP, budget - 8)
        add(min(12, budget - hp), hp)
        for r in runes:
            rest = budget - 8
            rp = min(RUNE_CAP, max(1, rest // 2)) if rest else 0
            if rp:
                add(8 + max(0, rest - rp - HILT_CAP), min(HILT_CAP, rest - rp), rp, r)
    return out


# ----------------------------------------------------------------------------
# Reports
# ----------------------------------------------------------------------------
def report_weapons():
    rows = [  # the worked examples in docs/prd/04-forge-system.md section 4.9
        ("E1 tutorial forge 1", 10, 2, 2, 0, None, 1),
        ("E2 tutorial forge 2 (Broad)", 10, 4, 3, 0, None, 2),
        ("E3 tutorial forge 3 (Needle+Ember)", 12, 3, 1, 3, "Ember", 2),
        ("E4 first Great (stage 7)", 12, 8, 0, 0, None, 3),
        ("E5 Ironhide answer", 20, 3, 4, 3, "Ember", 5),
        ("E6 Quick Forge, Temper 0", 28, 3, 5, 3, "Spark", 0),
        ("E7 no rune, 2 strikes unused", 24, 3, 6, 0, None, 4),
    ]
    print("| Example | MD | B/H/R | Temper | Form | H per hit | Interval s | Single-target DPS | Rune every N swings |")
    print("|---|---|---|---|---|---|---|---|---|")
    for name, md, bp, hp, rp, rune, tem in rows:
        w = weapon(md, bp, hp, rp, rune, tem)
        print(f"| {name} | {md} | {bp}/{hp}/{rp} {rune or ''} | {tem} | {w['form']} | {w['H']} | {w['I']} |"
              f" {w['H'] / w['I']:.1f} | {w['every'] or '-'} |")


def report_matrix():
    """Reference single-target numbers at Furnace 5 (MD 20), Anvil 5 (budget 10), Temper 3."""
    md = 20
    ws = [weapon(md, 3, 6, 0, None, 3), weapon(md, 4, 6, 0, None, 3), weapon(md, 8, 2, 0, None, 3),
          weapon(md, 3, 4, 3, "Ember", 3), weapon(md, 4, 3, 3, "Spark", 3), weapon(md, 8, 1, 1, "Frost", 3)]
    print("| Build | H | Interval s | DPS armor 0 | DPS armor 12 | DPS armor 20 | Burn DPS (Ember, steady) | Swings to break 3 Guard pips |")
    print("|---|---|---|---|---|---|---|---|")
    for w in ws:
        burn = 0.0
        if w["rune"] == "Ember":
            per_tick = math.ceil(w["H"] * EMBER_RATIO / 3)
            burn = per_tick * min(1.0, 3.0 / (w["every"] * w["I"]))
        cells = [f"{hit_after_armor(w['H'], a) / w['I'] + burn:.1f}" for a in (0, 12, 20)]
        guard = "never (interval > 1.5 s regen)" if w["I"] > 1.5 else "3"
        print(f"| {w['label']} | {w['H']} | {w['I']} | {' | '.join(cells)} | {burn:.1f} | {guard} |")


def report_stages(seeds=(1, 2, 3)):
    print("| Stage | State A/F/B | Budget | MD | Hero HP | Best single build | Result | Worst build | Result | 2-weapon rack (if no single build wins 3/3) |")
    print("|---|---|---|---|---|---|---|---|---|---|")
    for s in sorted(STAGES):
        a, f, b, runes = EXPECTED[s]
        budget, md, hero = ANVIL_BUDGET[a], FURNACE_MD[f], BARRACKS_HP[b]
        if s <= 2:
            runes = ()
        results = []
        for w in builds_for(budget, md, runes):
            rs = [simulate(s, w, hero, seed) for seed in seeds]
            wins = sum(r["win"] for r in rs)
            avg_t = sum(r["t"] for r in rs) / len(rs)
            avg_hp = sum(max(r["hp"], 0) for r in rs) / len(rs)
            if wins:
                score = wins * 1000 + avg_hp / hero * 100 - avg_t
            else:
                score = sum(r["wave"] * 100 + r["t"] for r in rs) / len(rs)
            results.append((score, w, wins, avg_t, avg_hp, rs))
        results.sort(key=lambda x: -x[0])
        best, worst = results[0], results[-1]
        rack_note = ""
        if best[2] < len(seeds):
            rack_note = best_rack(s, [x[1] for x in results], hero, seeds)
        def fmt(x):
            _, w, wins, avg_t, avg_hp, rs = x
            if wins == len(seeds):
                return f"Win {wins}/3, {avg_t:.0f}s, HP {avg_hp / hero:.0%}"
            r = rs[0]
            why = "timeout" if r.get("timeout") else "dead"
            return f"Win {wins}/3 ({why} at wave {r['wave']}, {r['t']:.0f}s)"
        print(f"| {s} | {a}/{f}/{b} | {budget} | {md} | {hero} | {best[1]['label']} | {fmt(best)} |"
              f" {worst[1]['label']} | {fmt(worst)} | {rack_note} |")


def best_rack(stage, ws, hero, seeds):
    """Best 2-weapon rack when the player swaps at wave breaks (oracle choice per wave)."""
    import itertools
    n = len(STAGES[stage])
    best = None
    for w1, w2 in itertools.combinations(ws, 2):
        for plan in itertools.product((w1, w2), repeat=n):
            if len(set(id(x) for x in plan)) < 2:
                continue
            rs = [simulate(stage, list(plan), hero, seed) for seed in seeds]
            wins = sum(r["win"] for r in rs)
            hp = sum(max(r["hp"], 0) for r in rs) / len(rs)
            key = (wins, hp)
            if best is None or key > best[0]:
                best = (key, plan)
    (wins, hp), plan = best
    names = " → ".join(w["label"] for w in plan)
    return f"Rack swap: {names}: Win {wins}/{len(seeds)}, HP {hp / hero:.0%}"


def report_all_builds(stage):
    a, f, b, runes = EXPECTED[stage]
    budget, md, hero = ANVIL_BUDGET[a], FURNACE_MD[f], BARRACKS_HP[b]
    for w in builds_for(budget, md, runes):
        r = simulate(stage, w, hero, 1)
        lg = r["log"]
        print(f"S{stage} {w['label']:<24} win={r['win']!s:<5} t={r['t']:>5} hp={max(r['hp'], 0):>4}/{hero} "
              f"wave={r['wave']} guardBlk={lg['blocked_by_guard']} armorAbs={lg['armor_absorbed']} "
              f"burn={lg['burn']} maxEngaged={lg['max_engaged']}")


# ----------------------------------------------------------------------------
# Economy
# ----------------------------------------------------------------------------
START = dict(coins=0, ore=20, stones=0, gems=0)
ORE_REFUND = 0.8        # smelting returns 80% of the ore (rounded down); rune stones are NOT returned
STONE_IDLE_MIN = 360    # +1 Rune Stone per 360 minutes once Cart opens after Stage 7
IDLE_CAP_MIN = 480      # offline accrual cap: 8 h
STONE_CAP = 20          # extra stones over the cap turn into coins (see PRD 7.1)
TUTORIAL_CLEAR_STAGE = 7
NATURAL_MIN_PER_DAY = 960
WELCOME_DOUBLE_CAP = 2
GEM_QUICK_MIN, GEM_QUICK_CAP = 120, 3
AD_QUICK_MIN, AD_QUICK_CAP = 30, 3
SUPPLY_COINS_MIN = 240   # one weekly purchase, not a daily reward


def forge_quote(highest_stage, furnace_lv, ore, stones, *, needs_stone=False,
                old_ore_paid=None):
    """Atomic Deliver quote. Subsidy is consumed in-place, never credited to a wallet.

    old_ore_paid is the refundable basis of the weapon being replaced/smelted.
    Same-element reforging sets needs_stone=False; a new/changed rune sets it True.
    This models material accounting only, not unlocks, locks or rack validation.
    """
    if ore < 0 or stones < 0 or (old_ore_paid is not None and old_ore_paid < 0):
        raise ValueError("resource balances must be nonnegative")
    cost = FURNACE_ORE[furnace_lv]
    refund = math.floor(ORE_REFUND * old_ore_paid) if old_ore_paid is not None else 0
    real_ore = min(cost, ore + refund)
    missing_ore = cost - real_ore
    missing_stone = int(needs_stone and stones < 1)
    tutorial = highest_stage < TUTORIAL_CLEAR_STAGE
    if not tutorial and (missing_ore or missing_stone):
        return None
    return dict(ore_after=ore + refund - real_ore,
                stones_after=stones - int(needs_stone and stones >= 1),
                ore_paid=real_ore, ore_subsidy=missing_ore,
                stone_subsidy=missing_stone, refund=refund)


def acceleration_limits():
    """Fixed-rate resource equivalents; NOT a calendar progression simulation."""
    welcome = WELCOME_DOUBLE_CAP * IDLE_CAP_MIN
    ad_quick = AD_QUICK_CAP * AD_QUICK_MIN
    gems = GEM_QUICK_CAP * GEM_QUICK_MIN
    return dict(welcome=welcome, ad_quick=ad_quick, gems=gems,
                ads_total=welcome + ad_quick, daily_total=welcome + ad_quick + gems,
                supply_weekly=SUPPLY_COINS_MIN)


def report_safeguards():
    limits = acceleration_limits()
    print("| Source | Extra Cart-equivalent minutes | Period / condition |")
    print("|---|---|---|")
    for name, value, period in (
        ("Welcome back x2", limits["welcome"], "daily; two 480-minute base claims"),
        ("Ad Quick Loot", limits["ad_quick"], "daily; 3 x 30"),
        ("Gem Quick Loot", limits["gems"], "daily; 3 x 120"),
        ("All ads", limits["ads_total"], "daily; excludes Daily Rune Stone"),
        ("All ads + Gems", limits["daily_total"], "daily; excludes weekly Supply Box"),
        ("Supply Box Coins", limits["supply_weekly"], "weekly; Coins only")):
        print(f"| {name} | {value} | {period} |")
    print()
    print("Daily Rune Stone: +1 stone/day. Supply Box: choose Coins OR 6 stones OR 10 forge costs of Ore.")
    print("Bonuses are paid directly; they never enter the Cart and cannot be doubled again.")
    print("These are resource bounds at a fixed rate, not predicted days to Stage 20.")
    print()
    print("| Tutorial case (highest stage / Furnace / Ore / Stones) | Wallet after O/S | ore_paid | Ore / Stone subsidy |")
    print("|---|---|---|---|")
    for stage, furnace, ore, stones, rune in ((2, 1, 0, 0, False), (5, 2, 2, 0, True)):
        q = forge_quote(stage, furnace, ore, stones, needs_stone=rune)
        print(f"| {stage} / {furnace} / {ore} / {stones} | {q['ore_after']}/{q['stones_after']} | "
              f"{q['ore_paid']} | {q['ore_subsidy']} / {q['stone_subsidy']} |")


def first_clear_reward(s):
    """(coins, ore, stones) for the FIRST clear of stage s. Boss stages pay coins x3."""
    coins = round(30 * 1.13 ** (s - 1))
    ore = round(6 * 1.08 ** (s - 1))
    stones = {5: 2, 8: 1, 10: 2, 12: 2, 15: 1, 20: 2}.get(s, 0)
    if s % 5 == 0:
        coins *= 3
    return coins, ore, stones


def idle_rate(s):
    """(coins/min, ore/min) while farming the highest cleared stage s, online or offline."""
    if s <= 0:
        return 0.0, 0.0
    return round(4 * 1.10 ** (s - 1), 2), round(0.025 * 1.06 ** (s - 1), 3)


def upgrade_cost(fac, target):
    base, growth = {"anvil": (40, 2.7), "furnace": (60, 2.6), "barracks": (50, 2.6)}[fac]
    return int(round(base * growth ** (target - 2), -1)) if target > 2 else base


for _fac in UPGRADE_COST:
    UPGRADE_COST[_fac] = {lv: upgrade_cost(_fac, lv) for lv in range(2, 11)}

# Forges the expected player makes when reaching a stage: (label, uses_stone, smelts_one_old_weapon)
# Forges the expected player makes on reaching a stage: (label, uses_new_stone, smelts_or_reforges_an_old_weapon).
# Reforge keeps the socketed stone when the element stays the same (PRD 4.10), so those rows use no new stone.
FORGE_PLAN = {
    1: [("Needle (tutorial forge 1)", False, False)],
    3: [("Broad (tutorial forge 2)", False, False)],
    6: [("Needle + Ember (tutorial forge 3)", True, False)],
    7: [("Great, smelts the first Needle", False, True)],
    8: [("Reforge Broad in Iron", False, True), ("Reforge Great in Iron", False, True)],
    9: [("Reforge Needle + Ember into Broad + Ember (Iron, same element)", False, True)],
    10: [("New Needle + Ember for Ironhide (rack slot 4, opened at stage 8)", True, False)],
    12: [("Reforge Broad at Furnace 6", False, True), ("Reforge Needle + Ember into Needle + Frost", True, True)],
    13: [("Reforge Broad + Ember into Broad + Spark", True, True)],
    15: [("Reforge Needle + Frost in Steel (same element)", False, True),
         ("Reforge Broad + Spark into Needle + Spark (Steel)", False, True),
         ("Reforge Great in Steel", False, True)],
    18: [("Reforge Great into Great + Ember", True, True), ("Reforge Broad in Steel+", False, True)],
    19: [("Reforge Needle + Spark (same element)", False, True)],
}
ACTIVE_MIN_PER_STAGE = {s: 1.0 for s in STAGES}   # play + forge + UI, minutes (sim times are 0.4-1.4 min)


def report_economy(show=True):
    coins, ore, stones = START["coins"], START["ore"], START["stones"]
    lv = {"anvil": 1, "furnace": 1, "barracks": 1}
    held_ore = []          # ore paid for each weapon still on the rack (for refunds)
    idle_total, active_total = 0.0, 0.0
    rows = []
    for s in sorted(EXPECTED):
        a, f, b, _ = EXPECTED[s]
        need = []
        for fac, target in (("anvil", a), ("furnace", f), ("barracks", b)):
            while lv[fac] < target:
                need.append((fac, lv[fac] + 1))
                lv[fac] += 1
        cost = sum(UPGRADE_COST[fac][l] for fac, l in need)
        forge_ore, forge_stones, refund = 0, 0, 0
        for label, stone, smelt in FORGE_PLAN.get(s, []):
            c = FURNACE_ORE[lv["furnace"]]
            forge_ore += c
            forge_stones += int(stone)
            if smelt and held_ore:
                refund += math.floor(held_ore.pop(0) * ORE_REFUND)
            held_ore.append(c)
        net_ore = forge_ore - refund
        rc, ro = idle_rate(s - 1)
        farm = 0.0
        if coins < cost:
            farm = max(farm, (cost - coins) / rc)
        if ore < net_ore and ro:
            farm = max(farm, (net_ore - ore) / ro)
        if stones < forge_stones:
            farm = max(farm, (forge_stones - stones) * STONE_IDLE_MIN)
        coins += farm * rc
        ore += farm * ro
        if s - 1 >= TUTORIAL_CLEAR_STAGE:
            stones += farm / STONE_IDLE_MIN
        coins -= cost
        ore -= net_ore
        stones -= forge_stones
        fc, fo, fs = first_clear_reward(s)
        coins, ore, stones = coins + fc, ore + fo, stones + fs
        idle_total += farm
        active_total += ACTIVE_MIN_PER_STAGE[s]
        ups = ", ".join(f"{fac[0].upper()}{l}" for fac, l in need) or "-"
        rows.append((s, ups, cost, forge_ore, refund, forge_stones, fc, fo, fs, farm, coins, ore, stones,
                     idle_total, active_total))
    if show:
        print("| Stage | Upgrades bought (coins) | Forge ore / refund / stones | First clear coins/ore/stones |"
              " Farm min before stage | Balance after (coins/ore/stones) | Cumulative idle min | ≈ Day |")
        print("|---|---|---|---|---|---|---|---|")
        for (s, ups, cost, fo_, rf, fst, fc, fo, fs, farm, c, o, st, it, at) in rows:
            day = 1 + it / NATURAL_MIN_PER_DAY
            print(f"| {s} | {ups} ({cost}) | {fo_} / {rf} / {fst} | {fc} / {fo} / {fs} | {farm:.0f} |"
                  f" {c:.0f} / {o:.0f} / {st:.1f} | {it:.0f} | {day:.1f} |")
    return rows


def report_tables():
    print("| Level | Anvil budget | Anvil cost | Furnace metal | Metal base dmg | Ore per forge | Furnace cost | Hero HP | Barracks cost |")
    print("|---|---|---|---|---|---|---|---|---|")
    for l in range(1, 11):
        def c(fac):
            return UPGRADE_COST[fac].get(l, "-")
        print(f"| {l} | {ANVIL_BUDGET[l]} | {c('anvil')} | {FURNACE_METAL[l]} | {FURNACE_MD[l]} | {FURNACE_ORE[l]} |"
              f" {c('furnace')} | {BARRACKS_HP[l]} | {c('barracks')} |")
    print()
    print("| Stage | First clear coins | ore | stones | Idle coins/min | Idle ore/min |")
    print("|---|---|---|---|---|---|")
    for st in range(1, 21):
        fc, fo, fs = first_clear_reward(st)
        rc, ro = idle_rate(st)
        print(f"| {st} | {fc} | {fo} | {fs} | {rc} | {ro} |")


if __name__ == "__main__":
    what = sys.argv[1] if len(sys.argv) > 1 else "all"
    if what in ("weapons", "all"):
        report_weapons(); print()
    if what in ("matrix", "all"):
        report_matrix(); print()
    if what in ("stages", "all"):
        report_stages(); print()
    if what in ("economy", "all"):
        report_economy(); print()
    if what in ("tables", "all"):
        report_tables(); print()
    if what in ("safeguards", "all"):
        report_safeguards(); print()
    if what.startswith("stage="):
        report_all_builds(int(what.split("=")[1]))
