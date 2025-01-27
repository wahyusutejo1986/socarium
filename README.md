# Socarium: Comprehensive SOC Management Package

---

## Overview

**Socarium** is a modular, open-source Security Operations Center (SOC) management package designed to simplify the deployment, management, and testing of SOC platforms. Developed collaboratively by **JICA** and **idCARE UI**, Socarium integrates industry-standard tools like Wazuh, DFIR IRIS, Shuffle, MISP, and OpenCTI, providing a streamlined approach to cybersecurity monitoring, analysis, and incident response.

---

## Features

1. **Modular Design**
   - Each SOC platform is managed independently, ensuring flexibility and scalability.

2. **Centralized Management**
   - A single `setup.sh` script handles installation, configuration, and management.

3. **Integrated Proof of Concept (PoC) Testing**
   - Attack simulations included to validate platform functionality.

4. **Extensive Documentation**
   - Platform-specific guides and troubleshooting tips included.

5. **Open Source Collaboration**
   - Freely available under the MIT License for contributions and enhancements.

---

## Repository Structure

| **Folder/File**             | **Purpose**                                                                |
|-----------------------------|----------------------------------------------------------------------------|
| `main.sh`                   | Main script to install, configure, and manage all SOC platforms.           |
| `health_check.sh`           | Script check for the docker installation before the deploys.               |
| `install_all.sh`            | Script install the main tools of SOC package with single option.           |
| `install_prerequisites.sh`  | Script to install all dependencies are needed for the deployment.          |
| `README.md`                 | Comprehensive guide for using and understanding the repository.            |
| `modules/`                  | Contains Docker Compose configurations for SOC platforms.                  |
| `config/`                   | Contain configuration of the dockers environtment.                         |

### **Modules Folder Structure**

| **Platform**        | **Docker Compose Location**                     |
|---------------------|-------------------------------------------------|
| **Wazuh**           | `modules/wazuh/docker-compose.yml`              |
| **IRIS**            | `modules/iris/docker-compose.yml`               |
| **Shuffle**         | `modules/shuffle/docker-compose.yml`            |
| **MISP**            | `modules/misp/docker-compose.yml`               |
| **OpenCTI**         | `modules/opencti/docker-compose.yml`            |

### **Docs Folder Structure**

| **Platform**        | **Documentation Files**                        |
|---------------------|------------------------------------------------|
| **Wazuh**           | `docs/wazuh/details.md`, `docs/wazuh/screenshots/` |
| **IRIS**            | `docs/iris/details.md`, `docs/iris/screenshots/` |
| **Shuffle**         | `docs/shuffle/details.md`, `docs/shuffle/screenshots/` |
| **MISP**            | `docs/misp/details.md`, `docs/misp/screenshots/` |
| **OpenCTI**         | `docs/opencti/details.md`, `docs/opencti/screenshots/` |

### **PoC Folder Structure**

| **Simulation**            | **Description**                                               |
|---------------------------|-------------------------------------------------------------|
| **Attack Simulation 1**   | `poc/attack_simulation_1/description.md`, `scripts/`         |
| **Attack Simulation 2**   | `poc/attack_simulation_2/description.md`, `scripts/`         |

---

## Prerequisites

### **System Requirements**

- **Memory:** Minimum 16GB RAM.
- **Disk Space:** At least 50GB of free space.
- **Operating System:** Linux (Ubuntu recommended).

### **Installed Tools**

Ensure the following tools are installed:
- Docker
- Docker Compose

Installation commands:
```bash
sudo apt update
sudo apt install -y docker docker-compose
```

---

## Installation and Setup

### **Clone the Repository**

```bash
git clone <repository-url>
cd socarium
```

### **Run the Setup Script**

Make the script executable and launch the management menu:
```bash
chmod +x setup.sh
./setup.sh
```

---

## Setup Script Menu

The `setup.sh` script provides an intuitive menu for managing Socarium:

| **Option**                | **Description**                                                                 |
|---------------------------|---------------------------------------------------------------------------------|
| **1) Check Requirements** | Validates system prerequisites (RAM, Docker, etc.).                            |
| **2) Install Prerequisites** | Installs Docker, Docker Compose, and other necessary tools.                  |
| **3) Install Socarium Modules** | Installs all SOC platforms at once.                                        |
| **4) Install Wazuh**      | Installs the Wazuh platform independently.                                     |
| **5) Install DFIR IRIS**  | Installs the DFIR IRIS platform independently.                                 |
| **6) Install Shuffle**    | Installs the Shuffle platform independently.                                   |
| **7) Install MISP**       | Installs the MISP platform independently.                                      |
| **8) Install OpenCTI**    | Installs the OpenCTI platform independently.                                   |
| **9) Install Yara**       | Installs Yara for advanced file scanning and malware detection.                |
| **10) Uninstall All**     | Removes all installed SOC platforms and cleans up the system.                  |
| **11) Help**              | Displays a detailed help guide for using the script.                          |
| **12) Exit**              | Exits the script.                                                              |

---

## SOC Platforms

### **1. Wazuh**
- **Purpose:** Security monitoring and compliance management.
- **URL:** `http://<your-server-ip>:5601`
- **Default Credentials:**
  - Username: `admin`
  - Password: `admin`

### **2. DFIR IRIS**
- **Purpose:** Incident response and forensic analysis.
- **URL:** `http://<your-server-ip>:8080`
- **Default Credentials:**
  - Username: `iris_admin`
  - Password: `iris_admin`

### **3. Shuffle**
- **Purpose:** SOC workflow orchestration and automation.
- **URL:** `http://<your-server-ip>:3001`
- **Default Credentials:**
  - Username: `admin@example.com`
  - Password: `password`

### **4. MISP**
- **Purpose:** Threat intelligence sharing.
- **URL:** `http://<your-server-ip>:80`
- **Default Credentials:**
  - Username: `admin@admin.test`
  - Password: `admin`

### **5. OpenCTI**
- **Purpose:** Cyber threat intelligence analysis.
- **URL:** `http://<your-server-ip>:8082`
- **Default Credentials:**
  - Username: `admin@opencti.io`
  - Password: `admin`

---

## Proof of Concept (PoC)

The `poc/` folder contains scripts and descriptions for attack simulations:

### **Attack Simulations**

| **Simulation**            | **Description**                                                                 |
|---------------------------|---------------------------------------------------------------------------------|
| **Brute Force Attack**    | Simulates multiple failed login attempts to test detection capabilities.        |
| **Ransomware Behavior**   | Mimics file encryption to test response to ransomware-like activities.          |

### **File Structure**

| **Folder**                | **Content**                                                                 |
|---------------------------|-----------------------------------------------------------------------------|
| `poc/attack_simulation_1/description.md` | Describes the brute force attack simulation.                     |
| `poc/attack_simulation_1/scripts/simulate_attack.sh` | Bash script for brute force attack.                     |
| `poc/attack_simulation_2/description.md` | Describes the ransomware behavior simulation.                   |
| `poc/attack_simulation_2/scripts/simulate_ransomware.py` | Python script for ransomware simulation.            |

---

## Advanced Features

### **Backup and Restore**
- Add backup functionality for logs, configurations, and dashboards.
- Use the `setup.sh` script to schedule automatic backups.

### **Monitoring and Metrics**
- Integrate **Prometheus** and **Grafana** for monitoring resource usage and SOC metrics.

---

## Contributing

We welcome contributions to improve Socarium. Please submit issues or pull requests on the repository.

---

## License

This project is licensed under the **MIT License**. See the LICENSE file for details.

