# Project Overview
Mindustry-inspired factory/tower-defense RTS on Roblox. Original IP — not a direct clone.
Players mine resources, build factory pipelines, defend against waves and fight other players.
The player physically walks around their base as part of gameplay flow.

# Game Modes
- Campaign — sector-based progression, 1-4 co-op, host migration
- PvP — two teams, 3 phases (Prep, Skirmish, Assault), first Core destroyed loses

# Framework & Packages
- Knit — Services (server), Controllers (client)
- Lief's DataService — all player data saving (in Packages)
- Rojo — file sync with VS Code

# Project Structure
```
ReplicatedStorage
└── Packages
    └── Knit
    └── DataService (Lief's)
└── Dictionaries
    └── ObjectNames
    └── Categories
└── Shared
    └── Config
        └── BuildingConfig
        └── FactoryConfig
        └── UnitFactoryConfig
        └── TurretConfig
        └── TurretBehaviorConfig
        └── UnitConfig
        └── BehaviorConfig
        └── ResearchTree
        └── ResourceConfig
        └── StorageConfig
        └── DrillConfig
        └── PowerConfig
        └── TransportConfig
    └── Util

ServerScriptService
└── Modules
    └── DataServiceModule
└── Services
    └── BuildingService
    └── ResourceService
    └── PowerService
    └── WaveService
    └── UnitService
    └── TurretService
    └── FactoryService
    └── ResearchService
    └── QuestService
    └── CampaignService
    └── PvPService
    └── CoopService
└── KnitServer.lua

StarterPlayerScripts
└── Controllers
    └── BuildController
    └── CameraController
    └── HUDController
    └── ResearchController
    └── QuestController
    └── FactoryController
    └── BuildingInfoController
    └── UnitController
    └── SettingsController
└── KnitClient.lua

StarterCharacterScripts
└── CharacterController
```

# Key Conventions
- Always reference object names via ObjectNames module — never hardcode strings
- Always reference categories via Categories module
- Config modules are pure data + getter APIs only — no game logic
- Services own game logic, configs own data
- OOP for individual game objects (Unit, Turret, Factory classes)
- Functional/Knit services manage collections of those objects
- Master class handles Basic logic, subclasses override special behavior
- All building placement validated server-side always
- Resources never trusted from client
- 4 studs per tile grid

# Naming Conventions
- Services: PascalCase, suffix Service (e.g. BuildingService)
- Controllers: PascalCase, suffix Controller (e.g. BuildController)
- Config modules: PascalCase, suffix Config (e.g. BuildingConfig)
- Classes: PascalCase, no suffix (e.g. Unit, Turret, Factory)
- Local variables: camelCase
- Constants: UPPER_SNAKE_CASE

# Categories Dictionary
```lua
Categories = {
    Factory = "Factory",
    Turret = "Turret",
    Wall = "Wall",
    Unit = "Unit",
    Core = "Core",
    ["Unit Factory"] = "Unit Factory",
    Drill = "Drill",
    ["Building Mender"] = "Building Mender",
    ["Unit Mender"] = "Unit Mender",
    Storage = "Storage",
    ["Power Generator"] = "Power Generator",
    Battery = "Battery",
    ["Power Node"] = "Power Node",
}
```

# Resource Chain
## Raw Ores (T1)
- Copper (Value 1), Tin (Value 1), Sand (Value 1)
- Coal (Value 2), Ironstone (Value 2)
- Bauxite (Value 3)
- Quartz (Value 4)
- Uranium (Value 6) — rare, late game only

## Liquids
- Water (Value 1) — extracted from water tiles
- Coolant (Value 3) — Bauxite + Water via Coolant Mixer
- Crude (Value 3) — Coal + Coolant via Crude Vat

## Processed Materials
- Bronze (Value 2) — Copper + Tin
- Ferrocast (Value 3) — Ironstone + Coal
- Aluminite (Value 3) — Bauxite
- Glassite (Value 2) — Sand + Copper
- Graphite (Value 2) — Coal
- Silicon (Value 3) — Coal + Sand
- Quartzite (Value 4) — Quartz + Ferrocast
- Steel (Value 6) — Ferrocast + Graphite — endgame cap
- Refined Uranium (Value 8) — Uranium
- Pyro Charge (Value 3) — turret ammo for Howitzer and Mortar

# Config File Schemas

## BuildingConfig
Fields: HP, Cost, BuildTime, Size{X,Y}, Category, Icon, Description,
        AcceptsResourceInput, AcceptsPowerInput, AcceptsUnitInput,
        OutputsResources, OutputsUnit

## FactoryConfig
Fields per entry: Inputs{[resource]={Amount, Capacity}}, Output, OutputAmount,
                  OutputCapacity, ProcessingTime, PowerNeeded
Key API: GetAdjustedProcessingTime(factoryId, currentPower) — scales with power efficiency

## UnitFactoryConfig
Fields: PowerNeeded, Recipes{[unitId]={Inputs{[resource]={Amount,Capacity}}, ProcessingTime}}
- Unit is spit out immediately on completion, no output buffer
- Advanced factories have completely separate rosters from Basic factories
Key API: GetAdjustedProcessingTime(factoryId, unitId, currentPower)

## TurretConfig
Fields: HP, MaxAmmo, Reload, EngagementRange, MinRange, Targets,
        Ammo, BulletStats{Damage, Speed, Range, Splash}

## TurretBehaviorConfig
Fields: Class, TargetLogic, ShootLogic, BulletLogic
Classes: BasicTurret, ArtilleryTurret, FlamethrowerTurret, TeslaTurret, LaserTurret

## UnitConfig
Fields: HP, Speed, UnitType(ObjectNames.Ground/Air), Targets(Ground/Air/Both/Neither),
        TargetAllies, ReloadSpeed, EngagementRange, ShootingRange, StoppingRange,
        RetreatingRange, Armor, BulletStats{Damage,Speed,Range,Name,Splash},
        AirSettings{MaxHeight,FallSpeed,FlySpeed} (air units only)
- BulletStats = nil for non-combat units
- AirSettings omitted for ground units

## BehaviorConfig
Fields: Class, MoveLogic, TargetLogic, ShootLogic, BulletLogic
Classes: BasicUnit, ArtilleryUnit, KamikazeUnit, BomberUnit, AirUnit,
         StealthUnit, MedicUnit, InterceptorUnit, ManufacturerUnit, CommanderUnit

## DrillConfig
Fields: BaseSpeed, WaterBonus, WaterNeeded(amount for full bonus),
        PowerNeeded, CanMine{[oreId]={Capacity}}
OreMultipliers: separate table, applied to BaseSpeed
Key API: GetDrillRate(drillId, oreId, currentWater, currentPower) — fully scaled rate
- Drill picks highest Value ore from ResourceConfig when placed on mixed deposits

## PowerConfig
Fields per generator: Category, Output(FC/sec), Inputs{[resource]={Amount,Capacity}}
Fields per battery: Category, Capacity(FC stored)
Fields per node: Category, Range(tiles), MaxLinks
- Passive generators (Solar, Geothermal) have Inputs = nil
- Batteries output whatever FC needed to reach net zero, calculated server-side

## StorageConfig
Fields: ItemCapacity(per type), LiquidCapacity, AcceptsLiquid
- Liquid Tank accepts one liquid type, rejects extras
- Vault standalone for now, Core pool merge planned later

## ResourceConfig
Fields: DisplayName, IconId, Kind(Ore/Liquid/Processed), Value, Description
Key API: GetHighestValueOre(oreList) — returns highest value ore from a set

## TransportConfig
Fields: Speed (items/sec or units/sec)
- Gate Splitter, Sieve, Crossway, Span Conveyor inherit speed from feeding belt

## ResearchTree
- DAG, one parent per node, can have multiple children
- Root nodes (free by default): Basic Drill, Conveyor, Cannon, Core Shard
- Costs multi-resource, Mindustry-scale (1000-10000 range)
- Resources spent from persistent cross-campaign bank
- Accessed via GUI between rounds, no physical building
Key APIs: CanUnlock(nodeId, unlockedSet), CanAfford(nodeId, resourceBank),
          GetDependencyChain(nodeId), DeductCost(nodeId, resourceBank)

# Power System
- Power unit: FC (Flux Charge), measured in FC/sec
- PowerNeeded in all configs is a number, 0 = no power required
- Power scales proportionally — underpowered buildings slow down, not stop
- Nuclear Reactor requires Refined Uranium + Coolant continuously
- Safety Module upgrade — clean shutdown on coolant loss instead of meltdown
- Reinforcement Module upgrade — higher HP
- No Uranium loaded = no explosion when destroyed
- Reactor goes red before meltdown — short window to intervene
- Meltdown = large explosion, region unbuildable for a duration
- Enemy destroying fuelled reactor = instant meltdown

# Transport System
## Solid Items
Conveyor (5/s) → Express Conveyor (10/s) → Reinforced Conveyor (10/s, high HP) → Sprint Conveyor (14/s, fragile)
Special: Gate Splitter (overflow), Sieve (filter), Crossway (crossing), Span Conveyor (bridge)

## Liquids
Duct (10/s) → Conduit (22/s)
Special: Pipe Bridge (bridge), Manifold (router)

## Payload (Units)
Haul Sled → Haul Router → Dispatch Bay (all Speed 4)
Unit spit out immediately on completion at Dispatch Bay

# Unit Factories
## Rosters
Tank Basic: Basic Tank, Light Tank, Basic Heavy Tank
Tank Advanced: Super Heavy Tank, Sniper Tank, Howitzer Tank
Drone Basic: Basic Drone, Bomber Drone, Kamikaze Drone
Drone Advanced: Gunship, AA Drone, Stealth Drone
Support Basic: Artillery Walker, AA Crawler, Medic Walker
Support Advanced: Projectile Interceptor, Kamikaze Drone Manufacturer, Commander

## Rules
- Advanced factories do NOT produce Basic factory units — completely separate rosters
- Unit output immediately on completion, no buffer
- Drone factories: units launch directly into air, no Haul Sled needed

# Special Units
## Medic Walker
- Heals nearby units and buildings
- Rebuilds destroyed buildings from shadow footprint using player resources
- Configurable priority order via UI (Heal Units / Heal Buildings / Rebuild)
- Battle zone avoidance toggle
- Pauses rebuild if resources run out, player can override to heal

## Commander
- Assigns up to 10 units
- Battle plans: Secure Area, Garrison, Strike and Retreat, Intercept, Escort
- No combat ability
- Fills gap between raw unit AI and player micro

## Kamikaze Drone Manufacturer
- Slow, fragile ground unit
- Passively spawns Kamikaze Drones at interval when enemies in range
- No weapons

## Projectile Interceptor
- Shoots down incoming slow projectiles (artillery, bombs)
- Does not target units directly

# Defense
## Turret Ammo Resources
- Cannon: Copper
- Flak Turret: Bronze
- Howitzer: Pyro Charge
- Railgun: Aluminite
- Flamethrower: Crude
- Tesla Tower: Silicon
- Mortar: Pyro Charge
- Sniper: Ferrocast
- Laser Cannon: Quartzite

## Walls (tier order)
Ironstone Wall → Ferrocast Wall → Quartzite Wall → Steel Wall

# Player Data Template
```lua
{
    Profile = { Level = 0, XP = 0, Gems = 0 },
    Settings = { SFX = 0.5, Music = 0.5 },
    Research = {},        -- unlocked node ids as true flags
    Campaign = {},        -- ["sector_id"] = { Completed, Stars }
    Quests = {
        Completed = {},
        Active = {},      -- ["quest_id"] = { Progress, StartedAt }
        DailyReset = 0,
        WeeklyReset = 0,
    },
}
```
- Research per player — each player uses own research in co-op
- Campaign per player — no star rating piggyback in co-op
- Quests save mid-objective progress
- Gems server authoritative — client fires RemoteEvent for purchase request only
- Single nested DataStore key per player

# Asset Standards
- Buildings: Studio primitives, unique top-face texture, shared side textures per category
- Top face is the identity face — camera is top-down
- Color per category: Drills=purple, Factories=blue, Power=orange, Turrets=red,
  Transport=grey, Unit Factories=green, Units=military green/tan
- Tier visual rule: T1=flat/no glow, T2=accent+subtle glow, T3=strong glow+more detail
- Building heights: Walls=6 studs, Drills=4, Factories=5-6, Reactor=10, Core tiers=8/12/16

# TODO — Configs Needed Later
- WaveConfig — enemy wave compositions, lives in its own folder with a module accessor
- Enemies reuse UnitConfig — no separate EnemyConfig needed
- Conveyor capacity/buffer — may be needed when building ResourceService
- Liquid Extractor tile mappings — which tile type produces which liquid
- Turret ammo depletion rate — currently MaxAmmo + Reload in TurretConfig but no per-shot consumption rate