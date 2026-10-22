# Home Supercomputer Starter Repo

<!-- repo-entrypoint-guide:start -->
> **How to approach this repository:** Begin with the [Contents](#contents) and [Quick Start](#quick-start), then inspect the runbook under `docs/` before provisioning K3s, NFS, Ray, or workers.
> 
> **Safety boundary:** Treat example cluster names and storage paths as placeholders. Verify node identity, firewall rules, credentials, capacity, and rollback procedures before joining machines or mounting existing disks.
<!-- repo-entrypoint-guide:end -->


Turn your heterogeneous devices into a single compute fabric without touching their internal disks.

## Contents
- `k8s/` — K3s add-ons: NFS provisioner, MinIO (S3), KubeRay (Ray on K8s), and Services so native workers can connect.
- `ansible/` — Roles/playbooks to bootstrap Linux/macOS native Ray workers (venv), enable WoL, set power governors.
- `jobs/` — Ray/Dask/Spark-ready templates (ffmpeg sharding, GPU-preferred tasks, CPU fallback, data-local hints).
- `scripts/` — Mode toggle (off-grid/on-grid), Wake-on-LAN, helper utilities.
- `docs/` — One-pager runbook and architecture notes.

## Quick Start
1. **K3s** on `atlas` (server) + join agents (see docs). Ensure kubeconfig on your admin laptop.
2. `kubectl apply -k k8s/bootstrap` (NFS provisioner + StorageClass).
3. `kubectl apply -k k8s/minio` (S3 storage).
4. `kubectl apply -k k8s/ray` (Ray head via KubeRay; workerSet for cluster nodes).
5. On laptops/desktops you don’t want in K8s, run the **Ansible worker** role or follow `docs/runbook.md` to join as native Ray workers.
6. Submit a job: `python jobs/ray/ffmpeg_shard/run_job.py` (edit S3/NFS paths first).

## Namespaces
- `infra` — storage, ingress, observability
- `data` — MinIO buckets and example datasets
- `compute` — Ray cluster

## Secrets & Credentials
- Create MinIO creds: `kubectl -n infra create secret generic minio-credentials --from-literal=AWS_ACCESS_KEY_ID=<key> --from-literal=AWS_SECRET_ACCESS_KEY=<secret>`
- Update `k8s/ray/raycluster.yaml` and `jobs/*` to point at your S3 endpoint and buckets.

## Safety
- Off-grid mode defaults to low telemetry and cordons the GPU node (Deathstar). Uncordon via script when needed.
- Review fusing and power notes from your wiring doc before powering additional devices.
