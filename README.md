# Predicting-Oil-Recovery-Factor-ORF-Using-Machine-Learning
This report presents a data-driven approach to predict the oil recovery factor (ORF) using machine learning. ORF measures the recoverable oil from a reservoir and impacts extraction efficiency and profitability. Traditional methods are costly and data-intensive, so ML offers early-stage, reliable ORF estimates to support decisions.

The dataset used for this study, referred to as Sands Atlas 2020, was sourced from the Bureau of Safety and Environmental Enforcement (BSEE) available at the BSEE website. It contains geological and reservoir engineering parameters collected from various offshore oil fields. The dataset includes key features such as:
Total Net Thickness (THK): Measures the total thickness of reservoir rock that contributes to
oil production.
Porosity: Represents the proportion of void space in the rock that can store hydrocarbons.
Water Saturation (SW): Indicates the fraction of pore space occupied by water rather than
hydrocarbons.
Permeability: Measures how easily fluids can flow through the reservoir rock, expressed in
millidarcies (mD).
Weighted Average Initial Pressure (PI): Represents the reservoir pressure before production
starts, affecting oil flow in pounds per square inch (psi).
Oil API Gravity (API): A measure of oil density; higher values indicate lighter oil that flows
more easily.
Gas-Oil Ratio (GOR): The volume of gas produced per barrel of oil, affecting reservoir pressure
and recovery efficiency in hydrocarbon reservoirs, with values expressed in thousand cubic feet
per barrel (mcf/bbl) to indicate the gas content relative to oil production.

The dataset was preprocessed to remove missing values and retain only numerical features for statistical analysis and machine learning modeling. To improve predictive accuracy, data entries where ORF values were zero were removed, as they could distort the model’s ability to learn meaningful patterns. Several models, including Random Forest, Linear Regression, Decision Tree, and LOESS, were trained and evaluated to determine the most effective predictive method. Model performance was assessed using Root Mean Squared Error (RMSE), a common metric for measuring prediction accuracy in regression problems. 
