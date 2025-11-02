# Lateral Movement Demo Kit

This repository contains a set of small, educational shell scripts that demonstrate lateral movement techniques and concepts in a controlled, local environment. These scripts are intended for learning, red-team training, and defensive research — not for malicious use.

## WARNING — Legal and Safety
- Use these scripts only on systems and networks you own or where you have explicit permission to run them.
- Never run these tools against third-party, production, or public systems without authorization.
- The author is not responsible for misuse. By using this repository you accept full responsibility for your actions.

## Purpose
The goal of this repository is to provide simple, easy-to-read shell examples that illustrate how attackers can move laterally between hosts and how defenders can detect or mitigate those activities.

## Requirements
- A POSIX-compatible shell (bash/sh)
- Basic UNIX utilities (ssh, scp, netcat, curl, socat) depending on the script
- A controlled lab environment (virtual machines or isolated network)

## Included scripts
Each script is small and documented inline. Read the top of each file for details and usage examples.

- discover_hosts.sh — Illustrates simple host discovery techniques (local network scanning using ping/arp)
- simple_ssh_move.sh — Demonstrates using SSH keys and agent forwarding for lateral movement in a lab
- file_transfer_example.sh — Shows secure (scp) and insecure (netcat) file transfer as part of lateral movement
- persistence_demo.sh — Shows a benign persistence pattern for demonstration (e.g., cron entry in a disposable VM)

Note: Script names above are examples. See the repository root to view the actual files and their exact names.

## Usage
1. Inspect each script before running: `less scriptname.sh` or open in an editor.
2. Make the script executable: `chmod +x scriptname.sh`.
3. Run in a lab environment: `./scriptname.sh`.

## Detecting and Mitigating
- Monitor unusual SSH connections and agent forwarding usage.
- Audit cron and startup entries for unexpected changes.
- Use network monitoring to detect scanning and unexpected lateral traffic.

## Contributing
Contributions are welcome but must follow these rules:
- Keep examples small and well-documented.
- Do not add tools that enable offensive operations against third-party targets.
- Include a clear explanation of the defensive lesson the example demonstrates.

## License
MIT — See LICENSE file for details.

## Contact
Repository owner: @0xHasanM

---

If you'd like, I can also add a CONTRIBUTING.md, safer-demo templates, or annotate each script with "Do not run on production" notices. Let me know which you prefer.