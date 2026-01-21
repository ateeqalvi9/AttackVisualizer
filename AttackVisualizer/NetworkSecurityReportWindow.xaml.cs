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
            var reportLines = new List<string>();

            reportLines.Add("=== INITIAL REPORT ===");
            reportLines.Add("No assets have been added yet.\n");

            // Single asset reports
            foreach (var asset in assets)
            {
                reportLines.Add($"=== REPORT AFTER ADDING {asset.ToUpper()} ===");
                reportLines.Add(GenerateReport(new List<string> { asset }));
                reportLines.Add("");
            }

            // Pairwise asset reports
            for (int i = 0; i < assets.Count; i++)
            {
                for (int j = i + 1; j < assets.Count; j++)
                {
                    var pair = new List<string> { assets[i], assets[j] };
                    reportLines.Add($"=== REPORT AFTER ADDING {assets[i].ToUpper()} + {assets[j].ToUpper()} ===");
                    reportLines.Add(GenerateReport(pair));
                    reportLines.Add("");
                }
            }

            // ✅ CORRECT CONTROL
            ReportBox.Text = string.Join("\n", reportLines);
        }

        // ================= REPORT LOGIC =================
        private string GenerateReport(List<string> activeAssets)
        {
            string report = $"Assets Active: {string.Join(", ", activeAssets)}\n";

            if (activeAssets.Contains("RedTeam01"))
                report += "- Threat Actor detected in network.\n";

            if (activeAssets.Contains("FortiGate"))
                report += "- Firewall is operational.\n";

            if (activeAssets.Contains("DefenderAV"))
                report += "- Endpoint protection active.\n";

            if (activeAssets.Contains("DB-Prod-01"))
                report += "- Corporate database online.\n";

            int risk = 1;
            if (activeAssets.Contains("RedTeam01")) risk = 2;
            if (activeAssets.Contains("RedTeam01") && activeAssets.Contains("DB-Prod-01")) risk = 3;
            if (activeAssets.Contains("RedTeam01") &&
                (activeAssets.Contains("FortiGate") || activeAssets.Contains("DefenderAV")))
                risk = 1;

            report += $"Network Risk Level: {(risk == 1 ? "Low" : risk == 2 ? "Medium" : "High")}\n";

            report += "Recommendations:\n";
            if (!activeAssets.Contains("FortiGate")) report += "- Add firewall appliance.\n";
            if (!activeAssets.Contains("DefenderAV")) report += "- Add endpoint protection.\n";
            if (activeAssets.Contains("RedTeam01")) report += "- Monitor threat actor activity.\n";

            return report;
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
