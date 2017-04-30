describe package 'openssh-server' do
  it { should be_installed }
end

describe service 'sshd' do
  it { should be_running }
  it { should be_enabled }
end

describe port 22 do
  it { should be_listening }
end

describe sshd_config do
  its('Port') { should cmp 22 }
  its('PermitRootLogin') { should eq 'no' }
  its('PasswordAuthentication') { should eq 'no' }
  its('UsePAM') { should eq 'yes' }
  its('PrintMotd') { should eq 'no' }
  its('UsePrivilegeSeparation') { should eq 'sandbox' }
  its('SyslogFacility') { should eq 'AUTHPRIV' }
end
