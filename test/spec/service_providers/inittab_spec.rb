#
# Copyright 2015, Noah Kantrowitz
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'spec_helper'

describe PoiseService::ServiceProviders::Inittab do
  service_provider('inittab')
  step_into(:poise_service)
  let(:inittab) { '' }
  before do
    allow(IO).to receive(:read).and_call_original
    allow(IO).to receive(:read).with('/etc/inittab').and_return(inittab)
  end

  context 'with action :enable' do
    recipe do
      poise_service 'test' do
        command 'myapp --serve'
      end
    end

    it { is_expected.to render_file('/sbin/poise_service_test').with_content(<<-EOH) }
#!/bin/sh
exec /opt/chef/embedded/bin/ruby -e 'IO.write("/var/run/test.pid", Process.pid); Dir.chdir("/"); Process::UID.change_privilege("root"); ENV["HOME"] = Dir.home("root") rescue nil; ; exec(*["myapp", "--serve"])'
EOH

    context 'with an empty inittab' do
      it { is_expected.to render_file('/etc/inittab').with_content(eq(<<-EOH)) }
# poise_service[test]
pcg:2345:respawn:/sbin/poise_service_test
EOH
    end # /context with an empty inittab

    context 'with a normal inittab' do
      let(:inittab) { <<-EOH }
# Run gettys in standard runlevels
co:2345:respawn:/sbin/agetty xvc0 9600 vt100-nav
#1:2345:respawn:/sbin/mingetty tty1
#2:2345:respawn:/sbin/mingetty tty2
#3:2345:respawn:/sbin/mingetty tty3
#4:2345:respawn:/sbin/mingetty tty4
#5:2345:respawn:/sbin/mingetty tty5
#6:2345:respawn:/sbin/mingetty tty6

# Run xdm in runlevel 5
x:5:respawn:/etc/X11/prefdm -nodaemon
EOH

      it { is_expected.to render_file('/etc/inittab').with_content(eq(<<-EOH)) }
# Run gettys in standard runlevels
co:2345:respawn:/sbin/agetty xvc0 9600 vt100-nav
#1:2345:respawn:/sbin/mingetty tty1
#2:2345:respawn:/sbin/mingetty tty2
#3:2345:respawn:/sbin/mingetty tty3
#4:2345:respawn:/sbin/mingetty tty4
#5:2345:respawn:/sbin/mingetty tty5
#6:2345:respawn:/sbin/mingetty tty6

# Run xdm in runlevel 5
x:5:respawn:/etc/X11/prefdm -nodaemon
# poise_service[test]
pcg:2345:respawn:/sbin/poise_service_test
EOH
    end # /context with a normal inittab

    context 'with an existing line' do
      let(:inittab) { <<-EOH }
# Run gettys in standard runlevels
co:2345:respawn:/sbin/agetty xvc0 9600 vt100-nav
#1:2345:respawn:/sbin/mingetty tty1
#2:2345:respawn:/sbin/mingetty tty2
#3:2345:respawn:/sbin/mingetty tty3
#4:2345:respawn:/sbin/mingetty tty4
#5:2345:respawn:/sbin/mingetty tty5
#6:2345:respawn:/sbin/mingetty tty6

# Run xdm in runlevel 5
x:5:respawn:/etc/X11/prefdm -nodaemon
# poise_service[test]
pcg:2345:respawn:/sbin/poise_service_test2
EOH

      it { is_expected.to render_file('/etc/inittab').with_content(eq(<<-EOH)) }
# Run gettys in standard runlevels
co:2345:respawn:/sbin/agetty xvc0 9600 vt100-nav
#1:2345:respawn:/sbin/mingetty tty1
#2:2345:respawn:/sbin/mingetty tty2
#3:2345:respawn:/sbin/mingetty tty3
#4:2345:respawn:/sbin/mingetty tty4
#5:2345:respawn:/sbin/mingetty tty5
#6:2345:respawn:/sbin/mingetty tty6

# Run xdm in runlevel 5
x:5:respawn:/etc/X11/prefdm -nodaemon
# poise_service[test]
pcg:2345:respawn:/sbin/poise_service_test
EOH
    end # /context with an existing line

    context 'with an existing line that matches' do
      let(:inittab) { <<-EOH }
# Run gettys in standard runlevels
co:2345:respawn:/sbin/agetty xvc0 9600 vt100-nav
#1:2345:respawn:/sbin/mingetty tty1
#2:2345:respawn:/sbin/mingetty tty2
#3:2345:respawn:/sbin/mingetty tty3
#4:2345:respawn:/sbin/mingetty tty4
#5:2345:respawn:/sbin/mingetty tty5
#6:2345:respawn:/sbin/mingetty tty6

# Run xdm in runlevel 5
x:5:respawn:/etc/X11/prefdm -nodaemon
# poise_service[test]
pcg:2345:respawn:/sbin/poise_service_test
EOH

      it { is_expected.to_not render_file('/etc/inittab') }
    end # /context with an existing line that matches
  end # /context with action :enable

  context 'with action :disable' do
    recipe do
      poise_service 'test' do
        action :disable
      end
    end

    it { is_expected.to delete_file('/sbin/poise_service_test') }
    it { is_expected.to delete_file('/var/run/test.pid') }

    context 'with an empty inittab' do
      it { is_expected.to_not render_file('/etc/inittab') }
    end # /context with an empty inittab

    context 'with a normal inittab' do
      let(:inittab) { <<-EOH }
# Run gettys in standard runlevels
co:2345:respawn:/sbin/agetty xvc0 9600 vt100-nav
#1:2345:respawn:/sbin/mingetty tty1
#2:2345:respawn:/sbin/mingetty tty2
#3:2345:respawn:/sbin/mingetty tty3
#4:2345:respawn:/sbin/mingetty tty4
#5:2345:respawn:/sbin/mingetty tty5
#6:2345:respawn:/sbin/mingetty tty6

# Run xdm in runlevel 5
x:5:respawn:/etc/X11/prefdm -nodaemon=
EOH

      it { is_expected.to_not render_file('/etc/inittab') }
    end # /context with a normal inittab

    context 'with an existing line' do
      let(:inittab) { <<-EOH }
# Run gettys in standard runlevels
co:2345:respawn:/sbin/agetty xvc0 9600 vt100-nav
#1:2345:respawn:/sbin/mingetty tty1
#2:2345:respawn:/sbin/mingetty tty2
#3:2345:respawn:/sbin/mingetty tty3
#4:2345:respawn:/sbin/mingetty tty4
#5:2345:respawn:/sbin/mingetty tty5
#6:2345:respawn:/sbin/mingetty tty6

# Run xdm in runlevel 5
x:5:respawn:/etc/X11/prefdm -nodaemon
# poise_service[test]
pcg:2345:respawn:/sbin/poise_service_test2
EOH

      it { is_expected.to render_file('/etc/inittab').with_content(eq(<<-EOH)) }
# Run gettys in standard runlevels
co:2345:respawn:/sbin/agetty xvc0 9600 vt100-nav
#1:2345:respawn:/sbin/mingetty tty1
#2:2345:respawn:/sbin/mingetty tty2
#3:2345:respawn:/sbin/mingetty tty3
#4:2345:respawn:/sbin/mingetty tty4
#5:2345:respawn:/sbin/mingetty tty5
#6:2345:respawn:/sbin/mingetty tty6

# Run xdm in runlevel 5
x:5:respawn:/etc/X11/prefdm -nodaemon
EOH
    end # /context with an existing line
  end # /context with action :disable

  context 'with action :stop' do
    recipe do
      poise_service 'test' do
        action :stop
      end
    end

    it { expect { subject }.to raise_error NotImplementedError }
  end # /context with action :stop

  describe '#pid' do
    subject { described_class.new(nil, nil) }
    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with('/pid').and_return(true)
      allow(IO).to receive(:read).and_call_original
      allow(IO).to receive(:read).with('/pid').and_return('100')
      expect(subject).to receive(:pid_file).and_return('/pid').at_least(:once)
    end
    its(:pid) { is_expected.to eq 100 }
  end # /describe #pid
end
