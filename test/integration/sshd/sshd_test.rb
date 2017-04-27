describe package 'openssh-server' do
  it { should be_installed }
end

describe service 'sshd' do
  it { should be_running }
end

describe port 22 do
  it { should be_listening }
end
