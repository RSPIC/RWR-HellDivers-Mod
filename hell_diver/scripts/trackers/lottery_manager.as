#include "tracker.as"
#include "helpers.as"
#include "admin_manager.as"
#include "log.as"
#include "query_helpers.as"
#include "query_helpers2.as"
#include "gamemode.as"
#include "all_helper.as"
#include "all_parameter.as"

#include "INFO.as"
#include "debug_reporter.as"
#include "math.as"

//author：rst
//抽奖脚本
//十连保底
//百连井
//功能性道具
//命运硬币

class lotteryInfo {
    protected string m_name;
    protected dictionary m_lotteryCount;

    lotteryInfo(string&in name){
        m_name = name;
    }

    string name(){return m_name;}

    int lotteryCount(string&in lottery){
        int count;
        if(m_lotteryCount.get(lottery,count)){
            return count;
        }
        return 0;
    }

    void addCount(string&in lottery){
        int count = 0;
        if(!m_lotteryCount.get(lottery,count)){
            m_lotteryCount.set(lottery,1);
        }else{
            count++;
            m_lotteryCount.set(lottery,count);
        }
    }
    void clearCount(string&in lottery){
        int count;
        if(!m_lotteryCount.get(lottery,count)){
            m_lotteryCount.set(lottery,0);
        }else{
            count = 0;
            m_lotteryCount.set(lottery,count);
        }
    }
}

class lotteryInfoBuck {
    protected array<lotteryInfo@> m_lotteryInfoBuck;

    lotteryInfoBuck(){
        lotteryInfo@ newinfo = lotteryInfo("");
        m_lotteryInfoBuck.insertLast(newinfo);
    }

    void addInfo(string&in name){
        for(uint i = 0 ; i < m_lotteryInfoBuck.size() ; ++i){
            if(m_lotteryInfoBuck[i].name() == name){
                return;
            }
        }
        lotteryInfo@ newinfo = lotteryInfo(name);
        m_lotteryInfoBuck.insertLast(newinfo);
    }
    void addCount(string&in name,string&in lottery){
        for(uint i = 0 ; i < m_lotteryInfoBuck.size() ; ++i){
            if(m_lotteryInfoBuck[i].name() == name){
                m_lotteryInfoBuck[i].addCount(lottery);
                return;
            }
        }
    }
    void clearCount(string&in name,string&in lottery){
        for(uint i = 0 ; i < m_lotteryInfoBuck.size() ; ++i){
            if(m_lotteryInfoBuck[i].name() == name){
                m_lotteryInfoBuck[i].clearCount(lottery);
                return;
            }
        }
    }
    int lotteryCount(string&in name,string&in lottery){
        for(uint i = 0 ; i < m_lotteryInfoBuck.size() ; ++i){
            if(m_lotteryInfoBuck[i].name() == name){
                int count = m_lotteryInfoBuck[i].lotteryCount(lottery);
                return count;
            }
        }
        return 0;
    }

    void clearAll(){
        m_lotteryInfoBuck.resize(0);
    }
}

class lottery_manager : Tracker {
    protected Metagame@ m_metagame;
    protected lotteryInfoBuck@ m_lotteryInfoBuck;
    protected string m_guaguale_num;

    lottery_manager(Metagame@ metagame){    
        @m_metagame = @metagame;
        @m_lotteryInfoBuck = lotteryInfoBuck();
        m_guaguale_num = "" + int(rand(10000,99999));
    }

    void start(){
    }

    void update(float time) {
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
    // --------------------------------------------
    protected void handleResultEvent(const XmlElement@ event) {
       
    }
    // --------------------------------------------
    protected void handleItemDropEvent(const XmlElement@ event) {
        handleFunctionalItemsEvent(event);
        handleFateCoinEvent(event);
        handleGuaranteedLottery(event);
        handleGuaGuaLeLottery(event);
        handleGuaGuaLeIILottery(event);
    }

    // --------------------------------------------
    protected void handleFunctionalItemsEvent(const XmlElement@ event) {
        string itemKey = event.getStringAttribute("item_key");
        int pid = event.getIntAttribute("player_id");
        int cid = event.getIntAttribute("character_id");
        if(cid == -1){return;}
        int containerId = event.getIntAttribute("target_container_type_id");
        if(containerId != 1){return;}// 1(军械库)
        if(g_playerInfoBuck is null){return;}
        string name = g_playerInfoBuck.getNameByPid(pid);
        if(name == ""){return;}
        array<string> targetKey = {"hd_bonusfactor_al_","hd_bonusfactor_xp_","hd_bonusfactor_rp_"};
        for(uint i = 0 ; i < targetKey.size() ; ++i){
            string tempKey = itemKey.substr(0,targetKey[i].length());
            //比对通过
            if(tempKey == targetKey[i]){
                string num = itemKey.substr(targetKey[i].size());
                if(isNumeric(num)){
                    //开局超时5分钟禁止使用加成卡
                    uint playingTime = g_battleInfoBuck.playingTime(name);
                    if(playingTime >= 5){
                        notify(m_metagame,"OverTime,You can only use this in first 5 min", dictionary(), "misc", pid, false, "", 1.0);
                        addItemInBackpack(m_metagame,cid,"carry_item",itemKey);
                        return;
                    }
                    float bonusFactor = 0.01*parseFloat(num);
                    //先过判断
                    if(g_firstUseInfoBuck.isFirst(name,"hd_bonusfactor")){
                        notify(m_metagame,"The bonus has taken effect", dictionary(), "misc", pid, false, "", 1.0);
                        dictionary a;
                        a["%bf"] = ""+bonusFactor;
                        notify(m_metagame,"Now Factor", a, "misc", pid, false, "", 1.0);
                    }else{
                        notify(m_metagame,"The bonus can only be applied once", dictionary(), "misc", pid, false, "", 1.0);
                        addItemInBackpack(m_metagame,cid,"carry_item",itemKey);
                        return;
                    }
                    //再过加成
                    if(i == 0){
                        g_battleInfoBuck.addBonusFactor(name,bonusFactor);
                    }else if(i == 1){
                        g_battleInfoBuck.addBonusFactorXp(name,bonusFactor);
                    }else if(i == 2){
                        g_battleInfoBuck.addBonusFactorRp(name,bonusFactor);
                    }
                    
                }
            }
        }
    } 
    // --------------------------------------------
    protected void handleFateCoinEvent(const XmlElement@ event) {
        string itemKey = event.getStringAttribute("item_key");
        if(itemKey != "fate_coin.carry_item"){return;}
        int containerId = event.getIntAttribute("target_container_type_id");
        if(containerId != 1){return;}// 1(军械库)
        int pid = event.getIntAttribute("player_id");
        int cid = event.getIntAttribute("character_id");
        int fid = g_playerInfoBuck.getFidByCid(cid);
        string pos = event.getStringAttribute("position");
        string name = g_playerInfoBuck.getNameByPid(pid);
        string INT_key = name+itemKey;
        if(!g_IRQ.isExist(INT_key)){
            array<string> soundList ={"coin_drop_01.wav","coin_drop_02.wav","coin_drop_03.wav"};
            playRandomSoundArray(m_metagame,soundList,fid,pos,1.0);
            fate_coin_task@ new_task = fate_coin_task(m_metagame,event,5,INT_key);
			TaskSequencer@ tasker = m_metagame.getTaskManager().newTaskSequencer();
			tasker.add(new_task);

        }else{
            addItemInBackpack(m_metagame,cid,"carry_item",itemKey);
            notify(m_metagame,"Processing", dictionary(), "misc", pid, false, "", 1.0);
        }
    }
    // --------------------------------------------
    protected void handleGuaranteedLottery(const XmlElement@ event) {
        string itemKey = event.getStringAttribute("item_key");
        if(itemKey != "lottery.carry_item"){return;}
        int containerId = event.getIntAttribute("target_container_type_id");
        if(containerId != 1){return;}// 1(军械库)
        int pid = event.getIntAttribute("player_id");
        int cid = event.getIntAttribute("character_id");
        string name = g_playerInfoBuck.getNameByPid(pid);
        g_userCountInfoBuck.addCount(name,itemKey+"10");
        g_userCountInfoBuck.addCount(name,itemKey+"300");
        int value;
        if(g_userCountInfoBuck.getCount(name,itemKey+"10",value) && value == 10){    //十次保底
            addItemInBackpack(m_metagame,cid,"carry_item","reward_box_skin.carry_item");
            notify(m_metagame,"Lottery Guaranteed Reward [10]", dictionary(), "misc", pid, false, "", 1.0);
            g_userCountInfoBuck.clearCount(name,itemKey+"10");
        }
        if(g_userCountInfoBuck.getCount(name,itemKey+"300",value) && value == 300){    //300吃井
            addItemInBackpack(m_metagame,cid,"carry_item","reward_box_weapon_lamda.carry_item");
            notify(m_metagame,"Lottery Guaranteed Reward [300]", dictionary(), "misc", pid, false, "", 1.0);
            g_userCountInfoBuck.clearCount(name,itemKey+"300");
        }
    }
    // --------------------------------------------
    protected void handleGuaGuaLeLottery(const XmlElement@ event) {
        string itemKey = event.getStringAttribute("item_key");
        if(itemKey != "lottery_cash.carry_item"){return;}
        int containerId = event.getIntAttribute("target_container_type_id");
        if(containerId != 1){return;}// 1(军械库)
        int pid = event.getIntAttribute("player_id");
        int cid = event.getIntAttribute("character_id");
        string pos = event.getStringAttribute("position");
        string pick_num = "" + int(rand(10000,99999));
        if(pick_num != m_guaguale_num){
            dictionary a;
            a["%mynum"] = pick_num;
            a["%tgnum"] = m_guaguale_num;
            notify(m_metagame,"GuaGuaLe", a, "misc", pid, false, "", 1.0);
        }else{
            string name = g_playerInfoBuck.getNameByPid(pid);
            dictionary a;
            a["%player"] = name;
            a["%tgnum"] = m_guaguale_num;
            _report(m_metagame,"GuaGuaLeReward",a,"GuaGuaLeRewardTitle",true);
            playSoundAtLocation(m_metagame,"cash_in.wav",-1,pos,1.0);
            playSoundAtLocation(m_metagame,"human_male_yee_01.wav",-1,pos,1.0);
            GiveRP(m_metagame,cid,7000000);
        }
    }
    // --------------------------------------------
    protected void handleGuaGuaLeIILottery(const XmlElement@ event) {
        string itemKey = event.getStringAttribute("item_key");
        if(itemKey != "lottery_cash_II.carry_item"){return;}
        int containerId = event.getIntAttribute("target_container_type_id");
        if(containerId != 1){return;}// 1(军械库)
        int pid = event.getIntAttribute("player_id");
        int cid = event.getIntAttribute("character_id");
        string pos = event.getStringAttribute("position");
        string pick_num = "" + int(rand(1000,9999));
        string guaguale_num = "" + int(rand(1000,9999));
        uint samenum = 0;
        for(uint i = 0; i < pick_num.length(); i++){
            string str_m = pick_num.substr(i,1);
            string str_t = guaguale_num.substr(i,1);
            if(str_t == str_m){
                samenum++;
            }
        }   
        int rp = 600*samenum*samenum;
        if(samenum == 0){
            dictionary a;
            a["%mynum"] = pick_num;
            a["%tgnum"] = guaguale_num;
            a["%samenum"] = ""+samenum;
            a["%rp"] = ""+rp;
            notify(m_metagame,"GuaGuaLeII", a, "misc", pid, false, "", 1.0);
        }else{
            dictionary a;
            a["%mynum"] = pick_num;
            a["%tgnum"] = guaguale_num;
            a["%samenum"] = ""+samenum;
            a["%rp"] = ""+rp;
            notify(m_metagame,"GuaGuaLeII", a, "misc", pid, false, "", 1.0);
            playSoundAtLocation(m_metagame,"cash_in.wav",-1,pos,1.0);
            GiveRP(m_metagame,cid,rp);
        }
    }
}

class fate_coin_task : Task{
	protected Metagame@ m_metagame;
	protected const XmlElement@ m_player;
	protected bool m_ended;
	protected float m_time;
    protected float m_timer;
    protected float m_timer_delay;
    protected string m_intKey;

	fate_coin_task(Metagame@ metagame,const XmlElement@ player,float time,string Key){
		@m_metagame = @metagame;
		@m_player = @player;
		m_time = time;
        m_timer = m_time;
        m_timer_delay = 2.0;
		m_intKey = Key;
		g_IRQ.set(m_intKey,true);  //添加至中断请求存储区
	}

	bool hasEnded() const{
		return m_ended;
    }

	void start(){
        m_ended = false;
    }

	void update(float time){
		m_timer -= time;
        m_timer_delay -= time;
        if(m_timer_delay <= 0 && !m_ended){
            MyTask();
            m_timer_delay = m_time;
        }
		if(m_timer >0){return;}
		g_IRQ.remove(m_intKey);     //清除字典内容
        m_ended = true;
	}

	protected void MyTask(){
		if(m_player is null){return;}
        string pos = m_player.getStringAttribute("position");
        int pid = m_player.getIntAttribute("player_id");
        int cid = m_player.getIntAttribute("character_id");
        int fid = g_playerInfoBuck.getFidByCid(cid);
        
        int basePrice = 12800;
        int rewardPrice = 0;
        float random = rand(0.0f,1.0f);
        if (random <= 0.01) {
            // 1% 概率获得10倍
            rewardPrice = basePrice * 10;
            GiveRP(m_metagame,cid,rewardPrice);
            playSoundAtLocation(m_metagame,"human_male_yee_01.wav",fid,pos,1.0);
        } 
        else if (random <= 0.11) {
            // 10% 概率获得3倍
            rewardPrice = basePrice * 3;
            GiveRP(m_metagame,cid,rewardPrice);
        } 
        else if (random <= 0.51) {
            // 40% 概率获得原价
            rewardPrice = basePrice;
            GiveRP(m_metagame,cid,rewardPrice);
        } 
        else {
            // 其余情况雷击
            spawnStaticProjectile(m_metagame,"dooms_hammer.projectile",pos,cid,fid);
            return;
        }
        dictionary a;
        a["%rp"] = formatInt(rewardPrice);
        notify(m_metagame,"FateCoin Result", a, "misc", pid, false, "", 1.0);
        playSoundAtLocation(m_metagame,"cash_in.wav",fid,pos,1.0);
	}
}