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

module Repo
  module Commands
    class Publish < Command
      def run
        if !Slack.auth?
          raise RepoError, "Valid Slack token not found; configure SLACK_TOKEN environment variable"
        end
        if !clean_git?
          raise RepoError, "Uncommitted changes detected"
        end
        if !same_arch?
          raise RepoError, "Mixed arch packages detected"
        end
        repo.download
        files.each do |f|
          repo.add(f)
        end
        repo.index
        unless options.dry_run
          repo.upload
          files.each do |f|
            Slack.say(
              File.basename(f),
              "#{Config.distro}:#{arch.name}",
              "https://#{repo.bucket_path}/#{File.basename(f)}"
            )
          end
        end
      end

      def files
        @files ||= args.map{|a| file(a)}
      end

      def file(a)
        if File.exist?(a)
          if File.extname(a) == Config.extname
            a
          else
            raise RepoError, "file has incorrect extension: #{a}"
          end
        else
          raise RepoError, "file not found: #{a}"
        end
      end

      def arch
        @arch ||= arches.first
      end

      def arch_for(f)
        begin
          # determine architecture based on filename
          arch_str = if Config.rhel?
                       `rpm -qip #{f} |grep '^Architecture' |awk '{print $2}'`.chomp
                     elsif Config.ubuntu?
                       `dpkg-deb -I #{f} |grep '^ Architecture' |awk '{print $2}'`.chomp
                     else
                       raise RepoError, "unable to determine architecture for: #{f}"
                     end
          if arch_str.empty?
            raise RepoError, "unable to determine architecture for: #{f}"
          elsif arch_str == 'noarch' || arch_str == 'all'
            if options.arch.nil?
              if Config.arch.length == 1
                arch_str = Config.arch[0]
              else
                raise RepoError, "must specify architecture for noarch packages"
              end
            else
              arch_str = options.arch
            end
          end
          Arch.get(arch_str)
        end
      end

      def repo
        @repo ||= Repository.get(:dev, arch)
      end

      def clean_git?
        files.each do |f|
          system(File.join(Config.root, 'libexec', 'committed-check.sh'), f)
        end
      end

      def arches
        @arches ||= files.map{|f| arch_for(f)}.uniq
      end

      def same_arch?
        arches.length == 1
      end
    end
  end
end
