using System;
using Xunit;
using AttackVisualizer.Core;

namespace AttackVisualizer.Tests
{
    public class AssetTests
    {
        [Fact]
        public void Asset_Initialization_SetsPropertiesCorrectly()
        {
            var asset = new Asset(AssetType.Firewall);

            Assert.Equal(AssetType.Firewall, asset.Type);
            Assert.Equal("Firewall", asset.Name);
            Assert.Equal(0, asset.RiskScore);
        }

        [Fact]
        public void Asset_IncreaseRisk_UpdatesRiskScore()
        {
            var asset = new Asset(AssetType.Server);

            asset.IncreaseRisk(30);

            Assert.Equal(30, asset.RiskScore);
        }

        [Fact]
        public void Asset_IncreaseRisk_CapsAt100()
        {
            var asset = new Asset(AssetType.Endpoint);

            asset.IncreaseRisk(120);

            Assert.Equal(100, asset.RiskScore);
        }

        [Fact]
        public void Asset_ToString_ReturnsTypeName()
        {
            var asset = new Asset(AssetType.Attacker);

            Assert.Equal("Attacker", asset.ToString());
        }
    }
}
