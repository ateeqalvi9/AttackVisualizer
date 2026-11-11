using System;
using Xunit;
using AttackVisualizer.Core;

namespace AttackVisualizer.Tests
{
    public class AssetTests
    {
        [Fact]
        public void Asset_Initialization_CorrectValues()
        {
            var asset = new Asset(AssetType.Server);
            Assert.Equal(AssetType.Server, asset.Type);
            Assert.Equal("Server", asset.Name);
            Assert.Equal(0, asset.RiskScore);
        }

        [Fact]
        public void Asset_IncreaseRisk_UpdatesRiskScore()
        {
            var asset = new Asset(AssetType.Server);
            asset.IncreaseRisk(10);
            Assert.Equal(10, asset.RiskScore);
        }

        [Fact]
        public void Asset_IncreaseRisk_CapsAt100()
        {
            var asset = new Asset(AssetType.Server);
            asset.IncreaseRisk(150);
            Assert.Equal(100, asset.RiskScore);
        }
    }
}
