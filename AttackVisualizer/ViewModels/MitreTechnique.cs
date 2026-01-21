namespace AttackVisualizer.Simulation
{
    public class MitreTechnique
    {
        public string Id { get; set; }
        public string Name { get; set; }
        public string Tactic { get; set; }

        public MitreTechnique(string id, string name, string tactic)
        {
            Id = id;
            Name = name;
            Tactic = tactic;
        }
    }
}
