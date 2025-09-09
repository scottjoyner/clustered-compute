import os, ray, subprocess, json, pathlib

RAY_ADDRESS = os.environ.get("RAY_ADDRESS", "auto")
S3_ENDPOINT = os.environ.get("AWS_ENDPOINT_URL", "http://minio.infra.svc.cluster.local:9000")
INPUT_PREFIX = os.environ.get("INPUT_PREFIX", "s3://media/input/")
OUTPUT_PREFIX = os.environ.get("OUTPUT_PREFIX", "s3://media/output/")
FFMPEG_BIN = os.environ.get("FFMPEG_BIN", "ffmpeg")

ray.init(address=RAY_ADDRESS)

@ray.remote(num_cpus=1)
def transcode(obj_key: str):
    # Pull via s5cmd/awscli if available, else stream via ffmpeg if endpoint supports
    src = f"{INPUT_PREFIX}{obj_key}"
    dst = f"{OUTPUT_PREFIX}{obj_key.rsplit('.',1)[0]}_720p.mp4"
    # Example CPU transcode (VAAPI/OpenCL can be injected by node env)
    cmd = [
        FFMPEG_BIN, "-y", "-i", src,
        "-vf", "scale=-2:720",
        "-c:v", "libx264", "-preset", "veryfast", "-crf", "23",
        "-c:a", "aac", "-b:a", "128k",
        dst
    ]
    try:
        subprocess.check_call(cmd)
        return {"ok": True, "key": obj_key}
    except subprocess.CalledProcessError as e:
        return {"ok": False, "key": obj_key, "error": str(e)}

def main():
    # Example shard list
    shards = [f"clip_{i:03d}.mp4" for i in range(16)]
    futures = [transcode.remote(k) for k in shards]
    results = ray.get(futures)
    ok = sum(1 for r in results if r["ok"])
    print(json.dumps({"ok": ok, "total": len(results)}, indent=2))

if __name__ == "__main__":
    main()
