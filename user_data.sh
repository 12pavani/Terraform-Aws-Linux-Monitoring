#!/bin/bash
# Boot-time configuration for the Amazon Linux 2023 web server.
# Installs Nginx, publishes a status page, and adds a self-healing health check.
set -euxo pipefail

dnf update -y
dnf install -y nginx cronie

# Read instance metadata using IMDSv2 (token required)
TOKEN=$(curl -sS -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 300")
INSTANCE_ID=$(curl -sS -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/instance-id)
AZ=$(curl -sS -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/placement/availability-zone)

cat > /usr/share/nginx/html/index.html <<HTML
<!DOCTYPE html>
<html>
  <head><title>Terraform AWS Linux Demo</title></head>
  <body>
    <h1>Provisioned with Terraform</h1>
    <p>Host: $(hostname)</p>
    <p>Instance: ${INSTANCE_ID}</p>
    <p>Availability zone: ${AZ}</p>
  </body>
</html>
HTML

systemctl enable --now nginx
systemctl enable --now crond

# Health check: restart Nginx if the local page stops answering
cat > /usr/local/bin/healthcheck.sh <<'SCRIPT'
#!/bin/bash
if ! curl -fsS --max-time 5 http://localhost/ > /dev/null; then
  echo "$(date -Is) nginx unhealthy, restarting" >> /var/log/healthcheck.log
  systemctl restart nginx
fi
SCRIPT
chmod +x /usr/local/bin/healthcheck.sh

echo "*/5 * * * * root /usr/local/bin/healthcheck.sh" > /etc/cron.d/healthcheck
chmod 644 /etc/cron.d/healthcheck
