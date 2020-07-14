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
require_relative 'config'
require_relative 'errors'

require 'fileutils'

module Repo
  class Repository
    class << self
      def get(n, arch)
        r = n.to_s
        if Config.repos.keys.include?(r)
          Repository.new(r, arch, Config.repos[r])
        else
          raise RepoError, "invalid repository: #{r}"
        end
      end
    end

    attr_accessor :name, :arch

    def initialize(n, arch, metadata)
      @name = n
      @arch = arch
      @metadata = metadata
    end

    def prefix
      @metadata['prefix']
    end

    def label
      @metadata['label']
    end

    def bucket_path
      @bucket_path ||= "#{prefix}/#{distro_path}/#{arch.path}"
    end

    def package_root_url
      @bucket_url ||= begin
                        bucket, path_prefix = prefix.split('/',2)
                        if bucket.include?('.')
                          [
                            "https://#{bucket}",
                            path_prefix,
                            distro_path,
                            arch.path
                          ]
                        else
                          [
                            "https://#{bucket}.s3.#{Config.region}.amazonaws.com",
                            path_prefix,
                            distro_path,
                            arch.path
                          ]
                        end.join('/')
                      end
    end

    def wd
      @wd ||= "/tmp/#{bucket_path}"
    end

    def terse!
      @terse = true
    end

    def add(f)
      puts "Copying #{f} to #{wd}..." unless @terse
      if File.exist?(File.join(wd, File.basename(f)))
        raise RepoError, "already exists: #{File.basename(f)}"
      end
      FileUtils.cp(f, wd)
    end

    def remove(f)
      puts "Removing #{f}..." unless @terse
      if !File.exist?(File.join(wd, File.basename(f)))
        raise RepoError, "not found: #{File.basename(f)}"
      end
      FileUtils.rm(f)
    end

    def find(f)
      files = Dir.glob(File.join(wd, "#{f}*"))
      if files.length == 0
        raise RepoError, "could not find match for: #{f}"
      else
        files
      end
    end

    def download
      FileUtils.mkdir_p(wd)
      cmd = %(aws --profile #{Config.profile} --region #{Config.region} s3 sync --delete s3://#{bucket_path} #{wd})
      run(cmd)
    end

    def index
      if Config.rhel?
        update = File.exist?(File.join(wd, 'repodata', 'repomd.xml'))
        cmd = %(createrepo -v #{update ? '--update ' : ''} --deltas #{wd})
        run(cmd)
      elsif Config.ubuntu?
        # create a list of packages, allowing multiple versions
        Dir.chdir(File.join(wd, '..', '..', '..', '..')) do
          cmd = %(dpkg-scanpackages -m dists/stable/#{arch.path} > dists/stable/#{arch.path}/Packages)
          run(cmd)
          cmd = %(cat dists/stable/#{arch.path}/Packages | gzip -9c > dists/stable/#{arch.path}/Packages.gz)
          run(cmd)
        end

        # Create distro release file
        Dir.chdir(File.join(wd, '..', '..')) do
          File.write(
            'Release',
            <<EOF
Origin: OpenFlightHPC
Label: #{label}
Suite: openflighthpc
Codename: stable
Architectures: #{arch.name}
Components: main
Description: #{label} for Ubuntu
#{`apt-ftparchive release .`}
EOF
          )

          # GPG signing
          cmd = %(rm -f InRelease && gpg --default-key openflighthpc --clearsign -o InRelease Release)
          run(cmd)
        end
      end
    end

    def upload
      cmd = %(aws --profile #{Config.profile} --region #{Config.region} s3 sync --delete #{wd} s3://#{bucket_path} --acl public-read)
      run(cmd)
    end

    def list
      Dir.glob(File.join(wd, "*#{Config.extname}")).map(&File.method(:basename)).sort
    end

    def run(cmd)
      unless @terse
        puts "Command: #{cmd}"
        puts "---------------------------------------\n\n"
      end
      IO.popen(cmd, :err=>[:child, :out]) do |io|
        io.each do |l|
          puts " > #{l}" unless @terse
        end
      end
      puts "\n---------------------------------------" unless @terse
      raise RepoError, "command failed: #{cmd}" unless $?.success?
    end

    def distro_path
      @distro_path ||= if Config.ubuntu?
                         'ubuntu/dists/stable'
                       else
                         Config.distro
                       end
    end
  end
end
