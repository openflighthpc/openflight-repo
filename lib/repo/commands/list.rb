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

module Repo
  module Commands
    class List < Command
      def run
        if !options.terse
          puts "Listing repository: #{repo.name} (#{repo.arch.name})"
        end
        repo.terse! if options.terse
        repo.download
        repo.list.each do |f|
          puts f
        end
      end

      def repo
        @repo ||= Repository.get(args[0], arch)
      end

      def arch
        @arch ||= if options.arch
                    Arch.get(options.arch)
                  elsif Config.arch.length == 1
                    Arch.get(Config.arch[0])
                  else
                    raise RepoError, "must specify architecture; choose from: #{Config.arch.join(', ')}"
                  end
      end
    end
  end
end
