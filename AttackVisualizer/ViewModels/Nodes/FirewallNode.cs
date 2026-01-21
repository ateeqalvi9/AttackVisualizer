using DynamicData;
using NodeNetwork.Toolkit.ValueNode;
using NodeNetwork.ViewModels;
using ReactiveUI;

namespace AttackVisualizer.ViewModels.Nodes
{
    public class FirewallNode : NodeViewModel
    {
        public ValueNodeInputViewModel<string> TrafficIn { get; }
        public ValueNodeOutputViewModel<string> TrafficOut { get; }

        public FirewallNode()
        {
            Name = "Firewall";

            TrafficIn = new ValueNodeInputViewModel<string>
            {
                Name = "Incoming"
            };

            TrafficOut = new ValueNodeOutputViewModel<string>
            {
                Name = "Filtered",
                Value = TrafficIn.WhenAnyValue(x => x.Value)
            };

            Inputs.Add(TrafficIn);
            Outputs.Add(TrafficOut);
        }
    }
}
