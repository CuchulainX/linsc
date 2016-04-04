require 'rubygems'
require 'mechanize'
require 'csv'
require 'fileutils'
require 'i18n'
require_relative 'proxy'
require_relative 'proxy_handler'
require_relative 'csv_handlers'

# tuck this away into a core_extensions module
class String
  def alnum
    return self.gsub(/[^\p{Alnum}\p{Space}]/u, ' ')
  end
end

class DuckScraper

  include CSVHandlers

  def initialize(working_dir, input_file, output_file, options)
    @working_dir, @input_file, @output_file, @noproxy =
      working_dir, input_file, output_file, options[:noproxy]

    @headers = get_headers(@input_file)
    @headers << "Linkedin Import Status" unless @headers.include?("Linkedin Import Status")
    @headers << "Urls" unless @headers.include?("Urls")
    @input_length = %x(wc -l "#{@input_file}").split[0].to_i - 1
    if File.exist?(@output_file)
      @start = CSV.read(@output_file, headers: true).length
      puts "resuming from row #{@start}"
    else
      create_file(@output_file)
    end
    @cooldown = 5
    @proxies = ProxyHandler.new(@cooldown) unless @noproxy
  end

  def find_profiles
    count = 0

    CSV.foreach(@input_file, headers: true) do |input_row|
      count += 1
      next if @start && @start >= count
      if @proxies
        tries = @proxies.length
      else
        tries = 3
      end
      puts "ddg #{count}/#{@input_length}"
      begin
        unless sufficient_data?(input_row)
          puts "Insufficient data, skipping"
          append_ddg_row(input_row, "Insufficient Data", nil)
          next
        end
        agent = Mechanize.new

        unless @noproxy
          proxy = @proxies.get_proxy
          agent.set_proxy(proxy.ip, proxy.port, proxy.username, proxy.password)
          agent.user_agent = proxy.user_agent
          puts "proxy: #{proxy.ip}"
        end
        sleep(@cooldown) if @noproxy
        query_string = create_query(input_row)
        puts "query string: #{query_string}"
        ddg_page = agent.get('https://www.duckduckgo.com/html')
        search_form = ddg_page.form_with(id: 'search_form_homepage')
        search_form.q = query_string
        results_page = agent.submit(search_form)
        urls = find_results(results_page, input_row)
        if urls.length > 0
          puts "Success! #{urls.length} possible urls found"
          append_ddg_row(input_row, "DDG results found", urls.join(', '))
        else
          puts "no results found"
          append_ddg_row(input_row, "No DDG results found", nil)
        end
        proxy.good if proxy

      rescue StandardError => msg
        tries -= 1
        if tries > 0
          puts "\n\n"
          puts msg
          puts 'RETRYING'
          puts "\n\n"
          proxy.used if proxy
          retry
        else
          append_ddg_row(input_row, msg, nil)
          puts msg
        end
      end
    end
  end

  def append_ddg_row(row, status, urls)
    row << ["Linkedin Import Status", status]
    row << ["Urls", urls]
    output_row = create_row(row, @headers)
    append_to_csv(@output_file, output_row)
  end

  def sufficient_data?(row)
    data_presence = 0
    if row["First Name"] && row["First Name"].alnum.strip != ""
      data_presence += 1
    end
    if row["Last Name"] && row["Last Name"].alnum.strip != ""
      data_presence += 1
    end
    if row["Employer Organization Name 1"] && row["Employer Organization Name 1"].alnum.strip != ""
      data_presence += 1
    end
    if row["Employer 1 Title"] && row["Employer 1 Title"].alnum.strip != ""
      data_presence += 1
    end
    data_presence == 4 ? true : false
  end

  def find_results(page, row)
    matches = []
    full_name = "#{row['First Name']} #{row['Last Name']}".gsub(row["Email"], ' ').alnum.strip
    if page.css("#links .results_links_deep")
      results = page.css("#links .results_links_deep")
    else
      return matches
    end
    results.each do |result|
      if result.at_css("a.result__a")

        url_text = result.css("a.result__a").text.alnum
        url = result.at_css('a.result__a')['href']
        bio = result.css("a.result__snippet").text.alnum || ""
        valid_url = true
        short_title = row["Employer 1 Title"].alnum.split.first(2)
        short_employer = row["Employer Organization Name 1"].alnum.split.first

        if result.css("a.large").text.include?("profiles | LinkedIn")
          valid_url = false
        end
        unless url.include?("linkedin") && (url.include?("/in/") || url.include?("/pub/"))
          valid_url = false
        end

        if valid_url && name_check(url_text, full_name)
          if bio.downcase.include?(short_title.join(' ').downcase) && bio.downcase.include?(short_employer.to_s.downcase)
            matches.unshift(url)
          else
            matches.push(url)
          end
        else
        end
      end
    end
    matches
  end

  def name_check(lin_name, csv_name)
    csv_array = csv_name.downcase.split(" ")
    lin_array = lin_name.downcase.split(" ")
    match = true
    csv_array.each do |chunk|
      unless lin_array.include?(chunk)
        match = false
      end
    end
    return match
  end

  def create_query(row)
    query_parts = [row["First Name"], row["Last Name"], row["Employer 1 Title"],
                   row["Employer Organization Name 1"]]
    query_parts.collect! do |part|
      part.gsub!(row["Email"], ' ')
      part.downcase.alnum.strip
    end
    "linkedin #{query_parts.join(' ')}"
  end

end
