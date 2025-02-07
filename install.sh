# !/bin/bash

LATEST_VERSION=$(curl -s "https://api.github.com/repos/prometheus/node_exporter/releases/latest" | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
EXPORTER_VERSION=${EXPORTER_VERSION:-$LATEST_VERSION}
EXPORTER_PORT=${EXPORTER_PORT:-9100}

function install_node_exporter() {
    echo "Downloading Node Exporter v${EXPORTER_VERSION}..."
    curl -LO https://github.com/prometheus/node_exporter/releases/download/v$EXPORTER_VERSION/node_exporter-$EXPORTER_VERSION.linux-amd64.tar.gz
    tar -xzf node_exporter-$EXPORTER_VERSION.linux-amd64.tar.gz
    sudo mv node_exporter-$EXPORTER_VERSION.linux-amd64/node_exporter /usr/local/bin

    echo "Cleaning up..."
    rm -rf node_exporter-$EXPORTER_VERSION.linux-amd64.tar.gz node_exporter-$EXPORTER_VERSION.linux-amd64
}

function create_user() {
    echo "Creating node_exporter user ..."
    sudo useradd --no-create-home --shell /bin/false node_exporter
}

function create_systemd_service() {
    echo "Creating node_exporter systemd service..."
    sudo tee /etc/systemd/system/node_exporter.service > /dev/null << EOF
[Unit]
Description=Prometheus Node Exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
ExecStart=/usr/local/bin/node_exporter --web.listen-address=:$EXPORTER_PORT

[Install]
WantedBy=multi-user.target
EOF
}

function enable_and_start_service() {
    echo "Enabling and starting node_exporter service..."
    sudo systemctl daemon-reload
    sudo systemctl enable node_exporter --now

    echo "Node Exporter installation completed."
    echo "You can now access the metrics at http://localhost:$EXPORTER_PORT/metrics"
}

install_node_exporter
create_user
create_systemd_service
enable_and_start_service
