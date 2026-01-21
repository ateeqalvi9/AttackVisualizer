using AttackVisualizer.ViewModels.Editors;
using DynamicData;
using NodeNetwork.Toolkit.ValueNode;
using NodeNetwork.ViewModels;
using ReactiveUI;

namespace AttackVisualizer.ViewModels.Nodes
{
    public class AttackerNode : NodeViewModel
    {
        public StringValueEditorViewModel AttackType { get; }
        public ValueNodeOutputViewModel<string> AttackOutput { get; }

        public AttackerNode()
        {
            Name = "Attacker";

            AttackType = new StringValueEditorViewModel("SQL");

            AttackOutput = new ValueNodeOutputViewModel<string>
            {
                Name = "Attack",

                // 🔥 THIS CREATES AN OBSERVABLE
                Value = AttackType.WhenAnyValue(x => x.Value)
            };

            Outputs.Add(AttackOutput);
        }
    }
}
