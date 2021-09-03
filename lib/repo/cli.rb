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
require_relative 'commands'
require_relative 'version'

require 'tty/reader'
require 'commander'
require_relative 'patches/highline-ruby_27_compat'

module Repo
  module CLI
    PROGRAM_NAME = ENV.fetch('FLIGHT_PROGRAM_NAME','repo')

    extend Commander::Delegates
    program :application, "Flight Repository Management"
    program :name, PROGRAM_NAME
    program :version, "v#{Repo::VERSION}"
    program :description, 'Manage OpenFlightHPC repositories'
    program :help_paging, false
    default_command :help
    silent_trace!

    error_handler do |runner, e|
      case e
      when TTY::Reader::InputInterrupt
        $stderr.puts "\n#{Paint['WARNING', :underline, :yellow]}: Cancelled by user"
        exit(130)
      else
        Commander::Runner::DEFAULT_ERROR_HANDLER.call(runner, e)
      end
    end

    if ENV['TERM'] !~ /^xterm/ && ENV['TERM'] !~ /rxvt/
      Paint.mode = 0
    end

    class << self
      def cli_syntax(command, args_str = nil)
        command.syntax = [
          PROGRAM_NAME,
          command.name,
          args_str
        ].compact.join(' ')
      end
    end

    global_option '--dry-run', "Don't synchronize any changes back to repos"
    global_option '-a', '--arch ARCH', String, 'Specify architecture (where necessary)'
    global_option '--config CONFIG', String, 'Specify config file name'

    command :publish do |c|
      cli_syntax(c, 'PACKAGE...')
      c.summary = 'Publish a package to the development repo'
      c.action Commands, :publish
      c.description = <<EOF
Publish a package to the development repo.
EOF
    end

    command :promote do |c|
      cli_syntax(c, 'PACKAGE...')
      c.summary = 'Promote a package to the production repo'
      c.action Commands, :promote
      c.description = <<EOF
Promote a package to the production repo.
EOF
    end

    command :reindex do |c|
      cli_syntax(c, 'REPO')
      c.summary = 'Re-index a repo'
      c.action Commands, :reindex
      c.description = <<EOF
Re-index a repo.
EOF
    end

    command :list do |c|
      cli_syntax(c, 'REPO')
      c.summary = 'List packages held in a repo'
      c.action Commands, :list
      c.description = <<EOF
List packages held in a repo.
EOF
      c.option '--terse', 'Suppress everything but package names'
    end

    command :vault do |c|
      cli_syntax(c, 'PACKAGE...')
      c.summary = 'Move a package from the production repo to the vault'
      c.action Commands, :vault
      c.description = <<EOF
Move a package from the production repo to the vault.
EOF
    end

    command :delete do |c|
      cli_syntax(c, 'PACKAGE...')
      c.summary = 'Remove a package from the dev repo'
      c.action Commands, :delete
      c.description = <<EOF
Remove a package from the dev repo.
EOF
    end

    command :stale do |c|
      cli_syntax(c, 'REPO')
      c.summary = 'List stale packages'
      c.action Commands, :stale
      c.description = <<EOF
List stale packages.
EOF
      c.option '--any', 'Show any stale packages, not just minor release multiples'
      c.option '--terse', 'Suppress everything but package names'
    end

    command :'run-release' do |c|
      cli_syntax(c, 'FILE')
      c.summary = 'Build, publish and promote the packages given by FILE'
      c.action Commands, :run_release
      c.description = <<EOF
Build, publish and promote the packages given by FILE
EOF
      c.option '--build', 'Build the packages'
      c.option '--publish', 'Publish packages to dev repos'
      c.option '--promote', 'Promote packages to production repos'
    end
  end
end
