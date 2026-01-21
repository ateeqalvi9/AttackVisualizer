using AttackVisualizer.ViewModels.Editors;
using ReactiveUI;
using System.Windows;
using System.Windows.Controls;

namespace AttackVisualizer.View
{
    public partial class ChoiceValueEditorView : UserControl, IViewFor<ChoiceValueEditorViewModel>
    {
        public ChoiceValueEditorView()
        {
            InitializeComponent();
            this.WhenActivated(d => {
                d(this.OneWayBind(ViewModel, vm => vm.Choices, v => v.DataContext));
                d(this.Bind(ViewModel, vm => vm.Value, v => v.DataContext));
            });
        }

        public ChoiceValueEditorViewModel ViewModel
        {
            get => (ChoiceValueEditorViewModel)GetValue(ViewModelProperty);
            set => SetValue(ViewModelProperty, value);
        }

        public static readonly DependencyProperty ViewModelProperty =
            DependencyProperty.Register(nameof(ViewModel), typeof(ChoiceValueEditorViewModel), typeof(ChoiceValueEditorView));

        object IViewFor.ViewModel
        {
            get => ViewModel;
            set => ViewModel = (ChoiceValueEditorViewModel)value;
        }
    }
}