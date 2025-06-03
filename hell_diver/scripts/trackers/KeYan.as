// internal
#include "tracker.as"
#include "helpers.as"
#include "admin_manager.as"
#include "log.as"
#include "query_helpers.as"
#include "query_helpers2.as"
#include "gamemode.as"
#include "gamemode_invasion.as"

#include "debug_reporter.as"
#include "INFO.as"
#include "extra_stash.as"

//Author： rst
//科研系统脚本

dictionary research_list = {

    // MK5
    {"ex_vergil_judgment_cut.weapon",450},
    {"acg_patricia_cumforce.weapon",450},
    {"ex_hyper_mega_bazooka_launcher_ex.weapon",450},
    {"acg_megumin_wand_float.weapon",750}, // rare
    {"ex_trinity_ghoul.weapon",450},
    {"acg_laisha_heliotrope.weapon",450},
    {"acg_elaina_wand.weapon",450},
    {"acg_izayoi_sakuya_i.weapon",450},
    {"ex_exo_dreadnought_mg.weapon",450},
    {"acg_takanashi_hoshino_battle.weapon",225},
    {"acg_takanashi_hoshino_battle_side_pistol.weapon",225},
    {"acg_sabayon_gun.weapon",450},
    {"ex_exo_telemon_cannon.weapon",450},

    // MK4
    {"acg_arknight_ifrit.weapon",450},// rare
    {"acg_bronya.weapon",150},
    {"acg_g41_lasercanno_diffusion.weapon",150},
    // {"acg_shuiniao.weapon",150},
    {"acg_fiammetta_gl.weapon",150},
    {"ex_disaster_railgun.weapon",150},
    {"acg_texas_skill.weapon",150},
    {"acg_ba_alice_railgun_ex.weapon",150},
    {"acg_starwars_shipgirls.weapon",150},
    {"acg_asagi_mutsuki.weapon",150},
    {"acg_rikuhachima_aru.weapon",150},
    {"acg_shinano.weapon",150},
    {"acg_incomparable.weapon",150},
    {"acg_yileina_wand.weapon",150},
    {"acg_hayase_yuuka.weapon",150},

    //mk3 
    {"acg_takanashi_hoshino.weapon",50},
    {"acg_g41_bp2077.weapon",50},
    {"acg_miyu.weapon",50},
    {"acg_g41_universe.weapon",50},
    {"acg_maria_schariac.weapon",50},
    {"ex_space_marines.weapon",50},
    {"acg_rumi.weapon",50},
    {"acg_bf109.weapon",50},
    {"acg_fade_red.weapon",50},

    //mk3 sell
    {"acg_sinteria_bow.weapon",40},
    {"acg_kokomi_portia.weapon",40},
    {"acg_sorasaki_hina.weapon",40},
    {"acg_hk416_starry_cocoon.weapon",450}, // rare
    {"acg_iws2000_banisher.weapon",40},
    {"acg_hongxue.weapon",40},
    {"acg_amamiya_kokoro.weapon",40},

    //mk2 sell
    {"acg_kemomimi.weapon",10},
    {"acg_reisenu_a.weapon",10},
    {"acg_ruby_rose_scythe.weapon",10},
    {"acg_mg4a3td.weapon",10},
    {"acg_mg4td_ke.weapon",10},
    {"ex_lancer_mk3.weapon",10},
    {"ex_soma_prime.weapon",10},
    {"acg_piko_hammer.weapon",10},
    {"acg_stylet_m61a1.weapon",10},
    {"acg_otogi_sniper.weapon",10},
    {"ex_heavy_infantry_morita.weapon",10},

    //mk1 sell
    {"acg_stylet_m61a1.weapon",5},
    {"acg_ka_ar8.weapon",5},
    {"acg_m14.weapon",5},
    {"acg_mari_sports_ver.weapon",5},
    {"ex_izanagis_burden.weapon",5},
    {"ex_funnelnet.weapon",5},
    {"acg_mg3.weapon",5},
    {"acg_ushio_noa.weapon",5}, // unsell
    {"ex_typhoon.weapon",5}, 
    {"ex_heavy_infantry_morita_mk1.weapon",5}, 

    //EXTRA
    {"ex_firework.weapon",80},
    {"hd_fire_bunny.weapon",5},


    {"",0}
};

class KeYan : Tracker{
    protected Metagame@ m_metagame;
    protected bool reward = false;

    KeYan(Metagame@ metagame){
        @m_metagame = @metagame;
    }
    // --------------------------------------------
	bool hasEnded() const {
		// always on
		return false;
	}
	// --------------------------------------------
	bool hasStarted() const {
		// always on
		return true;
	}
    // ----------------------------------------------------
	protected void handleMatchEndEvent(const XmlElement@ event) {
        if(!reward){
            KeYanReword();
            reward = true;
        }
	}	
    protected void KeYanReword(){
        _log("Getting KeYan Exp");
        array<const XmlElement@> players = getPlayers(m_metagame);
        if(players is null){return;}
        for(uint i = 0 ; i < players.size() ; ++i ){
            const XmlElement@ player = players[i];
            if(player is null){continue;}
            int cid = player.getIntAttribute("character_id");
            int pid = player.getIntAttribute("player_id");
            string name = player.getStringAttribute("name");
            float xp = g_battleInfoBuck.getXpReward(m_metagame,player,false);
            string sid = g_playerInfoBuck.getSidByName(name);
            addReserchedXp(sid,pid,xp);
        }
    }
    protected void addReserchedXp(string sid,int pid,float researchedXp){
        XmlElement@ allInfo = XmlElement(readPlayerStashInfo(sid));
        if(allInfo is null){
            _log("allInfo is null, in addReserchedXp");
            return;
        }
        string name = g_playerInfoBuck.getNameByPid(pid);
        // 读取存档玩家账号信息
        array<const XmlElement@> m_stashs = allInfo.getChilds();

        allInfo.removeAllChild();
        //解决空子项问题
        XmlElement a("player");
        a.setBoolAttribute("onRemove",true);
        allInfo.appendChild(a);
        bool findKeYan = false;
        for(int j = 0 ; j < int(m_stashs.size()) ; ++j){
            XmlElement@ m_stash = XmlElement(m_stashs[j]);
            if(m_stash.getName() == "KeYan"){
                findKeYan = true;
                array<const XmlElement@> childs = m_stash.getChilds();
                m_stash.removeAllChild();
                float m_globalXp = m_stash.getFloatAttribute("globalXp");
                m_stash.setFloatAttribute("globalXp",m_globalXp + researchedXp*0.1);//全局经验

                bool keyRegistered = false;
                for(uint i = 0 ; i < childs.size() ; ++i){
                    XmlElement@ child = XmlElement(childs[i]);
                    if(child is null){continue;}
                    string m_targetKey = child.getStringAttribute("key");
                    float m_researchedXp = child.getFloatAttribute("researchedXp");
                    float m_requiredXp = child.getFloatAttribute("requiredXp");
                    bool OnResearch = child.getBoolAttribute("OnResearch");
                    child.setBoolAttribute("OnResearch",false);
                    if(OnResearch){
                        keyRegistered = true;
                        m_researchedXp += researchedXp;
                        child.setFloatAttribute("researchedXp",m_researchedXp);
                        if(isEng(name)){
                            _notify(m_metagame,pid,"This Battle Get"+researchedXp+"w XP Research EXP (Global EXP +10%)");
                        }else{
                            _notify(m_metagame,pid,"本局已获得"+researchedXp+"w XP研究经验（全局经验 10%）");
                        }
                        child.setBoolAttribute("OnResearch",true);
                        if(m_researchedXp >= m_requiredXp){ //没有用XML记录里的requiredXp，便于以后出台科研XP打折的活动
                            if(isEng(name)){
                                _notify(m_metagame,pid,"The progress rate of your researched weapon has reached 100%!");
                            }else{
                                _notify(m_metagame,pid,"当前武器科研进度100%,已完成该科研");
                            }
                        }else{
                            if(isEng(name)){
                                _notify(m_metagame,pid,"The progress rate of your researched weapon:"+m_researchedXp+"/"+m_requiredXp+"w XP");
                            }else{
                                _notify(m_metagame,pid,"当前武器科研进度:"+m_researchedXp+"/"+m_requiredXp+"w XP");
                            }
                        }
                    }
                    m_stash.appendChild(child);
                }
                allInfo.appendChild(m_stash);
            }else{//其他玩家信息不修改存回去
                allInfo.appendChild(m_stash);
            }
        }
        if(!findKeYan){
            XmlElement newLine("KeYan");
            allInfo.appendChild(newLine);
            _notify(m_metagame,pid,"科研系统已注册");
        }
        allInfo.removeChild("player",0);
        savePlayerStashInfo(m_metagame,sid,allInfo);
        _log("addReserchedXp save KeYan PlayerStashInfo for sid="+sid);
        _debugReport(m_metagame,"saveKeYanPlayersStash");
    }
    protected void handleChatEvent(const XmlElement@ event){
		string message = event.getStringAttribute("message");
		string p_name = event.getStringAttribute("player_name");
		int pid = event.getIntAttribute("player_id");
        if(startsWith(message,"/research") || startsWith(message,"/rsc")){
            if(!g_server_activity_racing){
                _notify(m_metagame,pid,"科研系统查询仅在赛车服开启，请前往赛车服");
                return;
            }
            dictionary equipList;
            int cid = g_playerInfoBuck.getCidByPid(pid);
            if(!getPlayerEquipmentInfoArray(m_metagame,cid,equipList)){
                _notify(m_metagame,pid,"未获取到你的装备信息");
                return;
            }

            string equipKey_main = "";
            equipList.get("0",equipKey_main);//主手武器
            uint amount;
            if(!equipList.get(equipKey_main,amount) || amount == 0){
                equipKey_main = "";
            }
            if(equipKey_main == ""){
                equipList.get("1",equipKey_main);//副手武器
                if(!equipList.get(equipKey_main,amount) || amount == 0){
                    equipKey_main = "";
                }
            }
            _debugReport(m_metagame,"当前持有武器:"+equipKey_main);

            if(int(research_list[equipKey_main]) != 0){
                float requiredXp = int(research_list[equipKey_main]);
                if(message == "/research global" || message == "/rsc g"){
                    if(checkKeYanFile(p_name,pid,requiredXp,equipKey_main,true)){
                        addItemInBackpack(m_metagame,cid,"weapon",equipKey_main);
                        _notify(m_metagame,pid,"物品已送至背包");
                    }
                }else{
                    if(checkKeYanFile(p_name,pid,requiredXp,equipKey_main)){
                        addItemInBackpack(m_metagame,cid,"weapon",equipKey_main);
                        _notify(m_metagame,pid,"物品已送至背包");
                    }
                }
            }else{
                _notify(m_metagame,pid,"该武器（或模式）无法进行科研，尝试切换为一模式");
            }
        }
    }
    protected bool checkKeYanFile(string name,int pid,float requiredXp,string targetKey,bool useGlobalXp = false){
        string sid = g_playerInfoBuck.getSidByName(name);
        XmlElement@ allInfo = XmlElement(readPlayerStashInfo(sid));
        if(allInfo is null){
            _log("allInfo is null, in checkKeYanFile");
            return false;
        }
        // 读取存档玩家账号信息
        array<const XmlElement@> m_stashs = allInfo.getChilds();

        allInfo.removeAllChild();
        //解决空子项问题
        XmlElement a("player");
        a.setBoolAttribute("onRemove",true);
        allInfo.appendChild(a);
        bool findKeYan = false;
        bool isTrue = false;
        for(int j = 0 ; j < int(m_stashs.size()) ; ++j){
            XmlElement@ m_stash = XmlElement(m_stashs[j]);
            _debugReport(m_metagame,"m_stash.getName()="+m_stash.getName());
            if(m_stash.getName() == "KeYan"){
                findKeYan = true;
                _debugReport(m_metagame,"找到玩家科研信息");
                array<const XmlElement@> childs = m_stash.getChilds();
                m_stash.removeAllChild();
                float m_globalXp = m_stash.getFloatAttribute("globalXp");
                bool keyRegistered = false;
                for(uint i = 0 ; i < childs.size() ; ++i){
                    XmlElement@ child = XmlElement(childs[i]);
                    if(child is null){continue;}
                    string m_targetKey = child.getStringAttribute("key");
                    float m_researchedXp = child.getFloatAttribute("researchedXp");
                    bool OnResearch = child.getBoolAttribute("OnResearch");
                    child.setBoolAttribute("OnResearch",false);
                    if(m_targetKey == targetKey){
                        keyRegistered = true;
                        if(isEng(name)){
                            _notify(m_metagame,pid,"You selected weapon:"+targetKey+"for Research target");
                        }else{
                            _notify(m_metagame,pid,"已选定该武器"+targetKey+"作为科研对象");
                        }
                        child.setBoolAttribute("OnResearch",true);
                        if(m_researchedXp >= requiredXp){ //没有用XML记录里的requiredXp，便于以后出台科研XP打折的活动
                            _notify(m_metagame,pid,"当前武器科研进度100%,已完成该科研");
                            child.setFloatAttribute("researchedXp",m_researchedXp-requiredXp);
                            isTrue = true;
                        }else{
                            if(isEng(name)){
                                _notify(m_metagame,pid,"The progress rate of your researched weapon:"+m_researchedXp+"/"+requiredXp+"w XP");
                            }else{
                                _notify(m_metagame,pid,"当前武器科研进度:"+m_researchedXp+"/"+requiredXp+"w XP");
                            }
                        }
                        if(useGlobalXp){
                            if(m_researchedXp < requiredXp){
                                if(m_globalXp >= (requiredXp - m_researchedXp)){
                                    m_stash.setFloatAttribute("globalXp",(m_globalXp - (requiredXp - m_researchedXp)));
                                    child.setFloatAttribute("researchedXp",0);
                                    if(isEng(name)){
                                        _notify(m_metagame,pid,"Global XP has been used to complete the current weapon research progress, and the remaining global XP is:"+int(m_globalXp)+"w XP");
                                    }else{
                                        _notify(m_metagame,pid,"已使用全局XP完成当前武器科研进度，剩余全局XP："+int(m_globalXp)+"w XP");
                                    }
                                    isTrue = true;
                                }else{
                                    if(isEng(name)){
                                        _notify(m_metagame,pid,"Global XP is insufficient, the current weapon has been researched:"+m_researchedXp+"/"+requiredXp+"w XP, remaining global XP:"+int(m_globalXp)+"w XP");
                                    }else{
                                        _notify(m_metagame,pid,"全局XP不足,当前武器已研究"+m_researchedXp+"/"+requiredXp+"w XP，剩余全局XP："+int(m_globalXp)+"w XP");
                                    }
                                }
                            }else{
                                _notify(m_metagame,pid,"当前武器科研进度100%,已完成该科研");
                                child.setFloatAttribute("researchedXp",m_researchedXp-requiredXp);
                                isTrue = true;
                            }
                        }
                    }
                    m_stash.appendChild(child);
                }
                if(!keyRegistered){
                    _debugReport(m_metagame,"玩家未科研信息,新建");
                    if(isEng(name)){
                        _notify(m_metagame,pid,"Research on the current weapon has begun, and experience is required:"+requiredXp+"w Xp");
                    }else{
                        _notify(m_metagame,pid,"已开始当前武器的科研,需求经验:"+requiredXp+"w Xp");
                    }
                    XmlElement info("research");
                        info.setStringAttribute("key", targetKey);
                        info.setFloatAttribute("researchedXp", 0);
                        info.setFloatAttribute("requiredXp", requiredXp);
                        info.setStringAttribute("type", "weapon");
                        info.setBoolAttribute("OnResearch", true);
                    m_stash.appendChild(info);
                }
                allInfo.appendChild(m_stash);
            }else{//其他玩家信息不修改存回去
                allInfo.appendChild(m_stash);
            }
        }
        if(!findKeYan){
            XmlElement newLine("KeYan");
            allInfo.appendChild(newLine);
            _notify(m_metagame,pid,"科研系统已注册");
        }
        allInfo.removeChild("player",0);
        savePlayerStashInfo(m_metagame,sid,allInfo);
        _log("save KeYan PlayerStashInfo for sid="+sid);
        _debugReport(m_metagame,"saveKeYanPlayersStash");
        return isTrue;
    }
    // ----------------------------------------------------
    protected void savePlayerStashInfo(Metagame@ m_metagame, string sid, XmlElement@ allInfo){
        sid = sid+"_stash.xml";
        writeXML(m_metagame,sid,allInfo);
    }
    protected const XmlElement@ readPlayerStashInfo(string sid){
        sid = sid+"_stash.xml";
        const XmlElement@ root = readXML(m_metagame,sid).getFirstChild();
        if(root is null){
            _log("readPlayerStashInfo for sid="+sid+" is null,create");
            writeXML(m_metagame,sid,XmlElement("players"));
            @root = readXML(m_metagame,sid).getFirstChild();
        }
        return root;
    }
}