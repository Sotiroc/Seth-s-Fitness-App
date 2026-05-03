enum UnitSystem {
  metric('Metric (kg, cm)', 'kg', 'cm'),
  imperial('Imperial (lb, ft/in)', 'lb', 'ft/in');

  const UnitSystem(this.label, this.weightUnit, this.heightUnit);

  final String label;
  final String weightUnit;
  final String heightUnit;
}
