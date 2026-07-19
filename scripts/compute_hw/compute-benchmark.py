#!/usr/bin/env python3
"""
Babel-PC Rechen-Test
Testet numpy, scipy, pandas auf dem Remote-PC
"""
import numpy as np
import scipy.linalg
import pandas as pd
import time
import json
import sys

results = {}

# Test 1: Grosse Matrix-Multiplikation
print("Test 1: Matrix 3000x3000...", flush=True)
a = np.random.rand(3000, 3000)
b = np.random.rand(3000, 3000)
t0 = time.time()
c = a @ b
t1 = time.time()
results["matmul_3000"] = round(t1 - t0, 3)
print(f"  {results['matmul_3000']}s", flush=True)

# Test 2: Eigenwerte
print("Test 2: Eigenwerte 1000x1000...", flush=True)
m = np.random.rand(1000, 1000)
m = m + m.T  # symmetrisch
t0 = time.time()
eigenvalues = scipy.linalg.eigvalsh(m)
t1 = time.time()
results["eigenvalues_1000"] = round(t1 - t0, 3)
print(f"  {results['eigenvalues_1000']}s", flush=True)

# Test 3: FFT 10 Mio
print("Test 3: FFT 10 Mio Punkte...", flush=True)
data = np.random.rand(10_000_000)
t0 = time.time()
fft_result = np.fft.fft(data)
t1 = time.time()
results["fft_10m"] = round(t1 - t0, 3)
print(f"  {results['fft_10m']}s", flush=True)

# Test 4: Pandas Aggregation
print("Test 4: Pandas 2 Mio Zeilen...", flush=True)
df = pd.DataFrame({
    "group": np.random.choice(["A", "B", "C", "D"], 2_000_000),
    "value1": np.random.rand(2_000_000),
    "value2": np.random.rand(2_000_000)
})
t0 = time.time()
agg = df.groupby("group").agg({"value1": ["mean", "std"], "value2": "sum"})
t1 = time.time()
results["pandas_2m"] = round(t1 - t0, 3)
print(f"  {results['pandas_2m']}s", flush=True)

# Test 5: Numerische Integration
print("Test 5: SciPy Integration...", flush=True)
from scipy import integrate
t0 = time.time()
result, error = integrate.quad(lambda x: np.sin(x**2), 0, 10)
t1 = time.time()
results["integration"] = round(t1 - t0, 3)
results["integration_result"] = round(result, 6)
print(f"  {results['integration']}s, Ergebnis: {results['integration_result']}", flush=True)

# Zusammenfassung
print()
print("=" * 50)
print("ERGEBNISSE Babel-PC Rechen-Test")
print("=" * 50)
for k, v in results.items():
    print(f"  {k}: {v}")
print()

total = sum(v for k, v in results.items() if k.endswith(("3000", "1000", "10m", "2m", "integration")))
print(f"  Gesamtzeit: {round(total, 2)}s")
print()

if total < 10:
    print("  Bewertung: SEHR SCHNELL")
elif total < 30:
    print("  Bewertung: GUT")
else:
    print("  Bewertung: LANGSAM (erwartet fuer Celeron)")

# Save results
with open("/home/Babel/compute-results.json", "w") as f:
    json.dump(results, f, indent=2)
print("\nErgebnisse gespeichert in /home/Babel/compute-results.json")
