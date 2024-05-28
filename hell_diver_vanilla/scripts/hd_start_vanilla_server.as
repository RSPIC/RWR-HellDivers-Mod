// declare include paths
#include "path://media/packages/vanilla/scripts"
#include "path://media/packages/hell_diver/scripts"
#include "path://media/packages/hell_diver_vanilla/scripts"

#include "gamemode_invasion.as"

// --------------------------------------------
void main(dictionary@ inputData) {
        XmlElement inputSettings(inputData);

        UserSettings settings;
        settings.fromXmlElement(inputSettings);
        _setupLog("dev_verbose");

        settings.m_factionChoice = 0;                  // 
        settings.m_playerAiCompensationFactor = 5.0;   // was 1.1  (1.75)
        settings.m_playerAiReduction = 4.0;   // was 1.1  (1.75)

        settings.m_fellowCapacityFactor = 1.0;
        settings.m_fellowAiAccuracyFactor = 0.93;
        settings.m_enemyCapacityFactor = 1.5;
        settings.m_enemyAiAccuracyFactor = 0.967;

        settings.m_playerAiReduction = 0.0;            // didn't work before 1.76! (was 1.0)

        settings.m_xpFactor = 1.5;
        settings.m_rpFactor = 1.0;

        settings.m_teamKillPenaltyEnabled = true;
        settings.m_completionVarianceEnabled = false;
        settings.m_journalEnabled = true;
        settings.m_fellowDisableEnemySpawnpointsSoldierCountOffset = 1;

        settings.m_server_difficulty_level = 0;
        settings.m_server_test_mode = false;
        settings.m_top_down = false;

        settings.m_single_player = false;
        settings.m_GameMode = "Vanilla";
        settings.m_fov = true;

        array<string> overlays = {
                "media/packages/hell_diver_vanilla"
        };
        settings.m_overlayPaths = overlays;

        settings.m_startServerCommand = """
        <command class='start_server'
                server_name='[地狱潜兵] 香草模式'
                server_port='30202'
                url='https://steamcommunity.com/sharedfiles/filedetails/?id=2910392031'
                register_in_serverlist='1'
                mode='HD'
                persistency='forever'
                comment='人类 VS 人类模式，接近原版玩法。该模式同步存档。地狱潜兵模组  QQ：498520233 '
                max_players='16'>
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



