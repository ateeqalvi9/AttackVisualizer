using AttackVisualizer.ViewModels.Editors;
using ReactiveUI;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;

namespace AttackVisualizer.View
{
    /// <summary>
    /// Interaction logic for StringValueEditorView.xaml
    /// </summary>
    public partial class StringValueEditorView : UserControl, IViewFor<StringValueEditorViewModel>
    {
        public StringValueEditorView()
        {
            InitializeComponent();
        }
        object IViewFor.ViewModel
        {
            get => ViewModel;
            set => ViewModel = (StringValueEditorViewModel)value;
        }

        public StringValueEditorViewModel ViewModel { get; set; }
    }
}
