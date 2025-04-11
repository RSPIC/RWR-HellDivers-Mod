// internal
#include "tracker.as"
#include "helpers.as"
#include "admin_manager.as"
#include "log.as"
#include "query_helpers.as"
#include "query_helpers2.as"
#include "gamemode.as"
#include "gamemode_invasion.as"

#include "dynamic_alert.as"
#include "debug_reporter.as"
#include "INFO.as"

//Author： rst
//每日任务脚本

//todo : 新增突发事件，临时增加任务
//todo ：新增成就任务，只能完成一次
//todo ：合并支线任务接口


array<MissionCounter@> collector = {
    (MissionCounter("collect_mc_iron.carry_item","铁锭",30)),
    (MissionCounter("collect_mc_gold.carry_item","金锭",30)),
    (MissionCounter("collect_mc_emerald.carry_item","绿宝石",20)),
    (MissionCounter("collect_mc_diamond.carry_item","钻石",30))

};

array<MissionCounter@> kill_with_select_weapon = {
    (MissionCounter("hd_ar_ar19_liberator_full_upgrade.weapon","AR19解放者",80)),
    (MissionCounter("hd_ar_ar14d_paragon_full_upgrade.weapon","AR14D典范",80)),
    (MissionCounter("hd_ar_ar22c_patriot_full_upgrade.weapon","AR22C爱国者",80)),
    (MissionCounter("hd_ar_ar20l_justice_full_upgrade.weapon","AR20L正义",80)),
    (MissionCounter("hd_ar_ar77d_spade_mk3.weapon","AR77D黑桃",80)),

    (MissionCounter("hd_sg_sg225_breaker_full_upgrade.weapon","SG225破裂者",80)),
    (MissionCounter("hd_sg_sg8_punisher_full_upgrade.weapon","SG8制裁者",80)),
    (MissionCounter("hd_sg_double_freedom_full_upgrade_damage.projectile","DBS2双重解放",80)), //blast

    (MissionCounter("hd_smg_smg45_defender_full_upgrade.weapon","SMG45防卫者",80)),
    (MissionCounter("hd_smg_mp98_knight_smg_full_upgrade.weapon","MP98骑士",80)),
    (MissionCounter("hd_smg_smg34_ninja_full_upgrade.weapon","SMG34忍者",80)),
    (MissionCounter("hd_smg_tc171_cyclone_mk3.weapon","TC171气旋",80)),

    (MissionCounter("hd_psc_lho63_camper_full_upgrade.weapon","LHO63野营者",60)),
    (MissionCounter("hd_psc_rx1_railgun_full_upgrade_damage.projectile","RX1轨道炮",20)), //blast
    (MissionCounter("hd_psc_m2016_constitution_full_upgrade.weapon","M2016构建",50)), 
    (MissionCounter("hd_psc_atx25_revelator_mk3_damage.projectile","ATX25启示者",30)), //blast
    (MissionCounter("hd_psc_hho874_fraternity_mk3.weapon","HHO874博爱",50)),

    (MissionCounter("hd_hmg_mg107.weapon","MG107淬火",80)),
    (MissionCounter("hd_lmg_mg94_mk3.weapon","MG94",80)),
    (MissionCounter("hd_lmg_mgx42_mk3.weapon","MGX42",80)),
    (MissionCounter("hd_lmg_mg105_stalwart_full_upgrade.weapon","MG105盟友",80)),
    (MissionCounter("hd_hmg_mg255_melt_damage.projectile","MG255熔点",80)), //blast

    (MissionCounter("hd_laser_las13_trident_full_upgrade.weapon","LAS13三叉戟",80)),
    (MissionCounter("hd_laser_las12_tanto_full_upgrade.weapon","LAS12短刀",80)),
    (MissionCounter("hd_laser_las16_sickle_full_upgrade.weapon","LAS16镰刀",80)),
    (MissionCounter("hd_laser_las5_scythe_full_upgrade.weapon","LAS5长柄镰",80)),
    (MissionCounter("hd_laser_las98_laser_cannon_mk3.weapon","LAS98激光大炮",80)),

    (MissionCounter("hd_pst_tox13_avenger_mk3_damage.projectile","TOX13复仇者",80)), //blast
    (MissionCounter("hd_pst_tox17_sourhound_damage.projectile","TOX17酸液犬",80)), //blast
    (MissionCounter("hd_exp_m25_rumbler_full_upgrade_damage.projectile","M25雷鸣者",80)), //blast
    (MissionCounter("hd_exp_obliterator_grenade_launcher_full_upgrade_damage.projectile","消灭者榴弹",80)), //blast
    (MissionCounter("hd_exp_rl112_recoilless_rifle_mk3_damage.projectile","Rl112无后坐力火箭筒",20)), //blast
    (MissionCounter("hd_exp_eta17_mk3_damage.projectile","ETA17抛弃式火箭",80)), //blast
    (MissionCounter("hd_exp_rec6_demolisher_mk3_damage.projectile","REC6爆破手",30)), //blast
    (MissionCounter("hd_exp_cr9_suppressor_full_upgrade_damage.projectile","CR9抑制者",80)), //blast
    (MissionCounter("hd_exp_plas1_scorcher_full_upgrade_damage.projectile","Plas1焦土",80)), //blast
    (MissionCounter("hd_exp_plas1_scorcher_full_upgrade_damage.projectile","Plas3焦痕",80)), //blast
    (MissionCounter("hd_exp_ac22_dum_dum_mk3_damage.projectile","AC22达姆",80)), //blast
    (MissionCounter("hd_exp_mls4x_commando_mk3_damage.projectile","MLS4X突击队",30)), //blast
    (MissionCounter("hd_pst_flam40_incinerator_mk3_damage.projectile","Flam40焚化炉",80)), //blast
    (MissionCounter("hd_pst_flam40_incinerator_mk3_damage.projectile","Flam24烈焰",80)), //blast
    (MissionCounter("hd_lava17_roger_damage.projectile","Lava17游骑兵",80)), //blast
    (MissionCounter("hd_arc_ac5_shotgun_full_upgrade_damage.projectile","AC5电弧霰弹枪",80)), //blast
    (MissionCounter("hd_arc_ac3_thrower_full_upgrade_damage.projectile","AC3电弧发射器",80)), //blast

    (MissionCounter("hd_arc_as7_semiconductor_mk3.weapon","AS7半导体",25)),
    (MissionCounter("hd_arc_as5_resistance_mk3.weapon","AS5电阻",80)),
    (MissionCounter("hd_arc_mgc_capacitor_mk3.weapon","MGC电容",80)),

    (MissionCounter("hd_side_hg871_woodpecker.weapon","HG871啄木鸟",80)),
    (MissionCounter("hd_side_p2_peacemaker_full_upgrade.weapon","P2和平使者",80)),
    (MissionCounter("hd_side_digger_drill_damage.projectile","掘进者电钻",80)), //blast
    (MissionCounter("hd_side_p6_gunslinger.weapon","P6神枪手",80))

};

array<MissionCounter@> play_selected_mode = {
    (MissionCounter("Helldiver","地狱潜兵模式",1)),
    (MissionCounter("Vanilla","香草模式",1)),
    (MissionCounter("Zombie","僵尸模式",1)),
    (MissionCounter("Racing","完成赛车比赛",1))

};

array<MissionCounter@> kill_selected_enemy = {
    (MissionCounter("EnemyElite","敌方精英",20)),

    (MissionCounter("Zombie","僵尸",150)),
    (MissionCounter("EXO","地狱潜兵机甲",2))

};

class missionExchangeList{
    string m_mission_name;
    array<XmlElement@>@ m_deleteObjects;
    array<XmlElement@>@ m_getObjects;

    missionExchangeList(string name,array<XmlElement@>@ deleteObjects,array<XmlElement@>@ getObjects){
        m_mission_name = name;
        @m_deleteObjects = @deleteObjects;
        @m_getObjects = @getObjects;
    }
}

array<missionExchangeList@> missionExchangeLists ={
    missionExchangeList(
        "any",
        array<XmlElement@>= {
        }, 
        array<XmlElement@>= {
            getStashXmlElement("hd_money_1k","carry_item",3)
        }
    ),
    missionExchangeList(
        "TaskType",
        array<XmlElement@>= {
        }, 
        array<XmlElement@>= {
            getStashXmlElement("hd_money_1w","carry_item",1)
        }
    ),
    missionExchangeList(
        "TaskHardType",
        array<XmlElement@>= {
        }, 
        array<XmlElement@>= {
            getStashXmlElement("hd_money_1w","carry_item",2)
        }
    ),
    missionExchangeList(
        "TaskHonorType",
        array<XmlElement@>= {
        }, 
        array<XmlElement@>= {
            getStashXmlElement("hd_money_10w","carry_item",10)
        }
    ),
    missionExchangeList(
        "TaskHonorSpecialType",
        array<XmlElement@>= {
        }, 
        array<XmlElement@>= {
            getStashXmlElement("reward_box_collection.carry_item","carry_item",1)
        }
    ),
    missionExchangeList(
        "TaskFinish",
        array<XmlElement@>= {
        }, 
        array<XmlElement@>= {
            getStashXmlElement("hd_vote_ticket","carry_item",2),
            getStashXmlElement("lottery_cash.carry_item","carry_item",30),
            getStashXmlElement("hd_bonusfactor_al_10","carry_item",1)
        }
    ),
    missionExchangeList(
        "TaskHardFinish",
        array<XmlElement@>= {
        }, 
        array<XmlElement@>= {
            getStashXmlElement("samples_bugs_ex.carry_item","carry_item",1),
            getStashXmlElement("samples_cyborgs_ex.carry_item","carry_item",1),
            getStashXmlElement("samples_illuminate_ex.carry_item","carry_item",1),
            getStashXmlElement("hd_bonusfactor_xp_125","carry_item",1)
        }
    ),
    missionExchangeList(
        "SignInDays10",
        array<XmlElement@>= {
        }, 
        array<XmlElement@>= {
            getStashXmlElement("re_ex_ra2_tanya.weapon","weapon",2)
        }
    ),
    missionExchangeList(
        "SignInDays20",
        array<XmlElement@>= {
        }, 
        array<XmlElement@>= {
            getStashXmlElement("ex_cl_banzai_senpai.weapon","weapon",2)
        }
    )
};

class MissionCounter {
    string m_task_name;
    string m_task_CNname = m_task_name;
    string m_task_type;
    string m_task_version = "";
    int m_need_times;
    int m_finished_times;
    MissionCounter@ m_subMission;
    bool m_finished = false;

    MissionCounter(string name,string CNname,int needs,string type = "Task",string version = ""){
        m_task_name = name;
        m_need_times = needs;
        m_finished_times = 0;
        m_task_type = type;
        m_task_CNname = CNname;
        m_task_version = version;
    }
    MissionCounter(string name,string CNname,array<MissionCounter@> subMissions,string type = "Task",string version = ""){
        m_task_name = name;
        m_finished_times = -1;
        m_need_times = -1;
        m_task_type = type;
        m_task_CNname = CNname;
        m_task_version = version;
        // 确保传入的数组不为空且有元素
        uint randomIndex = rand(0,subMissions.size()-1); 
        for(uint i = 0; i < subMissions.size() ; ++i){
            if(i == randomIndex){
                MissionCounter@ SubMiss = subMissions[i];
                @m_subMission = SubMiss;
                break;
            }
        }
    }
    MissionCounter(string name,string CNname,MissionCounter@ subMissions,string type = "Task"){
        m_task_name = name;
        m_finished_times = -1;
        m_need_times = -1;
        m_task_type = type;
        m_task_CNname = CNname;
        @m_subMission = subMissions;
    }
    // 克隆方法
    MissionCounter@ clone() {
        MissionCounter@ clone = MissionCounter(m_task_name, m_task_CNname, m_need_times, m_task_type);
        clone.m_finished_times = this.m_finished_times;
        clone.m_finished = this.m_finished;
        if (this.m_subMission !is null) {
            @clone.m_subMission = this.m_subMission.clone(); // 递归克隆子任务
        }
        return clone;
    }
    bool addTimes(int times){ // 正负均可
        if(!hasSubMission()){
            m_finished_times += times;
            if(m_need_times <= m_finished_times){
                if(!m_finished){
                    m_finished = true;
                    return true;
                }
            }
        }else{
            if(m_subMission !is null){
                if(m_subMission.addTimes(times)){
                    if(!m_finished){
                        m_finished = true;
                        return true;
                    }
                }
            }
        }
        return false;
    }
    void setSubMission(MissionCounter@ subMission) {
        @m_subMission = @subMission;
    }
    bool hasSubMission(){
        if(m_subMission !is null){
            return true;
        }
        return false;
    }
}

class playerMissionInfo {
    // 使用立刻结算方法，不采用统一结算
    Metagame@ m_metagame;
    string m_name;
    string m_sid;
    array<MissionCounter@> m_missions; //DailyTask 固定内容
    array<MissionCounter@> m_honor_missions; //HonorTask 固定内容
    bool m_finish_today = false;
    int m_nowDay;
    int m_testToday = 0;

    array<MissionCounter@> dailyTasks;
    array<MissionCounter@> dailyTasks_hard;
    array<MissionCounter@> dailyTasks_honor;

    void buildMissions(){
        // 使用 push_back 方法添加元素
        dailyTasks.push_back(MissionCounter("kill_enemy_100", "击杀敌人", 100));
        dailyTasks.push_back(MissionCounter("timeplay_min_20", "游玩分钟", 20));
        dailyTasks.push_back(MissionCounter("buy_lottery_10", "买彩票", 10));
        dailyTasks.push_back(MissionCounter("play_selected_mode", "游玩指定模式", play_selected_mode));
        dailyTasks.push_back(MissionCounter("kill_with_select_weapon", "指定武器击杀", kill_with_select_weapon));

        dailyTasks_hard.push_back(MissionCounter("kill_selected_enemy", "击杀指定敌人", kill_selected_enemy, "TaskHard"));
        dailyTasks_hard.push_back(MissionCounter("timeplay_min_60", "游玩分钟", 60, "TaskHard"));
        dailyTasks_hard.push_back(MissionCounter("kill_with_melee", "近战击杀", 10, "TaskHard"));
        dailyTasks_hard.push_back(MissionCounter("finish_sidemission", "完成支线任务", 2, "TaskHard"));
        dailyTasks_hard.push_back(MissionCounter("collector", "收集战利品", collector, "TaskHard"));
    }
    void buildHonorMissions(){
        // 使用 push_back 方法添加元素
        dailyTasks_honor.push_back(MissionCounter("kill_enemy_5w", "击杀敌人", 50000, "TaskHonorSpecial"));
        dailyTasks_honor.push_back(MissionCounter("timeplay_min_6000", "游玩分钟", 6000, "TaskHonor"));
    }

    playerMissionInfo(Metagame@ metagame,string name){
        buildMissions();
        buildHonorMissions();
        @m_metagame = @metagame;
        m_name = name;
        m_sid = g_playerInfoBuck.getSidByName(m_name);
        writeMissionInfo("",null);
        getPermission();
        getSignInReward();
        _log("build playerMissionInfo for "+name);
    }
    protected bool writeMissionInfo(string TagName,XmlElement@ newXml,int syncTime = -1) {
        array<XmlElement@> newXmls;
        newXmls.insertLast(newXml);
        return writeMissionInfo(TagName,newXmls,syncTime);
    }
    protected bool writeMissionInfo(string TagName,array<XmlElement@> newXmls,int syncTime = -1) {
        _log("writeMissionInfo="+TagName+" syncTime="+syncTime);
        string sid = g_playerInfoBuck.getSidByName(m_name);
        sid = m_sid;
        if(sid == ""){return false;}
        // 单人战役情况下，复活事件首次不会产生，通常在脚本执行前
        // 因此玩家信息无法正常被读取，此时sid = ""，存储文件会在_stash.xml里面
        // 然而单机如果开启了服务器，玩家再次进入自己的存档时候，SID不再为ID0，而是正常SID
        // 这会导致再次游玩时部分进度清空
        // 因此，对于单机战役，在g_playerInfoBuck里检测并强制统一为ID0。是否单机由启动脚本决定
        _log("writeMissionInfo for "+m_name+"syncTime="+syncTime+"newXmls.size()="+newXmls.size());
        XmlElement@ allInfo = XmlElement(readPlayerStashInfo(sid));
        if (allInfo is null) {
            _log("allInfo is null, in initiateMissionInfo");
            return false;
        }
        // 读取存档玩家账号信息
        array<const XmlElement@> m_stashs = allInfo.getChilds();

        allInfo.removeAllChild();
        //解决空子项问题
        XmlElement a("player");
        a.setBoolAttribute("onRemove",true);
        allInfo.appendChild(a);
        bool findMission = false;
        bool isTrue = false;
        for(int j = 0 ; j < int(m_stashs.size()) ; ++j){
            if(syncTime == -114514){ //重置玩家任务信息进度,强制清空
                break;
            }
            XmlElement@ m_stash = XmlElement(m_stashs[j]);
            _debugReport(m_metagame,"m_stash.getName()="+m_stash.getName());
            if(m_stash.getName() == "mission"){
                findMission = true;
                _debugReport(m_metagame,"找到玩家任务信息");
                array<const XmlElement@> childs = m_stash.getChilds();
                m_stash.removeAllChild();
                bool isFindSubTag = false; // 用于觉得是否新建同类项，添加新任务时有用
                for(uint i = 0 ; i < childs.size() ; ++i){
                    XmlElement@ child = XmlElement(childs[i]);
                    if(child is null){continue;}
                    if(TagName == child.getName()){ // 子级比对,DailyTask or HonorMission
                        isFindSubTag = true;
                        bool updateFinishInfo = false; // 决定是否重置玩家的每日任务
                        bool updateHonorFinishInfo = false; // 决定是否重置玩家的每月任务
                        if(syncTime != -1 && syncTime >= 0){ // 需要同步玩家登陆日期信息 此处应对于DailyTask项
                            int lastDay = child.getIntAttribute("lastDay");
                            if(lastDay < syncTime){ // 排除同一天的累计更新
                                if(lastDay > syncTime - 3){ // 三个游戏日内算连续登陆
                                    int continueSignInDays = child.getIntAttribute("continueSignInDays");
                                    if(continueSignInDays > lastDay){
                                        continueSignInDays = lastDay;
                                    }
                                    child.setIntAttribute("continueSignInDays",++continueSignInDays);
                                }
                                // 更新总签到次数
                                int signInDays = child.getIntAttribute("signInDays");
                                child.setIntAttribute("signInDays",++signInDays);
                                // 更新玩家最后游玩日期
                                child.setIntAttribute("lastDay",syncTime);
                                updateFinishInfo = true;
                                _log("pass sync,oldDay="+lastDay+" toDay="+syncTime+", ready to refresh missionInfo for "+m_name);
                            }
                        }
                        if(TagName == "HonorMission"){  //月度任务检查
                            string nowVersion = getServerVersion(m_metagame);
                            string lastVersion = child.getStringAttribute("lastVersion");
                            _log("lastVersion ="+lastVersion);
                            _log("nowVersion ="+nowVersion);
                            child.setStringAttribute("lastVersion",nowVersion);
                            if(syncTime == -233){ //-233为特定code,由getPermission()传入，表示需要版本更新
                                _log("版本变动，更新任务，玩家="+m_name);
                                updateHonorFinishInfo=true;
                            }else{ //不更新，saveAndReload
                                array<const XmlElement@> m_honors = child.getChilds();
                                array<MissionCounter@> tasks = XmlToTask(m_honors);
                                if(tasks.size() == 0){ //首次获得每月任务
                                    resetHonorMissions();
                                    initiateHonorMissions(child);
                                    _log("从未执行每月任务，初始化");
                                }else{
                                    //??????
                                }
                            }
                        }
                        array<const XmlElement@> tagChilds = child.getChilds(); //m_stash.chuilds.chuild.tagChilds = DailyTask.childs 
                        child.removeAllChild();
                        if(updateFinishInfo){ // 刷新任务列表
                            resetMissions();
                            initiateDayMissions(child);
                        }else if(updateHonorFinishInfo){
                            resetHonorMissions();
                            initiateHonorMissions(child);
                        }else{
                            array<XmlElement@> tempChilds = constXmlToXml(tagChilds);
                            for(uint jj=0 ; jj < newXmls.size() ; ++jj){ //外来的信息
                                XmlElement@ newXml = newXmls[jj];
                                if(newXml is null){continue;}
                _log("newXmls TagName="+newXml.getName());
                                bool findSame = false;
                                for(uint k = 0 ; k < tempChilds.size() ; ++k){ //已存在的信息
                                    XmlElement@ tagchild = XmlElement(tempChilds[k]);
                                    if(tagchild is null){continue;}
                _log("tagchild TagName="+tagchild.getName());
                                    if(newXml !is null){
                                        if(tagchild.getStringAttribute("TaskName") == newXml.getStringAttribute("TaskName")){ //覆写文件
                                            tempChilds.removeAt(k);
                                            k--;
                                            findSame = true;
                                            break;
                                        }
                                    }
                                }
                                tempChilds.insertLast(newXml);
                            }
                            if(newXmls.size() == 0){ //if null 原封不动塞回去
                                child.appendChilds(tagChilds);
                            }else{
                                child.appendChilds(tempChilds);
                            }
                        }
                    }
                    m_stash.appendChild(child);
                }
                if(!isFindSubTag){
                    XmlElement@ new = XmlElement(TagName);
                    m_stash.appendChild(new);
                }
            }
            allInfo.appendChild(m_stash);
        }
        if(!findMission){
             // 如果没有<mission>元素，创建它
            XmlElement missionElement("mission");
            XmlElement dailyTask("DailyTask");
            dailyTask.setIntAttribute("signInDays", 0);
            dailyTask.setIntAttribute("continueSignInDays", 0);
            dailyTask.setIntAttribute("lastDay", -1); 
            missionElement.appendChild(dailyTask);

            XmlElement honorMission("HonorMission");
            honorMission.setStringAttribute("lastVersion", getServerVersion(m_metagame));
            missionElement.appendChild(honorMission);

            allInfo.appendChild(missionElement);
            int pid = g_playerInfoBuck.getPidByName(m_name);
            _notify(m_metagame,pid,"任务系统已注册");
        }
        allInfo.removeChild("player",0);
        savePlayerStashInfo(m_metagame,sid,allInfo);
        _log("save Mission PlayerStashInfo for sid="+sid);
        _debugReport(m_metagame,"initiateMissionInfo");
        return isTrue;
    }
    const XmlElement@ readMissionInfo(string TagName = ""){
        string sid = m_sid;
        if(sid == ""){return null;}   
        _log("read upgrade readMissionInfo for sid="+sid);
        const XmlElement@ allInfo = readPlayerStashInfo(sid);
        if(allInfo is null){
            _log("allInfo is null, in readMissionInfo");
            return null;
        }
        // 读取存档玩家账号信息
        array<const XmlElement@> m_stashs = allInfo.getChilds();

        for(int j = 0 ; j < int(m_stashs.size()) ; ++j){
            const XmlElement@ m_stash = m_stashs[j];
            if(m_stash is null){continue;}
            if(m_stash.getName() == "mission"){
                if(TagName == ""){
                    return m_stash;
                }
                array<const XmlElement@> childs = m_stash.getChilds();
                for(uint i = 0 ; i < childs.size() ; ++i){
                    const XmlElement@ child = childs[i];
                    if(child is null){continue;}
                    if(child.getName() == TagName){
                        _debugReport(m_metagame,"return "+TagName);
                        return child;
                    }
                }
            }
        }
        // 没有读取到信息，新建
        writeMissionInfo("",null);
        return null;
    }
    void readMissions(){
        const XmlElement@ missions = readMissionInfo("DailyTask");
        if(missions is null){return;}
        array<const XmlElement@> m_stashs = missions.getChilds();
        array<MissionCounter@> tasks = XmlToTask(m_stashs);
        for(uint i = 0 ; i < tasks.size() ; ++i){
            MissionCounter@ task = tasks[i];
            if(task is null){continue;}
            m_missions.insertLast(task);
        }
    }
    void readHonorMissions(){
        const XmlElement@ missions = readMissionInfo("HonorMission");
        if(missions is null){return;}
        array<const XmlElement@> m_stashs = missions.getChilds();
        array<MissionCounter@> tasks = XmlToTask(m_stashs);
        for(uint i = 0 ; i < tasks.size() ; ++i){
            MissionCounter@ task = tasks[i];
            if(task is null){continue;}
            m_honor_missions.insertLast(task);
        }
    }
    void initiateDayMissions(XmlElement@ xml){
        _log("addDayMissions for dailyTasks");
        addDayMissions(dailyTasks,xml);
        _log("addDayMissions for dailyTasks_hard");
        addDayMissions(dailyTasks_hard,xml,"TaskHard");
    }
    void initiateHonorMissions(XmlElement@ xml){
        _log("addDayMissions for dailyHonor");
        addDayMissions(dailyTasks_honor,xml,"TaskHonor");
    }

    void addDayMissions(array<MissionCounter@> @dic,XmlElement@ xml,string TagName = "Task"){
        for(uint i = 0; i < dic.size() ; ++i){
            // 由于基类不是const，需要拷贝
            MissionCounter@ cloned = dic[i].clone();
            if(cloned is null){continue;}
            if(TagName == "TaskHonor"){
                m_honor_missions.insertLast(cloned);
            }else{
                m_missions.insertLast(cloned);
            }

            XmlElement@ Task = XmlElement(TagName);
            Task.setStringAttribute("isFinish","0");

            string TaskName = cloned.m_task_name;
            string TaskCnName = cloned.m_task_CNname;
            Task.setStringAttribute("TaskName",TaskName);
            Task.setStringAttribute("TaskCnName",TaskCnName);
            Task.setStringAttribute("finishedTimes","0");

            int needsTime = cloned.m_need_times;

            if(cloned.hasSubMission()){
                needsTime = cloned.m_subMission.m_need_times;
                string SubTaskName = cloned.m_subMission.m_task_name;
                string SubTaskCnName = cloned.m_subMission.m_task_CNname;
                Task.setStringAttribute("SubTaskName",SubTaskName);
                Task.setStringAttribute("SubTaskCnName",SubTaskCnName);
            }

            Task.setIntAttribute("needTimes",needsTime);

            xml.appendChild(Task);
  
            _log("mission insert="+Task.toString());
        }
    }
    bool addMissionFinishTimes(string missionName,int times = 1,string subMissionName = ""){
        for(uint i = 0 ; i < m_missions.size() ; ++i){
            MissionCounter@ Mission = m_missions[i];
            if(Mission is null){continue;}
            if(Mission.m_finished){continue;
            }
            string taskName = Mission.m_task_name;
            string subTaskName = "";
            if(Mission.hasSubMission()){
                subTaskName = Mission.m_subMission.m_task_name;
            }
            if((taskName == missionName && subMissionName == subTaskName) || (taskName == missionName && subMissionName == "")){
                if(Mission.addTimes(times)){ //检测单项任务是否完成
                    getRewardOfMission(missionName,Mission.m_task_type);
                    // 检测是否同期所有任务完成
                    bool TasksFinish = true;
                    string taskType = Mission.m_task_type;
                    for(uint j = 0 ; j < m_missions.size() ; ++j){
                        @Mission = m_missions[j];
                        if(Mission.m_task_type == taskType){
                            if(!Mission.m_finished){
                                TasksFinish = false;
                            }
                        }
                    }
                    if(TasksFinish){
                        getRewardOfMission(taskType+"Finish");
                        int pid = g_playerInfoBuck.getPidByName(m_name);
                        _notify(m_metagame,pid,"你完成了"+taskType+"难度所有任务，额外奖励已发放");
                    }
                    saveAndReload();
                }
                // return true;
            }
        }
        for(uint i = 0 ; i < m_honor_missions.size() ; ++i){
            MissionCounter@ Mission = m_honor_missions[i];
            if(Mission is null){continue;}
            if(Mission.m_finished){continue;
            }
            string taskName = Mission.m_task_name;
            string subTaskName = "";
            if(Mission.hasSubMission()){
                subTaskName = Mission.m_subMission.m_task_name;
            }
            if((taskName == missionName && subMissionName == subTaskName) || (taskName == missionName && subMissionName == "")){
                if(Mission.addTimes(times)){
                    getRewardOfMission(missionName,Mission.m_task_type);
                    // 检测是否同期所有任务完成
                    bool TasksFinish = true;
                    string taskType = Mission.m_task_type;
                    for(uint j = 0 ; j < m_honor_missions.size() ; ++j){
                        @Mission = m_honor_missions[j];
                        if(Mission.m_task_type == taskType){
                            if(!Mission.m_finished){
                                TasksFinish = false;
                            }
                        }
                    }
                    if(TasksFinish){
                        getRewardOfMission(taskType+"Finish");
                        int pid = g_playerInfoBuck.getPidByName(m_name);
                        _notify(m_metagame,pid,"你完成了"+taskType+"难度所有任务，额外奖励已发放");
                    }
                    saveAndReload();
                }
                // return true;
            }
        }
        return false;
    }
    void saveAndReload(){
        writeMissionInfo("DailyTask",TaskToXml(m_missions));
        writeMissionInfo("HonorMission",TaskToXml(m_honor_missions));
        _log("saveAndReload missions for "+m_name);
    }
    array<XmlElement@> TaskToXml(array<MissionCounter@> tasks) {
        array<XmlElement@> xmlElements;

        // Loop through each task and convert it to an XmlElement
        for (uint i = 0; i < tasks.size(); ++i) {
            string TagName = tasks[i].m_task_type;
            XmlElement@ taskXml = XmlElement(TagName);
            taskXml.setBoolAttribute("isFinish", tasks[i].m_finished);  // Assume tasks are not finished
            taskXml.setStringAttribute("TaskName", tasks[i].m_task_name);
            taskXml.setStringAttribute("TaskCnName", tasks[i].m_task_CNname);
            taskXml.setIntAttribute("finishedTimes", tasks[i].m_finished_times); 

            int needsTime = tasks[i].m_need_times;
            if (tasks[i].hasSubMission()) {  // Task contains sub-mission
                if (tasks[i].m_subMission !is null) {
                    needsTime = tasks[i].m_subMission.m_need_times;
                    taskXml.setStringAttribute("SubTaskName", tasks[i].m_subMission.m_task_name);
                    taskXml.setStringAttribute("SubTaskCnName", tasks[i].m_subMission.m_task_CNname);
                    taskXml.setIntAttribute("finishedTimes", tasks[i].m_subMission.m_finished_times); 
                }
            }
            taskXml.setIntAttribute("needTimes", needsTime);

            xmlElements.insertLast(taskXml);
            _log("TaskToXml:"+taskXml.toString());
        }

        return xmlElements;
    }
    array<MissionCounter@> XmlToTask(const array<const XmlElement@>& xmlElements) {
        array<MissionCounter@> tasks;

        // 遍历每个 XML 元素并创建对应的 MissionCounter 对象
        for (uint i = 0; i < xmlElements.size(); ++i) {
            const XmlElement@ xmlElement = xmlElements[i];

            // 读取任务的基本属性
            string taskName = xmlElement.getStringAttribute("TaskName");
            string taskCNname = xmlElement.getStringAttribute("TaskCnName");
            string taskType = xmlElement.getName();  // Assuming task type is stored as the element's tag name
            int finishedTimes = xmlElement.getIntAttribute("finishedTimes");
            int needTimes = xmlElement.getIntAttribute("needTimes");
            bool isFinished = xmlElement.getBoolAttribute("isFinish");

            // 创建 MissionCounter 对象
            MissionCounter@ missionCounter = MissionCounter(taskName, taskCNname, needTimes, taskType);
            // 检查是否有子任务
            if (xmlElement.hasAttribute("SubTaskName")) {
                string subTaskName = xmlElement.getStringAttribute("SubTaskName");
                string subTaskCNName = xmlElement.getStringAttribute("SubTaskCnName"); // Assuming this is also stored

                // 创建子任务的 MissionCounter
                MissionCounter@ subMission = MissionCounter(subTaskName, subTaskCNName, needTimes, taskType);
                subMission.m_finished_times = finishedTimes;
                subMission.m_finished = isFinished;
                @missionCounter = MissionCounter(taskName, taskCNname, subMission, taskType); // 重定向并传入子任务
            }
            missionCounter.m_finished_times = finishedTimes;
            missionCounter.m_finished = isFinished;
            // 将任务添加到数组
            tasks.insertLast(missionCounter);
        }

        return tasks;
    }

    void getSignInReward(int days = 0){
        string fatherTag = "SignInReward";
        const XmlElement@ info = readMissionInfo(fatherTag);
        if(info is null){
            XmlElement@ Xml = XmlElement(fatherTag);
            writeMissionInfo(fatherTag,Xml);
            @info = readMissionInfo(fatherTag);
        }
        XmlElement@ SignInReward = XmlElement(info);

        const XmlElement@ DailyTask = readMissionInfo("DailyTask");
        if(DailyTask is null){return;}
        int continueSignInDays = DailyTask.getIntAttribute("continueSignInDays");

        int pid = g_playerInfoBuck.getPidByName(m_name);
        string rewardKey = "";
        if(days != 0){
            if(continueSignInDays <  days){
                if(isEng(m_name)){
                    _notify(m_metagame,pid,"The number of consecutive days you signed in is: "+continueSignInDays+", which is less than "+days+" days");
                }else{
                    _notify(m_metagame,pid,"你连续签到天数为:"+continueSignInDays+",不足"+days+"天");
                }
                return;
            }
            rewardKey = "SignInDays"+days;
        }else if(continueSignInDays == 10 || continueSignInDays == 20){
            array<const XmlElement@> SignIns = SignInReward.getChilds();
            for(int j = 0 ; j < int(SignIns.size()) ; ++j){
                XmlElement@ SignIn = XmlElement(SignIns[j]);
                if(SignIn is null){continue;}
                if(SignIn.hasAttribute("SignInDays"+continueSignInDays)){
                    return;
                }
            }
            // 找到了会自动return，反之就是没有找到
            XmlElement@ SignIn = XmlElement("SignIn");
            rewardKey = "SignInDays"+continueSignInDays;
            SignIn.setIntAttribute(rewardKey,1);
            writeMissionInfo(fatherTag,SignIn);
        }
        if(rewardKey == ""){return;}
        for(uint i = 0; i< missionExchangeLists.size() ; ++i){
            missionExchangeList@ list = missionExchangeLists[i];
            if(list !is null){
                string taskName = list.m_mission_name;
                if(taskName == rewardKey){
                    string sid = m_sid;
                    if(sid == ""){return;}
                    playerStashInfo@ thePlayer = playerStashInfo(m_metagame,sid,m_name);
                    if(!thePlayer.isOpen(false)){
                        thePlayer.openStash(false);
                    }
                    if(thePlayer.exchangeItems(list.m_deleteObjects,list.m_getObjects,false)){
                        thePlayer.openStash(false);
                        if(isEng(m_name)){
                            _notify(m_metagame,pid,"Congratulations on getting the reward of "+days+" for consecutive login days, which has been sent to your backpack.");
                        }else{
                            _notify(m_metagame,pid,"恭喜获得连续登陆"+days+"天奖励，已发送至背包");
                        }
                        return;
                    }
                }
            }
        }
        if(isEng(m_name)){
            _notify(m_metagame,pid,"There is no "+days+" day login reward");
        }else{
            _notify(m_metagame,pid,"不存在"+days+"天登陆奖励");
        }
    }
    void getRewardOfMission(string missionName, string missionType = "any"){
        string baseReward = "any";
        if(missionType == "Task"){
            baseReward = "TaskType";
        }else if(missionType == "TaskHard"){
            baseReward = "TaskHardType";
        }else if(missionType == "TaskHonor"){
            baseReward = "TaskHonorType";
        }else if(missionType == "TaskHonorSpecial"){
            baseReward = "TaskHonorSpecialType";
        }
        bool isFinish = false;
        for(uint i = 0; i< missionExchangeLists.size() ; ++i){
            missionExchangeList@ list = missionExchangeLists[i];
            if(list !is null){
                string taskName = list.m_mission_name;
                if(taskName == missionName || taskName == baseReward){ //固定奖励和额外奖励
                    string sid = m_sid;
                    if(sid == ""){return;}
                    playerStashInfo@ thePlayer = playerStashInfo(m_metagame,sid,m_name);
                    if(!thePlayer.isOpen(false)){
                        thePlayer.openStash(false);
                    }
                    if(thePlayer.exchangeItems(list.m_deleteObjects,list.m_getObjects,false)){
                        thePlayer.openStash(false);
                        int pid = g_playerInfoBuck.getPidByName(m_name);
                        _notify(m_metagame,pid,"你完成了每日任务，奖励已发放背包，输入/day查看剩余任务");
                        isFinish = true;
                    }
                }
            }
        }
        if(!isFinish){
            int pid = g_playerInfoBuck.getPidByName(m_name);
            _notify(m_metagame,pid,"奖励发放失败");
        }
    }

    void resetMissions(){
        // m_missions.resize(0);
        _log("resetMissions for "+m_name+",m_missions.size()="+m_missions.size());
        while(m_missions.size()!=0){
            m_missions.removeAt(0);
        }
    }
    void resetHonorMissions(){
        // m_honor_missions.resize(0);
        _log("resetMissions for "+m_name+",m_honor_missions.size()="+m_honor_missions.size());
        while(m_honor_missions.size()!=0){
            m_honor_missions.removeAt(0);
        }
    }
    bool getPermission(){ //是否重置当天的每日任务
        const XmlElement@ DailyTask = readMissionInfo("DailyTask");
        if(DailyTask !is null){
            if(DailyTask.hasAttribute("lastDay")){
                int lastDay = DailyTask.getIntAttribute("lastDay");
                if(getDays() != -1){
                    if(getDays() != DailyTask.getIntAttribute("lastDay")){ 
                        //如果玩家登陆日期不等于服务器记录日期，则刷新玩家的每日任务列表启动权限
                        //更新玩家日期和任务列表
                        m_nowDay = getDays();
                        _log("pass getPermission for "+m_name+", today is "+m_nowDay);
                        writeMissionInfo("DailyTask",null,getDays());
                        int pid = g_playerInfoBuck.getPidByName(m_name);
                        showDayMission();
                        return true;
                    }
                }
            }
        }
        const XmlElement@ HonorMission = readMissionInfo("HonorMission");
        if(HonorMission !is null){
            if(HonorMission.hasAttribute("lastVersion")){
                string lastVersion = HonorMission.getStringAttribute("lastVersion");
                string nowVersion = getServerVersion(m_metagame);
                if(nowVersion != ""){
                    if(lastVersion != nowVersion){ //版本变动，更新任务
                        _log("pass getPermission for "+m_name+", now Version is "+nowVersion);
                        writeMissionInfo("HonorMission",null,-233); //-233为特定code
                    }
                }else{
                    _report(m_metagame,"faild to get Server Version data,SID="+m_sid);
                }
            }
        }
        showDayMission();
        saveAndReload();
        return false;
    }
    void showDayMission(){
        if(m_missions.size() == 0){
            readMissions();
        }
        if(m_honor_missions.size() == 0){
            readHonorMissions();
        }
        array<MissionCounter@> temps = m_missions;
        for(uint i = 0 ; i < m_honor_missions.size() ; ++i){ //合并日常任务和月任务显示
            temps.insertLast(m_honor_missions[i]);
        }
        int pid = g_playerInfoBuck.getPidByName(m_metagame,m_name);
        
        dictionary a;
        //初始化
        for(int i = 0 ; i < 20 ; ++i){
            string strvalue;
            if(i < 10){
                strvalue = "%value"+i;
            }else{
                strvalue = "%valuea"+(i-9);
            }
            a[strvalue] = "";
        }
        bool isAllFinished = true;
        for(uint j = 0 ; j < temps.size() ; ++j){
            if(j < 20){
                MissionCounter@ task = temps[j];
                if(task is null){continue;}
                if(task.m_finished){continue;}
                isAllFinished = false;
                string baseCnName = task.m_task_CNname;
                string subBaseCnName = "";
                string taskType = task.m_task_type;
                int needTimes = task.m_need_times;
                int finishedTimes = task.m_finished_times;
                if(task.hasSubMission()){
                    subBaseCnName = task.m_subMission.m_task_CNname;
                    needTimes = task.m_subMission.m_need_times;
                    finishedTimes = task.m_subMission.m_finished_times;
                }
                if(isEng(m_name)){
                    baseCnName = task.m_task_name;
                    if(task.hasSubMission()){
                        subBaseCnName = task.m_subMission.m_task_name;
                    }
                }
                string strvalue;
                if(j < 10){
                    strvalue = "%value"+j;
                }else{
                    strvalue = "%valuea"+(j-9);
                }
                a[strvalue] = "Easy "+baseCnName+":"+subBaseCnName+" "+finishedTimes+"/"+needTimes;

                if(taskType == "TaskHard"){
                    a[strvalue] = "Hard "+baseCnName+":"+subBaseCnName+" "+finishedTimes+"/"+needTimes;
                }
                if(taskType == "TaskHonor"){
                    a[strvalue] = "Honor "+baseCnName+":"+subBaseCnName+" "+finishedTimes+"/"+needTimes;
                }
                if(taskType == "TaskHonorSpecial"){
                    a[strvalue] = "Honor "+baseCnName+":"+subBaseCnName+" "+finishedTimes+"/"+needTimes;
                }
            }
        }
        if(isAllFinished){
            a["%value0"] = "已完成所有每日任务";
            if(isEng(m_name)){
                a["%value0"] = "Finished All Daily missions";
            }
        }
        a["%day"] = "距离下次更新剩余进度:"+getNextServerDayRate(m_metagame)+"/100%";
        const XmlElement@ DailyTask = readMissionInfo("DailyTask");
        if(DailyTask is null){return;}
        int continueSignInDays = DailyTask.getIntAttribute("continueSignInDays");
        a["%sign"] = "累计签到:"+continueSignInDays+"天";
        if(isEng(m_name)){
            a["%day"] = "Next Day Left"+getNextServerDayRate(m_metagame)+"/100%";
            a["%sign"] = "Continue Signed:"+continueSignInDays+"Days";
        }
        notify(m_metagame, "DaylyMission", a, "misc", pid, true, "Dayly Mission List", 1.0);
    }
    bool checkDayUpdated(){
        return m_nowDay < getDays();
    }
    int getDays(){
        return getServerDay(m_metagame) + m_testToday;
    }
    void addDay(){
        m_testToday++;
    }
    void RESET(){
        writeMissionInfo("DailyTask",null,-114514);
    }

    // ----------------------------------------------------
    protected void savePlayerStashInfo(Metagame@ m_metagame, string sid, XmlElement@ allInfo){
        sid = sid+"_stash.xml";
        writeXML(m_metagame,sid,allInfo);
    }
    protected const XmlElement@ readPlayerStashInfo(string sid){
        sid = sid+"_stash.xml";
        const XmlElement@ root1 = readXML(m_metagame,sid);
        if(root1 is null){return null;}
        const XmlElement@ root = root1.getFirstChild();
        if(root is null){
            _log("readPlayerStashInfo for sid="+sid+" is null,create");
            writeXML(m_metagame,sid,XmlElement("players"));
            @root = readXML(m_metagame,sid).getFirstChild();
        }
        return root;
    }
}

class playerMissionInfoBuck {
    array<playerMissionInfo@> m_playerMissionInfos;

    playerMissionInfoBuck(){}

    void reMeta(Metagame@ metagame){
        for(uint i = 0; i<size(); i++){
            @m_playerMissionInfos[i].m_metagame = @metagame;
        }
    }
    string allName(){
        string name = "";
        for(uint i = 0; i<size(); i++){
            name += m_playerMissionInfos[i].m_name;
        }
        return name;
    }
    uint size(){
        return m_playerMissionInfos.size();
    }

    void addInfo(Metagame@ metagame, string name){
        checkToSave();
        for(uint i = 0; i<size(); i++){
            if(name == m_playerMissionInfos[i].m_name){
                return;
            }
        }
        playerMissionInfo@ newInfo = playerMissionInfo(metagame,name);
        m_playerMissionInfos.insertLast(newInfo);
    }
    void checkToSave(){
        for(uint i = 0; i<size(); i++){
            string name = m_playerMissionInfos[i].m_name;
            string sid = g_playerInfoBuck.getSidByName(name);
            _log("checkToSave sid="+sid+" m_sid="+m_playerMissionInfos[i].m_sid);
            if(sid != m_playerMissionInfos[i].m_sid){
                m_playerMissionInfos[i].saveAndReload();
                m_playerMissionInfos.removeAt(i);
                i--;
            }
        }
    }
    void removeInfo(string name) {
        for (uint i = 0; i < m_playerMissionInfos.length(); ++i) {
            if (m_playerMissionInfos[i].m_name == name) {
                m_playerMissionInfos.removeAt(i);
                return; 
            }
        }
    }
    bool addMissionFinishTimes(string name,string missionName,int times = 1,string subMissionName = ""){
        for(uint i = 0; i<size(); i++){
            if(name == m_playerMissionInfos[i].m_name){
                return m_playerMissionInfos[i].addMissionFinishTimes(missionName,times,subMissionName);
            }
        }
        return false;
    }

    void addDay(string name){
        for(uint i = 0; i<size(); i++){
            if(name == m_playerMissionInfos[i].m_name){
                m_playerMissionInfos[i].addDay();
            }
        }
    }
    void RESET(string name){
        for(uint i = 0; i<size(); i++){
            if(name == m_playerMissionInfos[i].m_name){
                m_playerMissionInfos[i].RESET();
            }
        }
    }
    void getPermission(string name){
        for(uint i = 0; i<size(); i++){
            if(name == m_playerMissionInfos[i].m_name){
                m_playerMissionInfos[i].getPermission();
            }
        }
    }
    void getSignInReward(string name,int days){
        for(uint i = 0; i<size(); i++){
            if(name == m_playerMissionInfos[i].m_name){
                m_playerMissionInfos[i].getSignInReward(days);
            }
        }
    }
    void saveAndReload(string name){
        for(uint i = 0; i<size(); i++){
            if(name == m_playerMissionInfos[i].m_name){
                m_playerMissionInfos[i].saveAndReload();
            }
        }
    }
    void showDayMission(string name){
        for(uint i = 0; i<size(); i++){
            if(name == m_playerMissionInfos[i].m_name){
                m_playerMissionInfos[i].showDayMission();
            }
        }
    }
    void addPlayTime(){
        for(uint i = 0; i<size(); i++){
            m_playerMissionInfos[i].addMissionFinishTimes("timeplay_min_20",1);
            m_playerMissionInfos[i].addMissionFinishTimes("timeplay_min_60",1);
            m_playerMissionInfos[i].addMissionFinishTimes("timeplay_min_6000",1);
        }
    }
    void playMode(string gameMode){
        for(uint i = 0; i<size(); i++){
            m_playerMissionInfos[i].addMissionFinishTimes("play_selected_mode",1,gameMode);
        }
    }
    void saveAll(){
        for(uint i = 0; i<size(); i++){
            m_playerMissionInfos[i].saveAndReload();
        }
    }

    void clearAll(){
        m_playerMissionInfos.resize(0);
    }
}

class hd_daily_mission : Tracker{
    protected Metagame@ m_metagame;
    protected float m_cdTime ;
	protected float m_timer;
    protected bool m_ended;

    protected playerMissionInfo@ m_testInfo;

    //--------------------------------------------
    hd_daily_mission(Metagame@ metagame,float time = 60.0){ //每分钟计时
        @m_metagame = @metagame;
        m_cdTime = time;
		m_timer = m_cdTime;
    }
    // --------------------------------------------
    void update(float time) {
        m_timer -= time;    //记录警报CD
        
		if (m_timer < 0.0) {
            m_timer = m_cdTime;
            g_playerMissionInfoBuck.addPlayTime();
		}

    }
    // --------------------------------------------
    void start(){
        m_ended = false;
    }
    // --------------------------------------------
	bool hasEnded() const {
		return false;
	}
	// --------------------------------------------
	bool hasStarted() const {
		return true;
	}
    // ----------------------------------------------------
    protected void handlePlayerConnectEvent(const XmlElement@ event) {
        // const XmlElement@ player = event.getFirstElementByTagName("player");
        // if(player is null){return;}
        // int pid = player.getIntAttribute("player_id");
        // string name = player.getStringAttribute("name");
        // g_playerMissionInfoBuck.addInfo(m_metagame,name);
        // 转入INFO.as里面添加玩家信息
    }
    // --------------------------------------------
	protected void handlePlayerDisconnectEvent(const XmlElement@ event) {
        const XmlElement@ player = event.getFirstElementByTagName("player");
        if(player is null){return;}
        string name = player.getStringAttribute("name");
        g_playerMissionInfoBuck.checkToSave();
        g_playerMissionInfoBuck.saveAndReload(name);
    }
    // ----------------------------------------------------
	protected void handleMatchEndEvent(const XmlElement@ event) {
        string m_GameMode = g_GameMode;
        if(m_GameMode == ""){
            m_GameMode = "Helldiver";
        }
		g_playerMissionInfoBuck.playMode(m_GameMode);
		g_playerMissionInfoBuck.checkToSave();
        g_playerMissionInfoBuck.saveAll();
        g_playerMissionInfoBuck.clearAll();
	}
    // --------------------------------------------
	protected void handleCharacterKillEvent(const XmlElement@ event) {
		const XmlElement@ killer = event.getFirstElementByTagName("killer");
		if(killer is null){return;}
		const XmlElement@ target = event.getFirstElementByTagName("target");
		if(target is null){return;}
		int k_pid = killer.getIntAttribute("player_id");
		int t_pid = target.getIntAttribute("player_id");
		if(k_pid == -1 && t_pid == -1){return;}//AI之间击杀，返回
		if(k_pid == -1 && t_pid != -1){return;}//AI TK玩家，返回
		string weaponKey = event.getStringAttribute("key");//击杀武器关键字
		string method_hint = event.getStringAttribute("method_hint");//击杀方式
		string soldier_group_name = target.getStringAttribute("soldier_group_name");//击杀兵种
		int target_fid = target.getIntAttribute("faction_id");
		int killer_xp = killer.getIntAttribute("xp");
		int killer_cid = killer.getIntAttribute("id");
		int killer_fid = killer.getIntAttribute("faction_id");
		if(g_playerInfoBuck is null){return;}
		if(g_battleInfoBuck is null){return;}
		string k_name = g_playerInfoBuck.getNameByCid(killer_cid);
		string t_name = g_playerInfoBuck.getNameByPid(t_pid);

        if (killer_fid != target_fid) {//普通击杀
            //处理变种兵种
            if(soldier_group_name == "Behemoth" || soldier_group_name == "BehemothM" || soldier_group_name == "Tank"  ){
                soldier_group_name = "EnemyElite";
            }
            if(soldier_group_name == "CouncilMember" || soldier_group_name == "Obelisk" ){
                soldier_group_name = "EnemyElite";
            }
            if(soldier_group_name == "Warlord" || soldier_group_name == "Hulk" ){
                soldier_group_name = "EnemyElite";
            }
            if(soldier_group_name == "zomberry" || soldier_group_name == "zomberryM" || soldier_group_name == "zomberryMM" ){
                soldier_group_name = "Zombie";
            }
            if(soldier_group_name == "exo44" || soldier_group_name == "exo48" || soldier_group_name == "exo51"){
                soldier_group_name = "EXO";
            }

            g_playerMissionInfoBuck.addMissionFinishTimes(k_name,"kill_enemy_100");
            g_playerMissionInfoBuck.addMissionFinishTimes(k_name,"kill_enemy_5w");
            if(soldier_group_name != ""){
                g_playerMissionInfoBuck.addMissionFinishTimes(k_name,"kill_selected_enemy",1,soldier_group_name);
            }
            if(weaponKey != ""){
                g_playerMissionInfoBuck.addMissionFinishTimes(k_name,"kill_with_select_weapon",1,weaponKey);
            }
            _log("killInfo,weaponKey="+weaponKey+" method_hint="+method_hint);
            if(method_hint == "stab"){
                g_playerMissionInfoBuck.addMissionFinishTimes(k_name,"kill_with_melee");
                
            }
        }
    }
    // --------------------------------------------
    protected void handleItemDropEvent(const XmlElement@ event) {
        string itemKey = event.getStringAttribute("item_key");
        int containerId = event.getIntAttribute("target_container_type_id");
        if(containerId != 1){return;} // 1(军械库)
        if(itemKey == "lottery.carry_item"){
            int pid = event.getIntAttribute("player_id");
            string name = g_playerInfoBuck.getNameByPid(pid);
            g_playerMissionInfoBuck.addMissionFinishTimes(name,"buy_lottery_10");
        }
        if(itemKey.find("collect_mc_") >= 0){
            int pid = event.getIntAttribute("player_id");
            string name = g_playerInfoBuck.getNameByPid(pid);
            g_playerMissionInfoBuck.addMissionFinishTimes(name,"collector",1,itemKey);
        }
    }
    // ----------------------------------------------------
    protected void handleResultEvent(const XmlElement@ event) {
        string EventKeyGet = event.getStringAttribute("key");
    }
    
    // ------------------------------------------------------
    protected void handleChatEvent(const XmlElement@ event) {
		string message = event.getStringAttribute("message");
        string p_name = event.getStringAttribute("player_name");
        int senderId = event.getIntAttribute("player_id");
        message = message.toLowerCase();
        if(message == "/day"){
            g_playerMissionInfoBuck.getPermission(p_name);
        }
        if(startsWith(message,"/login")){
            string days = message.substr(message.findFirst(" ")+1);
            int Days = 0;
            if(isNumeric(days)){ 
                Days = parseInt(days);
            }else{
                _notify(m_metagame,senderId,"数字输入错误,示例:/login 10");
                return;
            }
            g_playerMissionInfoBuck.getSignInReward(p_name,Days);
        }
        if(g_debugMode|| g_online_TestMode || m_metagame.getAdminManager().isAdmin(p_name,senderId) ){
            if(message == "/newinfo"){
                g_playerMissionInfoBuck.addInfo(m_metagame,p_name);
                _report(m_metagame,"创建玩家数据");
            }
            if(message == "/addday"){
                g_playerMissionInfoBuck.addDay(p_name);
                _report(m_metagame,"addDay");
            }
            if(message == "/getpermission"){
                g_playerMissionInfoBuck.getPermission(p_name);
                _report(m_metagame,"getPermission");
            }
            if(message == "/addk"){
                g_playerMissionInfoBuck.addMissionFinishTimes(p_name,"kill_enemy_100",45);
                _report(m_metagame,"addK");
            }
            if(message == "/addt"){
                g_playerMissionInfoBuck.addMissionFinishTimes(p_name,"timeplay_15_min",5);
                _report(m_metagame,"addK");
            }
            if(message == "/addb"){
                g_playerMissionInfoBuck.addMissionFinishTimes(p_name,"timeplay_40_min",19);
                _report(m_metagame,"addK");
            }
            if(message == "/finish"){
                g_playerMissionInfoBuck.addMissionFinishTimes(p_name,"kill_enemy_100",100);
                g_playerMissionInfoBuck.addMissionFinishTimes(p_name,"timeplay_min_20",100);
                g_playerMissionInfoBuck.addMissionFinishTimes(p_name,"buy_lottery_10",100);
                g_playerMissionInfoBuck.addMissionFinishTimes(p_name,"play_selected_mode",100);
                g_playerMissionInfoBuck.addMissionFinishTimes(p_name,"kill_with_select_weapon",100);
                g_playerMissionInfoBuck.addMissionFinishTimes(p_name,"kill_selected_enemy",100);
                g_playerMissionInfoBuck.addMissionFinishTimes(p_name,"timeplay_min_60",100);
                g_playerMissionInfoBuck.addMissionFinishTimes(p_name,"kill_with_melee",100);
                g_playerMissionInfoBuck.addMissionFinishTimes(p_name,"finish_sidemission",100);
                g_playerMissionInfoBuck.addMissionFinishTimes(p_name,"collector",100);
                g_playerMissionInfoBuck.addMissionFinishTimes(p_name,"kill_enemy_5w",50000);
                g_playerMissionInfoBuck.addMissionFinishTimes(p_name,"timeplay_min_6000",6000);
                _report(m_metagame,"addK");
            }
            if(message == "/saveandreload"){
                g_playerMissionInfoBuck.saveAndReload(p_name);
                _report(m_metagame,"saveAndReload");
            }
            if(message == "/size"){
                _report(m_metagame,"g_playerMissionInfoBuck.size()="+g_playerMissionInfoBuck.size());
                _report(m_metagame,"g_playerMissionInfoBuck.name="+g_playerMissionInfoBuck.allName());
            }
            if(message == "/remeta"){
                g_playerMissionInfoBuck.reMeta(m_metagame);
                _report(m_metagame,"reMeta");
            }
        }
	}
}