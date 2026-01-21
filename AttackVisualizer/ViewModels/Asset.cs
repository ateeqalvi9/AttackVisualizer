using AttackVisualizer.Core;

namespace AttackVisualizer.Core
{
    public class Asset
    {
        public string Name { get; set; }
        public AssetType Type { get; }
        public int RiskScore { get; set; }

        public Asset(AssetType type)
        {
            Type = type;
            Name = type.ToString();
            RiskScore = 0;
        }

        public override string ToString() => Type.ToString();
        public void IncreaseRisk(int value)
        {
            RiskScore += value;
            if (RiskScore > 100)
                RiskScore = 100;
        }
    }
}
