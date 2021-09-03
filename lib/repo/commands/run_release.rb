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
require_relative '../command'
require_relative '../repository'
require_relative '../arch'
require_relative '../slack'

require 'yaml'
require 'open3'

module Repo
  module Commands
    class RunRelease < Command
      def run
        if !Slack.auth?
          raise RepoError, "Valid Slack token not found; configure SLACK_TOKEN environment variable"
        end
        assert_arch

        packages.each do |package|
          remove_artefacts(package)
          clean(package)
          build(package)
          # publish(package)
        end
        packages.each do |package|
          # promote(package)
        end
      end

      private

      def packages
        if File.exist?(args[0])
          YAML.load_file(args[0])
        else
          raise RepoError, "file #{args[0]} not found"
        end
      end

      def remove_artefacts(package)
        header "Removing build artefacts #{package['name']}"
        Dir.chdir("/vagrant/builders/#{package['name']}") do
          cmd = ["rm", "-rf", "pkg/#{pkg_glob}*"]
          out, status = Open3.capture2(*cmd)
          puts out
          unless status.success?
            raise RepoError, "Failed to remove artefacts #{package['name']}"
          end
        end
      end

      def clean(package)
        return if package['type'] == 'build.sh'

        header "Cleaning package #{package['name']}"
        Dir.chdir("/vagrant/builders/#{package['name']}") do
          cmd = ["./bin/omnibus", "clean", "--purge", package['name']]
          out, status = Open3.capture2(*cmd)
          puts out
          unless status.success?
            raise RepoError, "Failed to clean #{package['name']}"
          end
        end
      end

      def build(package)
        header "Building package #{package['name']}"
        Dir.chdir("/vagrant/builders/#{package['name']}") do
          cmd =
            if package['type'] == 'build.sh'
              ["./build.sh"]
            else
              ["./bin/omnibus", "build", package['name']]
            end
          out, status = Open3.capture2(*cmd)
          puts out
          unless status.success?
            raise RepoError, "Failed to build #{package['name']}"
          end
          built = Dir.glob("pkg/#{package['name']}?#{package['version']}#{pkg_glob}")
          if built.empty?
            raise RepoError, "Failed to build expected version #{package['name']} #{package['version']}. Found #{built.join(' ')}"
          end
        end
      end

      def publish(package)
        Dir.chdir("/vagrant/builders/#{package['name']}") do
          Dir.glob("pkg/flight-#{pkg_glob}").each do |p|
            cmd = ["/vagrant/scripts/repo", "publish", "-a", arch, p]
            out, status = Open3.capture2(*cmd)
            puts out
            unless status.success?
              raise RepoError, "Failed to publish #{package['name']}"
            end
          end
        end
      end

      def promote(package)
        Dir.chdir("/vagrant/builders/#{package['name']}") do
          Dir.glob("pkg/flight-#{pkg_glob}").each do |p|
            cmd = ["/vagrant/scripts/repo", "promote", "-a", arch, p]
            out, status = Open3.capture2(*cmd)
            puts out
            unless status.success?
              raise RepoError, "Failed to promote #{package['name']}"
            end
          end
        end
      end

      def header(text)
        puts
        puts("=" * text.length)
        puts text
        puts("=" * text.length)
        puts
      end

      def pkg_glob
        case Config.distro
        when 'centos/7'
          '*.el7.*rpm'
        when 'centos/8'
          '*.el8.*rpm'
        when 'ubuntu'
          '*.deb'
        else
          raise RepoError, "unknown distro #{Config.distro}"
        end
      end

      def arch
        @arch ||=
          if options.arch
            Arch.get(options.arch)
          elsif Config.arch.length == 1
            Arch.get(Config.arch[0])
          else
            raise RepoError, "must specify architecture; choose from: #{Config.arch.join(', ')}"
          end
      end
      alias_method :assert_arch, :arch
    end
  end
end
