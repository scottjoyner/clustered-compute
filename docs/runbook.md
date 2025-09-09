# Operator Runbook (One Pager)

## Modes
- **OFF-GRID:** Pi runs DHCP/DNS; cordon GPU node; low telemetry.
- **ON-GRID:** Home router does DHCP; uncordon GPU; normal telemetry.

### Toggle
```
scripts/mode-toggle.sh offgrid
scripts/mode-toggle.sh ongrid
```

## Bring up core
```
kubectl apply -k k8s/bootstrap
kubectl -n infra create secret generic minio-credentials   --from-literal=AWS_ACCESS_KEY_ID=<key>   --from-literal=AWS_SECRET_ACCESS_KEY=<secret>
kubectl apply -k k8s/minio
kubectl apply -k k8s/ray
```

## Add native workers
```
ansible-playbook ansible/linux.yml   -e ray_head_address=192.168.50.10:30379 -e num_cpus=4
ansible-playbook ansible/macos.yml   -e ray_head_address=192.168.50.10:30379 -e num_cpus=2
```

## Submit jobs
```
python3 jobs/ray/ffmpeg_shard/run_job.py
python3 jobs/ray/gpu_preferred/gpu_example.py
```

## Labels & resources
- Tag GPU node with: `kubectl label node zeus accelerator=amd-opencl gpu_amd=1`
- Request in Ray: `@ray.remote(resources={"gpu_amd":1})`

## Data
- POSIX: NFS via `nfs-rwx` StorageClass.
- Object: MinIO S3 at `http://minio.infra.svc.cluster.local:9000`.
