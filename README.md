# Run-nmap-Switch-Networks
This will automatically run Nmap and switch networks. 

Background:
We run a highly segmented network that our users are connected to, depending on their job/role they are assigned a corresponding network/VLAN. We run quarterly Nmap scans from each one of those users networks that scans our CDE networks. This is a PCI requirement and also a good security practice.

Setup:
We have a VM with all of our networks/VLANs tagged, which is a separate virtual NIC. We can enable/disable any nic within the virtual machine to then hop on that desired network.
