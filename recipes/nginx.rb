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

# Start nginx
systemd_unit('nginx') { action [ :start, :enable ] }

# Configure nginx
file '/etc/nginx/nginx.conf' do
  action :create
  owner 'root'
  group 'root'
  mode  0644
  content ''
  notifies :restart, 'systemd_unit[nginx]', :delayed
end
