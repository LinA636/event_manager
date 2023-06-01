require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'

# METHODS 
def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,'0')[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output') #create on output folder
  
    filename = "output/thanks_#{id}.html"
  
    File.open(filename, 'w') do |file|
      file.puts form_letter
    end
end

def clean_phone_number(phone_number)
  phone_number.gsub!(/[^\d]/,'')
  if phone_number.length == 10
    phone_number
  elsif phone_number.length == 11 && phone_number[0] == 1
    phone_number[1..phone_number.length]
  else
    phone_number = "bad Number"
  end
end

def get_regdate(regdates)
  Date._parse(regdates)[:hour]
end

# EXECUTION
filename_attendees = 'event_attendees.csv'
filename_form_letter = 'form_letter.html'

template_letter = File.read(filename_form_letter)
erb_template = ERB.new template_letter

contents = CSV.open(
  filename_attendees, 
  headers: true,
  header_converters: :symbol)

hours = []
days = []

contents.each do |row|
  id = row[0]
  name = row[:first_name]

  zipcode = clean_zipcode(row[:zipcode])

  legislators = legislators_by_zipcode(zipcode)

  phone_numbers = clean_phone_number(row[:homephone])
  
  form_letter = erb_template.result(binding) 

  regdate = get_regdate(row[:regdate])
  hours.push(regdate[:hour])
  days.push(regdate[:mday])

  save_thank_you_letter(id, form_letter)
end


