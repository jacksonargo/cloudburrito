describe package 'nginx' do
  it { should be_installed }
end

describe service 'nginx' do
  it { should be_running }
end

describe port 80 do
  it { should be_listening }
end

describe port 443 do
  it { should be_listening }
end

describe command 'curl http://localhost -H X-Forwarded-Proto:https -H Host:cloudburrito.us' do
  its('stdout') { should match /Welcome/ }
end

describe command 'curl https://localhost -H Host:cloudburrito.us' do
  its('stdout') { should match /Welcome/ }
end

describe command 'curl http://localhost -H Host:cloudburrito.us -I' do
  its('stdout') { should match /Location: https:\/\/cloudburrito.us/ }
end

describe command 'curl http://localhost -I' do
  its('stdout') { should match /HTTP\/1.1 403 Forbidden/ }
end

describe command 'curl https://localhost -Ik' do
  its('stdout') { should match /HTTP\/1.1 403 Forbidden/ }
end
