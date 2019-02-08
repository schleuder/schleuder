require 'json-schema'

RSpec::Matchers.define :match_json_schema do |schema|
  match do |response_body|
    schema_directory = "#{Dir.pwd}/spec/support/api/schemas"
    schema_path = "#{schema_directory}/#{schema}.json"
    JSON::Validator.validate!(schema_path, response_body, strict: true)
  end
end
