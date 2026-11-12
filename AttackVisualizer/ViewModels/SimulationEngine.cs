using AttackVisualizer.Core;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace AttackVisualizer.Simulation
{
    public class SimulationEngine
    {
        public List<Asset> Assets { get; } = new();
        public int RiskScore { get; private set; }

        public void AddAsset(AssetType type)
        {
            Assets.Add(new Asset(type));
        }

        public bool RemoveAsset(AssetType type)
        {
            int index = Assets.FindIndex(a => a.Type == type);
            if (index == -1) return false;
            Assets.RemoveAt(index);
            return true;
        }

        public async Task RunAsync(Action<string> log)
        {
            RiskScore = 0;

            foreach (var asset in Assets)
            {
                await Task.Delay(400);

                switch (asset.Type)
                {
                    case AssetType.Attacker:
                        log("Threat Actor attempting intrusion...");
                        RiskScore += 40;
                        break;
                    case AssetType.Firewall:
                        log("Firewall inspecting traffic...");
                        RiskScore -= 10;
                        break;
                    case AssetType.Endpoint:
                        log("Endpoint Protection scanning malware...");
                        RiskScore -= 15;
                        break;
                    case AssetType.Server:
                        log("Corporate Database exposed.");
                        RiskScore += 25;
                        break;
                }
            }

            RiskScore = Math.Clamp(RiskScore, 0, 100);
        }
    }
}
