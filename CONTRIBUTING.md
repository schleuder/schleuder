Contributing
============

To contribute please follow this workflow:

1. Talk to us! E.g. create an issue about your idea or problem.
2. Fork the repository and work in a meaningful named branch that is based off of our "master".
3. Enable CI: In your fork, go to Settings -> CI / CD -> Expand next to Runners settings -> Enable shared Runners.
4. Commit in rather small chunks but don't split depending code across commits. Please write sensible commit messages.
5. Please add tests for your feature or bugfix.
6. If in doubt request feedback from us!
7. When finished create a merge request.


Thank you for your interest!


## Tutorial: Getting started with schleuder development

This short beginner's guide helps you getting started in schleuder development.

### Set up environment
First, we have to set up the development environment. We use [rvm](https://rvm.io/rvm/basics) to 
avoid dependency version mixups with other ruby projects.

1. Install ruby and [rvm](https://rvm.io/rvm/basics).
2. Clone the schleuder repository and cd into it.
3. Create a rvm gemset:
   	```
	rvm gemset create schleuder
	rvm gemset use schleuder
	rvm gemset list		# checks if it uses the correct gemset
	```
4. Install bundler: `gem install bundler`
5. Install dependencies with bundler:
	```
	bundle install
	``` 

### Getting started with development
To start with the actual development, we first have to get the schleuder system running.

1. Install schleuder: `rvmsudo bin/schleuder install`
2. Set permissions:
	```
	sudo chown -R <your_dev_user> /var/lib/schleuder/
	sudo chown -R <your_dev_user> /etc/schleuder/
	```
3. Clone and install schleuder-cli:
	```
	wget https://0xacab.org/schleuder/schleuder-cli/raw/master/gems/schleuder-cli-0.1.0.gem.sig && gpg --verify schleuder-cli-0.1.0.gem.sig
	gem install schleuder-cli-0.1.0.gem
	```
4. Configure schleuder-cli:
	```
	schleuder cert fingerprint | cut -d ' ' -f 4  # copy the output to tls_fingerprint in ~/.schleuder-cli/schleuder-cli.yml
	schleuder new_api_key # copy the output to api_key in ~/.schleuder-cli/schleuder-cli.yml AND /etc/schleuder/schleuder.yml
	```
5. Start schleuder-api-daemon: `schleuder-api-daemon`
6. Test if everything works by running (should not return an error): `schleuder-cli lists list`

#### Manual testing and debugging 

After we have implemented our code, it is time to test and debug it. 
To do that manually, we create a test list via schleuder-cli and throw in
test emails. There is a mock smtp daemon in `bin/schleuder-smtpd.rb` to help us test without a fully
configured mail server. 
This short tutorial will help you initialize the manual debug setup.

0. Create a list with a test public key:
	```
	gpg --export --armor <keyname> > pubkey.gpg
	schleuder-cli lists new test@test <email> pubkey.gpg
	```
1. Start fake smtp daemon: `rvmsudo ruby bin/schleuder-smtpd.rb`. Throw a test mail into it to verify it is running:
	```
	echo "test" | mailx -s "test" -S smtp=smtp://localhost list@list
	```
2. Create an email to send and store it in a file (e.g. `mail.txt`):
	```
	To: test@test
	From: root@localhost
	Subject: Test
	
	Test
	```
3. Throw email in `cat mail.txt | schleuder work test@test`. The receivers of the mail can be seen in the output of
`schleuder-smtpd.rb`
4. Start debugging your code!

From that we additionally can use schleuder-cli to set the list options or create different test scenarios.
Remember to restart the `schleuder-api-daemon` if you make any changes to the list config options.

#### Changing the database
- To change the database add a file to `db/migrate/` that has the same structure as the files in there. Then call `rake db:migrate`.
- To downgrade a specific change use: `rake db:migrate:down VERSION=<version number>`
- To upgrade a specific change use: `rake db:migrate:up VERSION=<version number>`

#### Automated tests
- Automated tests are defined in `spec/`
- Execute automated tests: 
	```
	SCHLEUDER_ENV=test SCHLEUDER_CONFIG=spec/schleuder.yml bundle exec rake db:init
	bundle exec rspec
	``` 
