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
            var asset = Assets.FirstOrDefault(a => a.Type == type);
            if (asset == null) return false;
            Assets.Remove(asset);
            return true;
        }

        public async Task RunAsync(Action<string> log)
        {
            RiskScore = 0;

            foreach (var asset in Assets)
            {
                await Task.Delay(400);

                if (asset.Type == AssetType.Attacker)
                {
                    log("Threat Actor attempting intrusion...");
                    RiskScore += 40;
                }
                else if (asset.Type == AssetType.Firewall)
                {
                    log("Firewall inspecting traffic...");
                    RiskScore -= 10;
                }
                else if (asset.Type == AssetType.Endpoint)
                {
                    log("Endpoint Protection scanning malware...");
                    RiskScore -= 15;
                }
                else if (asset.Type == AssetType.Server)
                {
                    log("Corporate Database exposed.");
                    RiskScore += 25;
                }
            }

            RiskScore = Math.Clamp(RiskScore, 0, 100);
        }
    }
}
