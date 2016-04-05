# Linsc

## Installation

### Windows

- Make sure Powershell is installed

- Download the Windows Ruby installer from here: http://rubyinstaller.org/downloads/

- Install ruby

- Open Powershell and run the command:
```ruby
gem install linsc
```

- When installation is completed find your gem directory with:
```ruby
gem environment
```

- Navigate to the path listed for INSTALLATION DIRECTORY, then gems -> linsc-(version) -> data

- Here you will find an empty proxies.txt and recruiters.txt

- Fill the recruiters file with your recruiters, ordered by priority. One recruiter per line, comma separated like this:
```
LIN1,
LIN2,
LIN3,
LIN4
```

- Fill proxies.txt, one proxy per line in the form ip:port or ip:port:username:password if using a username/password with the proxies.
```
108.123.523.23:8080:admin:pass
108.123.523.123:8080:admin:pass
108.123.523.535:8080:admin:pass
```
(username and password optional)

## Usage




## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/danmolloy/linsc.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
