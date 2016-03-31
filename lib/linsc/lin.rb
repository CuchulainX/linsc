require 'rubygems'
require 'mechanize'
require 'csv'
require 'fileutils'
require 'i18n'
require_relative 'proxy'
require_relative 'proxy_handler'
require_relative 'csv_handlers'
require_relative 'parsers'

# tuck this away into a core_extensions module
class String
  def alnum
    return self.gsub(/[^\p{Alnum}\p{Space}]/u, ' ')
  end
end

class NilClass
  def text
    return nil
  end
  def [](options = {})
    return nil
  end
  def css(options = {})
    return nil
  end
  def gsub(a, b)
    return nil
  end
  def at_css(options = {})
    return nil
  end
  def slice(a, b, options = {})
    return nil
  end
  def include?(a)
    return false
  end
  def gsub!(a, b)
    return nil
  end

end

class LinScraper
  include CSVHandlers
  include Parsers

  def initialize(working_dir, input_file, options)
    @working_dir, @input_file, @options = working_dir, input_file, options
    @output_update = "#{@working_dir}contact_update.csv" if @options[:update]
    @output_insert = "#{@working_dir}contact_insert.csv" if @options[:insert]
    @output_employment_update = "#{@working_dir}contact_employment_update.csv" if @options[:update]
    @output_employment_insert = "#{@working_dir}contact_employment_insert.csv" if @options[:insert]
    @output_education_update = "#{@working_dir}contact_education_update.csv" if @options[:update]
    @output_education_insert = "#{@working_dir}contact_education_insert.csv" if @options[:insert]

    @cooldown = 20
    @noproxy = options[:noproxy]
    @proxies = ProxyHandler.new(@cooldown) unless @options[:noproxy]
    @headers = get_headers(@input_file)
    @new_headers = ["Contact ID", "LIN ID", "CV TR", "Account Name", "Linkedin Import Status", "First Name", "Last Name", "Email", "LinkedIn Profile", "Candidate ID",
            "LIN 1st Degree", "Title", "Contact Country", "Contact LIN Sector", "Resume Last Updated", "LIN Import Date", "CV Uploaded",
            "Employer 1 Title", "Employer Organization Name 1", "Employer 1 Start Date",
            "Employer 1 End Date", "Employer 1 Location", "Employer 1 Description",
            "Employer 2 Title", "Employer Organization Name 2", "Employer 2 Start Date",
            "Employer 2 End Date", "Employer 2 Location", "Employer 2 Description",
            "Employer 3 Title", "Employer Organization Name 3", "Employer 3 Start Date",
            "Employer 3 End Date", "Employer 3 Location", "Employer 3 Description",
            "License or Certification Name 1", "License or Certification Name 2",
            "License or Certification Credential Type", "Education School 1",
            "Education Degree Name 1", "Education Degree Date 1",
            "Education School 2", "Education Degree Name 2",
            "Education Degree Date 2", "Text Resume"]
    @new_headers.each do |header|
      @headers << header unless @headers.include?(header)
    end
    @headers.delete('Urls')
    @employment_headers = ["Contact ID", "Employer Name", "Job Title", "Start Date", "End Date", "Location", "LIN ID"]
    @education_headers = ["Contact ID", "School Name", "Major", "Graduation Year", "LIN ID"]
    @input_length = %x(wc -l "#{@input_file}").split[0].to_i - 1
    I18n.available_locales = [:en]
    if (@output_update && File.exist?(@output_update)) || (@output_insert && File.exist?(@output_insert))
      if @output_update
        update_length = CSV.read(@output_update, headers: true).length
      else
        update_length = 0
      end
      if @output_insert
        insert_length = CSV.read(@output_insert, headers: true).length
      else
        insert_length = 0
      end
      @start = update_length + insert_length
    end
    [@output_insert, @output_update].each do |file|
      if file
        create_file(file) unless File.exist?(file)
      end
    end
    [@output_employment_update, @output_employment_insert].each do |file|
      if file
        create_file_with_headers(file, @employment_headers)
      end
    end
    [@output_education_update, @output_education_insert].each do |file|
      if file
        create_file_with_headers(file, @education_headers)
      end
    end
  end

  def name_check(lin_name, csv_name)
    csv_array = csv_name.downcase.alnum.split(" ")
    lin_array = lin_name.downcase.alnum.split(" ")
    match = true
    csv_array.each do |chunk|
      unless lin_array.include?(chunk)
        match = false
      end
    end
    return match
  end



  def format_date(input_date)
    if input_date.nil?
      return nil
    end
    begin
      date_arr = input_date.split(" ")
      if date_arr.length == 1
        output_date = Date.strptime(input_date, "%Y")
        return output_date.strftime("%Y-%m-%d")
      elsif date_arr.length == 2
        output_date = Date.strptime(input_date, "%B %Y")
        return output_date.strftime("%Y-%m-%d")
      else
        return nil
      end
    rescue
      if date_arr.length == 2
        return format_date(date_arr[1])
      else
        return nil
      end
    end
  end

  def validate(url, row)
    puts "url: #{url}"
    begin
      agent = Mechanize.new

      unless @noproxy
        proxy = @proxies.get_proxy
        agent.set_proxy(proxy.ip, proxy.port, proxy.username, proxy.password)
        agent.user_agent = proxy.user_agent
        puts "proxy: #{proxy.ip}"
      end
      sleep(@cooldown) if @noproxy
      page = agent.get(url)
      puts 'ACCESS GRANTED'

      return false unless page.at_css("#name") && page.css("#experience .positions .position")
      return false unless name_check(page.at_css("#name").text, "#{row['First Name']} #{row['Last Name']}")
      positions = page.css("#experience .positions .position")

      match = false
      positions.each do |position|
        if position.at_css("header .item-title a") && position.at_css("header .item-subtitle")
          profile_title = I18n.transliterate(position.at_css("header .item-title a").text).alnum
          profile_employer = I18n.transliterate(position.at_css("header .item-subtitle").text).alnum
          title = I18n.transliterate(row['Employer 1 Title']).alnum
          employer = I18n.transliterate(row['Employer Organization Name 1']).alnum
          if name_check(profile_title, title) && name_check(profile_employer, employer)
            match = true
          end
        end
      end
      proxy.good if proxy
      if match
        return [url, page]
      else
        return false
      end
    rescue StandardError => e
      puts e
      if e.to_s.start_with?('999')
        proxy.dead if proxy
        retry
      elsif e.to_s.start_with?('404') || e.to_s.start_with?('403')
        proxy.good if proxy
        return false
      else
        puts e.backtrace
        proxy.used if proxy
        retry
      end
    end
  end

  def start
    count = 0
    CSV.foreach(@input_file, headers: true) do |input_row|
      count += 1
      next if @start && @start >= count
      tries = @proxies.length unless @noproxy
      puts "lin #{count}/#{@input_length}"
      # begin
        urls = input_row['Urls']
        if urls && urls.include?('http')
          urls = urls.split(', ')
          correct_url, correct_page = nil
          urls.each do |url|
            correct_url, correct_page = validate(url, input_row)
            break if correct_url && correct_page
          end
          if correct_url
            puts "correct page"
            input_row << ["Linkedin Profile", correct_url]
            input_row["Linkedin Import Status"] = 'Profile imported'
            input_row.delete('Urls')
            if input_row['Contact ID'] && input_row['Contact ID'].strip.length > 0
              if @options[:update]
                new_row = scrape_contact(input_row, correct_page, 'update')
                puts "outputting update"
                append_to_csv(@output_update, new_row)
                scrape_employment(input_row, correct_page).each do |emp_row|
                  append_to_csv(@output_employment_update, emp_row)
                end
                scrape_education(input_row, correct_page).each do |ed_row|
                  append_to_csv(@output_education_update, ed_row)
                end
              end
            else
              if @options[:insert]
                new_row = scrape_contact(input_row, correct_page, 'insert')
                puts "outputting insert"
                append_to_csv(@output_insert, new_row)
                scrape_employment(input_row, correct_page).each do |emp_row|
                  append_to_csv(@output_employment_insert, emp_row)
                end
                scrape_education(input_row, correct_page).each do |ed_row|
                  append_to_csv(@output_education_insert, ed_row)
                end
              end
            end


          else
            if @options[:update] && input_row['Contact ID'] && input_row['Contact ID'].strip.length > 0
              input_row << ["Linkedin Profile", nil]
              input_row.delete('Urls')
              input_row["Linkedin Import Status"] = 'Profile not found'
              output_row = create_row(input_row, @headers)
              puts "outputting update"
              puts input_row["Linkedin Import Status"]
              append_to_csv(@output_update, output_row)
            elsif @options [:insert]
              input_row << ["Linkedin Profile", nil]
              input_row.delete('Urls')
              input_row["Linkedin Import Status"] = 'Profile not found'
              puts "outputting insert"
              puts input_row["Linkedin Import Status"]
              output_row = create_row(input_row, @headers)
              append_to_csv(@output_insert, output_row)
            end
          end
        else
          if @options[:update] && input_row['Contact ID'] && input_row['Contact ID'].strip.length > 0
            input_row << ["Linkedin Profile", nil]
            input_row.delete('Urls')
            puts "outputting update"
            puts input_row["Linkedin Import Status"]
            output_row = create_row(input_row, @headers)
            append_to_csv(@output_update, output_row)
          elsif @options [:insert]
            input_row << ["Linkedin Profile", nil]
            input_row.delete('Urls')
            puts "outputting insert"
            puts input_row["Linkedin Import Status"]
            output_row = create_row(input_row, @headers)
            append_to_csv(@output_insert, output_row)
          end
        end
      # rescue Exception => msg
      #   tries -= 1
      #   if tries > 0
      #     puts "\n\n"
      #     puts msg
      #     puts 'RETRYING'
      #     puts "\n\n"
      #     if msg.to_s.start_with?("999")
      #       proxy.dead
      #     else
      #       proxy.used
      #     end
      #     retry
      #   else
      #     #append_ddg_row(input_row, msg, nil)
      #     puts msg
      #   end
      # end
    end

  end

end
