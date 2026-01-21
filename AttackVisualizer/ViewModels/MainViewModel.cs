using AttackVisualizer.ViewModels.Nodes;
using DynamicData;
using NodeNetwork.ViewModels;
using ReactiveUI;
using System.Reactive;

namespace AttackVisualizer.ViewModels
{
    public class MainViewModel : BaseViewModel
    {
        public NetworkViewModel Network { get; } = new NetworkViewModel();

        public ReactiveCommand<Unit, Unit> ExecuteSimulationCommand { get; }

        public MainViewModel()
        {
            var attacker = new AttackerNode();
            var firewall = new FirewallNode();
            var server = new ServerNode();

            Network.Nodes.Add(attacker);
            Network.Nodes.Add(firewall);
            Network.Nodes.Add(server);

            ExecuteSimulationCommand = ReactiveCommand.Create(() => { });
        }
    }
}
