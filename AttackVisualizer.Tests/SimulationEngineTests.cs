using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Xunit;
using AttackVisualizer.Core;
using AttackVisualizer.Simulation;

namespace AttackVisualizer.Tests
{
    public class SimulationEngineTests
    {
        [Fact]
        public void AddAsset_AddsAssetToCollection()
        {
            var engine = new SimulationEngine();

            engine.AddAsset(AssetType.Attacker);

            Assert.Single(engine.Assets);
            Assert.Equal(AssetType.Attacker, engine.Assets[0].Type);
        }

        [Fact]
        public void RemoveAsset_ExistingAsset_RemovesAndReturnsTrue()
        {
            var engine = new SimulationEngine();
            engine.AddAsset(AssetType.Firewall);

            bool result = engine.RemoveAsset(AssetType.Firewall);

            Assert.True(result);
            Assert.Empty(engine.Assets);
        }

        [Fact]
        public void RemoveAsset_NonExistingAsset_ReturnsFalse()
        {
            var engine = new SimulationEngine();
            engine.AddAsset(AssetType.Firewall);

            bool result = engine.RemoveAsset(AssetType.Server);

            Assert.False(result);
            Assert.Single(engine.Assets);
        }

        [Fact]
        public async Task RunAsync_CalculatesCorrectRiskScore()
        {
            var engine = new SimulationEngine();
            engine.AddAsset(AssetType.Attacker); // +40
            engine.AddAsset(AssetType.Firewall); // -10
            engine.AddAsset(AssetType.Server);   // +25

            var logs = new List<string>();

            await engine.RunAsync(msg => logs.Add(msg));

            // Initial 0 + 40 - 10 + 25 = 55
            Assert.Equal(55, engine.RiskScore);
            Assert.Equal(3, logs.Count);
        }

        [Fact]
        public async Task RunAsync_CapsRiskScoreAtZeroAndOneHundred()
        {
            var engineHigh = new SimulationEngine();
            engineHigh.AddAsset(AssetType.Attacker); // +40
            engineHigh.AddAsset(AssetType.Attacker); // +40
            engineHigh.AddAsset(AssetType.Attacker); // +40
            // Total should be capped at 100

            await engineHigh.RunAsync(_ => { });

            Assert.Equal(100, engineHigh.RiskScore);

            var engineLow = new SimulationEngine();
            engineLow.AddAsset(AssetType.Firewall); // -10
            // Total should be capped at 0 (Math.Clamp(score, 0, 100))

            await engineLow.RunAsync(_ => { });

            Assert.Equal(0, engineLow.RiskScore);
        }
    }
}
