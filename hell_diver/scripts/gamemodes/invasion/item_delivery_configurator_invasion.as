// generic trackers
#include "item_delivery_objective.as"
#include "item_delivery_organizer.as"
#include "gift_item_delivery_rewarder.as"

// ------------------------------------------------------------------------------------------------
class ItemDeliveryConfiguratorInvasion : ItemDeliveryConfigurator {
	protected GameModeInvasion@ m_metagame;
	protected ItemDeliveryOrganizer@ m_itemDeliveryOrganizer;

	// ------------------------------------------------------------------------------------------------
	ItemDeliveryConfiguratorInvasion(GameModeInvasion@ metagame) {
		@m_metagame = @metagame;
	}

	// --------------------------------------------
	void setup(ItemDeliveryOrganizer@ organizer) {
		@m_itemDeliveryOrganizer = @organizer;

		setupBriefcaseUnlocks();
		setupCollection();    
		setupSkin(); 
		setupMusic(); 
        setupVehicle();  
        setupWeapon1();	//mk1
        setupWeapon2(); //mk2
		setupWeaponLamda(); // mk3
		setupWeaponDelta(); // mk4
		setupWeaponV(); // mk5
        setupWeaponUnknown(); // mk6
        setupWeaponAlpha(); // special 玩具箱
        //setupWeaponX(); // 复活自带系列
        setupWeaponBeta(); //mk1~mk5 系列数量限制 5/4/3/2/1
        setupWeaponGama(); //mk1~mk5 系列数量限制 5/4/3/2/1
		setupWeaponTheta(); //mk1~mk5 系列数量限制 5/4/3/2/1
		setupWeaponMiu(); //mk1~mk5 系列数量限制 5/4/3/2/1
        setupWeaponPi(); //mk1~mk5 系列数量限制 5/4/3/2/1
        setupWeaponPhi(); //当季限定，轮换
        setupWeaponOmega(); // mk1~mk3
        setupHDicker(); // mk1~mk3

		setupIcecream();
		setupHDlottery();
		setupEnemyWeaponUnlocks();
		setupLaptopUnlocks();
		
	}

	// --------------------------------------------
	void refresh() {
		// called each time an item unlock is removed
		refreshEnemyWeaponDeliveryObjectives();
	}

	// ----------------------------------------------------
	protected void setupLaptopUnlocks() {
		_log("adding laptop unlocks", 1);
		array<Resource@> deliveryList;
		{
			 deliveryList.insertLast(Resource("laptop.carry_item", "carry_item"));
		}

		dictionary unlockList;
		{
			string target = "laptop.carry_item";
			array<Resource@>@ list = getUnlockWeaponList2();
			unlockList.set(target, @list);
		}

		// thanks happens at ResourceUnlocker now instead at ItemDeliveryObjective, in order to avoid it when nothing to unlock anymore
		string thanks = "item objective thanks";
		ResourceUnlocker@ unlocker = ResourceUnlocker(m_metagame, 0, unlockList, m_metagame, "", thanks);

		string instructions = "item objective instruction";
		string mapText = "item objective map text";

		m_itemDeliveryOrganizer.addObjective(
			ItemDeliveryObjective(m_metagame, 0, deliveryList, m_itemDeliveryOrganizer, unlocker, instructions, mapText, "", "", -1 /* loop */)
			);
	}
	
	// ----------------------------------------------------
	protected void setupBriefcaseUnlocks() {
		_log("adding briefcase unlocks", 1);
		array<Resource@> deliveryList;
		{
			 deliveryList.insertLast(Resource("suitcase.carry_item", "carry_item"));
		}

		dictionary unlockList;
		{
			string target = "suitcase.carry_item";
			array<Resource@>@ list = getUnlockWeaponList();
			unlockList.set(target, @list);
		}
		// thanks happens at ResourceUnlocker now instead at ItemDeliveryObjective, in order to avoid it when nothing to unlock anymore
		string thanks = "item objective thanks";
		ResourceUnlocker@ unlocker = ResourceUnlocker(m_metagame, 0, unlockList, m_metagame, "", thanks);

		string instructions = "item objective instruction";
		string mapText = "item objective map text";

		m_itemDeliveryOrganizer.addObjective(
			ItemDeliveryObjective(m_metagame, 0, deliveryList, m_itemDeliveryOrganizer, unlocker, instructions, mapText, "", "", -1 /* loop */)
			);
	}

	// --------------------------------------------
	protected void processRewardPasses(array<array<ScoredResource@>>@ passes) {
		// campaign can use this to cleanup unavailable experimental resources in passes 
	}

	// ----------------------------------------------------
	protected void setupCollection() {
		_log("adding reward_box_collection config", 1);
		//收藏品箱子
		array<Resource@> deliveryList = {
			 Resource("reward_box_collection.carry_item", "carry_item")
		};

		array<array<ScoredResource@>> rewardPasses = {
			{
			ScoredResource("collect_fumo_cirno.carry_item", "carry_item", 1.0f),
			ScoredResource("collect_fumo_flandre_scarlet.carry_item", "carry_item", 1.0f),
			ScoredResource("collect_fumo_hong_meiling.carry_item", "carry_item", 1.0f),
			ScoredResource("collect_fumo_inu_sakuya.carry_item", "carry_item", 1.0f),
			ScoredResource("collect_fumo_junko.carry_item", "carry_item", 1.0f),
			ScoredResource("collect_fumo_koishi_komeiji.carry_item", "carry_item", 1.0f),
			ScoredResource("collect_fumo_mike_goutokuji.carry_item", "carry_item", 1.0f),
			ScoredResource("collect_fumo_mokou_fujiwara.carry_item", "carry_item", 1.0f),
			ScoredResource("collect_fumo_nitori_kawashiro.carry_item", "carry_item", 1.0f),
			ScoredResource("collect_fumo_reimu.carry_item", "carry_item", 1.0f),
			ScoredResource("collect_fumo_rumia.carry_item", "carry_item", 1.0f),
			ScoredResource("collect_fumo_sanae_kochiya.carry_item", "carry_item", 1.0f),
			ScoredResource("collect_fumo_shion_yorigami.carry_item", "carry_item", 1.0f),
			ScoredResource("collect_fumo_suwako_moriya.carry_item", "carry_item", 1.0f),
			ScoredResource("collect_fumo_youmu_konpaku.carry_item", "carry_item", 1.0f),
			ScoredResource("collect_fumo_yuyuko.carry_item", "carry_item", 1.0f)
			},
			{
			ScoredResource("lottery_cash_II.carry_item", "carry_item", 1.0f)
			}
		};   
			
		processRewardPasses(rewardPasses);

		GiftItemDeliveryRandomRewarder@ rewarder = GiftItemDeliveryRandomRewarder(m_metagame, rewardPasses);

		m_itemDeliveryOrganizer.addObjective(
			ItemDeliveryObjective(m_metagame, 0, deliveryList, m_itemDeliveryOrganizer, null, "", "", "", -1 /* loop */, rewarder)
			);
	}

	// ----------------------------------------------------
	protected void setupSkin() {
		_log("adding reward_box_skin config", 1);
		//信物箱子
		array<Resource@> deliveryList = {
			 Resource("reward_box_skin.carry_item", "carry_item")
		};

		array<array<ScoredResource@>> rewardPasses = {
			{
			ScoredResource("token_asakaze.projectile","projectile",1.0f,4),
			ScoredResource("token_acg_88mm_flak41.projectile","projectile",1.0f,4),
			ScoredResource("token_alice_tendou.projectile","projectile",1.0f,4),
			ScoredResource("token_amatsukaze.projectile","projectile",1.0f,4),
			ScoredResource("token_api.projectile","projectile",1.0f,4),
			ScoredResource("token_bronya_ex_1.projectile","projectile",1.0f,4),
			ScoredResource("token_cz75.projectile","projectile",1.0f,4),
			ScoredResource("token_fenrir_black.projectile","projectile",1.0f,4),
			ScoredResource("token_fenrir_white.projectile","projectile",1.0f,4),
			ScoredResource("token_fiammetta.projectile","projectile",1.0f,4),
			ScoredResource("token_g41_2064.projectile","projectile",1.0f,4),
			ScoredResource("token_gawr_gura.projectile","projectile",1.0f,4),
			ScoredResource("token_graf_spee_sweater_ver.projectile","projectile",1.0f,4),
			ScoredResource("token_heavy_equip_jk_ii.projectile","projectile",1.0f,4),
			ScoredResource("token_hibiki.projectile","projectile",1.0f,4),
			ScoredResource("token_hk416_starry_cocoon.projectile","projectile",1.0f,4),
			ScoredResource("token_incomparable.projectile","projectile",1.0f,4),
			ScoredResource("token_iruru.projectile","projectile",1.0f,4),
			ScoredResource("token_iws2000_banisher.projectile","projectile",1.0f,4),
			ScoredResource("token_iws2000_sandcastle_terminator.projectile","projectile",1.0f,4),
			ScoredResource("token_kagamine_rin.projectile","projectile",1.0f,4),
			ScoredResource("token_kaname_madoka.projectile","projectile",1.0f,4),
			ScoredResource("token_kemomimi.projectile","projectile",1.0f,4),
			ScoredResource("token_longdan.projectile","projectile",1.0f,4),
			ScoredResource("token_lulu.projectile","projectile",1.0f,4),
			ScoredResource("token_m37_summer_parader.projectile","projectile",1.0f,4),
			ScoredResource("token_maido1.projectile","projectile",1.0f,4),
			ScoredResource("token_maido2.projectile","projectile",1.0f,4),
			ScoredResource("token_maido3.projectile","projectile",1.0f,4),
			ScoredResource("token_maido4.projectile","projectile",1.0f,4),
			ScoredResource("token_megumin.projectile","projectile",1.0f,4),
			ScoredResource("token_mg4.projectile","projectile",1.0f,4),
			ScoredResource("token_mg4_703.projectile","projectile",1.0f,4),
			ScoredResource("token_nanachi.projectile","projectile",1.0f,4),
			ScoredResource("token_natsuki_amagi.projectile","projectile",1.0f,4),
			ScoredResource("token_neco.projectile","projectile",1.0f,4),
			ScoredResource("token_perseus.projectile","projectile",1.0f,4),
			ScoredResource("token_raiden_mei_ex_1.projectile","projectile",1.0f,4),
			ScoredResource("token_reisenu.projectile","projectile",1.0f,4),
			ScoredResource("token_rem.projectile","projectile",1.0f,4),
			ScoredResource("token_rkgk.projectile","projectile",1.0f,4),
			ScoredResource("token_rubyrose.projectile","projectile",1.0f,4),
			ScoredResource("token_sangonomiya_kokomi.projectile","projectile",1.0f,4),
			ScoredResource("token_scented.projectile","projectile",1.0f,4),
			ScoredResource("token_shigure.projectile","projectile",1.0f,4),
			ScoredResource("token_shigure_summer_ver.projectile","projectile",1.0f,4),
			ScoredResource("token_shokuhou_misaki.projectile","projectile",1.0f,4),
			ScoredResource("token_skyfire.projectile","projectile",1.0f,4),
			ScoredResource("token_sorasaki_hina.projectile","projectile",1.0f,4),
			ScoredResource("token_strelka.projectile","projectile",1.0f,4),
			ScoredResource("token_tachibana_kanade.projectile","projectile",1.0f,4),
			ScoredResource("token_takanashi_hoshino.projectile","projectile",1.0f,4),
			ScoredResource("token_texas.projectile","projectile",1.0f,4),
			ScoredResource("token_tima.projectile","projectile",1.0f,4),
			ScoredResource("token_uzuki.projectile","projectile",1.0f,4),
			ScoredResource("token_yukikaze.projectile","projectile",1.0f,4),
			ScoredResource("token_yuudachi_azurlane_origin.projectile","projectile",1.0f,4),
			ScoredResource("token_yuudachi_halloween_ver.projectile","projectile",1.0f,4),
			ScoredResource("token_tashkent_equipment.projectile","projectile",1.0f,4),
			ScoredResource("token_alibina.projectile","projectile",1.0f,4),
			ScoredResource("token_g41_schoolsuit.projectile","projectile",1.0f,4),
			ScoredResource("token_patricia_abelheim.projectile","projectile",1.0f,4),
			ScoredResource("token_lappland_refined_horrormare.projectile","projectile",1.0f,4),
			ScoredResource("token_m14.projectile","projectile",1.0f,4),
			ScoredResource("token_kal_tsit_m3.projectile","projectile",1.0f,4),
			ScoredResource("token_kal_tsit.projectile","projectile",1.0f,4),
			ScoredResource("token_miyu.projectile","projectile",1.0f,4),
			ScoredResource("token_felix_schultz.projectile","projectile",1.0f,4),
			ScoredResource("token_takanashi_hoshino_swim_ver.projectile","projectile",1.0f,4),
			ScoredResource("token_mari_lochi_gymsuit_ver.projectile","projectile",1.0f,4),
			ScoredResource("token_dark_excalibur.projectile","projectile",1.0f,4),
			ScoredResource("token_shirasu_azusa.projectile","projectile",1.0f,4),
			ScoredResource("token_laisha.projectile","projectile",1.0f,4),
			ScoredResource("token_ba_iroha.projectile","projectile",1.0f,4),
			ScoredResource("token_mg3.projectile","projectile",1.0f,4),
			ScoredResource("token_g41_space.projectile","projectile",1.0f,4),
			ScoredResource("token_toki.projectile","projectile",1.0f,4),
			ScoredResource("token_pmaru.projectile","projectile",1.0f,4),
			ScoredResource("token_kisaki.projectile","projectile",1.0f,4),
			ScoredResource("token_amamiya_kokoro.projectile","projectile",1.0f,4),
			ScoredResource("token_erina.projectile","projectile",1.0f,4),
			ScoredResource("token_ifrit.projectile","projectile",1.0f,4),
			ScoredResource("token_vergil.projectile","projectile",1.0f,4),
			ScoredResource("token_frieren.projectile","projectile",1.0f,4),
			ScoredResource("token_hk416_china.projectile","projectile",1.0f,4),
			ScoredResource("token_sf_m950a.projectile","projectile",1.0f,4),
			ScoredResource("token_tail_blue.projectile","projectile",1.0f,4),
			ScoredResource("token_tail_red.projectile","projectile",1.0f,4),
			ScoredResource("token_ump45_white.projectile","projectile",1.0f,4),
			ScoredResource("token_vepley.projectile","projectile",1.0f,4),
			ScoredResource("token_elaina_dress.projectile","projectile",1.0f,4),
			ScoredResource("token_sorasaki_hina_swim.projectile","projectile",1.0f,4),
			ScoredResource("token_starwars_shipgirls.projectile","projectile",1.0f,4),
			ScoredResource("token_asagi_mutsuki.projectile","projectile",1.0f,4),
			ScoredResource("token_rikuhachima_aru.projectile","projectile",1.0f,4),
			ScoredResource("token_lilies.projectile","projectile",1.0f,4),
			ScoredResource("token_zero401_casual_wear.projectile","projectile",1.0f,4),
			ScoredResource("token_maria_schariac.projectile","projectile",1.0f,4),
			ScoredResource("token_shinano.projectile","projectile",1.0f,4),
			// 1.6.4
			ScoredResource("token_irene.projectile","projectile",1.0f,4),
			ScoredResource("token_aur.projectile","projectile",1.0f,4),
			ScoredResource("token_ein.projectile","projectile",1.0f,4),
			ScoredResource("token_soph.projectile","projectile",1.0f,4),
			ScoredResource("token_florence_spring.projectile","projectile",1.0f,4),
			ScoredResource("token_minami_rena.projectile","projectile",1.0f,4),
			ScoredResource("token_racing_miku_2022.projectile","projectile",1.0f,4),
			ScoredResource("token_tail_yellow.projectile","projectile",1.0f,4),
			ScoredResource("token_togo_miomori.projectile","projectile",1.0f,4),
			// 1.7.0
			ScoredResource("token_kotori_itsuka.projectile","projectile",1.0f,4),
			ScoredResource("token_exo_cat.projectile","projectile",1.0f,4),
			ScoredResource("token_akane.projectile","projectile",1.0f,4),
			ScoredResource("token_asuna.projectile","projectile",1.0f,4),
			ScoredResource("token_karin.projectile","projectile",1.0f,4),
			ScoredResource("token_neru.projectile","projectile",1.0f,4),
			ScoredResource("token_latu.projectile","projectile",1.0f,4),
			ScoredResource("token_amau_ako.projectile","projectile",1.0f,4),
			ScoredResource("token_goto_hitori.projectile","projectile",1.0f,4),
			// 1.7.1
			ScoredResource("token_blaze.projectile","projectile",1.0f,4),
			ScoredResource("token_goldenglow.projectile","projectile",1.0f,4),
			ScoredResource("token_pamiat_merkuria.projectile","projectile",1.0f,4),
			ScoredResource("token_pamiat_merkuria_alter.projectile","projectile",1.0f,4),
			ScoredResource("token_skadi.projectile","projectile",1.0f,4),
			ScoredResource("token_arona.projectile","projectile",1.0f,4),
			ScoredResource("token_gehenna_member.projectile","projectile",1.0f,4),
			// 1.7.1fix
			ScoredResource("token_abandoned_isomer.projectile","projectile",1.0f,4),
			ScoredResource("token_dndn_porno.projectile","projectile",1.0f,4),	
			// 1.8.0
			ScoredResource("token_kirito.projectile","projectile",1.0f,4),	
			ScoredResource("token_lona.projectile","projectile",1.0f,4),	
			ScoredResource("token_misaka_10032_winter.projectile","projectile",1.0f,4),	
			ScoredResource("token_misaka_mikoto_winter.projectile","projectile",1.0f,4),	
			ScoredResource("token_sinon.projectile","projectile",1.0f,4),	
			ScoredResource("token_sinon_black.projectile","projectile",1.0f,4),	
			ScoredResource("token_yuuki_ggo.projectile","projectile",1.0f,4),	
			// 1.8.2
			ScoredResource("token_yui_katagiri.projectile","projectile",1.0f,4),	
			ScoredResource("token_odst.projectile","projectile",1.0f,4),	
			ScoredResource("token_hanaoka_yuzu.projectile","projectile",1.0f,4),	
			// 1.9.1
			ScoredResource("token_shimokura_megu.projectile","projectile",1.0f,4),	
			ScoredResource("token_otogi.projectile","projectile",1.0f,4),	
			// 1.9.2
			ScoredResource("token_rumi.projectile","projectile",1.0f,4),	
			// 1.9.3
			ScoredResource("token_yang.projectile","projectile",1.0f,4),	
			ScoredResource("token_yaha.projectile","projectile",1.0f,4),	
			ScoredResource("token_luna_child.projectile","projectile",1.0f,4),	
			ScoredResource("token_star_sapphire.projectile","projectile",1.0f,4),	
			ScoredResource("token_sunny_mlik.projectile","projectile",1.0f,4),	
			ScoredResource("token_final_chapter_i.projectile","projectile",1.0f,4),	
			ScoredResource("token_nar_lf.projectile","projectile",1.0f,4),	
			ScoredResource("token_rebellious_bunny_i.projectile","projectile",1.0f,4),	
			ScoredResource("token_rebellious_bunny_i_old.projectile","projectile",1.0f,4),	
			ScoredResource("token_alice_tendou_maid.projectile","projectile",1.0f,4),	
			ScoredResource("token_heavy_infantry.projectile","projectile",1.0f,4),	
			ScoredResource("token_misono_mika.projectile","projectile",1.0f,4),	
			ScoredResource("token_sabayon.projectile","projectile",1.0f,4),	
			// 1.9.4
			ScoredResource("token_hinanawi_tenshi.projectile","projectile",1.0f,4),	
			ScoredResource("token_tomoe_gozen.projectile","projectile",1.0f,4),	
			ScoredResource("token_asashio.projectile","projectile",1.0f,4),	
			ScoredResource("token_plana.projectile","projectile",1.0f,4),	
			ScoredResource("token_mizuha_mimori.projectile","projectile",1.0f,4),	

			//AI类信物
			ScoredResource("ai_token_asuma_toki.projectile","projectile",1.0f,2)

			},
			{
			ScoredResource("lottery_cash_II.carry_item", "carry_item", 1.0f)
			}
		};   
			
		processRewardPasses(rewardPasses);

		GiftItemDeliveryRandomRewarder@ rewarder = GiftItemDeliveryRandomRewarder(m_metagame, rewardPasses);

		m_itemDeliveryOrganizer.addObjective(
			ItemDeliveryObjective(m_metagame, 0, deliveryList, m_itemDeliveryOrganizer, null, "", "", "", -1 /* loop */, rewarder)
			);
	}

	// ----------------------------------------------------
	protected void setupMusic() {
		_log("adding reward_box_music config", 1);
		//音乐箱子
		array<Resource@> deliveryList = {
			 Resource("reward_box_music.carry_item", "carry_item")
		};

		array<array<ScoredResource@>> rewardPasses = {
			{
		 ScoredResource("ex_piano_uzuki.weapon", "weapon", 1.0f,2), 
		 ScoredResource("ex_piano_yuudachi.weapon", "weapon", 1.0f,2), 
		 ScoredResource("ex_piano_unwelcome_school.weapon", "weapon", 1.0f,2), 
		 ScoredResource("ex_piano_cradle_of_eternity.weapon", "weapon", 1.0f,2), 
         ScoredResource("ex_gramophone_steeltorrent.weapon", "weapon", 1.0f,2),
         ScoredResource("ex_power_chair_call.projectile", "projectile", 1.0f,2),
         ScoredResource("ex_gramophone_space_elevator.weapon", "weapon", 1.0f,2),
         ScoredResource("ex_gramophone_made_of_earth.weapon", "weapon", 1.0f,2)
			},
			{
			ScoredResource("lottery_cash_II.carry_item", "carry_item", 1.0f)
			}
		};   

		processRewardPasses(rewardPasses);
    
		GiftItemDeliveryRandomRewarder@ rewarder = GiftItemDeliveryRandomRewarder(m_metagame, rewardPasses);

		m_itemDeliveryOrganizer.addObjective(
			ItemDeliveryObjective(m_metagame, 0, deliveryList, m_itemDeliveryOrganizer, null, "", "", "", -1 /* loop */, rewarder)
			);
	}

	// ----------------------------------------------------
	protected void setupVehicle() {
		_log("adding reward_box_vehicle config", 1);
		//载具箱子
		array<Resource@> deliveryList = {
			 Resource("reward_box_vehicle.carry_item", "carry_item")
		};

		array<array<ScoredResource@>> rewardPasses = {
			{
			ScoredResource("deploy_ex_pak40.weapon", "weapon", 0.1f),
			ScoredResource("deploy_ex_zis3.weapon", "weapon", 0.1f),

			ScoredResource("ex_isu_152_call.projectile", "projectile", 1.0f),
			ScoredResource("noxe_call.projectile", "projectile", 1.0f),
			ScoredResource("ex_sturmtiger_tank_call.projectile", "projectile", 1.0f),
			ScoredResource("ex_apocalypse_tank_call.projectile", "projectile", 1.0f),
			ScoredResource("ex_kv2_gup_call.projectile", "projectile", 1.0f),
			ScoredResource("ex_sherman_call.projectile", "projectile", 1.0f),
			ScoredResource("ex_guntruck_plus_call.projectile", "projectile", 1.0f),
			ScoredResource("ba_crusader_call.projectile", "projectile", 1.0f),
			ScoredResource("ex_m18_call.projectile", "projectile", 1.0f),
			ScoredResource("ba_torumaru_tiger_call.projectile", "projectile", 1.0f),
			ScoredResource("mi_24_call.projectile", "projectile", 0.5f),
			ScoredResource("bell_360_call.projectile", "projectile", 0.5f),
			ScoredResource("mh_60s_call.projectile", "projectile", 0.5f),
			ScoredResource("is2_m1895_call.projectile", "projectile", 1.0f),
			ScoredResource("himars_call.projectile", "projectile", 0.5f),
			ScoredResource("mtlb_2b9_call.projectile", "projectile", 1.0f),
			ScoredResource("m61a5_call.projectile", "projectile", 1.0f),
			ScoredResource("uragan_call.projectile", "projectile", 0.5f),
			ScoredResource("borsig_call.projectile", "projectile", 1.0f),
			ScoredResource("zbd09_call.projectile", "projectile", 1.0f),
			ScoredResource("lav6_call.projectile", "projectile", 1.0f),
			ScoredResource("wiesel_tow_call.projectile", "projectile", 1.0f),
			ScoredResource("panther_a_call.projectile", "projectile", 1.0f),
			ScoredResource("panzer_3_a_call.projectile", "projectile", 1.0f),
			ScoredResource("sdkfz184_call.projectile", "projectile", 1.0f),
			ScoredResource("t90m3_call.projectile", "projectile", 1.0f),
			ScoredResource("marder_call.projectile", "projectile", 1.0f),
			ScoredResource("ex_unsc_scion_call.projectile", "projectile", 1.0f)
			},
			{
			ScoredResource("lottery_cash_II.carry_item", "carry_item", 1.0f)
			}
		};   

		processRewardPasses(rewardPasses);
    
		GiftItemDeliveryRandomRewarder@ rewarder = GiftItemDeliveryRandomRewarder(m_metagame, rewardPasses);

		m_itemDeliveryOrganizer.addObjective(
			ItemDeliveryObjective(m_metagame, 0, deliveryList, m_itemDeliveryOrganizer, null, "", "", "", -1 /* loop */, rewarder)
			);
	}

	// ----------------------------------------------------
	protected void setupWeapon1() {
		_log("adding reward_box_weapon_1 config", 1);
		// MK1系列武器
		array<Resource@> deliveryList = {
			 Resource("reward_box_weapon_1.carry_item", "carry_item")
		};

		array<array<ScoredResource@>> rewardPasses = {
			{
         	ScoredResource("acg_smg_strelka.weapon", "weapon", 1.0f),
        	ScoredResource("acg_m14.weapon", "weapon", 1.0f),
        	ScoredResource("acg_mari_sports_ver.weapon", "weapon", 1.0f),         
         	ScoredResource("acg_ka_ar8.weapon", "weapon", 1.0f),
         	ScoredResource("ex_funnelnet.weapon", "weapon", 1.0f),
         	ScoredResource("acg_mg3.weapon", "weapon", 1.0f),
         	ScoredResource("ex_izanagis_burden.weapon", "weapon", 1.0f),
			// 1.8.2
         	ScoredResource("ex_psc_srs99.weapon", "weapon", 1.0f),
         	ScoredResource("ex_psc_arc920.weapon", "weapon", 1.0f),
         	ScoredResource("ex_exp_m41_spnkr.weapon", "weapon", 1.0f),
         	ScoredResource("ex_side_m6g_magnum.weapon", "weapon", 1.0f),
			// 1.9.3
         	ScoredResource("ex_heavy_infantry_morita_mk1.weapon", "weapon", 1.0f),
         	ScoredResource("ex_typhoon.weapon", "weapon", 1.0f)

			},
			{
			ScoredResource("lottery_cash_II.carry_item", "carry_item", 1.0f)
			}
		};   

		processRewardPasses(rewardPasses);
    
		GiftItemDeliveryRandomRewarder@ rewarder = GiftItemDeliveryRandomRewarder(m_metagame, rewardPasses);

		m_itemDeliveryOrganizer.addObjective(
			ItemDeliveryObjective(m_metagame, 0, deliveryList, m_itemDeliveryOrganizer, null, "", "", "", -1 /* loop */, rewarder)
			);
	}

	// ----------------------------------------------------
	protected void setupWeapon2() {
		_log("adding reward_box_weapon_2 config", 1);
		array<Resource@> deliveryList = {
			 Resource("reward_box_weapon_2.carry_item", "carry_item")
		};
		// MK2系列武器
		array<array<ScoredResource@>> rewardPasses = {
			{
        	ScoredResource("acg_mg4td_ke.weapon", "weapon", 1.0f),
        	ScoredResource("ex_lancer_mk3.weapon", "weapon", 1.0f),
        	ScoredResource("ex_soma_prime.weapon", "weapon", 1.0f),
        	ScoredResource("acg_mg4a3td.weapon", "weapon", 1.0f),
        	ScoredResource("acg_ruby_rose_scythe.weapon", "weapon", 1.0f),
        	ScoredResource("acg_reisenu_a.weapon", "weapon", 1.0f),
        	ScoredResource("acg_piko_hammer.weapon", "weapon", 1.0f),
        	ScoredResource("acg_kemomimi.weapon", "weapon", 1.0f),
			// 1.9.3
        	ScoredResource("ex_heavy_infantry_morita.weapon", "weapon", 1.0f)
			},
			{
			ScoredResource("lottery_cash_II.carry_item", "carry_item", 1.0f)
			}
		};   

		processRewardPasses(rewardPasses);
    
		GiftItemDeliveryRandomRewarder@ rewarder = GiftItemDeliveryRandomRewarder(m_metagame, rewardPasses);

		m_itemDeliveryOrganizer.addObjective(
			ItemDeliveryObjective(m_metagame, 0, deliveryList, m_itemDeliveryOrganizer, null, "", "", "", -1 /* loop */, rewarder)
			);
	}	
	// ----------------------------------------------------
	protected void setupWeaponAlpha() {
		_log("adding setupWeaponAlpha config", 1);
		array<Resource@> deliveryList = {
			 Resource("reward_box_weapon_alpha.carry_item", "carry_item")
		};
		array<array<ScoredResource@>> rewardPasses = {
			{
        	ScoredResource("hd_scout_main.weapon", "weapon", 1.0f),
        	ScoredResource("ex_money_gun.weapon", "weapon", 1.0f),
        	ScoredResource("ex_auto_guaguale_i_gun.weapon", "weapon", 1.0f),
        	ScoredResource("deploy_rabbit.weapon", "weapon", 1.0f),
        	ScoredResource("deploy_fake_fumo_cirno.weapon", "weapon", 1.0f),
        	ScoredResource("hd_fire_bunny.weapon", "weapon", 1.0f)

			},
			{
			ScoredResource("lottery_cash_II.carry_item", "carry_item", 1.0f)
			}
		};   
		processRewardPasses(rewardPasses);
		GiftItemDeliveryRandomRewarder@ rewarder = GiftItemDeliveryRandomRewarder(m_metagame, rewardPasses);
		m_itemDeliveryOrganizer.addObjective(
			ItemDeliveryObjective(m_metagame, 0, deliveryList, m_itemDeliveryOrganizer, null, "", "", "", -1 /* loop */, rewarder)
			);
	}	
	// ----------------------------------------------------
	protected void setupWeaponUnknown() {
		_log("adding setupWeaponUnknown config", 1);
		// MK6系列武器
		array<Resource@> deliveryList = {
			 Resource("reward_box_weapon_unknown.carry_item", "carry_item")
		};
		array<array<ScoredResource@>> rewardPasses = {
			{
        	ScoredResource("acg_exo_toki.weapon", "weapon", 1.0f),
        	ScoredResource("acg_exo_toki_railgun.weapon", "weapon", 1.0f),
        	ScoredResource("acg_shigure_127mm.weapon", "weapon", 1.0f)
			},
			{
			ScoredResource("lottery_cash_II.carry_item", "carry_item", 1.0f)
			}
		};   
		processRewardPasses(rewardPasses);
		GiftItemDeliveryRandomRewarder@ rewarder = GiftItemDeliveryRandomRewarder(m_metagame, rewardPasses);
		m_itemDeliveryOrganizer.addObjective(
			ItemDeliveryObjective(m_metagame, 0, deliveryList, m_itemDeliveryOrganizer, null, "", "", "", -1 /* loop */, rewarder)
			);
	}	
	// ----------------------------------------------------
	protected void setupWeaponV() {
		_log("adding setupWeaponV config", 1);
		// MK5系列武器
		array<Resource@> deliveryList = {
			 Resource("reward_box_weapon_v.carry_item", "carry_item")
		};
		array<array<ScoredResource@>> rewardPasses = {
			{
        	ScoredResource("ex_hyper_mega_bazooka_launcher.weapon", "weapon", 1.0f),
        	ScoredResource("acg_patricia_cumforce.weapon", "weapon", 1.0f),
        	// ScoredResource("acg_megumin_wand_float.weapon", "weapon", 1.0f),
        	ScoredResource("acg_laisha_heliotrope.weapon", "weapon", 1.0f),
        	ScoredResource("ex_vergil_judgment_cut.weapon", "weapon", 1.0f),
        	ScoredResource("ex_trinity_ghoul.weapon", "weapon", 1.0f),
			// 1.8.2
        	ScoredResource("acg_elaina_wand.weapon", "weapon", 1.0f),
			// 1.9.3
        	ScoredResource("acg_izayoi_sakuya_i.weapon", "weapon", 1.0f),
			// 1.9.4
        	ScoredResource("ex_exo_dreadnought_mg.weapon", "weapon", 2.5f),
        	ScoredResource("acg_scripts_hoshino_get.weapon", "weapon", 2.5f)
			},
			{
			ScoredResource("lottery_cash_II.carry_item", "carry_item", 1.0f)
			}
		};   
		processRewardPasses(rewardPasses);
		GiftItemDeliveryRandomRewarder@ rewarder = GiftItemDeliveryRandomRewarder(m_metagame, rewardPasses);
		m_itemDeliveryOrganizer.addObjective(
			ItemDeliveryObjective(m_metagame, 0, deliveryList, m_itemDeliveryOrganizer, null, "", "", "", -1 /* loop */, rewarder)
			);
	}	
	// ----------------------------------------------------
	protected void setupWeaponX() {
		_log("adding setupWeaponX config", 1);
		// 复活自带系列
		array<Resource@> deliveryList = {
			 Resource("reward_box_weapon_x.carry_item", "carry_item")
		};
		array<array<ScoredResource@>> rewardPasses = {
			{
        	ScoredResource("ex_piano_uzuki.weapon", "weapon", 1.0f),

        	ScoredResource("ex_piano_uzuki.weapon", "weapon", 1.0f)
			},
			{
			ScoredResource("lottery_cash_II.carry_item", "carry_item", 1.0f)
			}
		};   
		processRewardPasses(rewardPasses);
		GiftItemDeliveryRandomRewarder@ rewarder = GiftItemDeliveryRandomRewarder(m_metagame, rewardPasses);
		m_itemDeliveryOrganizer.addObjective(
			ItemDeliveryObjective(m_metagame, 0, deliveryList, m_itemDeliveryOrganizer, null, "", "", "", -1 /* loop */, rewarder)
			);
	}	
	// ----------------------------------------------------
	protected void setupWeaponBeta() {
		_log("adding setupWeaponBeta config", 1);
		//mk1~mk5 系列数量限制 5/4/3/2/1
		array<Resource@> deliveryList = {
			 Resource("reward_box_weapon_beta.carry_item", "carry_item")
		};
		array<array<ScoredResource@>> rewardPasses = {
			{
        	ScoredResource("acg_patricia_cumforce.weapon", "weapon", 1.0f),

        	ScoredResource("acg_bronya.weapon", "weapon", 1.0f),
        	ScoredResource("acg_g41_lasercanno_diffusion.weapon", "weapon", 1.0f),

        	ScoredResource("acg_sinteria_bow.weapon", "weapon", 1.0f),
        	ScoredResource("acg_kokomi_portia.weapon", "weapon", 1.0f),
        	ScoredResource("acg_sorasaki_hina.weapon", "weapon", 1.0f),

        	ScoredResource("acg_reisenu_a.weapon", "weapon", 1.0f),
        	ScoredResource("acg_piko_hammer.weapon", "weapon", 1.0f),
        	ScoredResource("acg_mg4a3td.weapon", "weapon", 1.0f),
        	ScoredResource("acg_mg4td_ke.weapon", "weapon", 1.0f),
        	ScoredResource("ex_lancer_mk3.weapon", "weapon", 1.0f),

        	ScoredResource("acg_smg_strelka.weapon", "weapon", 1.0f),
        	ScoredResource("acg_m14.weapon", "weapon", 1.0f),
        	ScoredResource("ex_psc_srs99.weapon", "weapon", 1.0f),
         	ScoredResource("ex_psc_arc920.weapon", "weapon", 1.0f),
         	ScoredResource("ex_exp_m41_spnkr.weapon", "weapon", 1.0f),
         	ScoredResource("ex_side_m6g_magnum.weapon", "weapon", 1.0f)
			},
			{
			ScoredResource("lottery_cash_II.carry_item", "carry_item", 1.0f)
			}
		};   
		processRewardPasses(rewardPasses);
		GiftItemDeliveryRandomRewarder@ rewarder = GiftItemDeliveryRandomRewarder(m_metagame, rewardPasses);
		m_itemDeliveryOrganizer.addObjective(
			ItemDeliveryObjective(m_metagame, 0, deliveryList, m_itemDeliveryOrganizer, null, "", "", "", -1 /* loop */, rewarder)
			);
	}	
	// ----------------------------------------------------
	protected void setupWeaponGama() {
		_log("adding setupWeaponGama config", 1);
		//mk1~mk5 系列数量限制 5/4/3/2/1
		array<Resource@> deliveryList = {
			 Resource("reward_box_weapon_gama.carry_item", "carry_item")
		};
		array<array<ScoredResource@>> rewardPasses = {
			{
        	ScoredResource("acg_megumin_wand_float.weapon", "weapon", 1.0f),

        	ScoredResource("acg_shuiniao.weapon", "weapon", 1.0f),
        	ScoredResource("acg_fiammetta_gl.weapon", "weapon", 1.0f),

        	ScoredResource("acg_iws2000_banisher.weapon", "weapon", 1.0f),
        	ScoredResource("acg_g41_bp2077.weapon", "weapon", 1.0f),
			ScoredResource("acg_kokomi_portia.weapon", "weapon", 1.0f),

        	ScoredResource("acg_kemomimi.weapon", "weapon", 1.0f),
        	ScoredResource("acg_mg4a3td.weapon", "weapon", 1.0f),
        	ScoredResource("acg_mg4td_ke.weapon", "weapon", 1.0f),
        	ScoredResource("ex_lancer_mk3.weapon", "weapon", 1.0f),
        	ScoredResource("ex_soma_prime.weapon", "weapon", 1.0f),

        	ScoredResource("acg_smg_strelka.weapon", "weapon", 1.0f),
        	ScoredResource("acg_m14.weapon", "weapon", 1.0f),
        	ScoredResource("acg_mari_sports_ver.weapon", "weapon", 1.0f),
        	ScoredResource("acg_ka_ar8.weapon", "weapon", 1.0f),
         	ScoredResource("ex_funnelnet.weapon", "weapon", 1.0f),
        	ScoredResource("ex_izanagis_burden.weapon", "weapon", 1.0f)
			},
			{
			ScoredResource("lottery_cash_II.carry_item", "carry_item", 1.0f)
			}
		};   
		processRewardPasses(rewardPasses);
		GiftItemDeliveryRandomRewarder@ rewarder = GiftItemDeliveryRandomRewarder(m_metagame, rewardPasses);
		m_itemDeliveryOrganizer.addObjective(
			ItemDeliveryObjective(m_metagame, 0, deliveryList, m_itemDeliveryOrganizer, null, "", "", "", -1 /* loop */, rewarder)
			);
	}	
	// ----------------------------------------------------
	protected void setupWeaponDelta() {
		_log("adding setupWeaponDelta config", 1);
		// MK4 系列物品
		array<Resource@> deliveryList = {
			 Resource("reward_box_weapon_delta.carry_item", "carry_item")
		};
		array<array<ScoredResource@>> rewardPasses = {
			{
        	ScoredResource("acg_bronya.weapon", "weapon", 1.0f),
        	ScoredResource("acg_g41_lasercanno_diffusion.weapon", "weapon", 1.0f),
        	ScoredResource("acg_shuiniao.weapon", "weapon", 1.0f),
        	ScoredResource("acg_fiammetta_gl.weapon", "weapon", 1.0f),
        	ScoredResource("ex_disaster_railgun.weapon", "weapon", 1.0f),
        	ScoredResource("acg_texas_skill.weapon", "weapon", 1.0f),
        	//ScoredResource("acg_arknight_ifrit.weapon", "weapon", 1.0f),
        	ScoredResource("acg_starwars_shipgirls.weapon", "weapon", 1.0f),
        	ScoredResource("acg_asagi_mutsuki.weapon", "weapon", 1.0f),
        	ScoredResource("acg_rikuhachima_aru.weapon", "weapon", 1.0f),
        	ScoredResource("acg_shinano.weapon", "weapon", 1.0f),
        	ScoredResource("acg_ba_alice_railgun_ex.weapon", "weapon", 1.0f),
			// 1.7.2
        	ScoredResource("acg_incomparable.weapon", "weapon", 1.0f),
			// 1.8.2
        	ScoredResource("acg_yileina_wand.weapon", "weapon", 1.0f),
			// 1.9.2
        	ScoredResource("acg_hayase_yuuka.weapon", "weapon", 1.0f)
			},
			{
			ScoredResource("lottery_cash_II.carry_item", "carry_item", 1.0f)
			}
		};   
		processRewardPasses(rewardPasses);
		GiftItemDeliveryRandomRewarder@ rewarder = GiftItemDeliveryRandomRewarder(m_metagame, rewardPasses);
		m_itemDeliveryOrganizer.addObjective(
			ItemDeliveryObjective(m_metagame, 0, deliveryList, m_itemDeliveryOrganizer, null, "", "", "", -1 /* loop */, rewarder)
			);
	}	
	// ----------------------------------------------------
	protected void setupWeaponTheta() {
		_log("adding setupWeaponTheta config", 1);
		//mk1~mk5 系列数量限制 5/4/3/2/1
		array<Resource@> deliveryList = {
			 Resource("reward_box_weapon_theta.carry_item", "carry_item")
		};
		array<array<ScoredResource@>> rewardPasses = {
			{
        	ScoredResource("ex_trinity_ghoul.weapon", "weapon", 1.0f),

        	ScoredResource("ex_disaster_railgun.weapon", "weapon", 1.0f),
        	ScoredResource("acg_texas_skill.weapon", "weapon", 1.0f),

        	ScoredResource("acg_sinteria_bow.weapon", "weapon", 1.0f),
        	ScoredResource("acg_hongxue.weapon", "weapon", 1.0f),
        	ScoredResource("acg_g41_universe.weapon", "weapon", 1.0f),

        	ScoredResource("acg_kemomimi.weapon", "weapon", 1.0f),
        	ScoredResource("acg_piko_hammer.weapon", "weapon", 1.0f),
        	ScoredResource("acg_mg4td_ke.weapon", "weapon", 1.0f),
        	ScoredResource("ex_lancer_mk3.weapon", "weapon", 1.0f),
        	ScoredResource("ex_soma_prime.weapon", "weapon", 1.0f),

        	ScoredResource("acg_m14.weapon", "weapon", 1.0f),
        	ScoredResource("acg_mari_sports_ver.weapon", "weapon", 1.0f),
        	ScoredResource("acg_ka_ar8.weapon", "weapon", 1.0f),
         	ScoredResource("ex_funnelnet.weapon", "weapon", 1.0f),
         	ScoredResource("acg_mg3.weapon", "weapon", 1.0f),
        	ScoredResource("ex_izanagis_burden.weapon", "weapon", 1.0f)
			},
			{
			ScoredResource("lottery_cash_II.carry_item", "carry_item", 1.0f)
			}
		};   
		processRewardPasses(rewardPasses);
		GiftItemDeliveryRandomRewarder@ rewarder = GiftItemDeliveryRandomRewarder(m_metagame, rewardPasses);
		m_itemDeliveryOrganizer.addObjective(
			ItemDeliveryObjective(m_metagame, 0, deliveryList, m_itemDeliveryOrganizer, null, "", "", "", -1 /* loop */, rewarder)
			);
	}	
	// ----------------------------------------------------
	protected void setupWeaponLamda() {
		_log("adding setupWeaponLamda config", 1);
		// MK3系列武器
		array<Resource@> deliveryList = {
			 Resource("reward_box_weapon_lamda.carry_item", "carry_item")
		};
		array<array<ScoredResource@>> rewardPasses = {
			{
        	ScoredResource("acg_sinteria_bow.weapon", "weapon", 1.0f),
        	ScoredResource("acg_takanashi_hoshino.weapon", "weapon", 1.0f),
        	ScoredResource("acg_miyu.weapon", "weapon", 1.0f),
        	ScoredResource("acg_sorasaki_hina.weapon", "weapon", 1.0f),
        	ScoredResource("acg_iws2000_banisher.weapon", "weapon", 1.0f),
        	ScoredResource("acg_g41_bp2077.weapon", "weapon", 1.0f),
        	ScoredResource("acg_hongxue.weapon", "weapon", 1.0f),
        	ScoredResource("acg_g41_universe.weapon", "weapon", 1.0f),
        	ScoredResource("acg_maria_schariac.weapon", "weapon", 1.0f),
        	ScoredResource("acg_amamiya_kokoro.weapon", "weapon", 1.0f),
        	ScoredResource("ex_space_marines.weapon", "weapon", 1.0f),
        	ScoredResource("acg_rumi.weapon", "weapon", 1.0f),
			// 1.9.4
        	ScoredResource("acg_fade_red.weapon", "weapon", 2.0f),
        	ScoredResource("acg_bf109.weapon", "weapon", 2.0f)
			},
			{
			ScoredResource("lottery_cash_II.carry_item", "carry_item", 1.0f)
			}
		};   
		processRewardPasses(rewardPasses);
		GiftItemDeliveryRandomRewarder@ rewarder = GiftItemDeliveryRandomRewarder(m_metagame, rewardPasses);
		m_itemDeliveryOrganizer.addObjective(
			ItemDeliveryObjective(m_metagame, 0, deliveryList, m_itemDeliveryOrganizer, null, "", "", "", -1 /* loop */, rewarder)
			);
	}	
	// ----------------------------------------------------
	protected void setupWeaponMiu() {
		_log("adding setupWeaponMiu config", 1);
		//mk1~mk5 系列数量限制 5/4/3/2/1
		array<Resource@> deliveryList = {
			 Resource("reward_box_weapon_miu.carry_item", "carry_item")
		};
		array<array<ScoredResource@>> rewardPasses = {
			{
        	ScoredResource("ex_hyper_mega_bazooka_launcher.weapon", "weapon", 1.0f),

        	ScoredResource("acg_bronya.weapon", "weapon", 1.0f),
        	ScoredResource("acg_ba_alice_railgun_ex.weapon", "weapon", 1.0f),

        	ScoredResource("acg_g41_bp2077.weapon", "weapon", 1.0f),
        	ScoredResource("acg_amamiya_kokoro.weapon", "weapon", 1.0f),

        	ScoredResource("acg_kemomimi.weapon", "weapon", 1.0f),
        	ScoredResource("acg_reisenu_a.weapon", "weapon", 1.0f),
        	ScoredResource("acg_piko_hammer.weapon", "weapon", 1.0f),
        	ScoredResource("ex_lancer_mk3.weapon", "weapon", 1.0f),
        	ScoredResource("ex_soma_prime.weapon", "weapon", 1.0f),

        	ScoredResource("acg_smg_strelka.weapon", "weapon", 1.0f),
        	ScoredResource("acg_m14.weapon", "weapon", 1.0f),
        	ScoredResource("acg_mari_sports_ver.weapon", "weapon", 1.0f),
        	ScoredResource("acg_ka_ar8.weapon", "weapon", 1.0f),
         	ScoredResource("acg_mg3.weapon", "weapon", 1.0f),
        	ScoredResource("ex_izanagis_burden.weapon", "weapon", 1.0f)
			},
			{
			ScoredResource("lottery_cash_II.carry_item", "carry_item", 1.0f)
			}
		};   
		processRewardPasses(rewardPasses);
		GiftItemDeliveryRandomRewarder@ rewarder = GiftItemDeliveryRandomRewarder(m_metagame, rewardPasses);
		m_itemDeliveryOrganizer.addObjective(
			ItemDeliveryObjective(m_metagame, 0, deliveryList, m_itemDeliveryOrganizer, null, "", "", "", -1 /* loop */, rewarder)
			);
	}	
	// ----------------------------------------------------
	protected void setupWeaponPi() {
		_log("adding setupWeaponPi config", 1);
		//mk1~mk5 系列数量限制 5/4/3/2/1
		array<Resource@> deliveryList = {
			 Resource("reward_box_weapon_pi.carry_item", "carry_item")
		};
		array<array<ScoredResource@>> rewardPasses = {
			{
        	ScoredResource("acg_megumin_wand_float.weapon", "weapon", 1.0f),

        	ScoredResource("acg_shuiniao.weapon", "weapon", 1.0f),
        	ScoredResource("acg_texas_skill.weapon", "weapon", 1.0f),

        	ScoredResource("acg_sorasaki_hina.weapon", "weapon", 1.0f),
        	ScoredResource("acg_iws2000_banisher.weapon", "weapon", 1.0f),
        	ScoredResource("acg_amamiya_kokoro.weapon", "weapon", 1.0f),

        	ScoredResource("acg_kemomimi.weapon", "weapon", 1.0f),
        	ScoredResource("acg_reisenu_a.weapon", "weapon", 1.0f),
        	ScoredResource("acg_piko_hammer.weapon", "weapon", 1.0f),
        	ScoredResource("acg_mg4a3td.weapon", "weapon", 1.0f),
        	ScoredResource("acg_mg4td_ke.weapon", "weapon", 1.0f),

        	ScoredResource("acg_smg_strelka.weapon", "weapon", 1.0f),
        	ScoredResource("acg_m14.weapon", "weapon", 1.0f),
        	ScoredResource("acg_mari_sports_ver.weapon", "weapon", 1.0f),
        	ScoredResource("acg_ka_ar8.weapon", "weapon", 1.0f),
         	ScoredResource("ex_funnelnet.weapon", "weapon", 1.0f),
         	ScoredResource("acg_mg3.weapon", "weapon", 1.0f),
        	ScoredResource("ex_izanagis_burden.weapon", "weapon", 1.0f)
			},
			{
			ScoredResource("lottery_cash_II.carry_item", "carry_item", 1.0f)
			}
		};   
		processRewardPasses(rewardPasses);
		GiftItemDeliveryRandomRewarder@ rewarder = GiftItemDeliveryRandomRewarder(m_metagame, rewardPasses);
		m_itemDeliveryOrganizer.addObjective(
			ItemDeliveryObjective(m_metagame, 0, deliveryList, m_itemDeliveryOrganizer, null, "", "", "", -1 /* loop */, rewarder)
			);
	}	
	// ----------------------------------------------------
	protected void setupWeaponPhi() {
		_log("adding setupWeaponPhi config", 1);
		array<Resource@> deliveryList = {
			 Resource("reward_box_weapon_phi.carry_item", "carry_item")
		};
		array<array<ScoredResource@>> rewardPasses = {
			{
        	ScoredResource("ex_piano_uzuki.weapon", "weapon", 1.0f),

        	ScoredResource("ex_piano_uzuki.weapon", "weapon", 1.0f)
			},
			{
			ScoredResource("lottery_cash_II.carry_item", "carry_item", 1.0f)
			}
		};   
		processRewardPasses(rewardPasses);
		GiftItemDeliveryRandomRewarder@ rewarder = GiftItemDeliveryRandomRewarder(m_metagame, rewardPasses);
		m_itemDeliveryOrganizer.addObjective(
			ItemDeliveryObjective(m_metagame, 0, deliveryList, m_itemDeliveryOrganizer, null, "", "", "", -1 /* loop */, rewarder)
			);
	}	
	// ----------------------------------------------------
	protected void setupHDicker() {
		_log("adding setupHDicker config", 1);
		array<Resource@> deliveryList = {
			 Resource("reward_box_hdicker.carry_item", "carry_item")
		};
		array<array<ScoredResource@>> rewardPasses = {
			{
        	ScoredResource("token_hdicker_tactical_combat.projectile", "projectile", 1.0f),
        	ScoredResource("token_hdicker_para.projectile", "projectile", 1.0f),
        	ScoredResource("token_hdicker_marker.projectile", "projectile", 1.0f),
        	ScoredResource("token_hdicker_tactical.projectile", "projectile", 1.0f),
        	ScoredResource("token_hdicker_driver.projectile", "projectile", 1.0f),
        	ScoredResource("token_hdicker_electric.projectile", "projectile", 1.0f),
        	ScoredResource("token_hdicker_eod.projectile", "projectile", 1.0f),
        	ScoredResource("token_hdicker_medick.projectile", "projectile", 1.0f),
        	ScoredResource("token_hdicker_shadow.projectile", "projectile", 1.0f),
        	ScoredResource("token_hdicker_supporter_weaponMaster.projectile", "projectile", 1.0f)
			},
			{
			ScoredResource("hd_psc_atx25_revelator_dicker.weapon", "weapon", 1.0f),
			ScoredResource("hd_ar_ar77d_spade_dicker.weapon", "weapon", 1.0f),
			ScoredResource("hd_lava17_roger_dicker.weapon", "weapon", 1.0f),
			ScoredResource("hd_smg_tc171_cyclone_dicker.weapon", "weapon", 1.0f),
			ScoredResource("hd_arc_as5_resistance_dicker.weapon", "weapon", 1.0f),
			ScoredResource("hd_arc_as7_semiconductor_dicker.weapon", "weapon", 1.0f),
			ScoredResource("hd_arc_mgc_capacitor_dicker.weapon", "weapon", 1.0f),
			ScoredResource("hd_side_digger_drill_dicker.weapon", "weapon", 1.0f),
			ScoredResource("hd_side_hg871_woodpecker_dicker.weapon", "weapon", 1.0f),
			ScoredResource("hd_hmg_mg255_melt_dicker.weapon", "weapon", 1.0f),
			ScoredResource("hd_pst_tox17_sourhound_dicker.weapon", "weapon", 1.0f),
			ScoredResource("hd_psc_hho874_fraternity_dicker.weapon", "weapon", 1.0f)
			}
		};   
		processRewardPasses(rewardPasses);
		GiftItemDeliveryRandomRewarder@ rewarder = GiftItemDeliveryRandomRewarder(m_metagame, rewardPasses);
		m_itemDeliveryOrganizer.addObjective(
			ItemDeliveryObjective(m_metagame, 0, deliveryList, m_itemDeliveryOrganizer, null, "", "", "", -1 /* loop */, rewarder)
			);
	}	
	// ----------------------------------------------------
	protected void setupWeaponOmega() {
		_log("adding setupWeaponOmega config", 1);
		// MK1~MK3
		array<Resource@> deliveryList = {
			 Resource("reward_box_weapon_omega.carry_item", "carry_item")
		};
		array<array<ScoredResource@>> rewardPasses = {
			{
        	ScoredResource("acg_sinteria_bow.weapon", "weapon", 1.0f),
        	ScoredResource("acg_kokomi_portia.weapon", "weapon", 1.0f),
        	ScoredResource("acg_sorasaki_hina.weapon", "weapon", 1.0f),
        	ScoredResource("acg_iws2000_banisher.weapon", "weapon", 1.0f),
        	ScoredResource("acg_g41_bp2077.weapon", "weapon", 1.0f),
        	ScoredResource("acg_hongxue.weapon", "weapon", 1.0f),
        	ScoredResource("acg_g41_universe.weapon", "weapon", 1.0f),
        	ScoredResource("acg_amamiya_kokoro.weapon", "weapon", 1.0f),

        	ScoredResource("acg_kemomimi.weapon", "weapon", 1.0f),
        	ScoredResource("acg_reisenu_a.weapon", "weapon", 1.0f),
        	ScoredResource("acg_piko_hammer.weapon", "weapon", 1.0f),
        	ScoredResource("acg_mg4a3td.weapon", "weapon", 1.0f),
        	ScoredResource("acg_mg4td_ke.weapon", "weapon", 1.0f),
        	ScoredResource("ex_lancer_mk3.weapon", "weapon", 1.0f),
        	ScoredResource("ex_soma_prime.weapon", "weapon", 1.0f),

        	ScoredResource("acg_smg_strelka.weapon", "weapon", 1.0f),
        	ScoredResource("acg_m14.weapon", "weapon", 1.0f),
        	ScoredResource("acg_mari_sports_ver.weapon", "weapon", 1.0f),
        	ScoredResource("acg_ka_ar8.weapon", "weapon", 1.0f),
         	ScoredResource("ex_funnelnet.weapon", "weapon", 1.0f),
         	ScoredResource("acg_mg3.weapon", "weapon", 1.0f),
        	ScoredResource("ex_izanagis_burden.weapon", "weapon", 1.0f),
			ScoredResource("ex_psc_srs99.weapon", "weapon", 1.0f),
         	ScoredResource("ex_psc_arc920.weapon", "weapon", 1.0f),
         	ScoredResource("ex_exp_m41_spnkr.weapon", "weapon", 1.0f),
         	ScoredResource("ex_side_m6g_magnum.weapon", "weapon", 1.0f)
			},
			{
			ScoredResource("lottery_cash_II.carry_item", "carry_item", 1.0f)
			}
		};   
		processRewardPasses(rewardPasses);
		GiftItemDeliveryRandomRewarder@ rewarder = GiftItemDeliveryRandomRewarder(m_metagame, rewardPasses);
		m_itemDeliveryOrganizer.addObjective(
			ItemDeliveryObjective(m_metagame, 0, deliveryList, m_itemDeliveryOrganizer, null, "", "", "", -1 /* loop */, rewarder)
			);
	}	
	
	// ----------------------------------------------------
	protected void setupIcecream() {
		_log("adding icecream van config", 1);
		array<Resource@> deliveryList = {
			 Resource("lottery.carry_item", "carry_item")
		};

		array<array<ScoredResource@>> rewardPasses = {		
        	{
		ScoredResource("MTL_GOLD1", "carry_item", 10.0f),     
		ScoredResource("MTL_GOLD2", "carry_item", 3.0f),     
		ScoredResource("MTL_GOLD3", "carry_item", 1.0f),     
		ScoredResource("MTL_BASE_SL1", "carry_item", 10.0f),     
		ScoredResource("MTL_BASE_SL2", "carry_item", 3.0f),     
		ScoredResource("MTL_BASE_SL3", "carry_item", 1.0f),     
		ScoredResource("MTL_BASE_SYNTH1", "carry_item", 10.0f),     
		ScoredResource("MTL_BASE_SYNTH2", "carry_item", 3.0f),     
		ScoredResource("MTL_BASE_SYNTH3", "carry_item", 1.0f),     
		ScoredResource("MTL_SL_ALCOHOL1", "carry_item", 10.0f),     
		ScoredResource("MTL_SL_ALCOHOL2", "carry_item", 2.0f),     
		ScoredResource("MTL_SL_BOSS1", "carry_item", 10.0f),     
		ScoredResource("MTL_SL_BOSS2", "carry_item", 3.0f),     
		ScoredResource("MTL_SL_BOSS3", "carry_item", 1.0f),     
		ScoredResource("MTL_SL_BOSS4", "carry_item", 0.3f),     
		ScoredResource("MTL_SL_G1", "carry_item", 10.0f),     
		ScoredResource("MTL_SL_G2", "carry_item", 3.0f),     
		ScoredResource("MTL_SL_G3", "carry_item", 1.0f),     
		ScoredResource("MTL_SL_G4", "carry_item", 0.3f),     
		ScoredResource("MTL_SL_IRON1", "carry_item", 10.0f),     
		ScoredResource("MTL_SL_IRON2", "carry_item", 3.0f),     
		ScoredResource("MTL_SL_IRON3", "carry_item", 1.0f),     
		ScoredResource("MTL_SL_IRON4", "carry_item", 0.3f),     
		ScoredResource("MTL_SL_MANGANESE1", "carry_item", 2.0f),     
		ScoredResource("MTL_SL_MANGANESE2", "carry_item", 0.4f),     
		ScoredResource("MTL_SL_PG1", "carry_item", 2.0f),     
		ScoredResource("MTL_SL_PG2", "carry_item", 0.5f),     
		ScoredResource("MTL_SL_RMA7012", "carry_item", 1.0f),     
		ScoredResource("MTL_SL_RMA7024", "carry_item", 0.3f),     
		ScoredResource("MTL_SL_RUSH1", "carry_item", 10.0f),     
		ScoredResource("MTL_SL_RUSH2", "carry_item", 3.0f),     
		ScoredResource("MTL_SL_RUSH3", "carry_item", 1.0f),     
		ScoredResource("MTL_SL_RUSH4", "carry_item", 0.3f),     
		ScoredResource("MTL_SL_STRG1", "carry_item", 10.0f),     
		ScoredResource("MTL_SL_STRG2", "carry_item", 3.0f),     
		ScoredResource("MTL_SL_STRG3", "carry_item", 1.0f),     
		ScoredResource("MTL_SL_STRG4", "carry_item", 0.3f),     
		//total f = 130 左右 3280一张

		ScoredResource("reward_box_collection.carry_item", "carry_item", 0.001f),
		ScoredResource("reward_box_skin.carry_item", "carry_item", 20.0f),
		ScoredResource("reward_box_music.carry_item", "carry_item", 1.0f), 
		ScoredResource("reward_box_vehicle.carry_item", "carry_item", 5.0f), 
		// mk1 2w标价 期望＞6w
		ScoredResource("reward_box_weapon_1.carry_item", "carry_item", 7.1f),
		// mk2 5w 期望＞(2+7)*3=27w
		ScoredResource("reward_box_weapon_2.carry_item", "carry_item", 1.8f),
		// mk3 12w标价 期望＞(12+5+2)*3=57w
		ScoredResource("reward_box_weapon_lamda.carry_item", "carry_item", 0.72f),
		// mk4 非卖 预期24w 期望＞(24+12+5+2)*3=129w
		ScoredResource("reward_box_weapon_delta.carry_item", "carry_item", 0.30f),
		// mk5 非卖 预期48w 期望＞(48+24+12+5+2)*3=273w
		ScoredResource("reward_box_weapon_v.carry_item", "carry_item", 0.10f),
		// 待后续重置
		// ScoredResource("reward_box_weapon_beta.carry_item", "carry_item", 0.01f),
		// ScoredResource("reward_box_weapon_gama.carry_item", "carry_item", 0.01f),
		// ScoredResource("reward_box_weapon_theta.carry_item", "carry_item", 0.01f),
		// ScoredResource("reward_box_weapon_miu.carry_item", "carry_item", 0.01f),
		// ScoredResource("reward_box_weapon_pi.carry_item", "carry_item", 0.01f),

		// mk1~mk3 非卖 期望＞30w
		ScoredResource("reward_box_weapon_omega.carry_item", "carry_item", 0.7f),

		ScoredResource("reward_box_hdicker.carry_item", "carry_item", 0.2f)

			},
			{
			ScoredResource("balloon.carry_item", "carry_item", 300.0f),

			ScoredResource("hd_bonusfactor_al_10", "carry_item", 1.5f),
			ScoredResource("hd_bonusfactor_al_20", "carry_item", 0.5f),
			ScoredResource("hd_bonusfactor_al_45", "carry_item", 0.1f),
			ScoredResource("hd_bonusfactor_al_75", "carry_item", 0.04f),
			ScoredResource("hd_bonusfactor_al_125", "carry_item", 0.01f),
			ScoredResource("hd_bonusfactor_al_240", "carry_item", 0.001f),

			ScoredResource("hd_bonusfactor_xp_10", "carry_item", 1.5f),
			ScoredResource("hd_bonusfactor_xp_20", "carry_item", 0.5f),
			ScoredResource("hd_bonusfactor_xp_45", "carry_item", 0.1f),
			ScoredResource("hd_bonusfactor_xp_75", "carry_item", 0.04f),
			ScoredResource("hd_bonusfactor_xp_125", "carry_item", 0.01f),
			ScoredResource("hd_bonusfactor_xp_240", "carry_item", 0.001f),

			ScoredResource("hd_bonusfactor_rp_10", "carry_item", 1.5f),
			ScoredResource("hd_bonusfactor_rp_20", "carry_item", 0.5f),
			ScoredResource("hd_bonusfactor_rp_45", "carry_item", 0.1f),
			ScoredResource("hd_bonusfactor_rp_75", "carry_item", 0.041f),
			ScoredResource("hd_bonusfactor_rp_125", "carry_item", 0.01f),
			ScoredResource("hd_bonusfactor_rp_240", "carry_item", 0.001f)
			}
		};   
    
		processRewardPasses(rewardPasses);

		GiftItemDeliveryRandomRewarder@ rewarder = GiftItemDeliveryRandomRewarder(m_metagame, rewardPasses);

		m_itemDeliveryOrganizer.addObjective(
			ItemDeliveryObjective(m_metagame, 0, deliveryList, m_itemDeliveryOrganizer, null, "", "", "", -1 /* loop */, rewarder)
			);
	}
	// ----------------------------------------------------
	protected void setupHDlottery() {
		_log("adding HDlottery config", 1);
		array<Resource@> deliveryList = {
			Resource("lottery_superearth.carry_item", "carry_item")
		};

		array<array<ScoredResource@>> rewardPasses = {		
        	{
		ScoredResource("MTL_GOLD3", "carry_item", 1.0f),     
		ScoredResource("MTL_BASE_SL3", "carry_item", 1.0f),     
		ScoredResource("MTL_BASE_SYNTH3", "carry_item", 1.0f),     
		ScoredResource("MTL_SL_ALCOHOL2", "carry_item", 2.0f),     
		ScoredResource("MTL_SL_BOSS3", "carry_item", 1.0f),     
		ScoredResource("MTL_SL_BOSS4", "carry_item", 0.3f),     
		ScoredResource("MTL_SL_G3", "carry_item", 1.0f),     
		ScoredResource("MTL_SL_G4", "carry_item", 0.3f),     
		ScoredResource("MTL_SL_IRON3", "carry_item", 1.0f),     
		ScoredResource("MTL_SL_IRON4", "carry_item", 0.3f),     
		ScoredResource("MTL_SL_MANGANESE2", "carry_item", 0.4f),     
		ScoredResource("MTL_SL_PG2", "carry_item", 0.5f),     
		ScoredResource("MTL_SL_RMA7012", "carry_item", 1.0f),     
		ScoredResource("MTL_SL_RMA7024", "carry_item", 0.3f),     
		ScoredResource("MTL_SL_RUSH3", "carry_item", 1.0f),     
		ScoredResource("MTL_SL_RUSH4", "carry_item", 0.3f),     
		ScoredResource("MTL_SL_STRG3", "carry_item", 1.0f),     
		ScoredResource("MTL_SL_STRG4", "carry_item", 0.3f),     
		//total f = 13.7

		// 待后续重置
		ScoredResource("reward_box_weapon_beta.carry_item", "carry_item", 0.1f),
		ScoredResource("reward_box_weapon_gama.carry_item", "carry_item", 0.1f),
		ScoredResource("reward_box_weapon_theta.carry_item", "carry_item", 0.1f),
		ScoredResource("reward_box_weapon_miu.carry_item", "carry_item", 0.1f),
		ScoredResource("reward_box_weapon_pi.carry_item", "carry_item", 0.1f)

			},
			{
			ScoredResource("balloon.carry_item", "carry_item", 50.0f),

			ScoredResource("hd_bonusfactor_rp_10", "carry_item", 1.5f),
			ScoredResource("hd_bonusfactor_rp_20", "carry_item", 1.0f),
			ScoredResource("hd_bonusfactor_rp_45", "carry_item", 0.5f),
			ScoredResource("hd_bonusfactor_rp_75", "carry_item", 0.3f),
			ScoredResource("hd_bonusfactor_rp_125", "carry_item", 0.2f),
			ScoredResource("hd_bonusfactor_rp_240", "carry_item", 0.1f)
			}
		};   
    
		processRewardPasses(rewardPasses);

		GiftItemDeliveryRandomRewarder@ rewarder = GiftItemDeliveryRandomRewarder(m_metagame, rewardPasses);

		m_itemDeliveryOrganizer.addObjective(
			ItemDeliveryObjective(m_metagame, 0, deliveryList, m_itemDeliveryOrganizer, null, "", "", "", -1 /* loop */, rewarder)
			);
	}

	// ----------------------------------------------------  
	protected void setupEnemyWeaponUnlocks() {
		array<ItemDeliveryObjective@> objectives = createEnemyWeaponDeliveryObjectives();

		for (uint i = 0; i < objectives.size(); ++i) {
			m_itemDeliveryOrganizer.addObjective(objectives[i]);
		}
	}

	// ----------------------------------------------------
	protected array<Resource@>@ getEnemyWeaponDeliverables() const {
		array<Resource@> results;

		string type = "weapon";
		string typePlural = "weapons";

		// get the stuff we have in stock
		array<const XmlElement@> own = getFactionDeliverables(m_metagame, 0, type, typePlural);
		if (own is null) {
			_log("WARNING, getEnemyWeaponDeliverables, couldn't get own resources", -1);
			return results;
		}

		// get the grand list of deliverable weapons, all of them
		array<Resource@> deliverables = getDeliverablesList();
		for (uint i = 0; i < deliverables.size(); ++i) {
			Resource@ r = deliverables[i];
			// go through the list and only leave the ones in we're interested of, those which we don't have yet
			// check if we have this key
			bool add = true;
			for (uint j = 0; j < own.size(); ++j) {
				const XmlElement@ ownNode = own[j];
				string ownKey = ownNode.getStringAttribute("key");
				if (r.m_key != ownKey) {
					// no match, continue searching
				} else {
					// we already have this, skip it
					add = false;
					break;
				}
			}

			if (add) {
				// ensure it's not already in results
				if (results.findByRef(r) < 0) {
					results.insertLast(r);
				}
			}
		}

		return results;
	}

	// ----------------------------------------------------
	protected array<ItemDeliveryObjective@>@ createEnemyWeaponDeliveryObjectives() const {
		_log("createEnemyWeaponDeliveryObjectives", 1);

		array<ItemDeliveryObjective@> newObjectives;

		string instructions = "enemy item objective instruction";
		string thanks = "enemy item objective thanks";
		string thanksIncomplete = "enemy item objective thanks incomplete";

		// add objective for every enemy weapon not owned by friendlies yet
		array<Resource@>@ enemyWeaponResources = getEnemyWeaponDeliverables();
		for (uint i = 0; i < enemyWeaponResources.size(); ++i) {
			Resource@ resource = enemyWeaponResources[i];
			_log("enemy unlock target " + resource.m_key, 1);
			array<Resource@> deliveryList = {resource};
			// delivering certain amount of specific weapon unlocks that particular weapon
			dictionary unlockList = {
				{resource.m_key, array<Resource@> = {resource}}
			};
			ResourceUnlocker@ unlocker = ResourceUnlocker(m_metagame, 0, unlockList, m_metagame, /* custom stat tracker tag */ "enemy_weapon_delivered");

			int amount = 5;

			ItemDeliveryObjective objective(m_metagame, 0, deliveryList, m_itemDeliveryOrganizer, unlocker, instructions, "", thanks, thanksIncomplete, amount, 0, 50);

			if (m_itemDeliveryOrganizer.getObjectiveById(objective.getId()) is null) {
				newObjectives.insertLast(objective);
			}			
		}

		return newObjectives;
	}

	// ----------------------------------------------------
	protected void refreshEnemyWeaponDeliveryObjectives() {
		// only creates ones that don't already exist
		array<ItemDeliveryObjective@>@ newObjectives = createEnemyWeaponDeliveryObjectives();

		for (uint i = 0; i < newObjectives.size(); ++i) {
			ItemDeliveryObjective@ objective = newObjectives[i];
			m_itemDeliveryOrganizer.addObjective(objective);
			// insta-add tracker
			m_metagame.addTracker(objective);
		}
	}

	// --------------------------------------------
	array<Resource@>@ getUnlockWeaponList() const {
		array<Resource@> list;

		list.push_back(Resource("l85a2.weapon", "weapon"));
		list.push_back(Resource("famasg1.weapon", "weapon"));
		list.push_back(Resource("sg552.weapon", "weapon"));
		list.push_back(Resource("m79.weapon", "weapon"));
		list.push_back(Resource("gl06.weapon", "weapon"));
		list.push_back(Resource("rgm40.weapon", "weapon"));                
		list.push_back(Resource("minig_resource.weapon", "weapon"));
		list.push_back(Resource("desert_eagle.weapon", "weapon"));
		list.push_back(Resource("tow_resource.weapon", "weapon"));   
		list.push_back(Resource("eodvest.carry_item", "carry_item")); 
		list.push_back(Resource("gl_resource.weapon", "weapon"));
		list.push_back(Resource("smaw.weapon", "weapon"));
		list.push_back(Resource("hornet_resource.weapon", "weapon"));        

		return list;
	}

	// --------------------------------------------
	array<Resource@>@ getUnlockWeaponList2() const {
		array<Resource@> list;

		list.push_back(Resource("mp5sd.weapon", "weapon"));
//		list.push_back(Resource("beretta_m9.weapon", "weapon"));
		list.push_back(Resource("scorpion-evo.weapon", "weapon"));
//		list.push_back(Resource("glock17.weapon", "weapon"));
		list.push_back(Resource("qcw-05.weapon", "weapon"));
//		list.push_back(Resource("pb.weapon", "weapon"));    
//    list.push_back(Resource("vest_blackops.carry_item", "carry_item")); 
		list.push_back(MultiGroupResource("vest_blackops.carry_item", "carry_item", array<string> = {"default", "supply"}));
		list.push_back(Resource("apr.weapon", "weapon")); 
//		list.push_back(Resource("mk23.weapon", "weapon")); 
		list.push_back(MultiGroupResource("mk23.weapon", "weapon", array<string> = {"default", "supply"})); 
		list.push_back(MultiGroupResource("shuriken.projectile", "projectile", array<string> = {"supply"})); 
		list.push_back(MultiGroupResource("kunai.projectile", "projectile", array<string> = {"supply"}));                        
		 
		return list;
	}
	


	// --------------------------------------------
	array<Resource@>@ getDeliverablesList() const {
		array<Resource@> list;

		// list here what we want to track as delivering to armory, with intention of unlocking that same item

		// the upgrade weapons, l85a2, famas, sg552, are considered semi-rare, only unlockable through cargo truck & suitcases, see get_unlock_weapon_list
		// in 1.31 we removed the weapons as unlockables that are not dropped by the AI 

		// green weapons
		list.push_back(Resource("m16a4.weapon", "weapon"));
		list.push_back(Resource("m240.weapon", "weapon"));
		list.push_back(Resource("m24_a2.weapon", "weapon"));
		//list.push_back(Resource("mp5sd.weapon", "weapon"));
		list.push_back(Resource("mossberg.weapon", "weapon"));
		//list.push_back(Resource("l85a2.weapon", "weapon"));
		list.push_back(Resource("m72_law.weapon", "weapon"));
		//list.push_back(Resource("beretta_m9.weapon", "weapon"));
		//list.push_back(Resource("mini_uzi.weapon", "weapon"));     

		// grey weapons
		list.push_back(Resource("g36.weapon", "weapon"));
		list.push_back(Resource("imi_negev.weapon", "weapon"));
		list.push_back(Resource("psg90.weapon", "weapon"));
		//list.push_back(Resource("scorpion-evo.weapon", "weapon"));
		list.push_back(Resource("spas-12.weapon", "weapon"));
		//list.push_back(Resource("famasg1.weapon", "weapon"));
		list.push_back(Resource("m2_carlgustav.weapon", "weapon"));
		//list.push_back(Resource("glock17.weapon", "weapon"));
		//list.push_back(Resource("steyr_tmp.weapon", "weapon"));     

		// brown weapons
		list.push_back(Resource("ak47.weapon", "weapon"));
		list.push_back(Resource("pkm.weapon", "weapon"));
		list.push_back(Resource("dragunov_svd.weapon", "weapon"));
		//list.push_back(Resource("qcw-05.weapon", "weapon"));
		list.push_back(Resource("qbs-09.weapon", "weapon"));
		//list.push_back(Resource("sg552.weapon", "weapon"));
		list.push_back(Resource("rpg-7.weapon", "weapon"));
		//list.push_back(Resource("pb.weapon", "weapon")); 
		//list.push_back(Resource("aek_919k.weapon", "weapon"));     

		return list;
	}
}
