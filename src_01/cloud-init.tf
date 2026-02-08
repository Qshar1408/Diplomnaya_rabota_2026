users:
  - name: qshar
    groups: sudo
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    ssh_authorized_keys:
      - ${vms_ssh_root_key}
package_update: true
package_upgrade: false
