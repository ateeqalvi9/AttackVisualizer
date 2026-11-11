using System.Collections.Generic;
using System.Threading.Tasks;
using Xunit;
using AttackVisualizer.Simulation;
using AttackVisualizer.Core;

namespace AttackVisualizer.Tests
{
    public class SimulationEngineTests
    {
        [Fact]
        public void Engine_AddAsset_AddsToCollection()
        {
            var engine = new SimulationEngine();
            engine.AddAsset(AssetType.Server);
            Assert.Single(engine.Assets);
            Assert.Equal(AssetType.Server, engine.Assets[0].Type);
        }

        [Fact]
        public void Engine_RemoveAsset_RemovesFromCollection()
        {
            var engine = new SimulationEngine();
            engine.AddAsset(AssetType.Server);
            var removed = engine.RemoveAsset(AssetType.Server);

            Assert.True(removed);
            Assert.Empty(engine.Assets);
        }

        [Fact]
        public async Task Engine_RunAsync_UpdatesRiskScore()
        {
            var engine = new SimulationEngine();
            engine.AddAsset(AssetType.Attacker); // +40
            engine.AddAsset(AssetType.Firewall); // -10

            var logs = new List<string>();
            await engine.RunAsync(logs.Add);

            Assert.Equal(30, engine.RiskScore);
            Assert.Equal(2, logs.Count);
        }

        [Fact]
        public async Task Engine_RunAsync_RiskScoreDoesNotGoBelowZero()
        {
            var engine = new SimulationEngine();
            // Start with strong defense, no attack
            engine.AddAsset(AssetType.Firewall); // -10
            engine.AddAsset(AssetType.Endpoint); // -15

            var logs = new List<string>();
            await engine.RunAsync(logs.Add);

            Assert.Equal(0, engine.RiskScore); // Should clamp to 0 instead of -25
        }
    }
}
