#!/usr/bin/env ruby

# This script gets the target branch of a specific merge request. This
# is useful for example to check for a CHANGELOG edit.
#
# To enable the "export" of the env var to the parent (calling) shell,
# this script needs to be called in the following way:
# source <(./get-target-branch.rb)

require 'net/http'
require 'uri'
require 'json'

uri = URI.parse('https://0xacab.org/api/v4/projects/schleuder%2Fschleuder/merge_requests?state=opened')
response = Net::HTTP.get(uri)
json_data = JSON.parse(response)

if ! json_data.is_a?(Array)
  puts json_data
  exit 1
end

json_data.each do |merge_request|
  if merge_request['sha'] == ENV['CI_COMMIT_SHA']
    puts "export target_branch=#{merge_request['target_branch']}"
    break
  end
end
