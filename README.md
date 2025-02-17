# Socarium: Comprehensive SOC Management Package

---

## Overview

**Socarium** is a modular, open-source Security Operations Center (SOC) management package designed to simplify the deployment, management, and testing of SOC platforms. Developed collaboratively by **JICA** and **idCARE UI**, Socarium integrates industry-standard tools like Wazuh, DFIR IRIS, Shuffle, MISP, and OpenCTI, providing a streamlined approach to cybersecurity monitoring, analysis, and incident response.

<div align="center" width="100" height="100">

  <h3 align="center">System Overview</h3>

  <p align="center">
    <br />
    <a href="https://github.com/wahyusutejo1986/socarium/blob/main/images/socarium.png">
    <img src="images/socarium.png">
    </a>
    <br />
    <br />
  </p>
</div>

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
| **IRIS**            | `modules/iris-web/docker-compose.yml`           |
| **Shuffle**         | `modules/shuffle/docker-compose.yml`            |
| **MISP**            | `modules/misp/docker-compose.yml`               |
| **Velociraptor**    | `modules/velociraptor/docker-compose.yml`       |
| **Grafana**         | `modules/grafana/docker-compose.yml`            |
| **OpenCTI**         | `modules/opencti/docker-compose.yml`            |

### **PoC Folder Structure**

| **Simulation**            | **Description**                                               |
|---------------------------|-------------------------------------------------------------|
| **Attack Simulation 1**   | `poc/attack_simulation_1/description.md`, `scripts/`         |
| **Attack Simulation 2**   | `poc/attack_simulation_2/description.md`, `scripts/`         |

---

## Prerequisites

### **Minimum System Requirements**

- **Memory:** Minimum 16GB RAM.
- **Disk Space:** At least 100GB of free space.
- **Operating System:** Linux (Ubuntu recommended).

---

## Installation and Setup

Installation and configuration manuals please refers into GitHub Wiki (https://github.com/wahyusutejo1986/socarium/wiki)

---

## Setup Script Menu

The `main.sh` script provides an intuitive menu for managing Socarium:

| **Option**                       | **Description**                                                                 |
|----------------------------------|---------------------------------------------------------------------------------|
| **0) Install Prerequisites**     | Installs Docker, Docker Compose, and other necessary tools.                     |
| **1) Deploy All Core Services**  | Installs all SOC platforms at once.                                             |
| **2) Deploy Wazuh**              | Installs the Wazuh platform independently.                                      |
| **3) Deploy DFIR IRIS**          | Installs the DFIR IRIS platform independently.                                  |
| **4) Deploy Shuffle**            | Installs the Shuffle platform independently.                                    |
| **5) Deploy MISP**               | Installs the MISP platform independently.                                       |
| **6) Deploy Velociraptor**       | Installs the Veliciraptor platform independently.                               |
| **7) Deploy Yara**               | Installs Yara for advanced file scanning and malware detection.                 |
| **8) Deploy OpenCTI**            | Installs the OpenCTI platform independently.                                    |
| **9) Deploy Grafana**           | Installs the Grafana platform independently.                                    |
| **10) Socarium Configurations**  | Configuration the integration parts.                                            |
| **11) Exit**                     | Exits the script.                                                               |

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

### **Monitoring and Metrics**
- Integrate **Prometheus** and **Grafana** for monitoring resource usage and SOC metrics.

---

## Contributing

We welcome contributions to improve Socarium. Please submit issues or pull requests on the repository.

---

## License

This project is licensed under the **MIT License**. See the LICENSE file for details.

