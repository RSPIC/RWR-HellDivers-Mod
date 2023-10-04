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

//author:RST
//HD专用的脚本仓库脚本

// const XmlElement@ readXML(const Metagame@ metagame, string filename, string location = "savegame" ){
// 	XmlElement@ query = XmlElement(
// 		makeQuery(metagame, array<dictionary> = {
// 			dictionary = { {"TagName", "data"}, {"class", "saved_data"}, {"filename", filename}, {"location", location} } }));
// 	const XmlElement@ xml = metagame.getComms().query(query);
//     if(xml is null){
//         _log("readXml is null,create and reRead for filename="+filename+",in location="+location);
//         writeXML(metagame,filename,XmlElement(filename),location);
//         @xml = readXML(metagame,filename,location);
//     }
// 	return xml;
// }

// void writeXML(const Metagame@ metagame, string filename, XmlElement@ xml, string location = "savegame" ){
// 	XmlElement command("command");
// 		command.setStringAttribute("class", "save_data");
// 		command.setStringAttribute("filename", filename);
// 		command.setStringAttribute("location", location);
// 		command.appendChild(xml);
// 	metagame.getComms().send(command);
// }

class extra_stash : Tracker {
    protected Metagame@ m_metagame;
    protected bool save_data;
    protected float m_time;
    protected float m_timer;
    protected string m_playerInfo_FILENAME;
    protected string m_reward_keys_FILENAME;


    extra_stash(Metagame@ metagame){
        @m_metagame = @metagame;
        m_time = 1.0;
        m_timer = m_time;
        save_data = false;
        m_playerInfo_FILENAME = "_playerinfo.xml";
        m_reward_keys_FILENAME = "reward_keys.xml";
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
    }
    // -------------------------------------------
    void start(){
    }
    // -------------------------------------------
    protected void handlePlayerDisconnectEvent(const XmlElement@ event) {
        const XmlElement@ player = event.getFirstElementByTagName("player");
        if(player is null){return;}
    }
    // -------------------------------------------
	protected void handlePlayerConnectEvent(const XmlElement@ event) {
		const XmlElement@ player = event.getFirstElementByTagName("player");
        if(player is null){return;}
        updatePlayersStash(player);
	}
    // -------------------------------------------
    protected void debug(string&in message,string&in p_name){
        if(m_metagame.getAdminManager().isAdmin(p_name)){
			
		}
    }
    // -------------------------------------------
    protected void updatePlayersStash(const XmlElement@ newplayer = null){
        array<const XmlElement@> players;
        if(newplayer is null){
            return;
        }else{
            players.insertLast(newplayer);
        }
        //获取在线玩家信息
        for(uint i=0;i<players.size();++i){
            XmlElement@ player = XmlElement(players[i]);
            if(player is null){continue;}
            bool is_online = isOnline;
            bool is_main_account = false;
            string player_name = player.getStringAttribute("name");
            string profile_hash = player.getStringAttribute("profile_hash");
            string sid = player.getStringAttribute("sid");
            string ip = "0.0.0.0";
            if(player.hasAttribute("ip")){
                ip = player.getStringAttribute("ip");
            }

            // 读取存档玩家信息
            XmlElement@ allInfo = XmlElement(readPlayerStashInfo(sid));
            if(allInfo is null){
                _log("allInfo is null, in updatePlayers");
                return;
            }
            // 读取存档玩家账号信息
            array<const XmlElement@> m_players = allInfo.getElementsByTagName("player");

            allInfo.removeAllChild();
            //解决空子项问题
            XmlElement a("player");
            a.setBoolAttribute("onRemove",true);
            allInfo.appendChild(a);

            bool isExist = false;
            for(int j = 0 ; j < int(m_players.size()) ; ++j){
                XmlElement@ m_player = XmlElement(m_players[j]);
                string m_name = m_player.getStringAttribute("player_name");
                string m_sid = m_player.getStringAttribute("sid");
                //排除onRemove对象
                if(m_player.hasAttribute("onRemove")){
                    bool isToRemove = m_player.getBoolAttribute("onRemove");
                    if(isToRemove){
                        continue;
                    }
                }
                //玩家仓库存档文件存在，跳过
                if(m_sid == sid){
                    // is_main_account = m_player.getBoolAttribute("is_main_account");
                    
                    // array<const XmlElement@> childs = m_player.getElementsByTagName("access_tag");
                    // m_player.removeAllChild();
                    // m_player.setBoolAttribute("is_online",is_online);
                    // m_player.appendChilds(childs);
                    // allInfo.appendChild(m_player);
                    isExist = true;
                }else{//其他玩家信息不修改存回去

                    allInfo.appendChild(m_player);
                }
            }
            //不存在，新建信息
            if(!isExist){
                XmlElement playerinfo("player");
                playerinfo.setBoolAttribute("is_online",is_online);
                playerinfo.setBoolAttribute("is_main_account",is_main_account);
                playerinfo.setStringAttribute("player_name",player_name);
                playerinfo.setStringAttribute("profile_hash",profile_hash);
                playerinfo.setStringAttribute("sid",sid);
                playerinfo.setStringAttribute("ip",ip);
                allInfo.appendChild(playerinfo);
            }
            allInfo.removeChild("player",0);
            savePlayerInfo(m_metagame,sid,allInfo);
        }
        // writeXML(m_metagame,m_playerInfo_FILENAME,allInfo);
        if(g_debugMode){
            _report(m_metagame,"savePlayers");
        }
    }
    // -------------------------------------------
    // target_tags 传入格式如下：
    // <root>
    //     <target_tag (可选)player_name="">
    //         <access_tag  value="1"/>
    //         <access_tag2 />
    //     </target_tag>
    // </root>
    protected bool checkTagsInPlayerInfo(string sid, const XmlElement@ root_target_tags){
        XmlElement@ allInfo = XmlElement(readPlayerStashInfo(sid));
        if(allInfo is null){
            _log("allInfo is null, in addToPlayersInfo");
            return false;
        }
        array<const XmlElement@> target_tags = root_target_tags.getChilds();
        if(g_debugMode) _report(m_metagame,"要查询的对象的数组大小为="+target_tags.size());
        array<const XmlElement@> m_players = allInfo.getElementsByTagName("player");
        
        bool isAllPlayerValid = true;
        dictionary pass_list;
        for(uint n = 0; n < target_tags.size(); ++n){
            const XmlElement@ target_tag = target_tags[n];
            string target_TagName = target_tag.getName();
            pass_list.set(target_TagName,false);
            if(g_debugMode) _report(m_metagame,"正在检查目标标签:"+target_TagName);

            string target_player_name = "";
            string target_sid = "";
            if(target_tag.hasAttribute("player_name")){
                target_player_name = target_tag.getStringAttribute("player_name");
            }
            if(target_tag.hasAttribute("sid")){
                target_sid = target_tag.getStringAttribute("sid");
            }

            if(g_debugMode) _report(m_metagame,"比对对象的字典输出："+target_tag.toString());

            for(uint i=0; i<m_players.size(); ++i){
                const XmlElement@ m_player = m_players[i];
                string m_player_name = m_player.getStringAttribute("player_name");
                string m_sid = m_player.getStringAttribute("sid");
                if(g_debugMode) _report(m_metagame,"正在检查玩家:"+m_player_name);

                if(target_player_name != "" && target_player_name != m_player_name){ 
                    if(g_debugMode) _report(m_metagame,"目标玩家名:"+target_player_name+"实际玩家名"+m_player_name+"。跳过");
                    continue;
                }
                if(target_sid != "" && target_sid != m_sid) continue;

                bool isThisPlayerFind = false;
                array<const XmlElement@> m_access_tags = m_player.getChilds();
                for(uint j=0; j<m_access_tags.size(); ++j){
                    const XmlElement@ m_access_tag = m_access_tags[j];
                    string m_TagName = m_access_tag.getStringAttribute("AA_tag");
                    if(g_debugMode) _report(m_metagame,"正在比对标签:"+m_TagName);

                    if(g_debugMode) _report(m_metagame,"玩家存档的字典输出："+m_access_tag.toString());

                    // 与玩家列表的access_tag字典进行匹配，若get不到或value错误，则跳出。否则全部通过
                    bool isFindTargetAccessTags = true;
                    if(m_TagName == target_TagName){
                        array<const XmlElement@> sub_tags = target_tag.getChilds();
                        for(uint k=0;k<sub_tags.size();++k){
                            const XmlElement@ sub_tag = sub_tags[k];
                            string sub_TagName = sub_tag.getName();
                            string sub_value = "";
                            if(sub_tag.hasAttribute("value")){
                                sub_value = sub_tag.getStringAttribute("value");
                            }
                            if(g_debugMode) _report(m_metagame,"检查的子标签"+sub_TagName+"值:"+sub_value);
                            if(m_access_tag.hasAttribute(sub_TagName)){
                                string m_access_value = m_access_tag.getStringAttribute(sub_TagName);
                                if(sub_value == "" || sub_value == m_access_value){
                                    isFindTargetAccessTags = true;
                                    if(g_debugMode) _report(m_metagame,"找到匹配的标签"+sub_TagName+"值:"+sub_value);
                                    continue;
                                }else{
                                    // 有任意一次匹配不上，则退出
                                    if(g_debugMode) _report(m_metagame,"未找到匹配的标签"+sub_TagName+"值:"+sub_value);
                                    isFindTargetAccessTags = false;
                                    continue;
                                }
                            }else{
                                if(g_debugMode) _report(m_metagame,"该标签不存在"+sub_TagName+"值:"+sub_value);
                                isFindTargetAccessTags = false;
                                continue;
                            }
                        }
                        //全部通过
                        if(isFindTargetAccessTags){
                            isThisPlayerFind = true;
                            if(g_debugMode) _report(m_metagame,"找到匹配的标签:"+m_TagName);
                            break;
                        }
                    }
                }
                if(isThisPlayerFind){
                    pass_list.set(target_TagName,true);
                    break;
                }
            }
            bool isValid;
            if(pass_list.get(target_TagName,isValid)){
                if(!isValid){
                    isAllPlayerValid = false;
                    if(g_debugMode) _report(m_metagame,"检查 "+target_TagName+" 失败，将isAllPlayerValid设置为false");
                    continue;
                }else{
                    isAllPlayerValid = true;
                    break;
                }

            }
        }

        if(g_debugMode && !isAllPlayerValid) _report(m_metagame,"比对不通过，目标玩家存档未能找到对应键值");
        if(g_debugMode && isAllPlayerValid) _report(m_metagame,"比对通过，目标玩家存档能找到对应键值");
        return isAllPlayerValid;
    }
    // -------------------------------------------
    protected void addToPlayersInfo(array<const XmlElement@> xmls, string sid){
        XmlElement@ allInfo = XmlElement(readPlayerStashInfo(sid));
        if(allInfo is null){
            _log("allInfo is null, in addToPlayersInfo");
            return;
        }
        array<const XmlElement@> m_players = allInfo.getElementsByTagName("player");
        //读原玩家文件信息
        for(int i=int(m_players.size())-1;i>=0;--i){
            XmlElement m_player(m_players[i]);
            if(m_player is null){continue;}
            string player_name = m_player.getStringAttribute("player_name");
            bool isTarget = false;
            //读新传入文件信息
            XmlElement@ xml;
            for(uint k=0;k<xmls.size();++k){
                @xml = XmlElement(xmls[k]);
                if(!xml.hasAttribute("player_name")){continue;}
                string name = xml.getStringAttribute("player_name");
                xml.removeKey("player_name");
            
                //排除onRemove对象
                bool isToRemove = false;
                if(xml.hasAttribute("onRemove")){
                    isToRemove = xml.getBoolAttribute("onRemove");
                    if(isToRemove){
                        continue;
                    }
                }
                
                //名字匹配
                if(name == player_name){
                    isTarget = true;
                    //修改键值和TagName以符合规范
                    string TagName;
                    if(xml.hasAttribute("access_tag")){
                        TagName = xml.getStringAttribute("access_tag");
                        xml.removeKey("access_tag");
                    }else{
                        TagName = xml.getName();
                    }
                    xml.setStringAttribute("TagName","access_tag");
                    xml.setStringAttribute("AA_tag",TagName);

                    //是否有同类项，有则覆写
                    bool isExist = false;
                    array<const XmlElement@> access_tags = m_player.getElementsByTagName("access_tag");
                    m_player.removeAllChild();

                    //解决空子项问题
                    XmlElement a("access_tag");
                    a.setBoolAttribute("onRemove",true);
                    m_player.appendChild(a);

                    if(access_tags.size() != 0){
                        for(int j = 0 ; j < int(access_tags.size()) ; ++j){
                            const XmlElement@ access_tag = access_tags[j];
                            string m_TagName = access_tag.getStringAttribute("AA_tag");

                            //排除onRemove对象
                            if(access_tag.hasAttribute("onRemove")){
                                isToRemove = access_tag.getBoolAttribute("onRemove");
                                if(isToRemove){
                                    continue;
                                }
                            }
                            
                            if(TagName == m_TagName){//覆写原对象
                                if(xml.hasAttribute("override")){
                                    string isoverride = xml.getStringAttribute("override");
                                    if(isoverride == "0"){
                                        m_player.appendChild(access_tag);
                                        continue;
                                    }
                                }
                                m_player.appendChild(xml);
                                isExist = true;
                            }else{//保留原对象
                                m_player.appendChild(access_tag);
                            }
                        }
                    }
                    // 没有同类项
                    if(!isExist){
                        m_player.appendChild(xml);
                    }
                    m_player.removeChild("access_tag",0);
                }
            }
            //覆写玩家数据
            if(isTarget){
                allInfo.appendChild(m_player);
                allInfo.removeChild("player",i);
            }
        }
        savePlayerInfo(m_metagame,sid,allInfo);
        if(g_debugMode){
            _report(m_metagame,"addToPlayersInfo");
        }
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
    protected void savePlayerInfo(Metagame@ m_metagame, string sid, XmlElement@ allInfo){
        sid = sid+"_stash.xml";
        writeXML(m_metagame,sid,allInfo);
    }

    array<string> MassageBreakUp(string message, string command, int preNumber)  {
        string s = message.trim().substr(command.length() + preNumber + 1);
        array<string> a = s.split(" ");
        return a;
    }

}
