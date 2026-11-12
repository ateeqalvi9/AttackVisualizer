using AttackVisualizer.Core;
using AttackVisualizer.Simulation;

namespace AttackVisualizer.Tests;

public class SimulationEngineTests
{
    [Fact]
    public void AddAsset_ShouldAddAssetToList()
    {
        var engine = new SimulationEngine();

        engine.AddAsset(AssetType.Attacker);

        Assert.Single(engine.Assets);
        Assert.Equal(AssetType.Attacker, engine.Assets[0].Type);
    }

    [Fact]
    public void RemoveAsset_WhenAssetExists_ShouldRemoveAndReturnTrue()
    {
        var engine = new SimulationEngine();
        engine.AddAsset(AssetType.Firewall);

        bool result = engine.RemoveAsset(AssetType.Firewall);

        Assert.True(result);
        Assert.Empty(engine.Assets);
    }

    [Fact]
    public void RemoveAsset_WhenAssetDoesNotExist_ShouldReturnFalse()
    {
        var engine = new SimulationEngine();

        bool result = engine.RemoveAsset(AssetType.Server);

        Assert.False(result);
    }

    [Fact]
    public async Task RunAsync_ShouldCalculateCorrectScore()
    {
        var engine = new SimulationEngine();
        engine.AddAsset(AssetType.Attacker); // +40
        engine.AddAsset(AssetType.Server);   // +25
        engine.AddAsset(AssetType.Firewall); // -10

        var logs = new List<string>();
        await engine.RunAsync(msg => logs.Add(msg));

        // 40 + 25 - 10 = 55
        Assert.Equal(55, engine.RiskScore);
        Assert.Equal(3, logs.Count);
    }
}

public class AssetTests
{
    [Fact]
    public void IncreaseRisk_ShouldClampTo100()
    {
        var asset = new Asset(AssetType.Endpoint);
        asset.RiskScore = 90;

        asset.IncreaseRisk(20);

        Assert.Equal(100, asset.RiskScore);
    }
}
