// declare include paths
#include "path://media/packages/vanilla/scripts"
#include "path://media/packages/hell_diver/scripts"
#include "path://media/packages/hell_diver_zombie/scripts"

#include "gamemode_invasion.as"

// --------------------------------------------
void main(dictionary@ inputData) {
        XmlElement inputSettings(inputData);

        UserSettings settings;
        settings.fromXmlElement(inputSettings);
        _setupLog("dev_verbose");

        settings.m_factionChoice = 0;                  // 0{diver} 1{zombie}
        settings.m_playerAiCompensationFactor = 1.0;   // was 1.1  (1.75)

        settings.m_fellowCapacityFactor = 0.0;
        settings.m_fellowAiAccuracyFactor = 1.0;
        settings.m_enemyCapacityFactor = 1.0;
        settings.m_enemyAiAccuracyFactor = 0.94;

        settings.m_playerAiReduction = 30.0;            // didn't work before 1.76! (was 1.0)

        settings.m_xpFactor = 1.0;
        settings.m_rpFactor = 1.0;

        settings.m_teamKillPenaltyEnabled = true;
        settings.m_completionVarianceEnabled = false;
        settings.m_journalEnabled = true;
        settings.m_fellowDisableEnemySpawnpointsSoldierCountOffset = 1;

        settings.m_server_difficulty_level = 0;
        settings.m_server_test_mode = false;

        //settings.m_single_player = true;
        settings.m_GameMode = "Zombie";
        settings.m_fov = true;

        array<string> overlays = {
                "media/packages/hell_diver_zombie"
        };
        settings.m_overlayPaths = overlays;

        settings.m_startServerCommand = """
        <command class='start_server'
                server_name='[地狱潜兵] 僵尸服-1/报复打击 '
                server_port='1245'
                url='https://steamcommunity.com/sharedfiles/filedetails/?id=2910392031'
                register_in_serverlist='1'
                mode='HD'
                persistency='forever'
                comment='地狱潜兵模组  QQ：498520233 '
                max_players='8'>
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



