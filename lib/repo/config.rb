#==============================================================================
# Copyright (C) 2020-present Alces Flight Ltd.
#
# This file is part of OpenFlight Omnibus Builder.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# OpenFlight Omnibus Builder is distributed in the hope that it will be useful, but
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
# OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
# PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
# details.
#
# You should have received a copy of the Eclipse Public License 2.0
# along with OpenFlight Omnibus Builder. If not, see:
#
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on OpenFlight Omnibus Builder, please visit:
# https://github.com/openflighthpc/openflight-omnibus-builder
#==============================================================================
require 'tty-config'
require 'fileutils'

module Repo
  module Config
    class << self
      REPO_DIR_SUFFIX = File.join('flight','repo')

      def data
        @data ||= TTY::Config.new.tap do |cfg|
          cfg.filename = ENV['REPO_CONFIG'] || 'openflight'
          cfg.append_path(File.join(root, 'etc'))
          begin
            cfg.read
          rescue TTY::Config::ReadError
            nil
          end
        end
      end

      def save_data
        FileUtils.mkdir_p(File.join(root, 'etc'))
        data.write(force: true)
      end

      def data_writable?
        File.writable?(File.join(root, 'etc'))
      end

      def root
        @root ||= File.expand_path(File.join(__dir__, '..', '..'))
      end

      def distro
        @distro ||= "".tap do |s|
          if rhel?
            s << "centos/"
            if system('grep -q "release 7" /etc/redhat-release >& /dev/null')
              s << '7'
            elsif system('grep -q "release 8" /etc/redhat-release >& /dev/null')
              s << '8'
            else
              raise RepoError, "unable to determine distro: unknown CentOS release?"
            end
          elsif ubuntu?
            s << "ubuntu"
          else
            raise RepoError, "unable to determine distro"
          end
        end
      end

      def rhel?
        return @is_rhel unless @is_rhel.nil?
        @is_rhel = File.exist?('/etc/redhat-release')
      end

      def ubuntu?
        return @is_ubuntu unless @is_ubuntu.nil?
        @is_ubuntu = File.exist?('/etc/lsb-release')
      end

      def extname
        @extname ||= if rhel?
                       '.rpm'
                     elsif ubuntu?
                       '.deb'
                     else
                       raise RepoError, "unable to determine distro"
                     end
      end

      def region
        @region ||=
          data.fetch(
            'region',
            default: 'eu-west-1'
          )
      end

      def profile
        @profile ||=
          data.fetch(
            'profile',
            default: 'default'
          )
      end

      def repos
        @repos ||=
          data.fetch(
            'repos',
            default: {}
          )
      end

      def arch
        @arch ||=
          data.fetch(
            'arch',
            default: {}
          )[ubuntu? ? 'ubuntu' : 'centos'] || []
      end
    end
  end
end
