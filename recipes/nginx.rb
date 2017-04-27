##
## Install
##

# Install repo config
yum_repository 'nginx' do
  action :create
  description 'Nginx repo'
  baseurl  "http://nginx.org/packages/#{node[:platform]}/7/$basearch/"
  gpgkey   'http://nginx.org/keys/nginx_signing.key'
  gpgcheck true
  enabled  true
end

# Install the package
package('nginx') { action :install }
package('openssl') { action :install }

##
## Configure
##

# Create the config directory
directory '/etc/nginx' do
  action :create
  owner 'root'
  group 'root'
  mode 0755
end

# Configure nginx
cookbook_file '/etc/nginx/nginx.conf' do
  action :create
  owner 'root'
  group 'root'
  mode  0644
  source 'nginx/nginx.conf'
  notifies :restart, 'systemd_unit[nginx]', :delayed
end

# Create the default certificates
directory '/etc/nginx/ssl' do
  action :create
  owner 'root'
  group 'root'
  mode 0755
end

execute 'make_nginx_priv' do
  key_file = '/etc/nginx/ssl/key.pem'
  action :nothing
  command "openssl genrsa 4096 -nodes > #{key_file}"
  notifies :run, 'execute[make_nginx_cert]', :immediately
end

execute 'make_nginx_cert' do
  key_file = '/etc/nginx/ssl/key.pem'
  cert_file = '/etc/nginx/ssl/cert.pem'
  action :nothing
  command "openssl req -batch -key #{key_file} -new | openssl x509 -req -signkey #{key_file} > #{cert_file}"
  notifies :restart, 'systemd_unit[nginx]', :delayed
end

file '/etc/nginx/ssl/key.pem' do
  action :create
  owner 'root'
  group 'root'
  mode 0600
  notifies :run, 'execute[make_nginx_priv]', :immediately
end

file '/etc/nginx/ssl/cert.pem' do
  action :create
  owner 'root'
  group 'root'
  mode 0644
  notifies :run, 'execute[make_nginx_cert]', :immediately
end

##
## Start
##

# Start nginx
systemd_unit('nginx') { action [ :start, :enable ] }
