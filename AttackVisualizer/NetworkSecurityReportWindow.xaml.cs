using PdfSharp.Drawing;
using PdfSharp.Pdf;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Windows;
using AttackVisualizer.Simulation;

namespace AttackVisualizer
{
    public partial class NetworkSecurityReportWindow : Window
    {
        private readonly SimulationEngine _engine;

        public NetworkSecurityReportWindow(SimulationEngine engine)
        {
            InitializeComponent();
            _engine = engine;
            BuildReports();
        }

        // ================= BUILD THEORETICAL REPORT =================
        private void BuildReports()
        {
            var assets = _engine.Assets.Select(a => a.Name).ToList();
            var sb = new System.Text.StringBuilder();

            sb.AppendLine("=== INITIAL REPORT ===");
            sb.AppendLine("No assets have been added yet.");
            sb.AppendLine();

            // Single asset reports
            foreach (var asset in assets)
            {
                sb.AppendLine($"=== REPORT AFTER ADDING {asset.ToUpper()} ===");
                sb.AppendLine(GenerateReport(new List<string> { asset }));
                sb.AppendLine();
            }

            // Pairwise asset reports
            for (int i = 0; i < assets.Count; i++)
            {
                for (int j = i + 1; j < assets.Count; j++)
                {
                    var pair = new List<string> { assets[i], assets[j] };
                    sb.AppendLine($"=== REPORT AFTER ADDING {assets[i].ToUpper()} + {assets[j].ToUpper()} ===");
                    sb.AppendLine(GenerateReport(pair));
                    sb.AppendLine();
                }
            }

            // ✅ CORRECT CONTROL
            ReportBox.Text = sb.ToString();
        }

        // ================= REPORT LOGIC =================
        private string GenerateReport(List<string> activeAssets)
        {
            var sb = new System.Text.StringBuilder();
            sb.AppendLine($"Assets Active: {string.Join(", ", activeAssets)}");

            if (activeAssets.Contains("RedTeam01"))
                sb.AppendLine("- Threat Actor detected in network.");

            if (activeAssets.Contains("FortiGate"))
                sb.AppendLine("- Firewall is operational.");

            if (activeAssets.Contains("DefenderAV"))
                sb.AppendLine("- Endpoint protection active.");

            if (activeAssets.Contains("DB-Prod-01"))
                sb.AppendLine("- Corporate database online.");

            int risk = 1;
            if (activeAssets.Contains("RedTeam01")) risk = 2;
            if (activeAssets.Contains("RedTeam01") && activeAssets.Contains("DB-Prod-01")) risk = 3;
            if (activeAssets.Contains("RedTeam01") &&
                (activeAssets.Contains("FortiGate") || activeAssets.Contains("DefenderAV")))
                risk = 1;

            sb.AppendLine($"Network Risk Level: {(risk == 1 ? "Low" : risk == 2 ? "Medium" : "High")}");

            sb.AppendLine("Recommendations:");
            if (!activeAssets.Contains("FortiGate")) sb.AppendLine("- Add firewall appliance.");
            if (!activeAssets.Contains("DefenderAV")) sb.AppendLine("- Add endpoint protection.");
            if (activeAssets.Contains("RedTeam01")) sb.AppendLine("- Monitor threat actor activity.");

            return sb.ToString().TrimEnd();
        }

        // ================= PDF EXPORT =================
        private void ExportPdf_Click(object sender, RoutedEventArgs e)
        {
            try
            {
                var doc = new PdfDocument();
                var page = doc.AddPage();
                var gfx = XGraphics.FromPdfPage(page);
                var font = new XFont("Consolas", 10);

                double y = 20;
                foreach (string line in ReportBox.Text.Split('\n'))
                {
                    gfx.DrawString(line, font, XBrushes.Black,
                        new XRect(20, y, page.Width - 40, page.Height));
                    y += 14;

                    if (y > page.Height - 40)
                    {
                        page = doc.AddPage();
                        gfx = XGraphics.FromPdfPage(page);
                        y = 20;
                    }
                }

                string path = Path.Combine(
                    Environment.GetFolderPath(Environment.SpecialFolder.Desktop),
                    "NetworkSecurityReport.pdf");

                doc.Save(path);
                MessageBox.Show("PDF saved to Desktop.");

                System.Diagnostics.Process.Start(new System.Diagnostics.ProcessStartInfo(path)
                {
                    UseShellExecute = true
                });
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message);
            }
        }

        private void Close_Click(object sender, RoutedEventArgs e)
        {
            this.Close();
        }
    }
}
