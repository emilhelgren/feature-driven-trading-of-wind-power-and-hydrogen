

mscf_to_kg = 1000 / 423.3 # multiply this number on a value in mscf to get the value in kg
eta_storage = 0.88 # From technology data storage
MWh_per_kg_output = 1 / 20 # From technology data renewable fuels p. 107: 1 MW AEC => 20 kg hydrogen

MWh_per_kg_total = MWh_per_kg_output / eta_storage


### All costs in [$/mscf] from example2
fixed_cost = 0.625
capital_cost = 1.435
variable_cost = 0.52 * 3 - 0.54 + 0.03 + 0.07 # 52% of natural gas cost per mmbtu - revenue from steam benefit + power cost + chemical cost
variable_cost = 0.07 - 0.54 # We don't have natural gas cost or power cost
dollars_per_mscf = fixed_cost + capital_cost + variable_cost
dollars_per_kg = dollars_per_mscf / mscf_to_kg
cost_per_MWh_ex2 = dollars_per_kg / MWh_per_kg_total * 0.99 # 0.99 $ => €

# print("Production cost from SMR example in € per MWh (with storage): ")
# print(cost_per_MWh_ex2)
# print("\n\n")

### All costs from technology data
CAPEX = 750 * 1000 # [€]: 750 € per kW input capacity - 1 MW plant
lifetime = 25 * 0.98 * 363 # [day]: 25 years of technical lifetime minus 2% forced outage minus 2 days/per of planned outage
expected_prod = 24 * 20 * lifetime # [kg]: 20 full load hours of 1 MW on average each day * 20 kg per MWh
OPEX = 0.05 * CAPEX * lifetime
cost_per_MWh_tech = (CAPEX + OPEX) / expected_prod / eta_storage

# print("Production cost from technology data in € per MWh (without storage): ")
# print(cost_per_MWh_tech)
# print("\n\n")

cost_per_kg_technoeconomic = 1.06 # €/kg - 2030, no electricity cost
cost_per_MWh_technoeconomic = cost_per_kg_technoeconomic / MWh_per_kg_total

hydrogen_price_us_kg = 6 # $/kg
hydrogen_price_us_MWh = hydrogen_price_us_kg / MWh_per_kg_total * 0.99

hydrogen_price_ens_kg = 2.02 # €/kg - 2030
hydrogen_price_ens_MWh = hydrogen_price_ens_kg / MWh_per_kg_total


# We need to produce this much hydrogen to get to zero:
h2_nec = CAPEX / hydrogen_price_ens_kg
h2_nec_daily = h2_nec / lifetime # 41.748145129911876 kg - corresponding to 2.something full-load hours each day.
prod_capacity_daily = 24 * 20 # 20 kg / MWh => 20 kg each hour for 24 hours => 480
# That means we need to run on 8.698% capacity on average


# print("Sales price in € per MWh: ")
# print(hydrogen_price_us_MWh)
# print("\n\n")
# print("Final adjusted hydrogen net profit in € per MWh: ")
# print(hydrogen_price_us_MWh-cost_per_MWh_ex2)     # 92.81682907199999
# print(hydrogen_price_us_MWh-cost_per_MWh_tech)    # 15.567037016799247
# print(hydrogen_price_ens_MWh - cost_per_MWh_technoeconomic) # 16.896

hydrogen_price = hydrogen_price_ens_MWh - cost_per_MWh_technoeconomic
hydrogen_price = 2.0 / MWh_per_kg_total # 35.2