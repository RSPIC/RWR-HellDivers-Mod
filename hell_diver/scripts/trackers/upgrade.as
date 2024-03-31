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

    protected void handleChatEvent(const XmlElement@ event){
		string message = event.getStringAttribute("message");
		string p_name = event.getStringAttribute("player_name");
		int pid = event.getIntAttribute("player_id");
        if(startsWith(message,"/up")){
           
        }
    }
    const XmlElement@ readUpgradeFile(string name,string TagName == ""){
        _log("read upgrade PlayerStashInfo for sid="+sid);
        string sid = g_playerInfoBuck.getSidByName(name);   
        const XmlElement@ allInfo = readPlayerStashInfo(sid);
        if(allInfo is null){
            _log("allInfo is null, in writeUpgradeFile");
            return;
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
        return null;

    }
    void writeUpgradeFile(string name,int pid,string TagName,XmlElement@ newXml){
        string sid = g_playerInfoBuck.getSidByName(name);
        XmlElement@ allInfo = XmlElement(readPlayerStashInfo(sid));
        if(allInfo is null){
            _log("allInfo is null, in writeUpgradeFile");
            return;
        }
        // 读取存档玩家账号信息
        array<const XmlElement@> m_stashs = allInfo.getChilds();

        allInfo.removeAllChild();
        //解决空子项问题
        XmlElement a("player");
        a.setBoolAttribute("onRemove",true);
        allInfo.appendChild(a);
        bool isToCreate = true;
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

                        for(uint k = 0 ; k < childs.size() ; ++k){
                            XmlElement@ tagchild = XmlElement(tagChilds[i]);
                            if(tagchild is null){continue;}
                            if(tagchild.getName() == newXml.getStringAttribute("key")){ //覆写文件
                                child.appendChild(newXml);
                            }else{
                                child.appendChild(tagchild;)
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
        if(isToCreate){
            XmlElement upgrade("upgrade");
                XmlElement stratagems("stratagems");
                XmlElement hdWeapons("weapons");
                XmlElement prioritys("prioritys");
                XmlElement bases("bases");
                XmlElement others("others");
            upgrade.appendChild(stratagems);
            upgrade.appendChild(hdWeapons);
            upgrade.appendChild(priority);
            upgrade.appendChild(base);
            upgrade.appendChild(other);

            allInfo.appendChild(upgrade);
            _notify(m_metagame,pid,"研发升级系统已注册");
        }
        allInfo.removeChild("player",0);
        savePlayerStashInfo(m_metagame,sid,allInfo);
        _log("save upgrade PlayerStashInfo for sid="+sid);
        _debugReport(m_metagame,"saveUpgradePlayersStash");
        return;
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