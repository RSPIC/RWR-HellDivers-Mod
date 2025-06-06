#include "tracker.as"
#include "helpers.as"
#include "admin_manager.as"
#include "log.as"
#include "query_helpers.as"
#include "query_helpers2.as"
#include "gamemode.as"
#include "gamemode_invasion.as"
#include "all_helper.as"

#include "debug_reporter.as"
#include "INFO.as"
#include "stash_translation.as"

//author:RST
//HD专用的脚本仓库脚本

// 记录格式
// <stash AA_tag="normal.weapon" A_key="weapon" value="3" />
// 以AA_tag键值为唯一比对目标，若相同，则进行后续操作

class playerStashInfo {
    protected Metagame@ m_metagame;
    protected bool m_isStashOpen;
    protected XmlElement@ m_selectObject;
    protected array<XmlElement@> m_pushInObject;
    protected array<XmlElement@> m_overPushObject;
    protected array<XmlElement@> m_stashObject;
    protected int m_page;
    protected int m_eachPageSize = 30;
    protected int m_index;
    protected int m_stashSize;
    protected int m_stashUsedSize;
    protected string m_name;
    protected string m_sid;

    playerStashInfo(Metagame@ metagame,const XmlElement@ newplayer){
        @m_metagame = @metagame;
        if(newplayer is null){return;}
        m_sid = newplayer.getStringAttribute("sid");
        m_name = newplayer.getStringAttribute("name");
        m_isStashOpen = false;
        m_page = 0;
        m_index = 0;
        @m_selectObject = null;
        updatePlayersStash();
    }
    playerStashInfo(Metagame@ metagame,string sid,string name){
        @m_metagame = @metagame;
        m_sid = sid;
        m_name = name;
        m_isStashOpen = false;
        m_page = 0;
        m_index = 0;
        @m_selectObject = null;
        updatePlayersStash();
    }
    string getName(){
        return m_name;
    }
    string getSid(){
        return m_sid;
    }
    protected void clearInfos(){
        m_pushInObject.resize(0);
    }
    protected bool isPushIn(){
        if(m_pushInObject.size() != 0){
            return true;
        }
        return false;
    }
    bool isOpen(bool isNotify = false){
        if(!m_isStashOpen && isNotify){
            int pid = g_playerInfoBuck.getPidByName(m_name);
            _notify(m_metagame,pid,"仓库未打开");
        }
        return m_isStashOpen;
    }
    void changePage(int direction){
        if(!isOpen(true)){return;}
        m_page += direction;
        showNowPageObject();
    }
    void openStash(bool isNotify = true){//打开仓库
        refreshStash();
        int pid = g_playerInfoBuck.getPidByName(m_name);
        if(isPushIn()){
            pushInObjects();
            _notify(m_metagame,pid,"您有物品未存入，已自动帮你存入");
            return;
        }
        m_isStashOpen = !m_isStashOpen;
        if(isNotify){
            if(m_isStashOpen){
                _notify(m_metagame,pid,"仓库已打开");
            }else{
                _notify(m_metagame,pid,"仓库已关闭");
                returnOverPushObject();
                clearInfos();
            }
            XmlElement@ object = selectObject(0,false);
            if(object is null){
                if(isEng(m_name)){
                    _notify(m_metagame,pid,"Current warehouse capacity "+m_stashUsedSize+"/"+m_stashSize);
                }else{
                    _notify(m_metagame,pid,"当前仓库容量 "+m_stashUsedSize+"/"+m_stashSize);
                }
            }
        }
    }
    void upgradeStash(int num,bool isFree = false){//仓库升级 预处理
        if(!isOpen(true)){return;}
        int pid = g_playerInfoBuck.getPidByName(m_name);
        if(isPushIn()){
            pushInObjects();
            _notify(m_metagame,pid,"您有物品未存入，已自动帮你存入");
            return;
        }
        int cid = g_playerInfoBuck.getCidByName(m_name);
        const XmlElement@ character = getCharacterInfo(m_metagame,cid);
        if(character is null){return;}
        int rp = character.getIntAttribute("rp");
        int basePrice = 200000;//20w
        if(!isFree){
            if(rp < basePrice*num){
                notify(m_metagame, "Insufficient Rp", dictionary(), "misc", pid, false, "", 1.0);
                return;
            }
            GiveRP(m_metagame,cid,-basePrice*num);
        }
        updatePlayersStash(num);
        if(isEng(m_name)){
            _notify(m_metagame,pid,"Current warehouse capacity "+m_stashUsedSize+"/"+m_stashSize);
        }else{
            _notify(m_metagame,pid,"当前仓库容量 "+m_stashUsedSize+"/"+m_stashSize);
        }
    }
    protected void refreshStash(){//重载仓库内容
        // 读取存档玩家信息
        XmlElement@ allInfo = XmlElement(readPlayerStashInfo(m_sid));
        if(allInfo is null){
            _log("allInfo is null, in updatePlayers");
            _report(m_metagame,"player="+m_name+" failed to create stash file");
            return;
        }
        // 读取存档玩家账号信息
        array<const XmlElement@> m_stashs = allInfo.getChilds();
        for(int j = 0 ; j < int(m_stashs.size()) ; ++j){
            XmlElement@ m_stash = XmlElement(m_stashs[j]);
            if(m_stash.getName() == "player"){
                string sid = m_stash.getStringAttribute("sid");
                m_stashSize = m_stash.getIntAttribute("stash_size");
                if(m_sid == sid){
                    array<const XmlElement@> childs = m_stash.getChilds();
                    m_stashObject.resize(0);
                    for(uint i = 0 ; i < childs.size() ; ++i){
                        m_stashObject.insertLast(XmlElement(childs[i]));
                    }
                }
            }
        }
        getStashUsedSize();
        returnOverPushObject();//初始化退还物品列表
        if(g_debugMode){
            _report(m_metagame,"refreshStash");
        }
    }
    protected void returnOverPushObject(){
        array<Resource@> resources;
        Resource@ res;
        string backKey;
        string backType;
        for(uint i = 0 ; i < m_overPushObject.size() ; ++i){
            XmlElement@ m_object = m_overPushObject[i];

            int backNum = m_object.getIntAttribute("value");
            backKey = m_object.getStringAttribute("AA_tag");
            backType = m_object.getStringAttribute("A_tag");
            if(backType == "0"){
                backType = "weapon";
            }
            if(backType == "1"){
                backType = "projectile";
            }
            if(backType == "3"){
                backType = "carry_item";
            }
            @res = Resource(backKey,backType);
            res.addToResources(resources,backNum);
            m_overPushObject.removeAt(i);
            i--;
        }
        if(resources.size() != 0){
            int cid = g_playerInfoBuck.getCidByName(m_name);
            addListItemInBackpack(m_metagame,cid,resources);
            int pid = g_playerInfoBuck.getPidByName(m_name);
            _notify(m_metagame,pid,"溢出物品已退还");
        }
        //m_overPushObject.resize(0);
    }
    void pullOutObjects(int takeNum){//取出物品
        if(!isOpen(true)){return;}
        if(isPushIn()){
            int pid = g_playerInfoBuck.getPidByName(m_name);
            pushInObjects();
            _notify(m_metagame,pid,"您有物品未存入，已自动帮你存入");
            return;
        }
        int pid = g_playerInfoBuck.getPidByName(m_name);
        int cid = g_playerInfoBuck.getCidByName(m_name);
        if(takeNum > 0){
            //refreshStash();
            array<Resource@> resources;
            Resource@ res;
            string itemKey;
            string itemType;
            for(uint i = 0 ; i < m_stashObject.size() ; ++i){
                XmlElement@ m_object = m_stashObject[i];
                itemKey = m_object.getStringAttribute("AA_tag");
                itemType = m_object.getStringAttribute("A_tag");
                
                XmlElement@ object = m_selectObject;
                if(object is null){
                    _notify(m_metagame,pid,"未选择物品");
                    return;
                }
                string slect_itemType = object.getStringAttribute("A_tag");
                string temp = "";
                if(banTypeStoreItem.get(itemKey,temp)){
                    if(temp != ""){
                        if(itemType == temp){
                            m_stashObject.removeAt(i);
                            i--;
                            saveStashObject();
                            continue;
                        }
                    }
                }
                if(slect_itemType == "special"){
                    _notify(m_metagame,pid,"Special item can't be pull out");
                    return;
                }
                if(m_object.equals(object)){ 
                    int inNum = m_object.getIntAttribute("value");
                    int pullOutNum = takeNum;
                    if(pullOutNum >= inNum){ //取出数量超过已有数量，取出全部
                        pullOutNum = inNum;
                        if(slect_itemType == "weapon"){ // re的weapon物品特殊处理，保证永久有一把在仓库不会被取出
                            if(startsWith(itemKey,"re_")){
                                inNum++;
                            }else{
                                m_stashObject.removeAt(i);
                                i--;
                            }
                        }else{
                            m_stashObject.removeAt(i);    
                            i--;
                        }
                    }
                    m_object.setIntAttribute("value",inNum-pullOutNum);
                    @res = Resource(itemKey,itemType);
                    res.addToResources(resources,pullOutNum);
                }

            }
            if(resources.size() != 0){
                addListItemInBackpack(m_metagame,cid,resources);
                string itemCnName = "";
                canStoreItem.get(itemKey,itemCnName);
                if(isEng(m_name)){
                    itemCnName = itemKey;
                    notify(m_metagame, "Item "+itemCnName+" is fetched", dictionary(), "misc", pid, false, "", 1.0);
                }else{
                    notify(m_metagame, "物品"+itemCnName+"已取出", dictionary(), "misc", pid, false, "", 1.0);
                }
                saveStashObject();
            }else{
                notify(m_metagame, "未选定物品", dictionary(), "misc", pid, false, "", 1.0);
            }
        }
        clearInfos();
    }
    void addPushInObject(XmlElement@ object){
        if(object !is null){
            string o_itemKey = object.getStringAttribute("AA_tag");
            string o_itemType = object.getStringAttribute("A_tag");

            int itemNum = object.getIntAttribute("value");
            if(itemNum + getAfterPushStashUsedSize() > m_stashSize && o_itemType != "special"){
                int pid = g_playerInfoBuck.getPidByName(m_name);
                _notify(m_metagame,pid,"存放数量已超过仓库容量上限，多余物品将在您存入物品后退还。");
                m_overPushObject.insertLast(object);
                return;
            }

            if(m_pushInObject.size() > 0){ //堆叠同类物品
                XmlElement@ t_Object = m_pushInObject[m_pushInObject.size()-1]; //取尾部开始，对于一次性的大量同类物品投入有压缩效果
                string t_itemKey = t_Object.getStringAttribute("AA_tag");
                string t_itemType = t_Object.getStringAttribute("A_tag");
                if(t_itemKey == o_itemKey && t_itemType == o_itemType){
                    int t_value = t_Object.getIntAttribute("value");
                    t_Object.setIntAttribute("value",itemNum + t_value);
                }else{
                    m_pushInObject.insertLast(object);
                }
            }else{
                m_pushInObject.insertLast(object); //首个物品
            }
            string itemCnName = "";
            canStoreItem.get(o_itemKey,itemCnName);
            int pid = g_playerInfoBuck.getPidByName(m_name);
            if(isEng(m_name)){
                itemCnName = o_itemKey;
                _notify(m_metagame,pid,"Item "+itemCnName+" is temporarily stored, right click 'Save All' Items to store");
            }else{
                _notify(m_metagame,pid,"物品"+itemCnName+"已暂存，右键'全部存入'以存储至仓库");
            }
        }
       
    }
    void pushInObjects(){//存放物品
        if(!isOpen(true)){return;}
        //refreshStash();
        _debugReport(m_metagame,"pushin数量="+m_pushInObject.size());
        for(uint j = 0 ; j < m_pushInObject.size() ; ++j){
            XmlElement@ pushInObject = m_pushInObject[j];
            if(pushInObject is null){continue;}
            int p_itemValue = pushInObject.getIntAttribute("value");
            bool isExist = false;
            for(uint i = 0 ; i < m_stashObject.size() ; ++i){
                XmlElement@ m_object = m_stashObject[i];
                if(m_object is null){continue;}
                string m_itemKey = m_object.getStringAttribute("AA_tag");
                int m_itemValue = m_object.getIntAttribute("value");
                if(isMatch(m_object,pushInObject)){
                    m_object.setIntAttribute("value",m_itemValue + p_itemValue);
                    _debugReport(m_metagame,"添加物品="+m_itemKey+"数量="+p_itemValue);
                    isExist = true;
                    break;
                }
            }
            if(!isExist){
                m_stashObject.insertLast(pushInObject);
            }
            //自清理
            m_pushInObject.removeAt(j);
            j--;
        }
        int pid = g_playerInfoBuck.getPidByName(m_name);
        _notify(m_metagame,pid,"已全部存入!");
        int cid = g_playerInfoBuck.getCidByName(m_name);

        returnOverPushObject();//返回无法存入物品
        saveStashObject();
        refreshStash();
        //openStash(); //自动关仓
    }
    protected void saveStashObject(){//保存仓库信息于文件
        // 读取存档玩家信息
        XmlElement@ allInfo = XmlElement(readPlayerStashInfo(m_sid));
        if(allInfo is null){
            _log("allInfo is null, in updatePlayers");
            _debugReport(m_metagame,"player="+m_name+" failed to create stash file");
            return;
        }
        // 读取存档玩家账号信息
        array<const XmlElement@> m_stashs = allInfo.getChilds();

        allInfo.removeAllChild();
        //解决空子项问题
        XmlElement a("player");
        a.setBoolAttribute("onRemove",true);
        allInfo.appendChild(a);

        getStashUsedSize();//刷新已存入物品数量
        for(int j = 0 ; j < int(m_stashs.size()) ; ++j){
            XmlElement@ m_stash = XmlElement(m_stashs[j]);
            string sid = m_stash.getStringAttribute("sid");
            if(m_sid == sid){
                m_stash.setIntAttribute("now_size",m_stashUsedSize);
                array<const XmlElement@> childs = m_stash.getChilds();
                m_stash.removeAllChild();
                m_stash.appendChilds(m_stashObject);
                allInfo.appendChild(m_stash);
            }else{//其他玩家信息不修改存回去
                allInfo.appendChild(m_stash);
            }
        }
        allInfo.removeChild("player",0);
        savePlayerStashInfo(m_metagame,m_sid,allInfo);
        _debugReport(m_metagame,"saveStashObject");
    }

    protected void showNowPageObject(){ //展示当前页所有仓库物品
        if(!isOpen(true)){return;}
        _log("showNowPageObject");
        int startIndex = m_eachPageSize*m_page;
        int maxIndex = int(m_stashObject.size());
        int maxPage = int(floor(maxIndex/m_eachPageSize))+1;
        int m_maxPage = maxPage;
        _log("maxIndex="+maxIndex);
        _log("startIndex="+startIndex);
        int leftNum = m_eachPageSize;
        // 保证指向的index不会溢出，同时能够首尾循环选择
        if(maxIndex != 0){
            while(startIndex >= maxIndex){
                startIndex -= m_eachPageSize;
                m_page--;
            }
            while(startIndex < 0){
                startIndex += m_eachPageSize;
                m_page = --maxPage;
            }
            if(m_page == m_maxPage-1){
                leftNum = maxIndex % m_eachPageSize;
            }
            _log("startIndex after="+startIndex);
            _log("left num="+leftNum);
            string itemName;
            string itemType;
            int itemValue;
            dictionary a;
            a["%nowsize"] = formatInt(m_stashUsedSize);
            a["%maxsize"] = formatInt(m_stashSize);
            a["%nowpage"] = formatInt(m_page+1);
            a["%maxpage"] = ""+int(1+maxIndex/m_eachPageSize);
            for(int j = 0 ; j < m_eachPageSize ; ++j){
                string strkey;
                string strvalue;
                if(j >= 10 && j < 20){
                    strkey = "%a"+j;
                    strvalue = "%b"+j;
                }else if(j >= 20 && j < 30){
                    strkey = "%c"+j;
                    strvalue = "%d"+j;
                }else{
                    strkey = "%key"+j;
                    strvalue = "%value"+j;
                }
                a[strkey] = "";
                a[strvalue] = "";

            }
            //check if null
            if(startIndex < 0 && startIndex >= int(m_stashObject.size())){
                if(m_stashObject.size() != 0){
                    startIndex = 0;
                }else{
                    return;
                }
            }
            while(leftNum > 0){
                if(startIndex >= int(m_stashObject.size())){
                    break;
                }
                itemName = m_stashObject[startIndex].getStringAttribute("AA_tag");
                itemType = m_stashObject[startIndex].getStringAttribute("A_tag");
                itemValue = m_stashObject[startIndex].getIntAttribute("value");
                string strkey ;
                string strvalue ;
                int index = startIndex % m_eachPageSize;
                if(index >= 10 && index < 20){
                    strkey = "%a"+index;
                    strvalue = "%b"+index;
                }else if(index >= 20 && index < 30){
                    strkey = "%c"+index;
                    strvalue = "%d"+index;
                }else{
                    strkey = "%key"+index;
                    strvalue = "%value"+index;
                }
                string itemCnName = "";
                canStoreItem.get(itemName,itemCnName);
                if(isEng(m_name)){
                    itemCnName = itemName;
                }
                a[strkey] = itemCnName;
                a[strvalue] = ""+itemValue;
                startIndex++;
                leftNum--;
            }
            int pid = g_playerInfoBuck.getPidByName(m_name);
            if(isEng(m_name)){
                notify(m_metagame, "stashPageObjectInfo", a, "misc", pid, true, "Currently on the "+(m_page+1)+" page", 2.0);
            }else{
                notify(m_metagame, "stashPageObjectInfo", a, "misc", pid, true, "当前第"+(m_page+1)+"页", 2.0);
            }
        }else{
            int pid = g_playerInfoBuck.getPidByName(m_name);
            if(isEng(m_name)){
                notify(m_metagame, "Warehouse is currently empty, capacity "+m_stashUsedSize+"/"+m_stashSize, dictionary(), "misc", pid, false, "", 1.0);
            }else{
                notify(m_metagame, "仓库目前为空,容量 "+m_stashUsedSize+"/"+m_stashSize, dictionary(), "misc", pid, false, "", 1.0);
            }
        }
    }
    protected void updatePlayersStash(int add_stash = 0){ //仓库创建/刷新/升级
        // 读取存档玩家信息
        XmlElement@ allInfo = XmlElement(readPlayerStashInfo(m_sid));
        if(allInfo is null){
            _log("allInfo is null, in updatePlayers");
            _report(m_metagame,"player="+m_name+" failed to create stash file");
            return;
        }
        // 读取存档玩家账号信息
        array<const XmlElement@> m_stashs = allInfo.getChilds();

        allInfo.removeAllChild();
        //解决空子项问题
        XmlElement a("player");
        a.setBoolAttribute("onRemove",true);
        allInfo.appendChild(a);

        bool isExist = false;
        for(int j = 0 ; j < int(m_stashs.size()) ; ++j){
            XmlElement@ m_stash = XmlElement(m_stashs[j]);
            if(m_stash.getName() == "player"){
                isExist = true;
                int stash_size = m_stash.getIntAttribute("stash_size");
                array<const XmlElement@> childs = m_stash.getChilds();
                m_stashObject.resize(0);
                for(uint i = 0 ; i < childs.size() ; ++i){
                    m_stashObject.insertLast(XmlElement(childs[i]));
                }
                m_stash.removeAllChild();
                m_stashSize = stash_size + add_stash;
                    m_stash.setIntAttribute("stash_size",m_stashSize);
                getStashUsedSize();
                    m_stash.setIntAttribute("now_size",m_stashUsedSize);
                m_stash.appendChilds(m_stashObject);
            }
            //保存修改的和未修改的信息
            allInfo.appendChild(m_stash);
        }
        //不存在，新建信息
        if(!isExist){
            XmlElement playerinfo("player");
            playerinfo.setIntAttribute("stash_size",100);
            m_stashSize = 100;
            playerinfo.setIntAttribute("now_size",0);
            playerinfo.setStringAttribute("player_name",m_name);
            playerinfo.setStringAttribute("sid",m_sid);
            allInfo.appendChild(playerinfo);
        }
        allInfo.removeChild("player",0);
        savePlayerStashInfo(m_metagame,m_sid,allInfo);
        _debugReport(m_metagame,"savePlayersStash");
    }
    protected void getStashUsedSize(){
        int allValue = 0;
        for(uint i = 0 ; i < m_stashObject.size() ; ++i){
            int value = m_stashObject[i].getIntAttribute("value");
            if(m_stashObject[i].getStringAttribute("A_tag") == "special"){ //特殊物品不计入
                continue;
            }
            allValue += value;
        }
        m_stashUsedSize = allValue;
        return;
    }
    protected int getAfterPushStashUsedSize(){
        int allValue = m_stashUsedSize;
        for(uint i = 0 ; i < m_pushInObject.size() ; ++i){
            int value = m_pushInObject[i].getIntAttribute("value");
            allValue += value;
        }
        return allValue;
    }
    XmlElement@ selectObject(int index = 0 ,bool isNotify = true){
        m_index += index;
        bool positive_direction = true;
        if(m_index >= m_eachPageSize){
            m_index = 0;
            positive_direction = true;
        }
        if(m_index < 0){ //m_index 范围 0~9 恒为正
            m_index = m_eachPageSize - 1;
            positive_direction = false;
        }
        _debugReport(m_metagame,"m_index"+m_index);
        int stashObjectSize = int(m_stashObject.size());
        int targetIndex = m_index + m_eachPageSize*m_page;
        if(stashObjectSize != 0){
            if(targetIndex >= stashObjectSize){
                if(positive_direction){
                    targetIndex = m_eachPageSize*m_page;
                    m_index = 0;
                }else{
                    targetIndex = stashObjectSize - 1;
                    m_index = targetIndex % m_eachPageSize;
                }
            }
            _debugReport(m_metagame,"m_index="+m_index);
            _debugReport(m_metagame,"targetIndex"+targetIndex);
            _debugReport(m_metagame,"stashObjectSize"+stashObjectSize);
            if(targetIndex >= stashObjectSize){
                m_page--;
                if(m_page < 0){
                    return null;
                }
                return selectObject();//递归
            }
            if(targetIndex < 0 ){
                targetIndex = 0;
                _debugReport(m_metagame,"targetIndex 序号出现溢出风险 < 0");
            }
            if(targetIndex > int(m_stashObject.size())){
                targetIndex = m_stashObject.size() -1;
                _debugReport(m_metagame,"targetIndex 序号出现溢出风险 > "+m_stashObject.size());
            }
            if(m_stashObject.size() == 0){
                return null;
            }
            XmlElement@ object = m_stashObject[targetIndex];//DO: 这里的index不保险，必须添加强制不溢出的检测
            if(object !is null){
                string itemName = object.getStringAttribute("AA_tag");
                string itemType = object.getStringAttribute("A_tag");
                int itemValue = object.getIntAttribute("value");
                int pid = g_playerInfoBuck.getPidByName(m_name);
                string itemCnName = "";
                canStoreItem.get(itemName,itemCnName);
                if(isNotify){
                    if(isEng(m_name)){
                        itemCnName = itemName;
                        notify(m_metagame, "Currently selected item ="+itemCnName+" Quantity ="+itemValue, dictionary(), "misc", pid, false, "", 1.0);
                    }else{
                        notify(m_metagame, "当前选中的物品="+itemCnName+" 数量="+itemValue, dictionary(), "misc", pid, false, "", 1.0);
                    }
                }
            }
            @m_selectObject = object;
        }
        return m_selectObject;
    }
    bool exchangeItems(array<XmlElement@> deleteObjects,array<XmlElement@> getObjects,bool isNotify = true){
        if(isNotify){
            if(!isOpen(true)){return false;}
        }else{
            if(!isOpen(false)){return false;}
        }
        if(isPushIn()){
            int pid = g_playerInfoBuck.getPidByName(m_name);
            pushInObjects();
            _notify(m_metagame,pid,"您有物品未存入，已自动帮你存入");
            return false;
        }
        // 检测限定兑换物品
        XmlElement@ limits = XmlElement(readLimitationInfo());
        bool isSaveLimit = false;
        if(limits !is null){
            array<const XmlElement@> limitsItems = limits.getChilds();
            //_report(m_metagame,"limits存在,大小="+limitsItems.size());
            limits.removeAllChild();
            //解决空子项问题
            XmlElement a("item");
            a.setBoolAttribute("onRemove",true);
            limits.appendChild(a);
            if(limitsItems.size() != 0){
                for(uint j = 0 ; j < getObjects.size() ; ++j){
                    XmlElement@ object = getObjects[j];
                    string o_name = object.getStringAttribute("AA_tag");
                    //_report(m_metagame,"兑换对象名="+o_name);
                    for(uint i = 0 ; i < limitsItems.size() ; ++i){
                        XmlElement@ items = XmlElement(limitsItems[i]);
                        if(isMatch(items,object)){
                            //_report(m_metagame,"匹配通过");
                            int limitNum = items.getIntAttribute("value");
                            int pid = g_playerInfoBuck.getPidByName(m_name);
                            if(limitNum != 0){
                                // items.setIntAttribute("value",--limitNum); //1.8.2临时取消
                                if(isEng(m_name)){
                                    _notify(m_metagame,pid,"The number of redeemable times for this limited item ="+limitNum);
                                }else{
                                    _notify(m_metagame,pid,"该限量物品剩余兑换次数="+limitNum);
                                }
                                limits.appendChild(items);
                                isSaveLimit = true;
                            }else{
                                _notify(m_metagame,pid,"该限量物品已兑换完");
                                return false;
                            }
                        }
                    }
                }
            }
        }
        int cid = -1;
        int pid = -1;
        array<const XmlElement@> players = getPlayers(m_metagame);
		for(uint j = 0; j < players.size() ; ++j){
			const XmlElement@ player = players[j];
			if(player is null){continue;}
			if(m_name == player.getStringAttribute("name")){
				cid = player.getIntAttribute("character_id");
                pid = player.getIntAttribute("player_id");
			}
		}
        if(pid == -1 || cid == -1){
            _log("stash exhangeItems bugs,cid="+cid+" pid="+pid+" player="+m_name);
            return false;
        }
        if(deleteObjects.size() >= 0){
            _debugReport(m_metagame,"兑换物品：检测到删除对象");
            refreshStash();
            string itemKey;
            string itemCnName;
            bool isExchangeValid = false;
            bool isEmpty = true;
            array<uint> targetIndex;//暂存最后需要修改的对象的数组地址
            array<int> leftNumList;
            for(uint i = 0 ; i < m_stashObject.size() ; ++i){ //遍历仓库
                isEmpty = false;
                XmlElement@ m_object = m_stashObject[i];
            string testname = m_object.getStringAttribute("AA_tag");
            _debugReport(m_metagame,"仓库选取对象名="+testname);
                
                for(uint j = 0 ; j < deleteObjects.size() ; ++j){ //遍历删除对象
                    XmlElement@ d_object = deleteObjects[j];
                    if(d_object is null){
            _debugReport(m_metagame,"要删除的对象是Null");
                        return false;
                    }
                    itemKey = d_object.getStringAttribute("AA_tag");
                    itemCnName = itemKey;
            _debugReport(m_metagame,"对象名="+itemKey);
                    canStoreItem.get(itemKey,itemCnName); //中文翻译转换
                    if(isMatch(m_object,d_object)){ //匹配目标
            _debugReport(m_metagame,"匹配"+itemKey+"准备从仓库删除");
                        int deleteNum = d_object.getIntAttribute("value");
                        int mNum = m_object.getIntAttribute("value");
                        if(deleteNum > mNum){
                            if(isEng(m_name)){
                                itemCnName = itemKey;
                                _notify(m_metagame,pid,"There are not enough items "+itemCnName+", you need "+deleteNum+", you have "+mNum);
                            }else{
                                _notify(m_metagame,pid,"物品"+itemCnName+"数量不足，需要"+deleteNum+"个，你有"+mNum+"个");
                            }
                            continue;
                        }else{
                            int leftNum = mNum - deleteNum;
            _debugReport(m_metagame,"删除物品"+itemKey+"剩余数量="+leftNum);
                            deleteObjects.removeAt(j);
                            targetIndex.insertLast(i);
                            leftNumList.insertLast(leftNum);
                            break;
                        }
                    }
                }
            }
            if(deleteObjects.size() == 0){
                isExchangeValid = true;
            }
            if(isExchangeValid ){  //物品都满足需求
            _debugReport(m_metagame,"全部通过，执行兑换");
                uint removeTimes = 0;
                for(uint i = 0 ; i < targetIndex.size() ; ++i){ //遍历要修改的序号列表
                    uint index = targetIndex[i] - removeTimes;
                    XmlElement@ m_object = m_stashObject[index];
                    if(leftNumList[i] == 0){
                        m_stashObject.removeAt(index);
                        removeTimes++;
                        continue;
                    }
                    m_object.setIntAttribute("value",leftNumList[i]);
                }
                array<Resource@> resources;
                Resource@ res;
                for(uint j = 0 ; j < getObjects.size() ; ++j){
                    itemKey = getObjects[j].getStringAttribute("AA_tag");
                    string itemType = getObjects[j].getStringAttribute("A_tag");
                    int pullOutNum = getObjects[j].getIntAttribute("value");
                    @res = Resource(itemKey,itemType);
                    res.addToResources(resources,pullOutNum);
                }
                addListItemInBackpack(m_metagame,cid,resources);
                if(isNotify){
                    _notify(m_metagame,pid,"物品已兑换，请查收");
                }
                saveStashObject();
                if(isSaveLimit){
                    limits.removeChild("item",0);
                    saveLimitationInfo(limits);
                }
                return true;
            }else{
                if(isNotify){
                    _notify(m_metagame,pid,"该物品在仓库数量不足，无法兑换物品，请将兑换物存放至脚本仓库");
                }
            }
        }
        return false;
    }
    protected bool isMatch(XmlElement@ t_xml,XmlElement@ o_xml){
        if(t_xml is null || o_xml is null){
            return false;
        }
        string p_itemKey = t_xml.getStringAttribute("AA_tag");
        string p_itemType = t_xml.getStringAttribute("A_tag");
        string m_itemKey = o_xml.getStringAttribute("AA_tag");
        string m_itemType = o_xml.getStringAttribute("A_tag");
        _debugReport(m_metagame,"p_itemKey="+p_itemKey+" m_itemKey="+m_itemKey);
        _debugReport(m_metagame,"p_itemType="+p_itemType+" m_itemType="+m_itemType);
        if(p_itemKey == m_itemKey && p_itemType == m_itemType){
            return true;
        }
        return false;
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
    protected const XmlElement@ readLimitationInfo(){
        string LimitationInfoFile = "_exchange_limit.xml";
        const XmlElement@ root = readXML(m_metagame,LimitationInfoFile).getFirstChild();
        if(root is null){
            _log("readLimitationInfoFile is null,create");
            writeXML(m_metagame,LimitationInfoFile,XmlElement("items"));
            @root = readXML(m_metagame,LimitationInfoFile).getFirstChild();
        }
        return root;
    }
    protected void saveLimitationInfo(XmlElement@ allInfo){
       string LimitationInfoFile = "_exchange_limit.xml";
        writeXML(m_metagame,LimitationInfoFile,allInfo);
    }
    protected void savePlayerStashInfo(Metagame@ m_metagame, string sid, XmlElement@ allInfo){
        sid = sid+"_stash.xml";
        writeXML(m_metagame,sid,allInfo);
    }
}

class playerStashInfoBuck {
    protected array<playerStashInfo@> m_playerStashInfos;

    playerStashInfoBuck(){}

    void addInfo(Metagame@ m_metagame,const XmlElement@ newplayer){
        if(newplayer is null){return;}
        string name = newplayer.getStringAttribute("name");
        string sid = newplayer.getStringAttribute("sid");
        if(sid == ""){return;}
        for(uint i = 0 ; i < m_playerStashInfos.size() ; ++i){
            string m_name = m_playerStashInfos[i].getName();
            string m_sid = m_playerStashInfos[i].getSid();
            if(m_name == name || m_sid == sid){
                m_playerStashInfos.removeAt(i);
                i--;
            }
        }
        playerStashInfo@ info = playerStashInfo(m_metagame,newplayer);
        m_playerStashInfos.insertLast(info);
    }
    void addInfo(Metagame@ m_metagame,string name,string sid){
        for(uint i = 0 ; i < m_playerStashInfos.size() ; ++i){
            string m_name = m_playerStashInfos[i].getName();
            string m_sid = m_playerStashInfos[i].getSid();
            if(m_name == name || m_sid == sid){
                m_playerStashInfos.removeAt(i);
                i--;
            }
        }
        playerStashInfo@ info = playerStashInfo(m_metagame,sid,name);
        m_playerStashInfos.insertLast(info);
    }
    void changePage(string sid,int direction){
        for(uint i = 0 ; i < m_playerStashInfos.size() ; ++i){
            string m_sid = m_playerStashInfos[i].getSid();
            if(sid == m_sid){
                m_playerStashInfos[i].changePage(direction);
            }
        }
    }
    void selectObject(string sid,int index){
        for(uint i = 0 ; i < m_playerStashInfos.size() ; ++i){
            string m_sid = m_playerStashInfos[i].getSid();
            if(sid == m_sid){
                m_playerStashInfos[i].selectObject(index);
            }
        }
    }
    void openStash(string sid){
        for(uint i = 0 ; i < m_playerStashInfos.size() ; ++i){
            string m_sid = m_playerStashInfos[i].getSid();
            if(sid == m_sid){
                m_playerStashInfos[i].openStash();
            }
        }
    }
    bool isOpen(string sid,bool isNotify = false){
        for(uint i = 0 ; i < m_playerStashInfos.size() ; ++i){
            string m_sid = m_playerStashInfos[i].getSid();
            if(sid == m_sid){
                return m_playerStashInfos[i].isOpen(isNotify);
            }
        }
        return false;
    }
    void upgradeStash(string sid,int num,bool isFree = false){
        for(uint i = 0 ; i < m_playerStashInfos.size() ; ++i){
            string m_sid = m_playerStashInfos[i].getSid();
            if(sid == m_sid){
                m_playerStashInfos[i].upgradeStash(num,isFree);
            }
        }
    }
    void pullOutObjects(string sid,int num){
        for(uint i = 0 ; i < m_playerStashInfos.size() ; ++i){
            string m_sid = m_playerStashInfos[i].getSid();
            if(sid == m_sid){
                m_playerStashInfos[i].pullOutObjects(num);
            }
        }
    }
    void pushInObjects(string sid){
        for(uint i = 0 ; i < m_playerStashInfos.size() ; ++i){
            string m_sid = m_playerStashInfos[i].getSid();
            if(sid == m_sid){
                m_playerStashInfos[i].pushInObjects();
            }
        }
    }
    void addPushInObject(string sid,XmlElement@ object){
        for(uint i = 0 ; i < m_playerStashInfos.size() ; ++i){
            string m_sid = m_playerStashInfos[i].getSid();
            if(sid == m_sid){
                m_playerStashInfos[i].addPushInObject(object);
            }
        }
    }
    bool exchangeItems(string sid,array<XmlElement@> deleteObjects,array<XmlElement@> getObjects){
        for(uint i = 0 ; i < m_playerStashInfos.size() ; ++i){
            string m_sid = m_playerStashInfos[i].getSid();
            if(sid == m_sid){
                return m_playerStashInfos[i].exchangeItems(deleteObjects,getObjects);
            }
        }
        return false;
    }
    void clearAll(){
        m_playerStashInfos.resize(0);
    }
}

class extra_stash : Tracker {
    protected Metagame@ m_metagame;
    protected bool save_data;
    protected float m_time;
    protected float m_timer;
    protected playerStashInfoBuck m_playerStashInfoBuck;
    protected player_cd_bucket m_playerCds;

    extra_stash(Metagame@ metagame){
        @m_metagame = @metagame;
        m_time = 2.0;
        m_timer = m_time;
        save_data = false;
        m_playerStashInfoBuck.clearAll();
        if(g_single_player){    
            // 针对单机二次载入存档时候的脚本加载问题处理
            // 二次加载没有连接和复活事件，但是玩家信息可以提前查到
            // 单机里主机玩家强制绑定ID0，主机玩家在二次载入存档时会正确识取到SID，这是不希望出现的
            array<const XmlElement@> players = getPlayers(m_metagame);
            for(uint i=0;i<players.size();++i){
                const XmlElement@ player = players[i];
                if(player is null){continue;}
                string name = player.getStringAttribute("name");
                _log("extra_stash get playername="+name);
                m_playerStashInfoBuck.addInfo(m_metagame,name,"ID0");
            }
        }
        _log("extra_stash initiate");
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
	void update(float time) {
		m_timer -= time;
		if(m_timer <= 0){
			m_timer = m_time;
			//每秒更新一次
			if(m_playerCds !is null){
				m_playerCds.update(m_time,m_metagame);
                updateSuperCash();
                updateAceClip();
                // updateSample(); 存在取出来刷的bug，暂时不启用
			}
		}
	}
    // -------------------------------------------
    void start(){
    }
    // -------------------------------------------
	protected void updateSuperCash() {
        for(uint i = 0; i < g_userCountInfoBuck.size(); ++i){
            int SuperCash = 0;
            string name = g_userCountInfoBuck.indexName(i);
            // _report(m_metagame,"updateSuperCash ="+name);
            if(g_userCountInfoBuck.getCount(name,"SuperCash",SuperCash)){
                if(SuperCash > 0){
                    XmlElement newXml("stash");
                        newXml.setStringAttribute("AA_tag","SuperCash");
                        newXml.setStringAttribute("A_tag","special");
                        newXml.setIntAttribute("value",SuperCash);
                    string sid = g_playerInfoBuck.getSidByName(name);
                    if(!m_playerStashInfoBuck.isOpen(sid)){
                        m_playerStashInfoBuck.openStash(sid);
                    }
                    m_playerStashInfoBuck.addPushInObject(sid,newXml);
                    m_playerStashInfoBuck.pushInObjects(sid);
                    m_playerStashInfoBuck.openStash(sid);
                    g_userCountInfoBuck.clearCount(name,"SuperCash");
                }else{
                    continue;
                }
            }
        }
    }
    // -------------------------------------------
	protected void updateAceClip() {
        for(uint i = 0; i < g_userCountInfoBuck.size(); ++i){
            int SuperItem = 0;
            string name = g_userCountInfoBuck.indexName(i);
            // _report(m_metagame,"updateSuperCash ="+name);
            if(g_userCountInfoBuck.getCount(name,"acg_sky_striker_ace_clips",SuperItem)){
                if(SuperItem > 0){
                    XmlElement newXml("stash");
                        newXml.setStringAttribute("AA_tag","acg_sky_striker_ace_clips");
                        newXml.setStringAttribute("A_tag","special");
                        newXml.setIntAttribute("value",SuperItem);
                    string sid = g_playerInfoBuck.getSidByName(name);
                    if(!m_playerStashInfoBuck.isOpen(sid)){
                        m_playerStashInfoBuck.openStash(sid);
                    }
                    m_playerStashInfoBuck.addPushInObject(sid,newXml);
                    m_playerStashInfoBuck.pushInObjects(sid);
                    m_playerStashInfoBuck.openStash(sid);
                    g_userCountInfoBuck.clearCount(name,"acg_sky_striker_ace_clips");
                }else{
                    continue;
                }
            }
        }
    }
    // -------------------------------------------
	protected void updateSample() {
        for(uint i = 0; i < g_userCountInfoBuck.size(); ++i){
            int SuperItem = 0;
            string name = g_userCountInfoBuck.indexName(i);
            // _report(m_metagame,"updateSuperCash ="+name);
            if(g_userCountInfoBuck.getCount(name,"samples_acg.carry_item",SuperItem)){
                if(SuperItem > 0){
                    XmlElement newXml("stash");
                        newXml.setStringAttribute("AA_tag","samples_acg.carry_item");
                        newXml.setStringAttribute("A_tag","carry_item");
                        newXml.setIntAttribute("value",SuperItem);
                    string sid = g_playerInfoBuck.getSidByName(name);
                    if(!m_playerStashInfoBuck.isOpen(sid)){
                        m_playerStashInfoBuck.openStash(sid);
                    }
                    m_playerStashInfoBuck.addPushInObject(sid,newXml);
                    m_playerStashInfoBuck.pushInObjects(sid);
                    m_playerStashInfoBuck.openStash(sid);
                    g_userCountInfoBuck.clearCount(name,"samples_acg.carry_item");
                }else{
                    continue;
                }
            }
        }
    }
    // -------------------------------------------
	protected void handlePlayerConnectEvent(const XmlElement@ event) {
		const XmlElement@ player = event.getFirstElementByTagName("player");
        if(player is null){return;}
        m_playerStashInfoBuck.addInfo(m_metagame,player);
	}
    // ----------------------------------------------------
	protected void handlePlayerSpawnEvent(const XmlElement@ event) {
        const XmlElement@ player = event.getFirstElementByTagName("player");
		string name = player.getStringAttribute("name");
        m_playerStashInfoBuck.addInfo(m_metagame,player);
    }
    // -------------------------------------------
    protected void handleChatEvent(const XmlElement@ event){
		string message = event.getStringAttribute("message");
		string p_name = event.getStringAttribute("player_name");
		debug(message,p_name);
	}
    // -------------------------------------------
    protected void debug(string&in message,string&in p_name){
        if(m_metagame.getAdminManager().isAdmin(p_name)){
			if(message == "exchange"){
                array<XmlElement@> deleteObjects;
                array<XmlElement@> getObjects;
                deleteObjects.insertLast(getStashXmlElement("collect_fumo_cirno.carry_item","carry_item",1));
                deleteObjects.insertLast(getStashXmlElement("collect_fumo_flandre_scarlet.carry_item","carry_item",2));
                deleteObjects.insertLast(getStashXmlElement("collect_fumo_hong_meiling.carry_item","carry_item",3));
                getObjects.insertLast(getStashXmlElement("collect_fumo_koishi_komeiji.carry_item","carry_item",3));
                getObjects.insertLast(getStashXmlElement("collect_fumo_mike_goutokuji.carry_item","carry_item",2));
                getObjects.insertLast(getStashXmlElement("collect_fumo_mokou_fujiwara.carry_item","carry_item",1));
                int playerId = g_playerInfoBuck.getPidByName(p_name);
                string sid = g_playerInfoBuck.getSidByName(p_name);
                m_playerStashInfoBuck.exchangeItems(sid,deleteObjects,getObjects);
            }
		}
    }
    // -------------------------------------------
    protected bool handleExchangeEvent(const XmlElement@ event) {
        string itemKey = event.getStringAttribute("item_key");
        string position = event.getStringAttribute("position");
		int characterId = event.getIntAttribute("character_id");
		if(characterId == -1){return false;}
		int playerId = event.getIntAttribute("player_id");
		string item_class = event.getStringAttribute("item_class");
        string name = g_playerInfoBuck.getNameByPid(playerId);
        string sid = g_playerInfoBuck.getSidByName(name);
        int cid = g_playerInfoBuck.getCidByName(name);

        if(itemKey.find("_exchange") != -1){
            deleteItemInBackpack(m_metagame,cid,"carry_item",itemKey);
            if(itemKey.find("_weapon") != -1){
                deleteItemInBackpack(m_metagame,cid,"weapon",itemKey);
            }
            if(!g_server_activity_racing){
                _report(m_metagame,"兑换操作请在赛车服进行操作");
                return true;
            }
            if(!m_playerCds.exists(name,"exchangeItems")){
                m_playerCds.addNew(name,playerId,"exchangeItems",3.0);
                
                stashExchangeList@ executeList = cast<stashExchangeList@>(stashExchangeDict[itemKey]);
                bool isValid = false;
                if(executeList !is null){
                    isValid = executeList.handleExchange(@m_playerStashInfoBuck,sid); //执行删除和兑换新物品
                }
                // 没有新物品而是功能道具的，这里单独处理
                if(!isValid){return false;}
                if(itemKey == "collect_fumo_koishi_komeiji_exchange"){
                    //6 古明地恋Fumo[1] 换 脚本仓库容量[100]
                    if(!m_playerStashInfoBuck.isOpen(sid)){
                        m_playerStashInfoBuck.openStash(sid);
                    }
                    m_playerStashInfoBuck.upgradeStash(sid,5000,true);
                    m_playerStashInfoBuck.openStash(sid);
                    return true;
                }
                if(itemKey == "hd_supercash_rp_up_exchange"){
                    //70 超级货币[1000] 换 [永久全局RP倍率+12%]
                    upgrade@ m_upgrade = upgrade(m_metagame);
                    string m_times = m_upgrade.getAccessValue(name,"prioritys","extra_rp_factor","times");
                    int times = 0;
                    if(isNumeric(m_times)){ 
                        times = parseInt(m_times);
                    }
                    if(times >= 20){
                        _notify(m_metagame,playerId,"兑换次数达最大限制，超级货币已返还");
                        g_userCountInfoBuck.addCount(name,"SuperCash",1000);
                        return false;
                    }
                    XmlElement newXml("priority");
                        newXml.setStringAttribute("key","extra_rp_factor");
                        newXml.setFloatAttribute("value",0.12);
                        newXml.setIntAttribute("times",++times);

                    m_upgrade.writeUpgradeFile(name,"prioritys",newXml);
                    return true;
                }
                if(itemKey == "hd_supercash_xp_up_exchange"){
                    //70 超级货币[1000] 换 [永久科研XP倍率+25%]
                    upgrade@ m_upgrade = upgrade(m_metagame);
                    string m_times = m_upgrade.getAccessValue(name,"prioritys","extra_xp_factor","times");
                    int times = 0;
                    if(isNumeric(m_times)){ 
                        times = parseInt(m_times);
                    }
                    if(times >= 10){
                        _notify(m_metagame,playerId,"兑换次数达最大限制，超级货币已返还");
                        g_userCountInfoBuck.addCount(name,"SuperCash",1000);
                        return false;
                    }
                    XmlElement newXml("priority");
                        newXml.setStringAttribute("key","extra_xp_factor");
                        newXml.setFloatAttribute("value",0.25);
                        newXml.setIntAttribute("times",++times);

                    m_upgrade.writeUpgradeFile(name,"prioritys",newXml);
                    return true;
                }
                if(itemKey == "hd_supercash_rp_result_up_exchange"){
                    //70 超级货币[1000] 换 [永久额外结算RP收益+5%]
                    upgrade@ m_upgrade = upgrade(m_metagame);
                    string m_times = m_upgrade.getAccessValue(name,"prioritys","extra_rp_result","times");
                    int times = 0;
                    if(isNumeric(m_times)){ 
                        times = parseInt(m_times);
                    }
                    if(times >= 15){
                        _notify(m_metagame,playerId,"兑换次数达最大限制，超级货币已返还");
                        g_userCountInfoBuck.addCount(name,"SuperCash",1000);
                        return false;
                    }
                    XmlElement newXml("priority");
                        newXml.setStringAttribute("key","extra_rp_result");
                        newXml.setFloatAttribute("value",0.05);
                        newXml.setIntAttribute("times",++times);

                    m_upgrade.writeUpgradeFile(name,"prioritys",newXml);
                    return true;
                }
                return true;
            }else if(!m_playerCds.hasReady(name,"exchangeItems")){
                float leftCD = m_playerCds.leftCD(name,"exchangeItems");
                if(isEng(name)){
                    _notify(m_metagame,playerId,"Redemption cooldown ="+ int(leftCD));
                }else{
                    _notify(m_metagame,playerId,"兑换冷却时间="+ int(leftCD));
                }
                return false;
            }
        }
        return false;
    }
    // -------------------------------------------
    protected void handleItemDropEvent(const XmlElement@ event) {
        string itemKey = event.getStringAttribute("item_key");

        string position = event.getStringAttribute("position");
		int characterId = event.getIntAttribute("character_id");
		if(characterId == -1){return;}
		int playerId = event.getIntAttribute("player_id");
        if(playerId == -1){return;} // ban AI use
		int containerId = event.getIntAttribute("target_container_type_id");
		string item_class = event.getStringAttribute("item_class");
        
        // handleExchangeEvent(event);
        // if(startsWith(itemKey,"stash_ui_")){
        //     _notify(m_metagame,playerId,"脚本仓库未完善，暂时无法使用");
        //     return;
        // }
        //containerId = 0(地面) 1(军械库) 2（背包） 3（仓库）
		//itemClass = 0(主、副武器) 1（投掷物） 3（护甲、战利品）
        string name = g_playerInfoBuck.getNameByPid(playerId);
        string sid = g_playerInfoBuck.getSidByName(name);
        string translateName = "";
        
        if(containerId == 2){//背包
            int cid = g_playerInfoBuck.getCidByName(name);
            if(startsWith(itemKey,"stash_ui_") && !g_server_activity_racing){
                _report(m_metagame,"仓库操作请在赛车服进行操作");
                deleteItemInBackpack(m_metagame,cid,"weapon",itemKey);
                return;
            }
            if(handleExchangeEvent(event)){
                return;
            }
            if(itemKey == "stash_ui_open_close.weapon"){
                const XmlElement@ player = getPlayerInfo(m_metagame,playerId);
                if(player is null){return;}
                //m_playerStashInfoBuck.addInfo(m_metagame,player);
                m_playerStashInfoBuck.openStash(sid);
                deleteItemInBackpack(m_metagame,cid,"weapon",itemKey);
                if(m_playerStashInfoBuck.isOpen(sid)){
                    notify(m_metagame, "How To Use Stash", dictionary(), "misc", playerId, true, "Stash Help", 1.0);
                }
            }
            if(itemKey == "stash_ui_page_down.weapon"){
                m_playerStashInfoBuck.changePage(sid,1);
                deleteItemInBackpack(m_metagame,cid,"weapon",itemKey);
            }
            if(itemKey == "stash_ui_page_up.weapon"){
                m_playerStashInfoBuck.changePage(sid,-1);
                deleteItemInBackpack(m_metagame,cid,"weapon",itemKey);
            }
            if(itemKey == "stash_ui_pull_out.weapon"){
                m_playerStashInfoBuck.pullOutObjects(sid,255);
                deleteItemInBackpack(m_metagame,cid,"weapon",itemKey);
            }
            if(itemKey == "stash_ui_pull_out_1x.weapon"){
                m_playerStashInfoBuck.pullOutObjects(sid,1);
                deleteItemInBackpack(m_metagame,cid,"weapon",itemKey);
            }
            if(itemKey == "stash_ui_pull_out_10x.weapon"){
                m_playerStashInfoBuck.pullOutObjects(sid,10);
                deleteItemInBackpack(m_metagame,cid,"weapon",itemKey);
            }
            if(itemKey == "stash_ui_pull_out_100x.weapon"){
                m_playerStashInfoBuck.pullOutObjects(sid,100);
                deleteItemInBackpack(m_metagame,cid,"weapon",itemKey);
            }
            if(itemKey == "stash_ui_push_in.weapon"){
                m_playerStashInfoBuck.pushInObjects(sid);
                deleteItemInBackpack(m_metagame,cid,"weapon",itemKey);
            }
            if(itemKey == "stash_ui_select_down.weapon"){
                m_playerStashInfoBuck.selectObject(sid,1);
                deleteItemInBackpack(m_metagame,cid,"weapon",itemKey);
            }
            if(itemKey == "stash_ui_select_up.weapon"){
                m_playerStashInfoBuck.selectObject(sid,-1);
                deleteItemInBackpack(m_metagame,cid,"weapon",itemKey);
            }
            if(itemKey == "stash_ui_upgrade_1x.weapon"){
                if(!m_playerStashInfoBuck.isOpen(sid)){
                    m_playerStashInfoBuck.openStash(sid);
                }
                const XmlElement@ character = getCharacterInfo(m_metagame,characterId);
                if(character is null){return;}
                int rp = character.getIntAttribute("rp");
                if(rp < 10000000){
                    if(isEng(name)){
                        _notify(m_metagame,playerId,"You need 1000w RP to upgrade the Extra Stash");
                    }else{
                        _notify(m_metagame,playerId,"升级永久脚本仓库需要1000wRP");
                    }
                }else{
                    GiveRP(m_metagame,characterId,-10000000);
                    m_playerStashInfoBuck.upgradeStash(sid,9999,true);
                }
                deleteItemInBackpack(m_metagame,cid,"weapon",itemKey);
                m_playerStashInfoBuck.openStash(sid);
            }
        }
        if(containerId == 1){ // 商店
            if(itemKey == "hd_super_cash_100"){
                g_userCountInfoBuck.addCount(name,"SuperCash",100);
            }
            if(itemKey == "hd_super_cash_1000"){
                g_userCountInfoBuck.addCount(name,"SuperCash",1000);
            }
            if(itemKey == "acg_sky_striker_ace_clips"){
                g_userCountInfoBuck.addCount(name,"acg_sky_striker_ace_clips",1);
            }
            if(m_playerStashInfoBuck.isOpen(sid)){
                if(!canStoreItem.get(itemKey,translateName)){
                    g_userCountInfoBuck.addCount(name,"pushInStashError");
                    int errorTimes = 0; 
                    g_userCountInfoBuck.getCount(name,"pushInStashError",errorTimes);
                    if(errorTimes >= 3){
                        g_userCountInfoBuck.clearCount(name,"pushInStashError");
                        _notify(m_metagame,playerId,"失败次数过多，已自动关闭脚本仓库");
                        m_playerStashInfoBuck.openStash(sid);
                    }
                    if(isEng(name)){
                        _notify(m_metagame,playerId,"The item "+itemKey+" cannot be stored in the Extra Stash");
                    }else{
                        _notify(m_metagame,playerId,"该物品"+itemKey+"不能存入脚本仓库");
                    }
                    return;
                }
                if(item_class == "0"){
                    item_class = "weapon";
                }
                if(item_class == "1"){
                    item_class = "projectile";
                }
                if(item_class == "3"){
                    item_class = "carry_item";
                }
                string temp = "";
                if(specialTypeStoreItem.get(itemKey,temp)){
                    if(temp != ""){
                        return;
                    }
                }
                XmlElement newXml("stash");
                    newXml.setStringAttribute("AA_tag",itemKey);
                    newXml.setStringAttribute("A_tag",item_class);
                    newXml.setIntAttribute("value",1);
                m_playerStashInfoBuck.addPushInObject(sid,newXml);
            }else{  //未打开情况下，自动存入一些特殊道具
                if(autoStoreItem.get(itemKey,translateName)){
                    if(!m_playerStashInfoBuck.isOpen(sid)){
                        m_playerStashInfoBuck.openStash(sid);
                    }
                    if(item_class == "0"){
                        item_class = "weapon";
                    }
                    if(item_class == "1"){
                        item_class = "projectile";
                    }
                    if(item_class == "3"){
                        item_class = "carry_item";
                    }
                    XmlElement newXml("stash");
                        newXml.setStringAttribute("AA_tag",itemKey);
                        newXml.setStringAttribute("A_tag",item_class);
                        newXml.setIntAttribute("value",1);
                    m_playerStashInfoBuck.addPushInObject(sid,newXml);
                    m_playerStashInfoBuck.pushInObjects(sid);
                    m_playerStashInfoBuck.openStash(sid);
                }
            }
        }
    }
}
