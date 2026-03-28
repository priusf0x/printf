import pandas as pd
import matplotlib.pyplot as plt
import numpy as np

df = pd.read_json('meow.json')
data = df.to_dict()
data = data['results'][0]['times']

plt.hist(data, bins=20, edgecolor='black')
plt.title("Basic Distribution (Histogram)")
plt.xlabel("Time, sec")
plt.ylabel("Times")
plt.xlim(0)
plt.savefig("meow.png")
