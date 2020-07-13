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
require_relative '../arch'
require_relative '../repository'
require_relative '../slack'

module Repo
  module Commands
    class Promote < Command
      def run
        if !Slack.auth?
          raise RepoError, "Valid Slack token not found; configure SLACK_TOKEN environment variable"
        end
        dev.download
        sources = files.map{|f| dev.find(f)}.flatten.uniq
        prod.download
        sources.each do |s|
          prod.add(s)
        end
        prod.index
        unless options.dry_run
          prod.upload
          sources.each do |f|
            Slack.say(
              File.basename(f),
              "#{Config.distro}:#{arch.name}",
              "https://#{prod.bucket_path}/#{File.basename(f)}"
            )
          end
        end
      end

      def files
        @files ||= args.map{|a| File.basename(a)}
      end

      def arch
        @arch ||= begin
                    if options.arch.nil?
                      if Config.arch.length == 1
                        arch_str = Config.arch[0]
                      else
                        raise RepoError, "must specify architecture"
                      end
                    else
                      arch_str = options.arch
                    end
                    Arch.get(arch_str)
                  end
      end

      def dev
        @dev ||= Repository.get(:dev, arch)
      end

      def prod
        @prod ||= Repository.get(:prod, arch)
      end
    end
  end
end
