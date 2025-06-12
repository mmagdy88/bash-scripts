#!/bin/bash
# Installing Thumbor 6.7.0 on Ubuntu 24

# -------------------------------
# Install System Dependencies
# -------------------------------
sudo apt update
sudo apt install -y build-essential libssl-dev libffi-dev zlib1g-dev \
libbz2-dev libreadline-dev libsqlite3-dev wget curl libncurses5-dev \
libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev liblzma-dev \
libcurl4-openssl-dev libsm6 libxext6 libxrender1 gifsicle pngcrush jpegoptim \
libjpeg-dev libpng-dev libtiff-dev libwebp-dev libfreetype6-dev

# -------------------------------
# Install Python 2.7.18 from source
# -------------------------------
cd /usr/src
wget https://www.python.org/ftp/python/2.7.18/Python-2.7.18.tgz
tar -xf Python-2.7.18.tgz
cd Python-2.7.18
./configure --enable-optimizations
make -j$(nproc)
sudo make altinstall

# -------------------------------
# Install pip for Python 2.7
# -------------------------------
wget https://bootstrap.pypa.io/pip/2.7/get-pip.py
/usr/local/bin/python2.7 get-pip.py

# -------------------------------
# Install Thumbor and dependencies
# -------------------------------
/usr/local/bin/pip2.7 install "thumbor==6.7.0"
/usr/local/bin/pip2.7 uninstall -y derpconf
/usr/local/bin/pip2.7 install "derpconf==0.6.0"
/usr/local/bin/pip2.7 install "opencv-python==4.2.0.32"

# -------------------------------
# Create /etc/thumbor.conf (basic)
# -------------------------------
cat <<EOF | sudo tee /etc/thumbor.conf
ALLOWED_SOURCES = ['.*']
AUTO_PNG_TO_JPG = True
DETECTORS = [
    'thumbor.detectors.face_detector',
    'thumbor.detectors.feature_detector',
]
OPTIMIZERS = [
    'thumbor.optimizers.jpegtran',
    'thumbor.optimizers.gifsicle',
    'thumbor.optimizers.pngcrush',
]

JPEGTRAN_PATH = '/usr/bin/jpegtran'
GIFSICLE_PATH = '/usr/local/bin/gifsicle'
PNGCRUSH_PATH = '/usr/bin/pngcrush'
EOF

# -------------------------------
# Create systemd service template
# -------------------------------
sudo bash -c 'cat <<EOF > /etc/systemd/system/thumbor@.service
[Unit]
Description=Thumbor instance on port %i
After=network.target

[Service]
ExecStart=/usr/local/bin/thumbor --ip=127.0.0.1 --port=%i --conf=/etc/thumbor.conf
Restart=always
User=root
StandardOutput=journal
StandardError=journal
SyslogIdentifier=thumbor-%i

[Install]
WantedBy=multi-user.target
EOF'

# -------------------------------
# Reload systemd and enable Thumbor instances
# -------------------------------
sudo systemctl daemon-reload

for port in 8000 8001 8002 8003; do
    sudo systemctl enable thumbor@$port
    sudo systemctl start thumbor@$port
    sudo systemctl status thumbor@$port --no-pager
done

# -------------------------------
# Final test instructions
# -------------------------------
echo "-----------------------------------------"
echo "Thumbor should now be running on ports 8000-8003"
echo "Test with:"
echo 'curl -v "http://127.0.0.1:8000/unsafe/300x200/https://upload.wikimedia.org/wikipedia/commons/4/47/PNG_transparency_demonstration_1.png" -o test.png'
echo "-----------------------------------------"