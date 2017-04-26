##
## Deploy user
##

# Create our deploy user

user 'deploy' do
  home  '/home/deploy'
  shell '/bin/bash'
  action :create
  manage_home true
end

# Create our document root

directory '/var/www/html/cloudburrito' do
  owner 'deploy'
  group 'deploy'
  mode '0755'
  action :create
end

# Create the deploy .ssh dir

directory '/home/deploy/.ssh' do
  owner 'deploy'
  group 'deploy'
  mode '0700'
  action :create
end

# Add the authorized keys

file '/home/deploy/.ssh/authorized_keys' do
  owner 'deploy'
  group 'deploy'
  mode '0600'
  content File.read('files/authorized_keys')
end

##
## Security
##

# Add /etc/security/access.conf

file '/etc/security/access.conf' do
  owner 'root'
  group 'root'
  mode '0644'
  content 'deploy : ALL : ALL'
end

# Add /etc/ssh/sshd_config

file '/etc/ssh/sshd_config' do
  owner 'root'
  group 'root'
  mode '0644'
  content File.read('files/sshd_config')
end
