using System;
using Xunit;
using AttackVisualizer.Core;

namespace AttackVisualizer.Tests
{
    public class AssetTypeTests
    {
        [Fact]
        public void AssetType_HasExpectedValues()
        {
            var expectedValues = new[] { "Attacker", "Firewall", "Endpoint", "Server" };
            foreach (var expected in expectedValues)
            {
                var parsed = Enum.TryParse<AssetType>(expected, out var result);
                Assert.True(parsed, $"Expected AssetType {expected} to exist.");
            }
        }
    }
}
