
void _report(Metagame@ m_metagame,string input,string input_title = "Debug",bool isShow = false){
    array<const XmlElement@> players = getPlayers(m_metagame);
    for (uint j = 0; j < players.size(); ++j) {
        const XmlElement@ player = players[j];
        if(player is null){return;}
        int pid = player.getIntAttribute("player_id");
        notify(m_metagame, input, dictionary(), "misc", pid, isShow, input_title, 1.0);
    }
}
void _notify(Metagame@ m_metagame,int pid,string input,bool isShow = false){
    notify(m_metagame, input, dictionary(), "misc", pid, isShow, input, 1.0);
}
void _debugReport(Metagame@ m_metagame,string input,string input_title = "Debug",bool isShow = false){
    if(g_debugMode){
        array<const XmlElement@> players = getPlayers(m_metagame);
        for (uint j = 0; j < players.size(); ++j) {
            const XmlElement@ player = players[j];
            if(player is null){return;}
            int pid = player.getIntAttribute("player_id");
            notify(m_metagame, input, dictionary(), "misc", pid, isShow, input_title, 1.0);
        }
    } 
}
void _report(Metagame@ m_metagame,string input,dictionary a,string input_title = "Debug",bool isShow = false){
    array<const XmlElement@> players = getPlayers(m_metagame);
    for (uint j = 0; j < players.size(); ++j) {
        const XmlElement@ player = players[j];
        if(player is null){return;}
        int pid = player.getIntAttribute("player_id");
        notify(m_metagame, input, a, "misc", pid, isShow, input_title, 1.0);
    }
}

class Timer {
    protected float m_time;
    protected float m_timer;
    protected float d_time;
    protected float cycle_time;

    Timer(float time=60){
        cycle_time = time;
        m_time = cycle_time;
    }
    void update(float time){
        m_timer -= time;
        if(m_timer <=0){
            m_timer = cycle_time;
        }
    }
    float endT(){
        d_time = m_time - m_timer;
        m_time = m_timer;
        return d_time;
    }
}


