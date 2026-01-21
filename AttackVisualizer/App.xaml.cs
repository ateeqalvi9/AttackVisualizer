using System.Windows;
using ReactiveUI;
using Splat;
using NodeNetwork;
using AttackVisualizer.ViewModels.Editors; // Required
using AttackVisualizer.View; // Required

namespace AttackVisualizer
{
    public partial class App : Application
    {
        protected override void OnStartup(StartupEventArgs e)
        {
            base.OnStartup(e);

            // 1. Register NodeNetwork Grid
            Locator.CurrentMutable.Register(() => new NodeNetwork.Views.NetworkView(), typeof(IViewFor<NodeNetwork.ViewModels.NetworkViewModel>));

            // 2. Register Your New Dropdown (CRITICAL STEP)
            Locator.CurrentMutable.Register(() => new ChoiceValueEditorView(), typeof(IViewFor<ChoiceValueEditorViewModel>));
        }
    }
}