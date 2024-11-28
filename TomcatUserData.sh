#!/bin/bash
# Update and install dependencies
sudo yum update
sudo yum upgrade -y
sudo yum install -y java-17-amazon-corretto-devel

# Download and set up Apache Tomcat
wget https://downloads.apache.org/tomcat/tomcat-11/v11.0.0/bin/apache-tomcat-11.0.0.tar.gz
sudo tar -xf apache-tomcat-11.0.0.tar.gz
sudo mv apache-tomcat-11.0.0 /opt/tomcat

# Set permissions and environment variables
sudo chmod +x /opt/tomcat/bin/*.sh
export CATALINA_HOME="/opt/tomcat"

# Create a systemd service to manage Tomcat
cat <<EOT | sudo tee /etc/systemd/system/tomcat.service
[Unit]
Description=Apache Tomcat Web Application Container
After=network.target

[Service]
Type=forking

Environment=JAVA_HOME=/usr/lib/jvm/java-17-amazon-corretto
Environment=CATALINA_PID=/opt/tomcat/temp/tomcat.pid
Environment=CATALINA_HOME=/opt/tomcat
Environment=CATALINA_BASE=/opt/tomcat

ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/opt/tomcat/bin/shutdown.sh

User=root
Group=root

[Install]
WantedBy=multi-user.target
EOT

# Reload systemd to recognize the Tomcat service, enable and start it
sudo systemctl daemon-reload
sudo systemctl enable tomcat
sudo systemctl start tomcat



#!/bin/bash




# Set up a default welcome page in the ROOT webapp


# Fetch IMDSv2 Token for metadata requests# Define paths for context.xml files
MANAGER_CONTEXT="/opt/tomcat/webapps/manager/META-INF/context.xml"
HOST_MANAGER_CONTEXT="/opt/tomcat/webapps/host-manager/META-INF/context.xml"
TOMCAT_USERS_FILE="/opt/tomcat/conf/tomcat-users.xml"

# Check if Tomcat is installed
if [ ! -d "/opt/tomcat" ]; then
  echo "Tomcat not found in /opt/tomcat. Exiting."
  exit 1
fi

if [ -f "$MANAGER_CONTEXT" ]; then
  echo "Updating $MANAGER_CONTEXT..."
  
  # Comment out the Valve line
  sudo sed -i '/<Valve className="org.apache.catalina.valves.RemoteAddrValve"/ s|^|<!-- |; /<Valve className="org.apache.catalina.valves.RemoteAddrValve"/ s|$| -->|' "$MANAGER_CONTEXT"
  
  # Comment out the allow attribute line
  sudo sed -i '/allow="127\\.\d+\\.\d+\\.\d+\|::1\|0:0:0:0:0:0:0:1" \/>/ s|^|<!-- |; /allow="127\\.\d+\\.\d+\\.\d+\|::1\|0:0:0:0:0:0:0:1" \/>/ s|$| -->|' "$MANAGER_CONTEXT"
fi


if [ -f "$HOST_MANAGER_CONTEXT" ]; then
  echo "Updating $HOST_MANAGER_CONTEXT..."
  sudo sed -i '/<Valve className="org.apache.catalina.valves.RemoteAddrValve"/ s|^|<!-- |; /<Valve className="org.apache.catalina.valves.RemoteAddrValve"/ s|$| -->|' "$HOST_MANAGER_CONTEXT"
    # Comment out the allow attribute line
  sudo sed -i '/allow="127\\.\d+\\.\d+\\.\d+\|::1\|0:0:0:0:0:0:0:1" \/>/ s|^|<!-- |; /allow="127\\.\d+\\.\d+\\.\d+\|::1\|0:0:0:0:0:0:0:1" \/>/ s|$| -->|' "$HOST_MANAGER_CONTEXT"
fi

# Edit tomcat-users.xml to add roles and users
if [ -f "$TOMCAT_USERS_FILE" ]; then
  echo "Updating $TOMCAT_USERS_FILE..."
  sudo sed -i '/<\/tomcat-users>/i \
  <role rolename="manager-gui"/>\n\
  <role rolename="manager-script"/>\n\
  <role rolename="manager-jmx"/>\n\
  <role rolename="manager-status"/>\n\
  <user username="admin" password="admin" roles="manager-gui,manager-script,manager-jmx,manager-status"/>\n\
  <user username="deployer" password="deployer" roles="manager-script"/>\n\
  <user username="tomcat" password="s3cret" roles="manager-gui"/>' "$TOMCAT_USERS_FILE"
fi

# Restart Tomcat service
echo "Restarting Tomcat service..."
sudo systemctl restart tomcat

echo "Configuration completed."

TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

# Run curl requests in the background to get EC2 metadata and write to temp files
curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/local-ipv4 > /tmp/local_ipv4 &
curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/placement/availability-zone > /tmp/az &
curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/ > /tmp/macid &
wait  # Wait for all curl requests to complete

# Retrieve the necessary metadata values
macid=$(cat /tmp/macid)
local_ipv4=$(cat /tmp/local_ipv4)
az=$(cat /tmp/az)
vpc=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/${macid}/vpc-id)

# Create the custom index.html file in the ROOT webapp for Tomcat
sudo bash -c "cat << 'EOF' > /opt/tomcat/webapps/ROOT/index.html
<!doctype html>
<html lang=\"en\" class=\"h-100\">
<head>
<title>Details for EC2 instance</title>
</head>
<body>
<div>
<h1>AWS Instance Details</h1>
<h1>Samurai Katana</h1>

<br>
<img src=\"https://www.w3schools.com/images/w3schools_green.jpg\" alt=\"W3Schools.com\">
<br>

<p><b>Instance Name:</b> $(hostname -f) </p>
<p><b>Instance Private IP Address:</b> ${local_ipv4}</p>
<p><b>Availability Zone:</b> ${az}</p>
<p><b>Virtual Private Cloud (VPC):</b> ${vpc}</p>
</div>
</body>
</html>
EOF"

# Clean up temporary files
rm -f /tmp/local_ipv4 /tmp/az /tmp/macid

# Restart Tomcat to load the new default page
sudo systemctl restart tomcat
