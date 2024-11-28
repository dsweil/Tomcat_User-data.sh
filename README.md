# TomcatUserData
Here’s a well-structured README for your user data script:

---

# **User Data Script for Setting Up Apache Tomcat on EC2**

## **Overview**
This script automates the setup and configuration of an Apache Tomcat server on an Amazon EC2 instance. It includes the installation of Java, the setup of Tomcat, and custom configurations to enhance functionality and accessibility. The script also retrieves AWS EC2 metadata and dynamically generates a custom welcome page with instance-specific details.

---

## **Features**
- **Environment Setup:**
  - Installs Java 17 (Amazon Corretto).
  - Downloads and configures Apache Tomcat 11.
- **Service Management:**
  - Creates a systemd service for Tomcat to manage its lifecycle (start, stop, restart).
- **Security Enhancements:**
  - Updates `context.xml` to modify access control for the manager and host-manager web applications.
  - Adds users and roles to `tomcat-users.xml` for management purposes.
- **Dynamic Metadata Integration:**
  - Fetches EC2 instance metadata (e.g., IP, availability zone, VPC ID) using IMDSv2.
  - Generates a custom welcome page with instance-specific information.
- **Custom Welcome Page:**
  - Displays EC2 instance details (private IP, availability zone, hostname, and VPC ID).
  - Includes branding with an image and styled content.

---

## **Usage**
### **Prerequisites**
- An Amazon EC2 instance with user data support enabled.
- Amazon Linux 2 or Amazon Linux 2023 as the operating system.
- IAM Role or instance profile with access to IMDSv2.

### **Adding the Script**
1. Copy the script into the **user data** section while launching the EC2 instance.
2. Ensure the instance has internet access to download dependencies and access EC2 metadata.

### **Execution**
- The script runs automatically on the first boot of the instance.
- It sets up Tomcat, modifies configurations, and generates the custom welcome page.

---

## **Detailed Script Breakdown**

### **1. Install Dependencies**
- Updates the system and installs Java 17 to support Tomcat.

### **2. Download and Configure Tomcat**
- Downloads the latest version of Apache Tomcat (v11.0.0) and extracts it to `/opt/tomcat`.
- Sets proper permissions and environment variables.

### **3. Systemd Service for Tomcat**
- Creates a `tomcat.service` file to manage Tomcat as a systemd service.
- Enables and starts the service automatically.

### **4. Modify Tomcat Configuration**
- Edits `context.xml` for the manager and host-manager applications to allow access from any IP.
- Updates `tomcat-users.xml` to add roles and users for management access.

### **5. Retrieve EC2 Metadata**
- Uses IMDSv2 to securely fetch metadata:
  - Local IPv4 address
  - Availability zone
  - VPC ID
- Stores metadata in temporary files and extracts the required information.

### **6. Generate Custom Welcome Page**
- Creates a new `index.html` in Tomcat's `ROOT` web application directory.
- Displays instance-specific metadata dynamically.

### **7. Clean Up**
- Removes temporary files created during metadata retrieval.
- Restarts Tomcat to load the custom welcome page.

---

## **Custom Welcome Page Example**
The custom `index.html` includes:
- **Instance Name**
- **Private IP Address**
- **Availability Zone**
- **VPC ID**
- Branding with an image and styled content.

---

## **How to Verify**
1. **Check Tomcat Service:**
   ```bash
   sudo systemctl status tomcat
   ```
   Ensure the service is running.

2. **Access the Web Application:**
   Open a browser and navigate to:
   ```
   http://<instance-public-ip>:8080
   ```
   The custom welcome page should display instance details.

3. **View Manager App:**
   Use the credentials configured in `tomcat-users.xml` to log into the Tomcat Manager application.

---

## **Troubleshooting**
- **Service Not Running:** Verify logs using:
  ```bash
  sudo journalctl -u tomcat
  ```
- **Metadata Not Displayed:** Ensure the instance has IMDSv2 enabled and an active internet connection.

---

## **Future Improvements**
- Add HTTPS support with SSL certificates.
- Introduce more robust user management for enhanced security.
- Automate deployment of WAR files for application hosting.

---

## **Author**
- **Derrick Weil**  


