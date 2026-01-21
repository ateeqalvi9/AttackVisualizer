using DynamicData;
using NodeNetwork.Toolkit.ValueNode;
using NodeNetwork.ViewModels;
using ReactiveUI;

namespace AttackVisualizer.ViewModels.Nodes
{
    public class ServerNode : NodeViewModel
    {
        public ValueNodeInputViewModel<string> TrafficIn { get; }

        private bool isCompromised;
        public bool IsCompromised
        {
            get => isCompromised;
            set => this.RaiseAndSetIfChanged(ref isCompromised, value);
        }

        public ServerNode()
        {
            Name = "Server";

            TrafficIn = new ValueNodeInputViewModel<string>
            {
                Name = "Traffic"
            };

            TrafficIn.ValueChanged.Subscribe(v =>
            {
                IsCompromised = (v == "SQL");
            });

            Inputs.Add(TrafficIn);
        }
    }
}
