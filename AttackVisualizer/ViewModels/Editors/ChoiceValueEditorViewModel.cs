using NodeNetwork.ViewModels;
using ReactiveUI;
using System.Collections.ObjectModel;
using System.Linq;

namespace AttackVisualizer.ViewModels.Editors
{
    public class ChoiceValueEditorViewModel : NodeEndpointEditorViewModel
    {
        public ObservableCollection<string> Choices { get; } = new ObservableCollection<string>();

        // FIX: Initialize with string.Empty to silence the warning
        private string _value = string.Empty;
        public string Value
        {
            get => _value;
            set => this.RaiseAndSetIfChanged(ref _value, value);
        }

        public ChoiceValueEditorViewModel(params string[] choices)
        {
            foreach (var c in choices) Choices.Add(c);
            // Ensure Value is never null, even if choices are empty
            Value = choices.FirstOrDefault() ?? string.Empty;
        }
    }
}