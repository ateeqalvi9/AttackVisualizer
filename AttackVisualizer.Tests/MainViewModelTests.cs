using Xunit;
using AttackVisualizer.ViewModels;
using System.Linq;

namespace AttackVisualizer.Tests
{
    public class MainViewModelTests
    {
        [Fact]
        public void MainViewModel_Initialization_PopulatesNetworkNodes()
        {
            var vm = new MainViewModel();

            Assert.NotNull(vm.Network);
            Assert.Equal(3, vm.Network.Nodes.Count);

            var nodeNames = vm.Network.Nodes.Items.Select(n => n.Name).ToList();
            Assert.Contains("Attacker", nodeNames);
            Assert.Contains("Firewall", nodeNames);
            Assert.Contains("Server", nodeNames);
        }
    }
}
