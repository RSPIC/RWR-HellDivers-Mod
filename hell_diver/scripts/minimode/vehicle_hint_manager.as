#include "tracker.as"
#include "admin_manager.as"
#include "log.as"
#include "query_helpers.as"

// --------------------------------------------
class VehicleHintManager : Tracker {
	protected GameModeMiniModes@ m_metagame;
	protected string m_vehicleKey = "";
	protected string m_intelText = "";
	protected string m_destroyedText = "";
	protected int m_factionId = 0;
	protected string m_mode = "region"; 
	protected bool m_makeSpotted = false;

	// ----------------------------------------------------
	// mode = "region" or "base"
	VehicleHintManager(GameModeMiniModes@ metagame, string vehicleKey, string intelText, string destroyedText, int factionId = 0, string mode = "region", bool makeSpotted = false) {
		@m_metagame = @metagame;
		m_vehicleKey = vehicleKey;
		m_intelText = intelText;
		m_destroyedText = destroyedText;
		m_factionId = factionId;
		m_mode = mode;
		m_makeSpotted = makeSpotted;
	}

	// ----------------------------------------------------
	bool hasStarted() const {
		return true;
	}

	// ----------------------------------------------------
	bool hasEnded() const {
		return false;
	}

	// ----------------------------------------------------
	protected void handleVehicleSpawnEvent(const XmlElement@ event) {
		// vehicle_id
		string key = event.getStringAttribute("vehicle_key");
		if (key == m_vehicleKey) {
			_log("vehicle hint manager, new vehicle spawned", 1);
			// create hint tracker
			int vehicleId = event.getIntAttribute("vehicle_id");
			int factionId = event.getIntAttribute("faction_id");
			VehicleHint@ tracker = VehicleHint(m_metagame, vehicleId, m_intelText, m_destroyedText, factionId, m_mode, m_makeSpotted);
			// register it
			m_metagame.addTracker(tracker);
		}
	}

}

// --------------------------------------------
class VehicleHint : Tracker {
	protected GameModeMiniModes@ m_metagame;
	protected float m_waitForNewIntelTimer = 1.0; // start with a slight delay
	protected int m_trackedVehicleId = -1;
	protected string m_latestIntelText = "";
	protected string m_preIntelText = "";
	protected string m_destroyedText = "";
	protected int m_factionId = 0; 
	protected string m_mode = "region"; 
	protected bool m_makeSpotted = false;
	protected bool m_started = false;

	protected float MIN_WAIT_INTEL_TIME = 120.0;
	protected float MAX_WAIT_INTEL_TIME = 300.0;

	// ----------------------------------------------------
	VehicleHint(GameModeMiniModes@ metagame, int vehicleId, string preIntelText, string destroyedText, int factionId = 0, string mode = "region", bool makeSpotted = false) {
		@m_metagame = @metagame;
		m_trackedVehicleId = vehicleId;
		m_preIntelText = preIntelText;
		m_destroyedText = destroyedText;
		m_factionId = factionId;
		m_mode = mode;
		m_makeSpotted = makeSpotted;
	}

    // ----------------------------------------------------
	void update(float time) {
		_log(" * delivery, intel timer: " + m_waitForNewIntelTimer, 1);
		m_waitForNewIntelTimer -= time;
		if (m_waitForNewIntelTimer < 0.0) {
			// resets the timer
			const XmlElement@ vehicleInfo = getVehicleInfo(m_metagame, m_trackedVehicleId);
			if (vehicleInfo is null) {
				m_trackedVehicleId = -1;
			} else if (vehicleInfo.getIntAttribute("id") != 0) {
				m_trackedVehicleId = -1;
			} else {
				m_latestIntelText = getIntelText(vehicleInfo);
				instructObjective();
			}
		}
	}

	// ----------------------------------------------------
	void start() {
		if (m_makeSpotted) {
			// spot for all factions
			for (uint i = 0; i < m_metagame.getFactions().length(); ++i) {
				string command = "<command class='set_spotting' vehicle_id='" + m_trackedVehicleId + "' faction_id='" + i + "' />";
				m_metagame.getComms().send(command);
			}
		}
		m_started = true;
	}

	// ----------------------------------------------------
	bool hasStarted() const {
		return m_started;
	}

	// ----------------------------------------------------
	bool hasEnded() const {
		return m_trackedVehicleId == -1;
	}

	// ----------------------------------------------------
	protected void handleVehicleDestroyedEvent(const XmlElement@ event) {
		// vehicle_id
		if (event.getIntAttribute("vehicle_id") == m_trackedVehicleId) {
			// crate was destroyed, stop this tracker
			m_trackedVehicleId = -1;

			// TODO: use keyed messages instead

			// announce the message now
			if (m_latestIntelText != "" &&
			    m_destroyedText != "") {
				sendFactionMessage(m_metagame, m_factionId, m_destroyedText + m_latestIntelText);
			}
		}
	}

	// --------------------------------------------------------
	void instructObjective() {
		// TODO: use keyed messages instead

		// announce the message now
		sendFactionMessage(m_metagame, m_factionId, m_preIntelText + m_latestIntelText);
		m_waitForNewIntelTimer = rand(MIN_WAIT_INTEL_TIME, MAX_WAIT_INTEL_TIME);
	}

	// --------------------------------------------------------
	string getIntelText(const XmlElement@ vehicleInfo) {
		string text = "";
		Vector3 pos = stringToVector3(vehicleInfo.getStringAttribute("position"));
		if (m_mode == "region") {
			string regionText = m_metagame.getRegion(pos);
			text = regionText + " region";

		} else if (m_mode == "base") {
			float distance = 0.0;
			const XmlElement@ base = getClosestBase(m_metagame, pos, distance);
			string locationText = ".. somewhere";
			if (base !is null) {
				string baseName = base.getStringAttribute("name");
				locationText = baseName;
				/*
				locationText = "in " + baseName;
				if (distance > 50.0) {
					locationText = "near " + baseName;
				}
				*/
			}

			text = locationText + " area";
		}

		return text;
	}


}