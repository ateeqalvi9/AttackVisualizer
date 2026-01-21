using AttackVisualizer.Core;
using AttackVisualizer.Simulation;
using Microsoft.VisualBasic;
using System;
using System.Linq;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using System.Windows.Media.Animation;
using System.Windows.Shapes;
using NodeNetwork.ViewModels;
using ReactiveUI;
using DynamicData;


namespace AttackVisualizer
{
    public partial class MainWindow : Window
    {
        private readonly SimulationEngine _engine = new();

        public MainWindow()
        {
            InitializeComponent();
            Log("CyberVis system initialized.");
        }

        private void Log(string msg)
        {
            LogBox.Items.Add($"[{DateTime.Now:HH:mm:ss}] {msg}");
            LogBox.ScrollIntoView(LogBox.Items[^1]);
        }

        private void AddAttacker_Click(object sender, RoutedEventArgs e)
        {
            _engine.AddAsset(AssetType.Attacker);
            Log("Threat Actor added.");
        }

        private void AddFirewall_Click(object sender, RoutedEventArgs e)
        {
            _engine.AddAsset(AssetType.Firewall);
            Log("Firewall added.");
        }

        private void AddAV_Click(object sender, RoutedEventArgs e)
        {
            _engine.AddAsset(AssetType.Endpoint);
            Log("Endpoint Protection added.");
        }

        private void AddServer_Click(object sender, RoutedEventArgs e)
        {
            _engine.AddAsset(AssetType.Server);
            Log("Corporate Database added.");
        }

        private void RemoveAssets_Click(object sender, RoutedEventArgs e)
        {
            string promtp = "Enter asset to remove:\n" +
                            "Attacker\n" +
                            "Firewall\n" +
                            "Endpoint\n" +
                            "Server";
            string input = Interaction.InputBox(promtp, "Remove Asset");

            if (!Enum.TryParse(input, true, out AssetType type))
            {
                MessageBox.Show("Invalid asset.");
                return;
            }

            if (_engine.RemoveAsset(type))
                Log($"{type} removed.");
            else
                MessageBox.Show("Asset not found.");
        }

        private async void RunSimulation_Click(object sender, RoutedEventArgs e)
        {
            Log("Simulation started...");
            DrawAttackPath();
            await _engine.RunAsync(Log);
            Log($"Simulation completed. Risk Score: {_engine.RiskScore}%");
        }

        private void ExportReport_Click(object sender, RoutedEventArgs e)
        {
            new NetworkSecurityReportWindow(_engine).ShowDialog();
        }

        private void DrawAttackPath()
        {
            AttackCanvas.Children.Clear();
            double x = 120, y = 250;

            foreach (var asset in _engine.Assets)
            {
                var node = new Ellipse
                {
                    Width = 40,
                    Height = 40,
                    Fill = asset.Type switch
                    {
                        AssetType.Attacker => Brushes.Red,
                        AssetType.Firewall => Brushes.Orange,
                        AssetType.Endpoint => Brushes.DeepSkyBlue,
                        _ => Brushes.LimeGreen
                    }
                };

                Canvas.SetLeft(node, x);
                Canvas.SetTop(node, y);
                AttackCanvas.Children.Add(node);
                x += 150;
            }
        }
    }
}
