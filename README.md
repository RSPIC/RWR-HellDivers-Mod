# RWR HellDivers Mod
 基于running with rifle（小兵步枪）游戏的，以Helldivers（地狱潜者）游戏内容为主的模组
 
# 进度
+ 未完成（无标识）
+ √ **已完成**（√标记）
+ **正在进行**（粗体）

## 按总体框架
+ **阵营**
    + **Helldivers 地狱潜兵**
    + **Cyborgs 生化人**
    + Illuminate 光能者
    + Bugs 虫族
    + ACG 二次猿
+ **伤害与护甲系统**
    + 伤害类型
        <details> <summary>Title</summary>
        contents ...
        </details>
    + 护甲类型
        <details> <summary>Title</summary>
        contents ...
        </details>
    + 友军伤害
    + 自动回血
+ 经济系统
    + 战利品系统
        + 样本类战利品全局共享，但拾取者概率获得双倍
    + 收益和损失
        + 合作收益
            + 所有武器带空盾块，近距离可以共享击杀收益，潜行可以独享收益
        + 击杀/摧毁收益
            + 仅获得经验
        + 占领收益
            + 主攻点：经验收益高，货币收益少
            + 次要点：经验收益少，货币收益高
        + 
+ **武器和载具系统**
    + **视音效**
        + √ **粒子系统**
        + **音效库**
    + 升级/改造系统
        + 固定改造分支，玩家沿固定升级改造路线升级枪械至满级
        + 该类枪械掉落消失，不可交易
    + 再补给系统
        + 部分副手栏武器是有限子弹的，是否可以通过脚本补给
    + 逆向工程系统
        + 任何稀有度的武器只要攒满7把，即可获得一把属性略有削弱的复活自带版本
        + 不会削弱其优势性属性
    + 稀有度/获取方式
        + 军械库出售
        + 公文包解锁
        + 空投支援
        + 地图刷新
        + 抽奖
        + 限量发放
    + **功能分类和定位**
        + √ **AR 突击步枪系**
            + 泛用好
        + √ **SMG 冲锋枪系**
            + 独享特殊的尾迹粒子
        + √ **MG 机枪系**
            + 笨重但强力
        + √ **SG 霰弹枪系**
            + 保证近距离优势
        + √ **Precision 精确武器**
            + 保证体验手感，高穿透高伤害
        + **Explosive 榴弹/爆炸类系**
            + 溅射系统
        + Sidearms 副手系
            + 功能性强
        + √ **Laser Tech 激光系**
            + 保证持续性火力突出
        + Arc Tech 电弧系
            + 近距离群攻优势大于SG，Stun伤害可控场
        + Melle 近战系
            + 特效和音效要好
        + Magic 魔法系
            + 特效优秀
        + Deploy 部署系
            + 强力
            + 可合作
            + 音效优秀
        + Skill 技能系
            + 有特色
        + Suppressed 消音系
            + 枪械附带隐蔽加成
            + 枪械附带抗致死减成
        + Consume 消耗品系
            + 强力
            + 再补给有门槛
+ 养成系统
    + 经验（军衔）系统
        + 经验解锁/限制物品
            + 特定经验后可解锁更强力武器
            + 可以提供新手期特供强力武器，超过一定经验后限制使用
        + 各等级军衔HUD
        + 转阶系统
            + 到达最高军衔之后可以选择选择转阶重置经验为0，保留RP
            + 转阶后玩家转入特定的Soldier Group（相当于永久改造），拥有基础属性的永久增益，同时解锁特定披风等Resource
            + 转阶收益可叠加在其他改造上（额外写一些组然后copy_from）
    + 收集/兑换系统
        + 披风收集/兑换
        + 稀有武器、玩具收集/兑换
        + 活动限定物品等
    + 信物系统
        + 默认均为手雷投掷物
        + 可通过补给箱脚本再补给
+ 战斗系统
    + Ai行为和逻辑
    + 地图目标
    + 触发型事件（可否实现）
        + 护送人质？
        + 运送黑匣子？
        + 临时守护目标点？ 
        + 排雷？
        + 击毙特定单位？
 + 改造系统
     + 自动改造批处理程序
     + 注重功能性改造而非属性改造
     + 改造分支
         + Precision Expert
             + Precision Expert Uniform 披风
             + 指令呼叫增援的CD更短 -40%
             + Call增援呼叫更快
             + Vindicator Dive Bomb 呼叫权（辩护者）
             + P-6 Gunslinger 购买权（神射手手枪）
         + Ranger
             + Ranger Uniform 披风
             + Humblebee UAV 部署权（小蜜蜂）
             + 获得EAT-17 部署权（空投一次性便携反坦克武器）
             + 获得Stun Grenades 购买权（眩晕手雷）
             + 获得LHO-63 Camper 购买权（野营者精确步枪）
         + Entrenched 
             + Demolitionist Uniform 披风
             + REC-6 Demolisher 部署权（便携C4包）
             + A/GL-8 Launcher Turret 部署权（榴弹发射炮台）
             + AT-47 Anti-Tank Emplacement 部署权（反坦克炮台）
             + Thunderer Barrage 轰炸支援呼叫权（三重轰炸）
         + Defender
             + Defender Uniform 披风
             + 重型护甲（额外层数，略微减速）
             + CR-9 Suppressor 购买权（直射空炸榴弹）
             + TD-110 Bastion 坦克呼叫权
             + FLAM-24 Pyro 购买权（副手火焰发射器）
         + Pilot
             +	Pilot Uniform 披风
             + 永久携带跳包（修改角色Dive动作属性），可翻越障碍
             + EXO-48 Obsidian Exosuit 机甲部署权
             +	EXO-51 Lumberer Exosuit 机甲部署权
             + AC-5 Arc Shotgun 购买权（电弧霰弹枪)
         + Specialist
             + Specialist Uniform 披风
             + LAS-12 Tanto 购买权（三叉戟）
             +	Close Air Support 轰炸支援呼叫权
             + Saber 购买权（光剑）
             + RL-112 Recoilless Rifle 部署权(复装无后坐力反坦克炮）
         + Support
             + Support Uniform 披风
             + LAS-16 Sickle 购买权（镰刀）
             + AD-289 Angel 部署权（改为副手范围救人设备）
             + 更短的 Resupply 部署时间
             + REP-80 部署权（载具远距离修复装置）
         + Commando
             + Commando Uniform 披风
             + MLS-4X Commando 部署权（跟踪导弹/脚本）
             + SMG-34 Ninja 购买权（忍者消音冲锋枪）
             + PLAS-3 Singe 购买权（焦土手枪）
             + Heavy Strafing Run 机枪支援呼叫权
## 按阵营内容
+ **HellDivers**
    + **武器** [https://helldivers.fandom.com/wiki/Stratagems] [https://helldivers.fandom.com/wiki/Weapons]
        + **Sidearms**
            >+ √ **P-2 Peacemaker**
            >+ √ **P-6 Gunslinger**
            >+ FLAM-24 Pyro
            >+ PLAS-3 Singe
        + √ **Assault Rifles**
            >+ √ **AR-19 Liberator**
            >+ √ **AR-22C Patriot**
            >+ √ **AR-20L Justice**
            >+ √ **AR-14D Paragon**
        + **LMGs**
            >+ √ **MG-105 Stalwart**
        + √ **Shotguns**
            >+ √ **SG-225 Breaker**
            >+ √ *8SG-8 Punisher**
            >+ √ **DBS-2 Double Freedom**
        + √ **SMGs**
            >+ √ **SMG-45 Defender**
            >+ √ **MP-98 Knight SMG**
            >+ √ **SMG-34 Ninja**
        + √ **Precision**
            >+ √ **LHO-63 Camper**
            >+ √ **RX-1 Rail Gun**
            >+ √ **M2016 Constitution**
        + **Explosive**
            >+ √ **CR-9 Suppressor**
            >+ √ **PLAS-1 Scorcher**
        + √ **Laser Tech**
            >+ √ **LAS-5 Scythe**
            >+ √ **LAS-16 Sickle**
            >+ √ **LAS-12 Tanto**
            >+ √ **LAS-13 Trident**
        + Arc Tech
            >+ AC-3 Arc Thrower
            >+ AC-5 Arc Shotgun
        + Melee
            >+ Saber
    + **护甲**
        + **helldivers_vest** 通用护甲(待裁定伤害系统）
    + **模型** [https://helldivers.fandom.com/wiki/Armor]
        + Tactical
        + Desert
        + Woodland
        + Arctic
        + √ **Black Ops**
        + Veteran
        + √ **Volcanic** 
        + Heroic
        + Admiral
        + √ **Ceremonial**
        + Faction-Specific Capes
        + Assault
        + Liberty Cape
        + Next-Gen
        + Proving Grounds Specific Capes
        + Ranger
        + Commando
        + Defender
        + Support
        + Demolitionist
        + Hazard Ops
        + Pilot
        + Specialist
        + All-Terrain
        + Precision Expert
        + Community Cape
        + Developer Cape
        + Training Cape
    + 载具
        + Deploy:Vehicles
            >+ **EXO-44 Walker Exosuit**
            >+ **EXO-48 Obsidian Exosuit**
            >+ **EXO-51 Lumberer Exosuit**
            >+ √ **M5 APC**
            >+ M5-32 HAV
            >+ TD-110 Bastion
            >+ MC-109 Hammer Motorcycle
    + **投掷物**
        + Deploy:Support
            >+ Resupply
            >+ REP-80
        + Deploy:BackPacks
            >+	AD-289 Angel
            >+	AD-334 Guard Dog
            >+ LIFT-850 Jump Pack
            >+ Resupply Pack
            >+ SH-20 Shield Generator Pack
            >+ SH-32 Directional Kinetic Shield
        + **Deploy:Secondary Weapons**
            >+ AC-22 Dum-Dum
            >+ EAT-17
            >+ FLAM-40 Incinerator 
            >+ √ **LAS-98 Laser Cannon**
            >+ √ **M-25 Rumbler**
            >+ √ **MG-94 Machine Gun**
            >+ MGX-42 Machine Gun
            >+ MLS-4X Commando
            >+ √ **Obliterator Grenade Launcher**
            >+ REC-6 Demolisher
            >+ RL-112 Recoilless Rifle
            >+ TOX-13 Avenger
        + Defensive
            >+ A/AC-6 Tesla Tower
            >+ A/GL-8 Launcher Turret
            >+	A/MG-11 Minigun Turret
            >+	A/RX-34 Railcannon Turret
            >+	√	**Airdropped Anti-Personnel Mines**
            >+	√	**Airdropped Stun Mines**
            >+	Anti-Personnel Barrier
            >+	AT-47 Anti-Tank Emplacement
            >+	Distractor Beacon
            >+	Humblebee UAV drone
            >+	Thunderer Smoke Round
        + **Offensive**
            >+ Airstrike
            >+	Close Air Support
            >+	Heavy Strafing Run
            >+	Incendiary Bombs
            >+	Missile Barrage
            >+	Orbital Laser Strike
            >+	Railcannon Strike
            >+	Shredder Missile Strike
            >+	Sledge Precision Artillery
            >+	Static Field Conductors
            >+	Strafing Run
            >+	Thunderer Barrage
            >+ √	**Vindicator Dive Bomb**
        + Special
            >+ Emergency Beacon
            >+	ME-1 Sniffer Metal Detector
            >+	NUX-223 Hellbomb
            >+ Reinforce
    + 掉落物
        + 空
    + AI逻辑
        + 空
    + **角色属性**
        + helldivers_default_base.character 父级
            + helldivers_default_chat.character 子集
    + Call支援
        + 空
    + 翻译
+ Cyborgs
    + 武器
        + cyborgs_all_weapons.xml 附带注释
    + 护甲
        + 空
    + 模型 [https://helldivers.fandom.com/wiki/Cyborgs]
        + Scout
            >+ √	**'Squadleader' Soldier**
            >+ √	**Legionnaire**
        + Infantry
            >+ √	**Initiate**
            >+ √	**Immolator**
            >+ √	**Comrade**
            >+ √	**Berserker**
            >+ √	**Butcher**
            >+ √	**Hound**
            >+ √	**Grotesque**
        + Tank
            >+ √	**Hulk**
            >+ Infantry Fighting Vehicle
        + Elite
            >+ Warlord
        + Master
            >+ Siege Mech
    + 载具
        + Infantry Fighting Vehicle
    + 投掷物
        + cyborgs_all_throwables.xml 附带注释
    + 掉落物
    + AI逻辑
        + **squadleader.ai**
        + **legionnaire.ai**
        + **initiate.ai**
        + **immolator.ai**
        + **comrade.ai**
        + **berserker.ai**
        + **butcher.ai**
        + **hound.ai**
        + **grotesque.ai**
        + **hulk.ai**
    + 角色属性
        + cyborgs_default_base.character 父级
            + cyborgs_default_chat.character 子集
                >+ cyborgs_squadleader_state
                >+ cyborgs_legionnaire_state
                >+ cyborgs_initiate_state
                >+ cyborgs_immolator_state
                >+ cyborgs_comrade_state
                >+ cyborgs_berserker_state
                >+ cyborgs_butcher_state
                >+ cyborgs_hound_state
                >+ cyborgs_grotesque_state
                >+ cyborgs_hulk_state
    + Call支援
    + 翻译
+ Illuminate
+ Bugs
