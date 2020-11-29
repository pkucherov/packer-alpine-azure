# Packer template for Alpine Linux on Hyper-V and Azure

This Packer template will generate a VHD suitable for use in Hyper-V or Azure.

## How it works

- The Packer template downloads the Alpine 3.6 ISO from the official download site.
- It then uses `setup-alpine` to perform an [installation to disk](https://wiki.alpinelinux.org/wiki/Install_to_disk).
- The `answers` file is served using Packer's built-in HTTP server.
- It also installs the `hvtools` package and enables the `hv_kvp_daemon` service so Hyper-V can detect the VM is running and retrieve its IP address. (Read more about [Hyper-V Integration Services](https://docs.microsoft.com/en-us/windows-server/virtualization/hyper-v/manage/manage-hyper-v-integration-services#start-and-stop-an-integration-service-from-a-linux-guest).)

## Software installed

The Packer provisioning step performs the following actions in order to prepare a proper Azure image:

- Installs Python and OpenSSL, plus `sudo` and `bash`
- Installs the `shadow` package (for `useradd`)
- Installs the [Azure Linux Agent](https://github.com/Azure/WALinuxAgent/)
- Adds recommended boot parameters
- Sets the `ssh` client interval to 180
- Enables the Azure Agent to start at boot

The template also installs a custom `useradd` script (in `/usr/local/sbin`) that changes the behavior of adding password-less accounts (i.e. accounts that log in using SSH keys). By default `useradd` locks the password-less account, preventing it from logging in. The custom script forces an illegal password, so that the password cannot be used to log in, but leaves the account unlocked so it can be access via SSH.

## How to use the template

### On Linux, using `qemu`

Check out the `packer-qemu` branch for a WIP version that builds the Alpine image using `qemu`, allowing you to generate the image from a Linux machine.

Detailed docs TBD, but the Windows instructions below should help.

### On Windows, using Hyper-V

The commands need to be run from an elevated PowerShell prompt so that they can interact with Hyper-V.

First run the template. This will generate a VHDX file locally, in `output-hyperv-iso`.

```
packer build alpinehv.json
```

To use the image in Azure, you need to convert the image to VHD using `convert.ps1`.

The `deploy.cmd` script will upload the VHD to Azure and start a VM based on the image. Please amend the script variables as necessary.

For waagent run: to support python3
```
cat bin/waagent | sed 's_#!/usr/bin/env python_#!/usr/bin/env python3_' > /usr/sbin/waagent
```

Once the VM is started, you can log on via `ssh` and make any additional changes. Then deprovision the VM to get it ready to be used as an image:

```
waagent -deprovision
```

Finally, `makeimage.cmd` will deallocate the VM, capture it as an image, and start another VM based on that image.

## TODO

- Review/tweak boot command based on [ladar's comment](https://github.com/hashicorp/packer/issues/5049#issuecomment-343531173)
- Investigate `iptables` error messages


## Alpine commands

- resize 
    Install cfdisk (apk add cfdisk)

    Use it to expand partition (just run cfdisk and it pretty intuitive)

    Install e2fsprogs-extra

    run resize2fs /dev/sda* to expand the file system (substitute * with partition that you want to expand)

- check free space 
  sudo df -h

