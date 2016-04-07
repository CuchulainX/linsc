# Linsc

## Installation

### Windows

- Make sure Powershell is installed

- Download the Windows Ruby installer from here: http://rubyinstaller.org/downloads/
(tested on 2.2.4, but should work on 2.3)

- Make sure Powershell is closed, and install ruby (check all 3 boxes)

- Open Powershell and run the command:
```ruby
gem install linsc
```

- When installation is completed find your gem directory with:
```ruby
gem environment
```

- In your file manager, navigate to the path listed for INSTALLATION DIRECTORY, then gems -> linsc-(version) -> data

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

- Download your linkedin connections export csv files and put them in an empty directory. Each of these files should have exactly the same filename as one of the lines from your recruiters.txt file, and should end with .csv.
It is expected that these csvs will have the following fields: First Name, Last Name, E-mail Address, Company, Job Title. All other fields are ignored.

- Run a Salesforce report and put the csv in the same directory as your LIN files. The required fields for the Salesforce file are: Contact ID, LIN ID, Email.
This file should be named sf_ref.csv

- In Powershell (or any terminal), navigate to the directory and run this command:
```
linsc
```

- There are several optional flags you can provide to modify behaviour. To see the full list of available flags, run:
```
linsc -h
```

- If all proxies get blocked the program will exit. Wait a few hours or a day for the proxies to cool off, then run linsc again. It will pick up where it left off.

- When scraping is complete, import your data. If you had the -i flag set, you must import the contact_insert csv, then export a new report with the fields: LIN ID, Contact ID.
Name this csv history_ref.csv and put it in the same folder as your data. Run linsc again with the -e flag set and the new Contact IDs will be mapped to the education and employment histories for the new contacts. You can now import these new history objects.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/danmolloy/linsc.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
