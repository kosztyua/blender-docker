#!/bin/bash
rm /home/$USERNAME/.ssh/authorized_keys 2> /dev/null
for user in $(echo $GITHUB_USERS | tr "," "\n"); do
    curl -sL https://github.com/$user.keys >> /home/$USERNAME/.ssh/authorized_keys
done
chown $USERNAME:$USERNAME /home/$USERNAME/.ssh/authorized_keys
chmod 600 /home/$USERNAME/.ssh/authorized_keys

/usr/sbin/sshd -D