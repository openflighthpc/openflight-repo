# frozen_string_literal: true
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
module Repo
  module Slack
    class << self
      def auth?
        if ENV['SLACK_TOKEN'].nil?
          false
        else
          system(File.join(Config.root, 'libexec', 'slack-check.sh'))
        end
      end

      def say(package, repo, repo_url, package_url, production)
        print "Sending Slack publication notification... "
        IO.popen(
          {
            'PACKAGE' => package,
            'REPO' => repo,
            'REPO_S3_URL' => repo_url,
            'PACKAGE_URL' => package_url,
            'NAME' => Config.name,
            'BUILDER_REPO' => Config.builder_repo,
            'EMOJI' => Config.emoji,
            'PRODUCTION' => production.to_s,
          },
          File.join(Config.root, 'libexec', 'slack-notify.sh'),
          :err=>[:child, :out]
        ) do |io|
          io.readlines
        end
        puts "Done."
      end
    end
  end
end
