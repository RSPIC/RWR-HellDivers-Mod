// declare include paths
#include "path://media/packages/vanilla/scripts"
#include "path://media/packages/hell_diver/scripts"

#include "gamemode_invasion.as"

// --------------------------------------------
void main(dictionary@ inputData) {
        XmlElement inputSettings(inputData);

        UserSettings settings;

        _setupLog("dev_verbose");

        settings.m_factionChoice = 0;                  // 0(acg) 1(helldivers), 2(cyborgs), 3(illuminate), 4(bugs), 
        settings.m_playerAiCompensationFactor = 10.0;   // was 1.1  (1.75)
        settings.m_playerAiReduction = 4.0;   // was 1.1  (1.75)

        settings.m_fellowCapacityFactor = 2.0;
        settings.m_fellowAiAccuracyFactor = 1.0;
        settings.m_enemyCapacityFactor = 4.0;
        settings.m_enemyAiAccuracyFactor = 1.0;

        settings.m_playerAiReduction = 0.0;            // didn't work before 1.76! (was 1.0)

        settings.m_xpFactor = 1.0;
        settings.m_rpFactor = 1.0;

        settings.m_teamKillPenaltyEnabled = true;
        settings.m_completionVarianceEnabled = false;
        settings.m_journalEnabled = true;
        settings.m_fellowDisableEnemySpawnpointsSoldierCountOffset = 1;

        settings.m_server_difficulty_level = 3;
        settings.m_fov = false;

        settings.m_server_activity = true; //define whether skip the map when end.
        settings.m_server_activity_racing = true;

        array<string> overlays = {
                "media/packages/hell_diver"
        };
        //settings.m_overlayPaths = overlays;

        settings.m_startServerCommand = """
<command class='start_server'
	server_name='[地狱潜兵] 难度 15EX[FOV] '
	server_port='1245'
	url='https://steamcommunity.com/sharedfiles/filedetails/?id=2910392031'
	register_in_serverlist='1'
	mode='HD FOV'
        persistency='forever'
	comment='地狱潜兵模组  QQ：498520233 1倍XP'
	max_players='12'>
	<client_faction id='0' />
</command>
""";
        settings.print();

        GameModeInvasion metagame(settings);

        metagame.init();
        metagame.run();
        metagame.uninit();

        _log("ending execution");
}



