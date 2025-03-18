import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import math
from datetime import timedelta

# Simulation parameters
lambda_rate = 10  # Arrival rate (flights per hour)
mu_rate = 12  # Service rate (flights per hour)
c = 2  # Number of runways
simulation_time = 10  # Simulation time in hours

# Convert rates to minutes
lambda_per_min = lambda_rate / 60
mu_per_min = mu_rate / 60

# Set random seed for reproducibility
np.random.seed(42)

# Generate flight arrivals (Poisson process)
arrival_times = []
current_time = 0
while current_time < simulation_time * 60:
    inter_arrival = np.random.exponential(1 / lambda_per_min)
    current_time += inter_arrival
    if current_time < simulation_time * 60:
        arrival_times.append(current_time)

# Generate service times (Exponential distribution)
service_times = np.random.exponential(1 / mu_per_min, len(arrival_times))

# Simulate the M/M/C queue
runway_available = [0] * c
completion_times = []
runway_assignments = []

# Process each flight
for i in range(len(arrival_times)):
    # Find next available runway
    runway = np.argmin(runway_available)

    # Calculate start and completion times
    start_time = max(arrival_times[i], runway_available[runway])
    completion_time = start_time + service_times[i]

    # Update runway availability
    runway_available[runway] = completion_time
    completion_times.append(completion_time)
    runway_assignments.append(runway + 1)

    # Print flight information with simplified time format
    arrival_str = str(timedelta(minutes=int(arrival_times[i])))
    waiting_time = start_time - arrival_times[i]
    waiting_str = str(timedelta(minutes=int(waiting_time)))
    departure_str = str(timedelta(minutes=int(completion_time)))

    print(
        f"Flight {i + 1}: Arrival at {arrival_str}, Waiting {waiting_str}, Departure at {departure_str}, Runway {runway + 1}")

# Create results dataframe
results = pd.DataFrame({
    'Arrival Time': arrival_times,
    'Service Time': service_times,
    'Completion Time': completion_times,
    'Runway': runway_assignments,
    'Hour': (np.array(arrival_times) / 60).astype(int)
})

# Calculate waiting times and total time in system
results['Waiting Time'] = results['Completion Time'] - results['Service Time'] - results['Arrival Time']
results['System Time'] = results['Completion Time'] - results['Arrival Time']

# Create basic plots
plt.figure(figsize=(10, 6))
plt.plot(results['Arrival Time'] / 60, label='Arrival Time', marker='o', alpha=0.7)
plt.plot(results['Completion Time'] / 60, label='Completion Time', marker='x', alpha=0.7)
plt.xlabel('Flight Index')
plt.ylabel('Time (hours)')
plt.title('Flight Arrivals and Completions')
plt.legend()
plt.grid(alpha=0.3)
plt.tight_layout()
plt.savefig('flight_sequence.png')
plt.show()

# Waiting time distribution
plt.figure(figsize=(10, 6))
sns.histplot(results['Waiting Time'], bins=15, kde=True)
plt.axvline(results['Waiting Time'].mean(), color='r', linestyle='--',
            label=f'Mean: {results["Waiting Time"].mean():.2f} min')
plt.xlabel('Waiting Time (minutes)')
plt.ylabel('Number of Flights')
plt.title('Distribution of Flight Waiting Times')
plt.legend()
plt.grid(alpha=0.3)
plt.tight_layout()
plt.savefig('waiting_time_distribution.png')
plt.show()

# Calculate runway utilization
runway_stats = results.groupby('Runway').agg(
    flights=('Arrival Time', 'count'),
    total_service=('Service Time', 'sum')
).reset_index()
runway_stats['utilization'] = runway_stats['total_service'] / (simulation_time * 60)

# Print summary statistics
print("\n==== SIMULATION SUMMARY ====")
print(f"Total flights: {len(results)}")
print(f"Average flights per hour: {len(results) / simulation_time:.2f}")
print(f"Average waiting time: {str(timedelta(minutes=int(results['Waiting Time'].mean())))}")
print(f"Maximum waiting time: {str(timedelta(minutes=int(results['Waiting Time'].max())))}")
print(f"Overall runway utilization: {sum(service_times) / (c * simulation_time * 60):.2%}")

print("\n==== RUNWAY STATISTICS ====")
for _, row in runway_stats.iterrows():
    print(f"Runway {int(row['Runway'])}: {row['flights']} flights, {row['utilization']:.2%} utilization")

# Calculate theoretical metrics for M/M/C queue
rho = lambda_rate / (c * mu_rate)
p0_denom = sum([(c * rho) ** n / math.factorial(n) for n in range(c)]) + (c * rho) ** c / (
            math.factorial(c) * (1 - rho))
p0 = 1 / p0_denom
lq = (p0 * (lambda_rate / mu_rate) ** c * rho) / (math.factorial(c) * (1 - rho) ** 2)
wq_theory = lq / lambda_rate * 60  # Convert to minutes

print("\n==== THEORETICAL METRICS ====")
print(f"Theoretical utilization (ρ): {rho:.2%}")
print(f"Theoretical average waiting time: {str(timedelta(minutes=int(wq_theory)))}")
