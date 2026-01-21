using ReactiveUI;

namespace AttackVisualizer.ViewModels.Editors
{
    public class StringValueEditorViewModel : ReactiveObject
    {
        private string value;

        public string Value
        {
            get => value;
            set => this.RaiseAndSetIfChanged(ref this.value, value);
        }

        public StringValueEditorViewModel(string initial)
        {
            Value = initial;
        }
    }
}
