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
require 'logger'

module Repo
  module Commands
    class RunRelease < Command

      # The package that is being built.
      class TargetPackage
        attr_reader :name, :version, :build_type

        def initialize(hash, arch)
          @name = hash['name']
          @version = hash['version']
          @build_type = hash['build_type'] || 'omnibus'
          @arch = arch
        end

        # Paths to the built package files to publish.
        def build_artefacts
          Dir.glob("#{dir}/pkg/flight-*#{version}#{distro_glob}") + noarch_packages
        end

        # The names of the built packages.  Used to promote.
        def built_package_names
          build_artefacts.map { |p| File.basename(p) }
        end

        def dir
          "/vagrant/builders/#{name}"
        end

        private

        def noarch_packages
          return [] if Config.distro == 'ubuntu'

          exclude =
            case Config.distro
            when 'centos/7'
              /\.el8\./
            when 'centos/8'
              /\.el7\./
            end

          Dir.glob("#{dir}/pkg/flight-*#{version}*noarch*.rpm").select do |p|
            name = File.basename(p)
            !name.match(exclude)
          end
        end

        # A glob that matches the built RPMs or Debs for this package.
        def distro_glob
          case Config.distro
          when 'centos/7'
            # XXX match '*noarch.rpm' too.
            "*.el7.#{@arch.name}.rpm"
          when 'centos/8'
            # XXX match '*noarch.rpm' too.
            "*.el8.#{@arch.name}.rpm"
          when 'ubuntu'
            '*.deb'
          else
            raise RepoError, "unknown distro #{Config.distro}"
          end
        end
      end

      def run
        if !Slack.auth?
          raise RepoError, "Valid Slack token not found; configure SLACK_TOKEN environment variable"
        end
        assert_arch

        packages.each do |package|
          if options.build
            remove_artefacts(package)
            clean(package)
            build(package)
          end
          if options.publish
            publish(package)
          end
        end

        if options.promote
          packages.each do |package|
            promote(package)
          end
        end
      ensure
        logger.close
      end

      private

      def packages
        if File.exist?(args[0])
          YAML.load_file(args[0]).map { |p| TargetPackage.new(p, arch) }
        else
          raise RepoError, "file #{args[0]} not found"
        end
      end

      def remove_artefacts(package)
        header "Removing build artefacts #{package.name}"
        package.build_artefacts.each do |p|
          unless FileUtils.rm_f(p, verbose: true)
            raise RepoError, "Failed to remove artefacts #{package.name}"
          end
        end
      end

      def clean(package)
        return unless package.build_type == 'omnibus'

        header "Cleaning package #{package.name}"
        Dir.chdir(package.dir) do
          cmd = ["./bin/omnibus", "clean", "--purge", package.name]
          out, status = Open3.capture2(*cmd)
          puts out
          unless status.success?
            raise RepoError, "Failed to clean #{package.name}"
          end
        end
      end

      def build(package)
        header "Building package #{package.name}"
        Dir.chdir(package.dir) do
          cmd =
            case package.build_type
            when 'build.sh'
              ["./build.sh"]
            when 'omnibus'
              ["./bin/omnibus", "build", package.name]
            else
              raise RepoError, "unknown build type #{package.build_type}"
            end

          out, status = Open3.capture2(*cmd)
          puts out
          unless status.success?
            raise RepoError, "Failed to build #{package.name}"
          end

          found_expected = package.built_package_names.any? do |p|
            p.match(/#{package.name}[-_]#{package.version}/)
          end
          unless found_expected
            raise RepoError, "Failed to build expected version #{package.name}-#{package.version}. Found #{package.built_package_names.join(' ')}"
          end

          subheader "Built the following"
          package.built_package_names.each do |p|
            puts "  #{p}"
            logger.info("Built #{p}")
          end
          puts
        end
      end

      def publish(package)
        package.build_artefacts.each do |p|
          cmd = ["/vagrant/scripts/repo", "publish", "-a", arch, p]
          out, status = Open3.capture2(*cmd)
          puts out
          unless status.success?
            raise RepoError, "Failed to publish #{package.name}"
          end
          logger.info("Published #{p}")
        end
      end

      def promote(package)
        package.built_package_names.each do |p|
          cmd = ["/vagrant/scripts/repo", "promote", "-a", arch, p]
          out, status = Open3.capture2(*cmd)
          puts out
          unless status.success?
            raise RepoError, "Failed to promote #{package.name}"
          end
          logger.info("Promoted #{p}")
        end
      end

      def header(text)
        puts
        puts("=" * text.length)
        puts text
        puts("=" * text.length)
        puts
      end

      def subheader(text)
        puts
        puts text
        puts("-" * text.length)
        puts
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

      def logger
        return @logger if @logger
        file = File.open('/vagrant/run_release_built_packages.log', File::WRONLY | File::APPEND | File::CREAT)
        @logger = Logger.new(file, level: 'INFO')
      end
    end
  end
end
