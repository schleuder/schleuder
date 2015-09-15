require 'schleuder/cli/helper'
require 'schleuder/cli/subcommand_fix'
require 'schleuder/cli/subscription'
require 'schleuder/cli/list'
require 'schleuder/cli/runlist'
require 'schleuder/cli/check_keys'
require 'schleuder/cli/install'

module Schleuder
  module Cli
    class Base < Thor

      register(Cli::Subscription,
               'subscription',
               'subscription ...',
               'Create and manage subscriptions')

      register(Cli::List,
               'list',
               'list ...',
               'Create and manage lists')

      register(Cli::Runlist,
               'runlist',
               'runlist list@hostname',
               'Run a message through a list, reading the message from STDIN.')

      register(Cli::Install,
               'install',
               'install',
               'Set up Schleuder initially.')

      register(Cli::CheckKeys,
               "check_keys",
               "check_keys",
               "Check public keys of all lists for expiry")


      desc 'version', 'Show version of schleuder'
      def version
        say Schleuder::VERSION
      end


    end
  end
end
