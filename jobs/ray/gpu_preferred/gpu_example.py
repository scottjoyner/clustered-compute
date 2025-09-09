import ray, os, time

# Require AMD GPU-tagged node
@ray.remote(resources={"gpu_amd": 1})
def gpu_task(x):
    # Placeholder GPU workload; replace with OpenCL pipeline or hipSYCL etc.
    # Simulate compute
    s = 0
    for i in range(10_000_000):
        s += (i ^ x) & 0xFF
    return s

def main():
    ray.init(address="auto")
    futs = [gpu_task.remote(i) for i in range(8)]
    print(ray.get(futs))

if __name__ == "__main__":
    main()
