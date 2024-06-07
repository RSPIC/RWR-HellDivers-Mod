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
//升级、研发系统脚本

class upgrade : Tracker{
    protected Metagame@ m_metagame;

    upgrade(Metagame@ metagame){
        @m_metagame = @metagame;
    }
    // --------------------------------------------
    protected void handleItemDropEvent(const XmlElement@ event) {
        handleUpgradeEvent(event);
    }
    protected void handleChatEvent(const XmlElement@ event){
		string message = event.getStringAttribute("message");
		string p_name = event.getStringAttribute("player_name");
		int pid = event.getIntAttribute("player_id");
        if(startsWith(message,"/up")){
           
        }
    }
    const XmlElement@ readUpgradeFile(string name,string TagName = ""){
        string sid = g_playerInfoBuck.getSidByName(name);   
        _log("read upgrade PlayerStashInfo for sid="+sid);
        const XmlElement@ allInfo = readPlayerStashInfo(sid);
        if(allInfo is null){
            _log("allInfo is null, in readUpgradeFile");
            return null;
        }
        // 读取存档玩家账号信息
        array<const XmlElement@> m_stashs = allInfo.getChilds();

        for(int j = 0 ; j < int(m_stashs.size()) ; ++j){
            const XmlElement@ m_stash = m_stashs[j];
            if(m_stash is null){continue;}
            if(m_stash.getName() == "upgrade"){
                if(TagName == ""){
                    return m_stash;
                }
                array<const XmlElement@> childs = m_stash.getChilds();
                for(uint i = 0 ; i < childs.size() ; ++i){
                    const XmlElement@ child = childs[i];
                    if(child is null){continue;}
                    if(child.getName() == TagName){
                        return child;
                    }
                }
            }
        }
        // 没有读取到信息，新建
        writeUpgradeFile(name,"",null);
        return null;

    }
    void writeUpgradeFile(string name,string TagName,XmlElement@ newXml){
        string sid = g_playerInfoBuck.getSidByName(name);
        XmlElement@ allInfo = XmlElement(readPlayerStashInfo(sid));
        if(allInfo is null){
            _log("allInfo is null, in writeUpgradeFile");
            return;
        }
        // 读取存档玩家账号信息
        bool isToCreate = true;
        array<const XmlElement@> m_stashs = allInfo.getChilds();
        allInfo.removeAllChild();
        //解决空子项问题
        XmlElement a("player");
        a.setBoolAttribute("onRemove",true);
        allInfo.appendChild(a);
        for(int j = 0 ; j < int(m_stashs.size()) ; ++j){
            XmlElement@ m_stash = XmlElement(m_stashs[j]);
            if(m_stash.getName() == "upgrade"){
                isToCreate = false;
                array<const XmlElement@> childs = m_stash.getChilds();
                m_stash.removeAllChild();

                for(uint i = 0 ; i < childs.size() ; ++i){ //stratagems and so on
                    XmlElement@ child = XmlElement(childs[i]);
                    if(child is null){continue;}
                    if(TagName == child.getName()){
                        array<const XmlElement@> tagChilds = child.getChilds();
                        child.removeAllChild();
                        bool findSame = false;
                        for(uint k = 0 ; k < tagChilds.size() ; ++k){
                            XmlElement@ tagchild = XmlElement(tagChilds[k]);
                            if(tagchild is null){continue;}
                            if(newXml !is null){
                                if(tagchild.getName() == newXml.getStringAttribute("key")){ //覆写文件
                                    child.appendChild(newXml);
                                    findSame = true;
                                    continue;
                                }
                            }
                            // 前面没有覆写文件，此处则保存文件
                            child.appendChild(tagchild);
                        }
                        if(!findSame){
                            child.appendChild(newXml);
                        }
                    }
                    m_stash.appendChild(child);
                }
            }
            allInfo.appendChild(m_stash);
        }
        if(isToCreate){
            XmlElement upgrade("upgrade");
                XmlElement stratagems("stratagems");
                XmlElement hdWeapons("weapons");
                XmlElement prioritys("prioritys");
                XmlElement bases("bases");
                XmlElement others("others");
            upgrade.appendChild(stratagems);
            upgrade.appendChild(hdWeapons);
            upgrade.appendChild(prioritys);
            upgrade.appendChild(bases);
            upgrade.appendChild(others);

            allInfo.appendChild(upgrade);
            int pid = g_playerInfoBuck.getPidByName(name);
            _notify(m_metagame,pid,"研发升级系统已注册");
        }
        allInfo.removeChild("player",0);
        savePlayerStashInfo(m_metagame,sid,allInfo);
        _log("save upgrade PlayerStashInfo for sid="+sid);
        _debugReport(m_metagame,"saveUpgradePlayersStash");
        return;
    }
    bool checkAccess(string name,string TagName,string TagKey,string TagType = ""){
        const XmlElement@ info = readUpgradeFile(name,TagName);
        if(info is null){return false;}
        array<const XmlElement@> bases = info.getChilds();
        _log("PrintTest(checkAccess(name,'"+TagName+"')):"+info.toString());
        for(uint i=0; i<bases.size(); ++i){
            const XmlElement@ base = bases[i];
            if(base is null){continue;}
            string key = base.getStringAttribute("key");
            if(key == TagKey){
                if(TagType != ""){
                    string type = base.getStringAttribute("type");
                    if(type == TagType){
                        return true;
                    }
                }else{
                    return true;
                }
            }
        }
        return false;
    }
    // --------------------------------------------
    protected void handleUpgradeEvent(const XmlElement@ event) {
        int pid = event.getIntAttribute("player_id");
        string itemKey = event.getStringAttribute("item_key");
        int characterId = event.getIntAttribute("character_id");
        if(!startsWith(itemKey,"upgrade_ui_")){return;}
		if(characterId == -1){return;}
        if(g_vestInfoBuck is null){return;}
        if(g_playerInfoBuck is null){return;}
        string name = g_playerInfoBuck.getNameByCid(characterId);
        int containerId = event.getIntAttribute("target_container_type_id");
        //containerId = 0(地面) 1(军械库) 2（背包） 3（仓库）
        //itemClass = 0(主、副武器) 1（投掷物） 3（护甲、战利品）

        if(containerId == 2 || containerId == 3){
            if(itemKey.find("vest") > 0 ){
                handleVestUpgradeEvent(itemKey,name);
                deleteItemInBackpack(m_metagame,characterId,"carry_item",itemKey);
            }
            if(itemKey.find("_weapon") > 0 ){
                handleHdWeaponUpgradeEvent(itemKey,name);
                deleteItemInBackpack(m_metagame,characterId,"weapon",itemKey);
            }
        }
    }
    // --------------------------------------------
    protected void handleVestUpgradeEvent(string itemKey,string name) {
        string subStr = getCutKey(itemKey,"cost:");
        if(isNumeric(subStr)){
            int cost = parseInt(subStr);
            const XmlElement@ info = readUpgradeFile(name,"bases");
            if(info is null){return;}
            array<const XmlElement@> bases = info.getChilds();
            _log("PrintTest(readUpgradeFile(name,'bases')):"+info.toString());
            string vestKey = getCutKey(itemKey,"target:");
            bool isBuy = false;
            bool isOwn = false;
            for(uint i=0; i<bases.size(); ++i){
                const XmlElement@ base = bases[i];
                if(base is null){continue;}
                string key = base.getStringAttribute("key");
                if(key == vestKey){
                    isBuy = true;
                    int pid = g_playerInfoBuck.getPidByName(name);
                    _notify(m_metagame,pid,"已拥有该护甲，现已装配");
                    g_vestInfoBuck.changeVest(name,vestKey);
                    int cid = g_playerInfoBuck.getCidByName(name);
                    editPlayerVest(m_metagame,cid,vestKey,4);
                    isOwn = true;
                }
            }
            if(!isBuy){
                string sid = g_playerInfoBuck.getSidByName(name);
                playerStashInfo@ thePlayer = playerStashInfo(m_metagame,sid,name);
                array<XmlElement@> m_deleteObjects = {
                    getStashXmlElement("samples_acg.carry_item","carry_item",cost)
                };
                array<XmlElement@> m_getObjects = {};
                if(!thePlayer.isOpen()){
                    thePlayer.openStash();
                }
                if(thePlayer.exchangeItems(m_deleteObjects,m_getObjects)){

                    int pid = g_playerInfoBuck.getPidByName(name);
                    _notify(m_metagame,pid,"已购买该护甲，现已装配");
                    g_vestInfoBuck.changeVest(name,vestKey);
                    int cid = g_playerInfoBuck.getCidByName(name);
                    editPlayerVest(m_metagame,cid,vestKey,4);

                    XmlElement newXml("base");
                        newXml.setStringAttribute("key",vestKey);
                        newXml.setStringAttribute("type","vest");
                    writeUpgradeFile(name,"bases",newXml);
                    thePlayer.openStash();
                    isOwn = true;
                }
            }
            if(isOwn){
                g_vestInfoBuck.resetUpgrade(name);

                bool state;
                if(itemKey.find("healNeedle") >= 0){
                    if(g_vestInfoBuck.setHealNeedle(name,state)){
                        if(!state){
                            g_vestInfoBuck.setHealNeedle(name,state);
                        }
                        if(state){
                            int pid = g_playerInfoBuck.getPidByName(name);
                            _notify(m_metagame,pid,"医疗针已配给");
                        }
                    }
                }
                if(itemKey.find("impactGl") >= 0){
                    if(g_vestInfoBuck.setImpactGl(name,state)){
                        if(!state){
                            g_vestInfoBuck.setImpactGl(name,state);
                        }
                        if(state){
                            int pid = g_playerInfoBuck.getPidByName(name);
                            _notify(m_metagame,pid,"冲击雷已配给");
                        }
                    }
                }
                if(itemKey.find("autoHeal") >= 0){
                    if(g_vestInfoBuck.setAutoHeal(name,state)){
                        if(!state){
                            g_vestInfoBuck.setAutoHeal(name,state);
                        }
                        if(state){
                            int pid = g_playerInfoBuck.getPidByName(name);
                            _notify(m_metagame,pid,"自动回血已配置");
                        }
                    }
                }
                if(itemKey.find("autoRecover") >= 0){
                    if(g_vestInfoBuck.setAutoHeal(name,state)){
                        if(!state){
                            g_vestInfoBuck.setAutoHeal(name,state);
                        }
                        if(state){
                            int pid = g_playerInfoBuck.getPidByName(name);
                            _notify(m_metagame,pid,"自救针已配置");
                        }
                    }
                }
                if(itemKey.find("SP:") >= 0){ //战略优先权
                    subStr = getCutKey(itemKey,"SP:");
                    uint priority;
                    if(isNumeric(subStr)){
                        cost = parseInt(subStr);
                        for(int k=0; k<cost; ++k){
                            g_vestInfoBuck.setStratagemsFirst(name,priority);
                        }
                        int pid = g_playerInfoBuck.getPidByName(name);
                        notify(m_metagame,"StratagemsPriority Upgrade "+priority, dictionary(), "misc", pid, false,"", 1.0);
                    }
                }
            }
        }else{
            _report(m_metagame,"cost 提取错误");
            return;
        }
    }
    // --------------------------------------------
    protected void handleHdWeaponUpgradeEvent(string itemKey,string name) {
        string subStr = getCutKey(itemKey,"cost:");
        if(isNumeric(subStr)){
            int cost = parseInt(subStr);
            const XmlElement@ info = readUpgradeFile(name,"weapons");
            if(info is null){return;}
            array<const XmlElement@> weapons = info.getChilds();
            _log("PrintTest(readUpgradeFile(name,'weapons')):"+info.toString());
            string weaponKey = getCutKey(itemKey,"target:");
            weaponKey = weaponKey + ".weapon";
            bool isBuy = false;
            bool isOwn = false;
            for(uint i=0; i<weapons.size(); ++i){
                const XmlElement@ weapon = weapons[i];
                if(weapon is null){continue;}
                string key = weapon.getStringAttribute("key");
                if(key == weaponKey){
                    isBuy = true;
                    int pid = g_playerInfoBuck.getPidByName(name);
                    _notify(m_metagame,pid,"已拥有该武器，已送至背包");
                    int cid = g_playerInfoBuck.getCidByName(name);
                    addItemInBackpack(m_metagame,cid,"weapon",key);
                    isOwn = true;
                }
            }
            if(!isBuy){
                string sid = g_playerInfoBuck.getSidByName(name);
                playerStashInfo@ thePlayer = playerStashInfo(m_metagame,sid,name);
                array<XmlElement@> m_deleteObjects = {
                    getStashXmlElement("samples_acg.carry_item","carry_item",cost)
                };
                array<XmlElement@> m_getObjects = {
                    getStashXmlElement(weaponKey,"weapon",1)
                };
                if(!thePlayer.isOpen()){
                    thePlayer.openStash();
                }
                if(thePlayer.exchangeItems(m_deleteObjects,m_getObjects)){
                    int pid = g_playerInfoBuck.getPidByName(name);
                    _notify(m_metagame,pid,"已研发该武器，现已装配");
                    // int cid = g_playerInfoBuck.getCidByName(name);
                    // addItemInBackpack(m_metagame,cid,"weapon",weaponKey);

                    XmlElement newXml("base");
                        newXml.setStringAttribute("key",weaponKey);
                        newXml.setStringAttribute("type","weapon");
                    int checkTime = 3;
                    while(checkTime > 0){
                        if(itemKey.find("preset"+checkTime) >= 0){
                            string presetKey = getCutKey(itemKey,"preset"+checkTime+":");
                            newXml.setStringAttribute("preset"+checkTime+":",presetKey);
                        }                      
                        checkTime--;
                    }
                    writeUpgradeFile(name,"weapons",newXml);
                    thePlayer.openStash();
                    isOwn = true;
                }
            }
            if(isOwn){
                
            }
        }else{
            _report(m_metagame,"cost 提取错误");
            return;
        }
    }

    protected string getCutKey(string str,string keyWord){
        if(str.find(keyWord) >= 0 ){
            int startPos = str.find(keyWord);
            int endDotPos = str.find(".",startPos);
            string subStr = str.substr(startPos + keyWord.length(), endDotPos - startPos - keyWord.length());
            _log("截取字符为"+subStr);
            return subStr;
        }else{
            return "";
        }
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