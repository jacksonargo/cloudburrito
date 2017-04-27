# Install ssh
package('openssh-server') { action :install }

# Enable ssh
systemd_unit('sshd') { action [ :start, :enable ] }

# Configure ssh
file '/etc/ssh/sshd_config' do
  action :create
  owner 'root'
  group 'root'
  mode  0644
  notifies :restart, 'systemd_unit[sshd]', :delayed
  content 'Port 22
PermitRootLogin no
PasswordAuthentication no
ChallengeResponseAuthentication no
AuthorizedKeysFile .ssh/authorized_keys
UsePAM yes
UsePrivilegeSeparation sandbox'
end
