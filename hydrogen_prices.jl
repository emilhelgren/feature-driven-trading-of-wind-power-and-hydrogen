eta_storage = 0.88          # From technology data storage
MWh_per_kg_output = 1 / 20  # From technology data renewable fuels p. 107: 1 MW AEC => 20 kg hydrogen
MWh_per_kg_total = MWh_per_kg_output / eta_storage

hydrogen_price = 2.0 / MWh_per_kg_total # 35.2