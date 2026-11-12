using ReactiveUI;

namespace AttackVisualizer.ViewModels.Editors
{
    public class StringValueEditorViewModel : ReactiveObject
    {
        private string _value = string.Empty;

        public string Value
        {
            get => _value;
            set => this.RaiseAndSetIfChanged(ref _value, value);
        }

        public StringValueEditorViewModel(string initial)
        {
            Value = initial;
        }
    }
}
